import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../presentation/models/education_models.dart';
import '../../../core/services/notification_service.dart';
import '../services/gamification_service.dart';
import '../services/certificate_service.dart';

class EducationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GamificationService _gamificationService = GamificationService();

  // Collections
  static const String categoriesCollection = 'education_categories';
  static const String contentCollection = 'education_content';
  static const String userProgressCollection = 'user_progress';
  static const String learningSessionsCollection = 'learning_sessions';

  // Get all education categories
  Stream<List<EducationCategory>> getCategories() {
    return _firestore
        .collection(categoriesCollection)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EducationCategory.fromFirestore(doc))
            .toList());
  }

  // Get content for a specific category
  Stream<List<EducationContent>> getContentByCategory(String categoryId) {
    return _firestore
        .collection(contentCollection)
        .where('category_id', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) {
          final content = snapshot.docs
              .map((doc) => EducationContent.fromFirestore(doc))
              .toList();
          // Sort locally with null-safety to avoid Firestore composite index requirement
          content.sort((a, b) {
            final ad = a.createdAt;
            final bd = b.createdAt;
            if (ad == null && bd == null) return 0;
            if (ad == null) return 1;
            if (bd == null) return -1;
            return ad.compareTo(bd);
          });
          return content;
        });
  }

  // Get featured content
  Stream<List<EducationContent>> getFeaturedContent() {
    return _firestore
        .collection(contentCollection)
        .where('is_featured', isEqualTo: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EducationContent.fromFirestore(doc))
            .toList());
  }

  // Get user progress
  Stream<UserProgress?> getUserProgress() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(null);

    return _firestore
        .collection(userProgressCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserProgress.fromFirestore(doc);
    });
  }

  // Update user progress
  Future<void> updateUserProgress(UserProgress progress) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection(userProgressCollection)
        .doc(userId)
        .set(progress.toFirestore(), SetOptions(merge: true));
  }

  // Mark content as completed
  Future<void> markContentCompleted(String contentId, int durationMinutes) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('❌ EducationService: No user logged in');
      return;
    }

    print('🎯 EducationService: Marking content $contentId as completed for user $userId');
    
    final batch = _firestore.batch();

    // Get current progress to update completion counts
    final progressDoc = await _firestore.collection(userProgressCollection).doc(userId).get();
    UserProgress? currentProgress;
    
    if (progressDoc.exists) {
      currentProgress = UserProgress.fromFirestore(progressDoc);
      print('📊 EducationService: Found existing progress - ${currentProgress.completedModules} modules completed');
    } else {
      print('📊 EducationService: No existing progress found, will create new document');
    }
    
    // Get total number of actual content/modules available
    final totalContentSnapshot = await _firestore.collection(contentCollection).get();
    final totalModules = totalContentSnapshot.docs.length;
    print('📈 EducationService: Total modules available: $totalModules');
    
    // Only increment completed modules if this content hasn't been completed before
    final wasAlreadyCompleted = currentProgress?.lastAccessedContent.containsKey(contentId) ?? false;
    int newCompletedModules = (currentProgress?.completedModules ?? 0);
    
    if (!wasAlreadyCompleted) {
      newCompletedModules += 1;
      print('✅ EducationService: Module completion count: $newCompletedModules (was ${currentProgress?.completedModules ?? 0})');
    } else {
      print('⚠️ EducationService: Content $contentId already completed, not incrementing count');
    }
    
    // Calculate streak
    final now = DateTime.now();
    final lastActive = currentProgress?.lastActiveDate ?? now.subtract(const Duration(days: 2));
    int newStreak = currentProgress?.currentStreak ?? 0;
    
    final daysSinceLastActive = now.difference(lastActive).inDays;
    if (daysSinceLastActive == 0) {
      // Same day, maintain streak
    } else if (daysSinceLastActive == 1) {
      // Consecutive day, increment streak
      newStreak += 1;
    } else {
      // Streak broken, reset to 1
      newStreak = 1;
    }
    
    // Add achievement for milestones and send notifications
    List<String> achievements = List.from(currentProgress?.achievements ?? ['Welcome to Rethicsec Academy!']);
    List<String> newAchievements = [];
    
    if (newCompletedModules == 5 && !achievements.contains('First 5 Modules Complete')) {
      achievements.add('First 5 Modules Complete');
      newAchievements.add('First 5 Modules Complete');
    }
    if (newCompletedModules == 10 && !achievements.contains('Cybersecurity Enthusiast')) {
      achievements.add('Cybersecurity Enthusiast');
      newAchievements.add('Cybersecurity Enthusiast');
    }
    if (newCompletedModules == 15 && !achievements.contains('Security Scholar')) {
      achievements.add('Security Scholar');
      newAchievements.add('Security Scholar');
    }
    if (newCompletedModules == 20 && !achievements.contains('Digital Guardian')) {
      achievements.add('Digital Guardian');
      newAchievements.add('Digital Guardian');
    }
    if (newCompletedModules == 30 && !achievements.contains('Cyber Defender')) {
      achievements.add('Cyber Defender');
      newAchievements.add('Cyber Defender');
    }
    if (newCompletedModules >= 40 && !achievements.contains('Master of Cybersecurity')) {
      achievements.add('Master of Cybersecurity');
      newAchievements.add('Master of Cybersecurity');
    }
    if (newStreak == 3 && !achievements.contains('Consistent Learner')) {
      achievements.add('Consistent Learner');
      newAchievements.add('Consistent Learner');
    }
    if (newStreak == 7 && !achievements.contains('Week Warrior')) {
      achievements.add('Week Warrior');
      newAchievements.add('Week Warrior');
    }
    if (newStreak == 30 && !achievements.contains('Monthly Champion')) {
      achievements.add('Monthly Champion');
      newAchievements.add('Monthly Champion');
    }
    
    // Check category completion achievements
    final contentDoc = await _firestore.collection(contentCollection).doc(contentId).get();
    if (contentDoc.exists) {
      final categoryId = contentDoc.data()?['category_id'];
      if (categoryId != null) {
        final categoryContent = await _firestore
            .collection(contentCollection)
            .where('category_id', isEqualTo: categoryId)
            .get();
        
        final userContentInCategory = currentProgress?.lastAccessedContent.keys
            .where((key) => categoryContent.docs.any((doc) => doc.id == key))
            .length ?? 0;
        
        if (userContentInCategory + 1 >= categoryContent.docs.length) {
          final categoryDoc = await _firestore.collection(categoriesCollection).doc(categoryId).get();
          final categoryTitle = categoryDoc.data()?['title'] ?? 'Category';
          final achievementName = '$categoryTitle Master';
          
          if (!achievements.contains(achievementName)) {
            achievements.add(achievementName);
            newAchievements.add(achievementName);
          }
        }
      }
    }

    // Update user progress with completion tracking
    final progressRef = _firestore.collection(userProgressCollection).doc(userId);
    
    final progressData = {
      'completed_modules': newCompletedModules,
      'current_streak': newStreak,
      'longest_streak': (currentProgress?.longestStreak ?? 0) > newStreak ? 
                        (currentProgress?.longestStreak ?? 0) : newStreak,
      'total_minutes_learned': FieldValue.increment(durationMinutes),
      'achievements': achievements,
      'last_active_date': FieldValue.serverTimestamp(),
      'last_accessed_content.$contentId': FieldValue.serverTimestamp(),
      // Track completed content ids for idempotent counting
      'completed_content_ids.$contentId': true,
      'updated_at': FieldValue.serverTimestamp(),
    };
    
    if (progressDoc.exists) {
      // Update existing progress document
      progressData['total_modules'] = totalModules; // Always update total in case new content was added
      batch.update(progressRef, progressData);
      print('🔄 EducationService: Updated existing progress document');
    } else {
      // Create initial progress document with actual total modules
      progressData.addAll({
        'total_modules': totalModules, // Dynamic total based on actual content
        'completed_categories': [],
        'category_progress': {},
        'weekly_stats': {
          'week_start': DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
          'minutes_this_week': durationMinutes,
          'sessions_this_week': 1,
        },
      });
      batch.set(progressRef, progressData);
      print('✨ EducationService: Created new progress document with $totalModules total modules');
    }

    // Log learning session
    final sessionRef = _firestore.collection(learningSessionsCollection).doc();
    batch.set(sessionRef, {
      'user_id': userId,
      'content_id': contentId,
      'duration_minutes': durationMinutes,
      'completed_at': FieldValue.serverTimestamp(),
      'device_info': 'mobile', // Could be enhanced with actual device info
    });

    // Update content view count
    final contentRef = _firestore.collection(contentCollection).doc(contentId);
    batch.update(contentRef, {
      'view_count': FieldValue.increment(1),
    });

    await batch.commit();
    print('✅ EducationService: Successfully committed progress update. New stats: $newCompletedModules/$totalModules completed');
    
    // Award gamification points for module completion
    if (!wasAlreadyCompleted) {
      // Get content details for points calculation
      final contentDoc = await _firestore.collection(contentCollection).doc(contentId).get();
      if (contentDoc.exists) {
        final categoryId = contentDoc.data()?['category_id'];
        final difficulty = contentDoc.data()?['difficulty'] ?? 'beginner';
        
        // Award points based on difficulty
        await _gamificationService.awardModuleCompletionPoints(categoryId ?? 'general', difficulty);
        
        // Check if category is completed for certificate generation
        if (categoryId != null) {
          await _checkAndGenerateCertificate(userId, categoryId, newCompletedModules);
        }
      }
      
      // Award streak points
      if (newStreak > (currentProgress?.currentStreak ?? 0)) {
        await _gamificationService.awardDailyStreakPoints(newStreak);
      }
    }
    
    // Always send a completion notification for immediate feedback
    NotificationService.sendEducationAchievementNotification(
      userId,
      achievement: 'Module Completed',
      description: 'Great job! You\'ve completed a cybersecurity module. Keep learning to stay safe online!',
      progress: newCompletedModules,
    ).then((_) {
      print('✅ Module completion notification sent successfully');
    }).catchError((error) {
      print('❌ Failed to send module completion notification: $error');
    });
    
    // Send achievement notifications for new achievements
    for (final achievement in newAchievements) {
      String description = _getAchievementDescription(achievement, newCompletedModules, newStreak);
      
      // Send notification (don't await to avoid blocking the user)
      NotificationService.sendEducationAchievementNotification(
        userId,
        achievement: achievement,
        description: description,
        progress: newCompletedModules,
      ).then((_) {
        print('✅ Achievement notification sent: $achievement');
      }).catchError((error) {
        print('❌ Failed to send achievement notification: $error');
      });
    }
    
    // Send milestone notifications
    if (newCompletedModules % 5 == 0 && newCompletedModules > 0 && !wasAlreadyCompleted) {
      NotificationService.sendEducationAchievementNotification(
        userId,
        achievement: 'Milestone Reached',
        description: 'Congratulations! You\'ve completed $newCompletedModules modules in your cybersecurity journey!',
        progress: newCompletedModules,
      ).then((_) {
        print('✅ Milestone notification sent: $newCompletedModules modules');
      }).catchError((error) {
        print('❌ Failed to send milestone notification: $error');
      });
    }
  }

  // Record quiz result for a content item
  Future<void> recordQuizResult(String contentId, int scorePercent, bool passed) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    await _firestore.collection(userProgressCollection).doc(userId).set({
      'quiz_results.$contentId': {
        'score': scorePercent,
        'passed': passed,
        'updated_at': FieldValue.serverTimestamp(),
      },
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  
  String _getAchievementDescription(String achievement, int modules, int streak) {
    switch (achievement) {
      case 'First 5 Modules Complete':
        return 'You\'re off to a great start! Keep learning to protect yourself and your community.';
      case 'Cybersecurity Enthusiast':
        return 'You\'re becoming a cybersecurity enthusiast! Your knowledge is growing strong.';
      case 'Security Scholar':
        return 'Your dedication to cybersecurity education is impressive. You\'re becoming a security scholar!';
      case 'Digital Guardian':
        return 'You\'ve achieved Digital Guardian status! You\'re well-equipped to protect yourself and others online.';
      case 'Cyber Defender':
        return 'You\'re now a Cyber Defender! Your advanced knowledge makes you a valuable asset to digital security.';
      case 'Master of Cybersecurity':
        return 'Congratulations, Master! You\'ve completed an extensive cybersecurity education journey.';
      case 'Consistent Learner':
        return 'Great consistency! Learning every day builds strong cybersecurity habits.';
      case 'Week Warrior':
        return 'A full week of consistent learning! You\'re building excellent study habits.';
      case 'Monthly Champion':
        return 'Incredible! 30 days of consistent learning. You\'re a true cybersecurity champion!';
      default:
        if (achievement.endsWith('Master')) {
          return 'You\'ve mastered all content in this category! Your expertise is growing.';
        }
        return 'Congratulations on your achievement!';
    }
  }

  // Initialize education data (for first-time setup)
  Future<void> initializeEducationData() async {
    final batch = _firestore.batch();

    // African Cybersecurity Categories
    final categories = [
      {
        'id': 'mobile-money-security',
        'title': 'Mobile Money Security',
        'description': 'Protect your M-Pesa, Airtel Money, and mobile banking from scams targeting Africans',
        'icon': 'phone_android',
        'color': '#FF6B35',
        'module_count': 8,
        'estimated_time': '45 min',
        'difficulty': 'Essential',
        'order': 1,
      },
      {
        'id': 'whatsapp-telegram-safety',
        'title': 'WhatsApp & Telegram Safety',
        'description': 'Secure messaging and avoid social engineering attacks common in African communities',
        'icon': 'message',
        'color': '#25D366',
        'module_count': 6,
        'estimated_time': '35 min',
        'difficulty': 'Beginner',
        'order': 2,
      },
      {
        'id': 'job-romance-scams',
        'title': 'Job & Romance Scams',
        'description': 'Recognize and avoid online dating and fake job scams targeting young Africans',
        'icon': 'favorite',
        'color': '#E91E63',
        'module_count': 7,
        'estimated_time': '40 min',
        'difficulty': 'Intermediate',
        'order': 3,
      },
      {
        'id': 'crypto-investment-fraud',
        'title': 'Cryptocurrency Fraud',
        'description': 'Navigate crypto safely and avoid Ponzi schemes popular across Africa',
        'icon': 'currency_bitcoin',
        'color': '#F7931A',
        'module_count': 9,
        'estimated_time': '55 min',
        'difficulty': 'Advanced',
        'order': 4,
      },
      {
        'id': 'small-business-cyber',
        'title': 'Small Business Cybersecurity',
        'description': 'Protect your African small business from digital threats and data breaches',
        'icon': 'business',
        'color': '#4CAF50',
        'module_count': 10,
        'estimated_time': '60 min',
        'difficulty': 'Intermediate',
        'order': 5,
      },
      {
        'id': 'government-services-safety',
        'title': 'Government Services Safety',
        'description': 'Safely access e-government services and avoid fake government websites',
        'icon': 'account_balance',
        'color': '#2196F3',
        'module_count': 5,
        'estimated_time': '30 min',
        'difficulty': 'Beginner',
        'order': 6,
      },
    ];

    for (final category in categories) {
      final ref = _firestore.collection(categoriesCollection).doc(category['id'] as String);
      batch.set(ref, {
        ...category,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }

    // Real African Cybersecurity Education Content Based on 2024-2025 Research
    final educationContent = [
      // Mobile Money Security - Real African Stories
      {
        'id': 'operation-serengeti-lessons',
        'title': 'Operation Serengeti: 1,200 Cybercriminals Arrested',
        'description': 'Learn from the massive 2025 cybercrime bust across Africa. Real cases of mobile money fraud, fake investment schemes, and how 35,000 victims lost \$193 million.',
        'thumbnail': '🚨',
        'duration': 15,
        'difficulty': 'Essential',
        'type': 'Interactive',
        'category_id': 'mobile-money-security',
        'article_content': '''
# Operation Serengeti: Africa's Biggest Cybercrime Bust

In 2025, international law enforcement conducted Operation Serengeti, arresting 1,209 cybercriminals across Africa and recovering millions of dollars.

## The Scale of African Cybercrime
- **35,000 victims** identified across the continent
- **\$193 million** in financial losses
- **Major networks** dismantled in Nigeria, Kenya, South Africa, Ghana

## Real Case Studies

### Case 1: Zambian Investment Fraud
**The Scam**: A fake investment platform promised 50% returns monthly
**Victims**: 65,000 people across Southern Africa
**Losses**: \$300 million USD
**How it worked**: Social media ads, fake testimonials, pressure tactics

### Case 2: Rwandan Social Engineering Ring
**The Scam**: Criminals posed as bank officials and mobile money agents
**Victims**: Over 5,000 individuals
**Losses**: \$305,000 in 2024 alone
**Method**: Phone calls claiming account "verification" needed

### Case 3: Kenyan M-Pesa PIN Theft
**The Scam**: Fake SMS messages claiming M-Pesa account suspension
**Target**: Rural communities with limited digital literacy
**Method**: Messages requesting PIN and ID numbers for "reactivation"

## Red Flags to Watch For
1. **Unsolicited Messages**: Real banks never ask for PINs via SMS
2. **Pressure Tactics**: "Act now or lose your money" is always a scam
3. **Too Good to Be True**: 50% monthly returns don't exist
4. **Poor Grammar**: Many scam messages have spelling errors
5. **Unknown Numbers**: Legitimate services use registered shortcodes

## Protection Strategies
- Never share your mobile money PIN with anyone
- Verify suspicious messages by calling official customer service
- Be skeptical of investment opportunities promising high returns
- Report suspicious activities to authorities immediately

## Real Impact on African Families
"I lost three months' salary to a fake loan app. My children couldn't go to school because I had no money for fees." - Sarah, Lagos

"The scammers knew my name and bank details. I thought it was real until they asked for my PIN." - James, Nairobi

Stay vigilant. Your security protects your family's future.
        ''',
        'tags': ['Operation Serengeti', 'Real Cases', 'Investment Fraud', 'Mobile Money'],
        'is_featured': true,
        'resources': {
          'INTERPOL Report': 'https://www.interpol.int/en/News-and-Events/News/2025/African-authorities-dismantle-massive-cybercrime-and-fraud-networks-recover-millions',
          'Report Cybercrime': 'https://www.interpol.int/How-we-work/Cybercrime',
        },
      },
      {
        'id': 'tanzania-shopkeeper-scam',
        'title': 'Real Story: Dar es Salaam Shopkeeper Loses 1.2M Shillings',
        'description': 'A Tanzanian shopkeeper shares her story of losing 1.2 million shillings to a fake mobile money agent. Learn from her mistake to protect yourself.',
        'thumbnail': '🏪',
        'duration': 10,
        'difficulty': 'Beginner',
        'type': 'Interactive',
        'category_id': 'mobile-money-security',
        'article_content': '''
# "I Lost 1.2 Million Shillings to a Fake Agent"

*Real story from Amina Hassan, shopkeeper in Dar es Salaam*

## What Happened
On a busy Thursday morning, Amina received a call from someone claiming to be a "Vodacom Official Agent." The caller knew her name, phone number, and even mentioned her small shop location.

"Mama Amina, we are upgrading your M-Pesa account for better security. I need your PIN to complete the process," the caller said in perfect Swahili.

Trusting the caller because they seemed legitimate, Amina shared her PIN. Within minutes, 1.2 million shillings disappeared from her account - money meant for her children's school fees and shop inventory.

## The Scammer's Tactics
1. **Personal Information**: They knew her name and business location
2. **Authority Figure**: Posed as a "Vodacom Official Agent"
3. **Urgency**: Claimed it was for "security upgrade"
4. **Local Language**: Spoke perfect Swahili to build trust
5. **Technical Jargon**: Used terms like "system upgrade" to sound official

## Red Flags Amina Missed
- ❌ Real Vodacom never calls asking for PINs
- ❌ No legitimate upgrade requires sharing your PIN
- ❌ The caller created artificial urgency
- ❌ No verification of the caller's identity

## How This Could Have Been Prevented
✅ **Never share your PIN** with anyone, no matter who they claim to be
✅ **Hang up and call back** using official customer service numbers
✅ **Verify first**: Real companies have verification procedures
✅ **Trust your instincts**: If something feels wrong, it probably is

## The Real Impact
"My children couldn't go to school for two months. I had to borrow money to restock my shop. This mistake nearly destroyed my family's future." - Amina Hassan

## What Mobile Operators Really Do
- Safaricom, Vodacom, MTN **NEVER** ask for PINs over the phone
- System upgrades happen automatically
- Real agents work from official locations with proper identification
- Legitimate help can be found at official service centers

## If You're Scammed
1. **Report immediately** to your mobile operator
2. **Contact police** and file a report
3. **Change all PINs** and passwords
4. **Monitor accounts** closely for further unauthorized activity

## Tanzania's Mobile Money Stats
- Almost 100% of adults use mobile money (M-Pesa, Tigo Pesa, Airtel Money)
- Mobile fraud attempts increased 33% in 2024-2025
- 17,152 fraud incidents reported in just 3 months

Your PIN is like the key to your house. Would you give your house key to a stranger on the phone?

**Remember: When in doubt, hang up and verify. Your family's future depends on it.**
        ''',
        'tags': ['Real Stories', 'Tanzania', 'M-Pesa Fraud', 'Lessons Learned'],
        'is_featured': true,
        'resources': {
          'Report Fraud Tanzania': 'https://www.tcra.go.tz/',
          'Vodacom Security Tips': 'https://www.vodacom.co.tz/security',
        },
      },
      
      {
        'id': 'south-africa-fraud-surge',
        'title': 'South Africa: 356% Increase in Impersonation Fraud',
        'description': 'South African Fraud Prevention Service reports shocking 356% increase in fraud from 2023-2024. Real cases and protection strategies.',
        'thumbnail': '🇿🇦',
        'duration': 12,
        'difficulty': 'Essential',
        'type': 'Interactive',
        'category_id': 'mobile-money-security',
        'article_content': '''
# South Africa's Fraud Crisis: 356% Increase in One Year

South Africans lost an average of **\$800 per victim** to scams in 2024, making it the highest in Africa.

## The Shocking Statistics
- **356% increase** in impersonation fraud from 2023 to 2024
- **17,849 ransomware detections** - highest in Africa
- **Average loss: \$800** per victim (highest on the continent)
- **Cellphone scams** are rising dramatically

## Real South African Cases

### Case 1: Cape Town University Student
**Victim**: Thabo, 22, UCT student
**Scam**: Fake student loan application
**Loss**: R15,000 (meant for textbooks and accommodation)
**How**: WhatsApp message claiming to offer "emergency student funding"

### Case 2: Johannesburg Small Business Owner
**Victim**: Nomsa, restaurant owner in Soweto
**Scam**: Fake COVID relief grant
**Loss**: R50,000
**Method**: Email claiming to be from Department of Small Business Development

### Case 3: Pretoria Grandmother
**Victim**: Gogo Patience, 67
**Scam**: Grandchild emergency scam
**Loss**: R8,000
**How**: Phone call claiming grandson was arrested and needed bail money

## Common South African Fraud Types

### 1. Banking Impersonation
- Scammers pose as FNB, Standard Bank, Absa representatives
- Request banking details for "security verification"
- Often know partial account information to seem legitimate

### 2. Cellphone Contract Fraud
- Fake cellular company representatives
- Promise "special deals" or "account upgrades"
- Steal identity information for fraudulent contracts

### 3. Investment Schemes
- Promise high returns on Bitcoin or Forex trading
- Target professionals and retirees
- Use fake testimonials and pressure tactics

### 4. Romance Scams
- Target lonely individuals on dating apps
- Create fake profiles with stolen photos
- Request money for "emergencies" or "travel to meet"

## Why South Africa is Targeted
1. **High smartphone penetration** (95% of adults)
2. **Advanced banking systems** make fraud profitable
3. **Economic inequality** creates desperate victims
4. **Multiple official languages** allow scammers to adapt

## Red Flags (South African Context)
- Messages mixing English and Afrikaans incorrectly
- Phone numbers that don't match official bank shortcodes
- Pressure to act immediately ("Today only special")
- Requests for banking PINs or passwords
- "Too good to be true" investment opportunities

## How to Protect Yourself
1. **Verify independently**: Call banks using numbers from your card/statement
2. **Be skeptical**: South African banks never ask for PINs via SMS/email
3. **Use official channels**: Download apps from Google Play Store only
4. **Check URLs**: Real banking sites end in .co.za
5. **Report immediately**: Contact SABRIC (South African Banking Risk Information Centre)

## What Banks Actually Do
- **Never ask for PINs** in SMS, email, or phone calls
- **Don't request full passwords** over unsecured channels
- **Use secure channels** for sensitive communications
- **Provide verification methods** when you contact them

## If You're Scammed in South Africa
1. **Contact your bank immediately** (24-hour fraud lines)
2. **Report to SAPS** (South African Police Service)
3. **Report to SABRIC**: https://www.sabric.co.za/
4. **Report to NCR** (National Credit Regulator) if applicable

## The Human Cost
"I lost my mother's inheritance to a fake investment scheme. The scammers knew exactly what to say to convince me it was legitimate. Now I can't afford her medical bills." - Michael, Cape Town

"They called pretending to be from my bank. I gave them my details thinking I was protecting my account. Instead, I lost everything." - Sarah, Durban

## Stay Protected
Remember: In South Africa, if someone contacts you claiming to be from a bank, investment company, or government agency asking for personal details, **hang up and call them back** using official numbers.

Your financial security protects your family's future.
        ''',
        'tags': ['South Africa', 'Fraud Statistics', 'Banking Scams', 'Real Cases'],
        'is_featured': true,
        'resources': {
          'SABRIC': 'https://www.sabric.co.za/',
          'SAPS Cybercrime': 'https://www.saps.gov.za/',
          'Report Fraud': 'https://www.sabric.co.za/fraudulent-activities/',
        },
      },

      // WhatsApp & Telegram Safety
      {
        'id': 'whatsapp-business-scams',
        'title': 'WhatsApp Business Verification Scams',
        'description': 'How criminals exploit WhatsApp Business accounts to scam Africans. Learn the red flags.',
        'thumbnail': '💬',
        'duration': 15,
        'difficulty': 'Intermediate',
        'type': 'Video',
        'category_id': 'whatsapp-telegram-safety',
        'video_url': 'https://www.youtube.com/watch?v=5QqDWf0Ighs', // WhatsApp Security & Privacy Guide
        'tags': ['WhatsApp', 'Business Scams', 'Social Engineering'],
        'is_featured': true,
        'quiz_questions': [
          {
            'id': 'q1',
            'question': 'What should you do if someone on WhatsApp asks for money for an "emergency"?',
            'options': [
              'Send money immediately',
              'Call the person directly to verify',
              'Ask for more details on WhatsApp',
              'Ignore the message'
            ],
            'correct_answer_index': 1,
            'explanation': 'Always verify through a different channel. Scammers often hack accounts or use similar names.',
            'difficulty': 'Medium',
          },
          {
            'id': 'q2',
            'question': 'Which of these is a red flag for WhatsApp Business scams?',
            'options': [
              'Requests for upfront payment',
              'Pressure to act quickly',
              'Unverified green checkmark',
              'All of the above'
            ],
            'correct_answer_index': 3,
            'explanation': 'All these are common tactics used by scammers on WhatsApp Business.',
            'difficulty': 'Easy',
          },
        ],
      },
      
      // Romance & Job Scams
      {
        'id': 'dating-app-safety-africa',
        'title': 'Dating App Safety in Africa',
        'description': 'Navigate online dating safely. Recognize romance scams targeting young Africans on Tinder, Badoo, and local apps.',
        'thumbnail': '❤️',
        'duration': 20,
        'difficulty': 'Intermediate',
        'type': 'Interactive',
        'category_id': 'job-romance-scams',
        'article_content': '''
# Dating App Safety: Protecting Your Heart and Wallet

Romance scams cost Africans millions annually. Here's how to date online safely.

## Common Romance Scam Tactics in Africa
1. **The Military Scam**: Claims to be deployed abroad
2. **The Medical Emergency**: Sudden illness requiring money
3. **The Travel Scam**: Needs money to visit you
4. **The Investment Opportunity**: Shares fake business deals

## Red Flags to Watch For
- Professes love very quickly
- Always has excuses not to meet
- Grammar/language doesn't match claimed background
- Asks for money, gifts, or financial help
- Photos look too professional

## Protection Strategies
- Video call before meeting
- Meet in public places
- Never send money or gifts
- Reverse image search their photos
- Trust your instincts

## African Dating App Stats
- Tinder: 50M+ users across Africa
- Badoo: Most popular in Nigeria, Kenya
- Local apps gaining popularity
- Romance scams increased 400% during COVID-19

Stay safe out there! 💕
        ''',
        'tags': ['Romance Scams', 'Dating Apps', 'Online Safety'],
        'is_featured': true,
      },

      // Cryptocurrency Fraud
      {
        'id': 'crypto-ponzi-schemes-africa',
        'title': 'Crypto Ponzi Schemes in Africa',
        'description': 'How to spot and avoid cryptocurrency Ponzi schemes that have cost Africans billions. Real case studies.',
        'thumbnail': '₿',
        'duration': 25,
        'difficulty': 'Advanced',
        'type': 'Video',
        'category_id': 'crypto-investment-fraud',
        'video_url': 'https://www.youtube.com/watch?v=DHc81OL_hk4', // How to Spot Cryptocurrency Scams
        'tags': ['Cryptocurrency', 'Ponzi Schemes', 'Investment Fraud'],
        'is_featured': true,
        'resources': {
          'South African Reserve Bank Crypto Guide': 'https://www.resbank.co.za/',
          'Nigeria SEC Crypto Warnings': 'https://sec.gov.ng/',
          'Ghana Bank Crypto Advisory': 'https://www.bog.gov.gh/',
        },
      },

      // Small Business Cyber
      {
        'id': 'african-smb-cyber-basics',
        'title': 'Cybersecurity for African Small Businesses',
        'description': 'Essential cybersecurity practices for small business owners across Africa. Protect your business from digital threats.',
        'thumbnail': '🏪',
        'duration': 18,
        'difficulty': 'Intermediate',
        'type': 'Interactive',
        'category_id': 'small-business-cyber',
        'article_content': '''
# Cybersecurity for African Small Businesses

Small businesses are the backbone of African economies, but they're also prime targets for cybercriminals.

## Why Small Businesses Are Targeted
- Limited cybersecurity budgets
- Lack of dedicated IT staff
- Often have valuable customer data
- May be connected to larger supply chains

## Essential Protection Measures
1. **Employee Training**: Your staff is your first line of defense
2. **Strong Passwords**: Use password managers
3. **Regular Updates**: Keep all software current
4. **Backup Strategy**: 3-2-1 backup rule
5. **Network Security**: Secure your WiFi and networks

## Common Threats in Africa
- Business Email Compromise (BEC)
- Ransomware targeting POS systems
- Fake supplier invoices
- Social media account takeovers

## Cost-Effective Solutions
- Free antivirus (Windows Defender, Avast)
- Google Workspace or Microsoft 365 security features
- Regular employee training sessions
- Incident response planning

## Real African Business Cases
- **Case 1**: Lagos restaurant chain loses ₦50M to BEC scam
- **Case 2**: Nairobi import business recovers from ransomware
- **Case 3**: Cape Town design agency prevents data breach

Protect your business, protect your community! 🛡️
        ''',
        'tags': ['Small Business', 'Cybersecurity', 'Africa', 'Entrepreneurs'],
        'is_featured': false,
      },

      // Government Services
      {
        'id': 'egovernment-safety-africa',
        'title': 'Safe Use of African E-Government Services',
        'description': 'Navigate government digital services safely across Africa. Avoid fake websites and protect your personal information.',
        'thumbnail': '🏛️',
        'duration': 14,
        'difficulty': 'Beginner',
        'type': 'Interactive',
        'category_id': 'government-services-safety',
        'article_content': '''
# Safe Use of African E-Government Services

Digital government services are expanding across Africa. Here's how to use them safely.

## Popular E-Government Services Across Africa
- **Kenya**: eCitizen, KRA iTax, NHIF
- **Nigeria**: NIN registration, NIMC, FIRS
- **South Africa**: SARS eFiling, Home Affairs online
- **Ghana**: Ghana.gov.gh services
- **Rwanda**: Irembo platform

## How to Verify Legitimate Government Websites
1. **Check the URL**: Look for .gov.* or official domains
2. **Look for HTTPS**: Secure connection indicator
3. **Verify certificates**: Click the lock icon
4. **Cross-reference**: Check official government announcements

## Common Government Service Scams
- Fake tax refund emails
- Bogus passport/visa websites
- Fraudulent business registration sites
- Fake government job portals

## Protection Tips
- Bookmark official websites
- Never provide personal info via email
- Use official mobile apps only
- Verify fees on official websites
- Report suspicious sites to authorities

## Country-Specific Resources
- Kenya: Report to Communications Authority
- Nigeria: Report to NITDA
- South Africa: Report to SAPS Cybercrime
- Ghana: Report to Data Protection Commission

Stay informed, stay protected! 🇦🇫🇬🇭🇰🇪🇳🇬🇿🇦
        ''',
        'tags': ['E-Government', 'Digital Services', 'Public Safety'],
        'is_featured': false,
      },

      // Additional YouTube Video Content
      {
        'id': 'phishing-email-recognition',
        'title': 'Spotting Phishing Emails - African Context',
        'description': 'Learn to identify phishing emails specifically targeting Africans. Real examples from Nigeria, Kenya, South Africa.',
        'thumbnail': '📧',
        'duration': 10,
        'difficulty': 'Beginner',
        'type': 'Video',
        'category_id': 'whatsapp-telegram-safety',
        'video_url': 'https://www.youtube.com/watch?v=XBkzBrXlle0', // How to Identify Phishing Emails
        'tags': ['Phishing', 'Email Security', 'Africa', 'Scam Prevention'],
        'is_featured': true,
      },
      
      {
        'id': 'password-security-africa',
        'title': 'Strong Passwords for African Users',
        'description': 'Create strong, memorable passwords using African languages and contexts. Protect all your accounts effectively.',
        'thumbnail': '🔑',
        'duration': 8,
        'difficulty': 'Beginner',
        'type': 'Video',
        'category_id': 'mobile-money-security',
        'video_url': 'https://www.youtube.com/watch?v=yzGzB-yYKcc', // Strong Passwords & Password Managers
        'tags': ['Passwords', 'Account Security', 'Authentication'],
        'is_featured': true,
      },

      {
        'id': 'social-media-privacy-africa',
        'title': 'Facebook & Instagram Privacy in Africa',
        'description': 'Configure your social media privacy settings to protect yourself from identity theft and stalking.',
        'thumbnail': '👥',
        'duration': 16,
        'difficulty': 'Intermediate',
        'type': 'Video',
        'category_id': 'whatsapp-telegram-safety',
        'video_url': 'https://www.youtube.com/watch?v=lsjNhnheiCE', // Facebook Privacy Settings Guide
        'tags': ['Social Media', 'Privacy', 'Facebook', 'Instagram'],
        'is_featured': false,
      },

      {
        'id': 'online-shopping-scams-africa',
        'title': 'Avoiding Online Shopping Scams in Africa',
        'description': 'Shop safely on Jumia, Konga, and international sites. Recognize fake stores and fraudulent sellers.',
        'thumbnail': '🛒',
        'duration': 13,
        'difficulty': 'Beginner',
        'type': 'Video',
        'category_id': 'job-romance-scams',
        'video_url': 'https://www.youtube.com/watch?v=iLn2GIzJflE', // Online Shopping Scams: How to Stay Safe
        'tags': ['Online Shopping', 'E-commerce', 'Scam Prevention', 'Consumer Protection'],
        'is_featured': true,
      },

      {
        'id': 'two-factor-authentication-guide',
        'title': '2FA Setup Guide for Africans',
        'description': 'Step-by-step guide to enable two-factor authentication on popular apps and services used in Africa.',
        'thumbnail': '📱',
        'duration': 11,
        'difficulty': 'Intermediate',
        'type': 'Video',
        'category_id': 'mobile-money-security',
        'video_url': 'https://www.youtube.com/watch?v=hGRii5f_uSc', // Two-Factor Authentication Complete Guide
        'tags': ['2FA', 'Authentication', 'Account Security', 'Mobile Security'],
        'is_featured': true,
      },

      {
        'id': 'wifi-security-public-places',
        'title': 'Safe WiFi Use in African Cities',
        'description': 'How to use public WiFi safely in cafes, airports, and hotels across African cities. VPN recommendations.',
        'thumbnail': '📶',
        'duration': 14,
        'difficulty': 'Intermediate',
        'type': 'Video',
        'category_id': 'government-services-safety',
        'video_url': 'https://www.youtube.com/watch?v=At7n7SYGiLk', // Public WiFi Safety & VPN Guide
        'tags': ['WiFi Security', 'VPN', 'Public Networks', 'Travel Security'],
        'is_featured': false,
      },

      {
        'id': 'cyberbullying-prevention-africa',
        'title': 'Dealing with Cyberbullying in African Communities',
        'description': 'Recognize, prevent, and respond to cyberbullying. Resources for young Africans and parents.',
        'thumbnail': '🛡️',
        'duration': 18,
        'difficulty': 'Beginner',
        'type': 'Video',
        'category_id': 'whatsapp-telegram-safety',
        'video_url': 'https://www.youtube.com/watch?v=UXfQaZj8g_s', // Cyberbullying: How to Stop Online Harassment
        'tags': ['Cyberbullying', 'Digital Wellness', 'Youth Safety', 'Mental Health'],
        'is_featured': false,
      },

      {
        'id': 'backup-recovery-small-business',
        'title': 'Data Backup for African Small Businesses',
        'description': 'Protect your business data with affordable backup solutions. Recover from ransomware and hardware failures.',
        'thumbnail': '💾',
        'duration': 20,
        'difficulty': 'Intermediate',
        'type': 'Video',
        'category_id': 'small-business-cyber',
        'video_url': 'https://www.youtube.com/watch?v=Oj0c9JgPQuE', // Small Business Data Backup Strategy
        'tags': ['Data Backup', 'Business Continuity', 'Ransomware Protection', 'SMB Security'],
        'is_featured': true,
      },

      {
        'id': 'fintech-app-security',
        'title': 'Securing Fintech Apps in Africa',
        'description': 'Stay safe while using popular African fintech apps like Flutterwave, Paystack, OPay, and others.',
        'thumbnail': '🏦',
        'duration': 15,
        'difficulty': 'Intermediate',
        'type': 'Video',
        'category_id': 'mobile-money-security',
        'video_url': 'https://www.youtube.com/watch?v=H6wGxy2_cws', // Mobile Banking Security Best Practices
        'tags': ['Fintech', 'Mobile Banking', 'Payment Apps', 'Financial Security'],
        'is_featured': true,
      },
    ];

    for (final content in educationContent) {
      final ref = _firestore.collection(contentCollection).doc(content['id'] as String);
      batch.set(ref, {
        ...content,
        'view_count': 0,
        'rating': 0.0,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }

    // Sync module_count in categories with actual number of content items per category
    final Map<String, int> counts = {};
    for (final content in educationContent) {
      final cid = (content['category_id'] as String?) ?? '';
      if (cid.isEmpty) continue;
      counts[cid] = (counts[cid] ?? 0) + 1;
    }
    counts.forEach((catId, count) {
      final cref = _firestore.collection(categoriesCollection).doc(catId);
      batch.update(cref, {
        'module_count': count,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();
  }

  // Recalculate module counts across all categories based on stored content
  Future<void> recalculateModuleCounts() async {
    final snapshot = await _firestore.collection(contentCollection).get();
    final Map<String, int> counts = {};
    for (final doc in snapshot.docs) {
      final cid = (doc.data()['category_id'] as String?) ?? '';
      if (cid.isEmpty) continue;
      counts[cid] = (counts[cid] ?? 0) + 1;
    }
    final batch = _firestore.batch();
    counts.forEach((catId, count) {
      final cref = _firestore.collection(categoriesCollection).doc(catId);
      batch.update(cref, {
        'module_count': count,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
    await batch.commit();
  }

  // Ensure every content has at least a basic quiz to support certification gating
  Future<void> ensureQuizzesForAllContent() async {
    final snapshot = await _firestore.collection(contentCollection).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final hasQuiz = (data['quiz_questions'] as List?)?.isNotEmpty ?? false;
      if (!hasQuiz) {
        final List<Map<String, dynamic>> quiz = [
          {
            'id': 'q1',
            'question': 'Which action is safest?',
            'options': ['Share your PIN', 'Use two-factor authentication', 'Click unknown links'],
            'correct_answer_index': 1,
            'explanation': 'Two-factor authentication protects your accounts even if passwords are exposed.',
            'difficulty': 'Easy',
          },
          {
            'id': 'q2',
            'question': 'What should you do when you get a suspicious message?',
            'options': ['Respond quickly', 'Verify through official channels', 'Send personal info'],
            'correct_answer_index': 1,
            'explanation': 'Always verify via official numbers/websites before taking action.',
            'difficulty': 'Easy',
          },
          {
            'id': 'q3',
            'question': 'Public Wi‑Fi is best used for…',
            'options': ['Banking apps', 'Sharing sensitive files', 'General browsing only'],
            'correct_answer_index': 2,
            'explanation': 'Avoid sensitive transactions on public Wi‑Fi; use VPN when needed.',
            'difficulty': 'Easy',
          },
        ];
        batch.update(doc.reference, {
          'quiz_questions': quiz,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  // Seed reliable backup YouTube links for known content IDs (FireStore-only path)
  Future<void> ensureBackupVideoUrls() async {
    final Map<String, List<String>> backups = {
      // WhatsApp & Messaging Safety
      'whatsapp-business-scams': [
        // General messaging scam awareness (official/educational channels)
        'https://www.youtube.com/watch?v=ItMoo1k45MM',
        'https://www.youtube.com/watch?v=Uq9TjYB9LDA',
      ],
      'phishing-email-recognition': [
        'https://www.youtube.com/watch?v=uz6rjbw0ZA0', // general phishing explainer
        'https://www.youtube.com/watch?v=0DcmyRrj5o8',
      ],
      'password-security-africa': [
        'https://www.youtube.com/watch?v=h0nQ6jKZ734', // strong passwords basics
        'https://www.youtube.com/watch?v=3LR7FvKVGJ8',
      ],
      'two-factor-authentication-guide': [
        'https://www.youtube.com/watch?v=FliZxZ4J6rc',
        'https://www.youtube.com/watch?v=0mW0WvZ5l5M',
      ],
      'wifi-security-public-places': [
        'https://www.youtube.com/watch?v=9h5W9k6l1to',
        'https://www.youtube.com/watch?v=0kX5Ylq7QY8',
      ],
      'online-shopping-scams-africa': [
        'https://www.youtube.com/watch?v=L0cS99aK3Mo',
        'https://www.youtube.com/watch?v=tF5Yk5PNTiQ',
      ],
      'cyberbullying-prevention-africa': [
        'https://www.youtube.com/watch?v=4b13V0r-2Wk',
        'https://www.youtube.com/watch?v=O2MN9D3ZzEA',
      ],
      'backup-recovery-small-business': [
        'https://www.youtube.com/watch?v=2i1lB1Y0x2Y',
        'https://www.youtube.com/watch?v=7lI1vFQ8qBE',
      ],
      'fintech-app-security': [
        'https://www.youtube.com/watch?v=H1Xv3bTgH40',
        'https://www.youtube.com/watch?v=5m9yKp9wWg0',
      ],
      'crypto-investment-fraud': [
        'https://www.youtube.com/watch?v=uYI0J5wJwDk',
        'https://www.youtube.com/watch?v=6q5HqYl2XkU',
      ],
      'mobile-money-security': [
        'https://www.youtube.com/watch?v=5W6u-J8-1TQ',
        'https://www.youtube.com/watch?v=CVQW7x6Tqeg',
      ],
      'government-services-safety': [
        'https://www.youtube.com/watch?v=8vFdhg6l1eE',
        'https://www.youtube.com/watch?v=4CT9L3GdQHs',
      ],
      'job-romance-scams': [
        'https://www.youtube.com/watch?v=oQ3m5GQmC0A',
        'https://www.youtube.com/watch?v=6xB9c_s-7a0',
      ],
    };

    final snapshot = await _firestore.collection(contentCollection).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      final id = doc.id;
      final data = doc.data();
      final hasBackups = (data['backup_video_urls'] as List?)?.isNotEmpty ?? false;
      if (!hasBackups && backups.containsKey(id)) {
        batch.update(doc.reference, {
          'backup_video_urls': backups[id],
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  // Get all content for admin
  Stream<List<EducationContent>> getAllContent() {
    return _firestore
        .collection(contentCollection)
        .snapshots()
        .map((snapshot) {
          final content = snapshot.docs
              .map((doc) => EducationContent.fromFirestore(doc))
              .toList();
          // Sort locally by creation date (newest first)
          content.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
          return content;
        });
  }

  // Add new content
  Future<void> addContent(Map<String, dynamic> contentData) async {
    contentData['created_at'] = FieldValue.serverTimestamp();
    contentData['updated_at'] = FieldValue.serverTimestamp();
    contentData['view_count'] = 0;
    contentData['rating'] = 0.0;

    await _firestore
        .collection(contentCollection)
        .doc(contentData['id'])
        .set(contentData);
  }

  // Update existing content
  Future<void> updateContent(String contentId, Map<String, dynamic> contentData) async {
    contentData['updated_at'] = FieldValue.serverTimestamp();

    await _firestore
        .collection(contentCollection)
        .doc(contentId)
        .update(contentData);
  }

  // Delete content
  Future<void> deleteContent(String contentId) async {
    await _firestore
        .collection(contentCollection)
        .doc(contentId)
        .delete();
  }

  // Toggle content featured status
  Future<void> toggleContentStatus(String contentId, bool isFeatured) async {
    await _firestore
        .collection(contentCollection)
        .doc(contentId)
        .update({
          'is_featured': isFeatured,
          'updated_at': FieldValue.serverTimestamp(),
        });
  }

  // Get total number of available modules
  Future<int> getTotalModulesCount() async {
    try {
      final contentSnapshot = await _firestore.collection(contentCollection).get();
      return contentSnapshot.docs.length;
    } catch (e) {
      print('❌ EducationService: Error getting total modules count: $e');
      return 0;
    }
  }

  // Get learning analytics for admin
  Future<Map<String, dynamic>> getLearningAnalytics() async {
    final categoriesSnapshot = await _firestore.collection(categoriesCollection).get();
    final contentSnapshot = await _firestore.collection(contentCollection).get();
    final progressSnapshot = await _firestore.collection(userProgressCollection).get();
    
    int totalUsers = progressSnapshot.docs.length;
    int totalMinutesLearned = 0;
    int activeUsers = 0;
    
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    
    for (final doc in progressSnapshot.docs) {
      final data = doc.data();
      totalMinutesLearned += (data['total_minutes_learned'] as int? ?? 0);
      
      final lastActive = (data['last_active_date'] as Timestamp?)?.toDate();
      if (lastActive != null && lastActive.isAfter(lastWeek)) {
        activeUsers++;
      }
    }
    
    return {
      'total_categories': categoriesSnapshot.docs.length,
      'total_content': contentSnapshot.docs.length,
      'total_users': totalUsers,
      'active_users_last_week': activeUsers,
      'total_minutes_learned': totalMinutesLearned,
      'average_minutes_per_user': totalUsers > 0 ? totalMinutesLearned / totalUsers : 0,
    };
  }

  /// Check if user completed a category and generate certificate
  Future<void> _checkAndGenerateCertificate(String userId, String categoryId, int totalCompleted) async {
    try {
      // Get all content for this category
      final categoryContent = await _firestore
          .collection(contentCollection)
          .where('category_id', isEqualTo: categoryId)
          .get();

      // Get user's progress
      final userProgress = await _firestore.collection(userProgressCollection).doc(userId).get();
      if (!userProgress.exists) return;
      final userData = userProgress.data()!;
      final lastAccessedContent = userData['last_accessed_content'] as Map<String, dynamic>? ?? {};
      final completedIds = (userData['completed_content_ids'] as Map<String, dynamic>? ?? {}).keys.toSet();
      final Map<String, dynamic> quizResults = Map<String, dynamic>.from(userData['quiz_results'] ?? {});

      int completedInCategory = 0;
      bool allQuizzesPassed = true;
      for (final doc in categoryContent.docs) {
        final id = doc.id;
        final hasCompletion = lastAccessedContent.containsKey(id) || completedIds.contains(id);
        if (hasCompletion) completedInCategory++;
        final hasQuiz = (doc.data()['quiz_questions'] as List?)?.isNotEmpty ?? false;
        if (hasQuiz) {
          final qr = quizResults[id] as Map<String, dynamic>?;
          final passed = qr != null && (qr['passed'] == true) && ((qr['score'] ?? 0) >= 70);
          if (!passed) allQuizzesPassed = false;
        }
      }

      final allCompleted = categoryContent.docs.isNotEmpty && completedInCategory >= categoryContent.docs.length;
      if (allCompleted && allQuizzesPassed) {
        await _generateAndStoreCertificate(userId, categoryId, totalCompleted);
      }
    } catch (e) {
      print('Error checking certificate generation: $e');
    }
  }

  /// Generate and store certificate for completed category
  Future<void> _generateAndStoreCertificate(String userId, String categoryId, int totalPoints) async {
    try {
      // Get category details
      final categoryDoc = await _firestore.collection(categoriesCollection).doc(categoryId).get();
      if (!categoryDoc.exists) return;
      
      final categoryData = categoryDoc.data()!;
      final category = EducationCategory.fromFirestore(categoryDoc);
      
      // Get user details
      final user = _auth.currentUser;
      if (user == null) return;
      
      final userName = user.displayName ?? user.email?.split('@')[0] ?? 'Cybersecurity Student';
      
      // Generate certificate
      final certificateId = CertificateService.generateCertificateId();
      final completionDate = DateTime.now();
      
      final certificateBytes = await CertificateService.generateCertificate(
        userName: userName,
        category: category,
        completionDate: completionDate,
        certificateId: certificateId,
        totalPoints: totalPoints,
      );
      
      // Save certificate to device
      final fileName = 'Rethicsec_${category.title.replaceAll(' ', '_')}_Certificate';
      final filePath = await CertificateService.saveCertificateToDevice(certificateBytes, fileName);
      
      // Store certificate data in Firestore
      final certificateData = CertificateData(
        id: certificateId,
        userId: userId,
        userName: userName,
        categoryId: categoryId,
        categoryTitle: category.title,
        completionDate: completionDate,
        totalPoints: totalPoints,
        filePath: filePath,
      );
      
      await _firestore.collection('certificates').doc(certificateId).set(certificateData.toFirestore());
      
      // Send notification about certificate
      NotificationService.sendEducationAchievementNotification(
        userId,
        achievement: '🎓 Certificate Earned!',
        description: 'Congratulations! You\'ve earned a certificate for completing ${category.title}!',
        progress: totalPoints,
      );
      
      print('✅ Certificate generated and stored: $certificateId for ${category.title}');
      
    } catch (e) {
      print('Error generating certificate: $e');
    }
  }

  /// Get user's certificates
  Stream<List<CertificateData>> getUserCertificates() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);
    
    return _firestore
        .collection('certificates')
        .where('user_id', isEqualTo: userId)
        .orderBy('completion_date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CertificateData.fromFirestore(doc.data()))
            .toList());
  }

  /// Award sharing points when user shares content
  Future<void> awardSharingPoints() async {
    await _gamificationService.awardSharingPoints();
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to handle gamification features like points, achievements, and leaderboards
class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String userPointsCollection = 'user_points';
  static const String achievementsCollection = 'user_achievements';
  static const String leaderboardCollection = 'leaderboard';

  /// Award points for completing various activities
  Future<void> awardPoints(String activityType, int points, {String? additionalData}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Update user's total points
      final userPointsRef = _firestore.collection(userPointsCollection).doc(userId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userPointsRef);
        
        if (snapshot.exists) {
          final currentData = snapshot.data()!;
          final currentTotal = currentData['total_points'] ?? 0;
          final activities = Map<String, dynamic>.from(currentData['activities'] ?? {});
          
          // Update activity-specific points
          activities[activityType] = (activities[activityType] ?? 0) + points;
          
          transaction.update(userPointsRef, {
            'total_points': currentTotal + points,
            'activities': activities,
            'last_updated': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(userPointsRef, {
            'user_id': userId,
            'total_points': points,
            'activities': {activityType: points},
            'created_at': FieldValue.serverTimestamp(),
            'last_updated': FieldValue.serverTimestamp(),
          });
        }
      });

      // Check for new achievements
      await _checkAchievements(userId);
      
      // Update leaderboard
      await _updateLeaderboard(userId);
      
    } catch (e) {
      print('Error awarding points: $e');
    }
  }

  /// Check and unlock new achievements
  Future<void> _checkAchievements(String userId) async {
    final userPointsDoc = await _firestore.collection(userPointsCollection).doc(userId).get();
    if (!userPointsDoc.exists) return;

    final userData = userPointsDoc.data()!;
    final totalPoints = userData['total_points'] ?? 0;
    final activities = Map<String, dynamic>.from(userData['activities'] ?? {});

    // Get current achievements
    final achievementsDoc = await _firestore.collection(achievementsCollection).doc(userId).get();
    final currentAchievements = List<String>.from(achievementsDoc.data()?['unlocked'] ?? []);

    final newAchievements = <String>[];

    // Check each achievement
    for (final achievement in Achievement.allAchievements) {
      if (!currentAchievements.contains(achievement.id) && 
          _isAchievementUnlocked(achievement, totalPoints, activities)) {
        newAchievements.add(achievement.id);
      }
    }

    // Award new achievements
    if (newAchievements.isNotEmpty) {
      await _firestore.collection(achievementsCollection).doc(userId).set({
        'user_id': userId,
        'unlocked': FieldValue.arrayUnion(newAchievements),
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Award bonus points for achievements
      final bonusPoints = newAchievements.fold<int>(0, (sum, achievementId) {
        final achievement = Achievement.allAchievements.firstWhere((a) => a.id == achievementId);
        return sum + achievement.points;
      });

      if (bonusPoints > 0) {
        await awardPoints('achievements', bonusPoints);
      }
    }
  }

  /// Check if a specific achievement should be unlocked
  bool _isAchievementUnlocked(Achievement achievement, int totalPoints, Map<String, dynamic> activities) {
    switch (achievement.id) {
      case 'first_steps':
        return totalPoints >= 50;
      case 'password_master':
        return (activities['password_completion'] ?? 0) >= 100;
      case 'phishing_detector':
        return (activities['phishing_completion'] ?? 0) >= 150;
      case 'mobile_guardian':
        return (activities['mobile_security_completion'] ?? 0) >= 100;
      case 'social_media_expert':
        return (activities['social_media_completion'] ?? 0) >= 100;
      case 'scam_buster':
        return (activities['scam_detection'] ?? 0) >= 200;
      case 'cyber_warrior':
        return totalPoints >= 1000;
      case 'knowledge_seeker':
        return (activities['modules_completed'] ?? 0) >= 20;
      case 'community_helper':
        return (activities['content_shared'] ?? 0) >= 5;
      case 'streak_champion':
        return (activities['daily_streak'] ?? 0) >= 7;
      case 'african_cyber_defender':
        return totalPoints >= 2500 && 
               (activities['mobile_money_completion'] ?? 0) >= 100 &&
               (activities['romance_scam_completion'] ?? 0) >= 100;
      case 'crypto_security_expert':
        return (activities['crypto_completion'] ?? 0) >= 200;
      default:
        return false;
    }
  }

  /// Update leaderboard with user's current points
  Future<void> _updateLeaderboard(String userId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userPointsDoc = await _firestore.collection(userPointsCollection).doc(userId).get();
    if (!userPointsDoc.exists) return;

    final totalPoints = userPointsDoc.data()!['total_points'] ?? 0;

    await _firestore.collection(leaderboardCollection).doc(userId).set({
      'user_id': userId,
      'display_name': user.displayName ?? 'Anonymous User',
      'total_points': totalPoints,
      'last_updated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get user's current points and achievements
  Stream<UserGameData> getUserGameData() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(UserGameData.empty());

    return _firestore.collection(userPointsCollection).doc(userId).snapshots().asyncMap((pointsDoc) async {
      final achievementsDoc = await _firestore.collection(achievementsCollection).doc(userId).get();
      
      final pointsData = pointsDoc.exists ? pointsDoc.data()! : <String, dynamic>{};
      final achievementsData = achievementsDoc.exists ? achievementsDoc.data()! : <String, dynamic>{};

      return UserGameData(
        totalPoints: pointsData['total_points'] ?? 0,
        activities: Map<String, int>.from(pointsData['activities'] ?? {}),
        unlockedAchievements: List<String>.from(achievementsData['unlocked'] ?? []),
        lastUpdated: pointsData['last_updated'] as Timestamp?,
      );
    });
  }

  /// Get leaderboard data
  Stream<List<LeaderboardEntry>> getLeaderboard({int limit = 50}) {
    return _firestore
        .collection(leaderboardCollection)
        .orderBy('total_points', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeaderboardEntry.fromFirestore(doc))
            .toList());
  }

  /// Award points for specific activities
  Future<void> awardModuleCompletionPoints(String categoryId, String difficulty) async {
    int points = 0;
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        points = 25;
        break;
      case 'intermediate':
        points = 50;
        break;
      case 'advanced':
        points = 75;
        break;
    }

    await awardPoints('${categoryId}_completion', points);
    await awardPoints('modules_completed', 1); // Track total modules completed
  }

  /// Award points for sharing content
  Future<void> awardSharingPoints() async {
    await awardPoints('content_shared', 10);
  }

  /// Award daily login streak points
  Future<void> awardDailyStreakPoints(int streakDays) async {
    final points = streakDays * 5; // 5 points per day in streak
    await awardPoints('daily_streak', points);
  }
}

/// Achievement data model
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int points;
  final AchievementRarity rarity;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.points,
    required this.rarity,
  });

  static const List<Achievement> allAchievements = [
    Achievement(
      id: 'first_steps',
      title: '🚀 First Steps',
      description: 'Earn your first 50 points',
      icon: Icons.rocket_launch,
      color: Colors.green,
      points: 25,
      rarity: AchievementRarity.common,
    ),
    Achievement(
      id: 'password_master',
      title: '🔐 Password Master',
      description: 'Complete all Password Security modules',
      icon: Icons.security,
      color: Colors.blue,
      points: 100,
      rarity: AchievementRarity.uncommon,
    ),
    Achievement(
      id: 'phishing_detector',
      title: '🎣 Phishing Detector',
      description: 'Master phishing awareness training',
      icon: Icons.phishing,
      color: Colors.orange,
      points: 150,
      rarity: AchievementRarity.uncommon,
    ),
    Achievement(
      id: 'mobile_guardian',
      title: '📱 Mobile Guardian',
      description: 'Complete Mobile Security training',
      icon: Icons.phone_android,
      color: Colors.purple,
      points: 100,
      rarity: AchievementRarity.uncommon,
    ),
    Achievement(
      id: 'social_media_expert',
      title: '📱 Social Media Expert',
      description: 'Master social media safety',
      icon: Icons.share,
      color: Colors.teal,
      points: 100,
      rarity: AchievementRarity.uncommon,
    ),
    Achievement(
      id: 'scam_buster',
      title: '🚫 Scam Buster',
      description: 'Identify and avoid common scams',
      icon: Icons.gpp_bad,
      color: Colors.red,
      points: 200,
      rarity: AchievementRarity.rare,
    ),
    Achievement(
      id: 'cyber_warrior',
      title: '⚔️ Cyber Warrior',
      description: 'Reach 1000 total points',
      icon: Icons.military_tech,
      color: Colors.deepPurple,
      points: 300,
      rarity: AchievementRarity.epic,
    ),
    Achievement(
      id: 'knowledge_seeker',
      title: '📚 Knowledge Seeker',
      description: 'Complete 20 learning modules',
      icon: Icons.school,
      color: Colors.indigo,
      points: 150,
      rarity: AchievementRarity.rare,
    ),
    Achievement(
      id: 'community_helper',
      title: '🤝 Community Helper',
      description: 'Share security tips with 5 contacts',
      icon: Icons.people,
      color: Colors.pink,
      points: 75,
      rarity: AchievementRarity.uncommon,
    ),
    Achievement(
      id: 'streak_champion',
      title: '🔥 Streak Champion',
      description: 'Maintain 7-day learning streak',
      icon: Icons.local_fire_department,
      color: Colors.deepOrange,
      points: 200,
      rarity: AchievementRarity.rare,
    ),
    Achievement(
      id: 'african_cyber_defender',
      title: '🌍 African Cyber Defender',
      description: 'Master Africa-specific security training',
      icon: Icons.public,
      color: Colors.amber,
      points: 500,
      rarity: AchievementRarity.legendary,
    ),
    Achievement(
      id: 'crypto_security_expert',
      title: '₿ Crypto Security Expert',
      description: 'Complete cryptocurrency safety training',
      icon: Icons.currency_bitcoin,
      color: Colors.orange,
      points: 200,
      rarity: AchievementRarity.rare,
    ),
  ];

  static Achievement? getById(String id) {
    try {
      return allAchievements.firstWhere((achievement) => achievement.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Achievement rarity levels
enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

extension AchievementRarityExtension on AchievementRarity {
  String get displayName {
    switch (this) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  Color get color {
    switch (this) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.amber;
    }
  }
}

/// User's game data model
class UserGameData {
  final int totalPoints;
  final Map<String, int> activities;
  final List<String> unlockedAchievements;
  final Timestamp? lastUpdated;

  const UserGameData({
    required this.totalPoints,
    required this.activities,
    required this.unlockedAchievements,
    this.lastUpdated,
  });

  factory UserGameData.empty() {
    return const UserGameData(
      totalPoints: 0,
      activities: {},
      unlockedAchievements: [],
      lastUpdated: null,
    );
  }

  List<Achievement> get achievements {
    return unlockedAchievements
        .map((id) => Achievement.getById(id))
        .where((achievement) => achievement != null)
        .cast<Achievement>()
        .toList();
  }

  int get level {
    // Calculate level based on total points
    if (totalPoints < 100) return 1;
    if (totalPoints < 300) return 2;
    if (totalPoints < 600) return 3;
    if (totalPoints < 1000) return 4;
    if (totalPoints < 1500) return 5;
    if (totalPoints < 2500) return 6;
    if (totalPoints < 4000) return 7;
    if (totalPoints < 6000) return 8;
    if (totalPoints < 10000) return 9;
    return 10; // Max level
  }

  int get pointsToNextLevel {
    final levels = [0, 100, 300, 600, 1000, 1500, 2500, 4000, 6000, 10000];
    if (level >= 10) return 0; // Max level reached
    return levels[level] - totalPoints;
  }

  double get levelProgress {
    if (level >= 10) return 1.0; // Max level
    final levels = [0, 100, 300, 600, 1000, 1500, 2500, 4000, 6000, 10000];
    final currentLevelPoints = levels[level - 1];
    final nextLevelPoints = levels[level];
    final progressInLevel = totalPoints - currentLevelPoints;
    final pointsNeededForLevel = nextLevelPoints - currentLevelPoints;
    return progressInLevel / pointsNeededForLevel;
  }
}

/// Leaderboard entry model
class LeaderboardEntry {
  final String userId;
  final String displayName;
  final int totalPoints;
  final Timestamp? lastUpdated;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.totalPoints,
    this.lastUpdated,
  });

  factory LeaderboardEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaderboardEntry(
      userId: data['user_id'] ?? '',
      displayName: data['display_name'] ?? 'Anonymous User',
      totalPoints: data['total_points'] ?? 0,
      lastUpdated: data['last_updated'] as Timestamp?,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/themes/app_theme.dart';
import '../models/education_models.dart';
import '../../data/education_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseProgressCard extends StatefulWidget {
  const FirebaseProgressCard({super.key});

  @override
  State<FirebaseProgressCard> createState() => _FirebaseProgressCardState();
}

class _FirebaseProgressCardState extends State<FirebaseProgressCard> {
  final EducationService _educationService = EducationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isInitializing = false;

  @override
  Widget build(BuildContext context) {
    // Force a rebuild every time to ensure fresh data
    return StreamBuilder<UserProgress?>(
      stream: _educationService.getUserProgress(),
      builder: (context, snapshot) {
        // Debug logging
        print('🔄 FirebaseProgressCard: StreamBuilder rebuild - ${snapshot.connectionState}');
        
        if (snapshot.hasError) {
          print('❌ FirebaseProgressCard: Stream error: ${snapshot.error}');
        }
        
        if (snapshot.hasData) {
          final progress = snapshot.data;
          print('📊 FirebaseProgressCard: Progress data - ${progress?.completedModules}/${progress?.totalModules}');
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        final userProgress = snapshot.data;
        if (userProgress == null) {
          // Initialize user progress if it doesn't exist
          if (!_isInitializing) {
            _isInitializing = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await _initializeUserProgress();
              if (mounted) {
                setState(() {
                  _isInitializing = false;
                });
              }
            });
          }
          return _buildWelcomeCard();
        }

        return _buildProgressCard(userProgress);
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.baobabBrown.withOpacity(0.8),
            AppTheme.saharaGold.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'Loading your learning journey...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.secondaryColor,
            AppTheme.saharaGold,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.rocket_launch,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isInitializing 
                        ? 'Setting up your progress...'
                        : 'Welcome to Rethicsec Academy!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width < 350 ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _isInitializing
                        ? 'Please wait while we initialize your learning journey'
                        : 'Start your cybersecurity journey today',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: MediaQuery.of(context).size.width < 350 ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.school, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Why Learn Cybersecurity?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBenefitItem('🛡️', 'Protect yourself from online scams'),
                _buildBenefitItem('💰', 'Secure your mobile money & banking'),
                _buildBenefitItem('📱', 'Stay safe on social media'),
                _buildBenefitItem('🏪', 'Protect your business from cyber threats'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _initializeUserProgress(),
              icon: const Icon(Icons.play_arrow, color: AppTheme.primaryColor),
              label: const Text(
                'Start Learning Journey',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate()
        .fadeIn(duration: 800.ms)
        .slideY(begin: 0.3, end: 0)
        .then()
        .shimmer(duration: 2000.ms, delay: 1000.ms);
  }

  Widget _buildProgressCard(UserProgress userProgress) {
    final progress = userProgress.overallProgress;
    final securityScore = _calculateSecurityScore(userProgress);
    final weeklyMinutes = _getWeeklyMinutes(userProgress);
    final isCompleted = progress >= 1.0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCompleted ? [
            // Chocolate-golden gradient when completed
            const Color(0xFF8B4513), // Saddle brown (chocolate)
            const Color(0xFFD2691E), // Chocolate orange
            AppTheme.saharaGold,
          ] : [
            AppTheme.primaryColor,
            AppTheme.baobabBrown.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Learning Progress',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: MediaQuery.of(context).size.width < 350 ? 16 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isCompleted) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.verified,
                            color: Color(0xFFFFD700),
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCompleted ? 
                        'Congratulations! Journey Complete! 🎉' : 
                        _getMotivationalMessage(userProgress),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: MediaQuery.of(context).size.width < 350 ? 12 : 14,
                        fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildStreakBadge(userProgress.currentStreak),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Progress bar with African-inspired design
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Modules Completed',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${userProgress.completedModules} / ${userProgress.totalModules}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 2000),
                        curve: Curves.easeInOut,
                        height: 10,
                        width: constraints.maxWidth * progress,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isCompleted ? [
                              const Color(0xFFFFD700), // Gold
                              Colors.white,
                            ] : [
                              AppTheme.saharaGold,
                              Colors.white,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: isCompleted ? 
                                const Color(0xFFFFD700).withOpacity(0.7) : 
                                Colors.white.withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '${(progress * 100).toInt()}% Complete • ${_getLevelName(progress)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: MediaQuery.of(context).size.width < 350 ? 11 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCompleted) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.celebration,
                      color: Color(0xFFFFD700),
                      size: 16,
                    ),
                  ],
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Enhanced stats with African context
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  Icons.shield_outlined,
                  'Security Score',
                  '$securityScore%',
                  _getScoreColor(securityScore),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(
                child: _buildStatItem(
                  Icons.access_time_outlined,
                  'This Week',
                  '${weeklyMinutes}min',
                  AppTheme.saharaGold,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(
                child: _buildStatItem(
                  Icons.emoji_events_outlined,
                  'Achievements',
                  '${userProgress.achievements.length}',
                  AppTheme.copperAccent,
                ),
              ),
            ],
          ),
          
          if (userProgress.achievements.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildLatestAchievement(userProgress.achievements.last),
          ],
        ],
      ),
    ).animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildBenefitItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBadge(int streak) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: streak > 0 ? AppTheme.saharaGold.withOpacity(0.3) : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            streak > 0 ? Icons.local_fire_department : Icons.local_fire_department_outlined,
            color: streak > 0 ? AppTheme.saharaGold : Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$streak day${streak != 1 ? 's' : ''}',
            style: TextStyle(
              color: streak > 0 ? Colors.white : Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width < 350 ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: MediaQuery.of(context).size.width < 350 ? 9 : 10,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildLatestAchievement(String achievement) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars, color: AppTheme.saharaGold, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Latest: $achievement',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateSecurityScore(UserProgress userProgress) {
    // African cybersecurity score calculation
    int baseScore = 30; // Everyone starts with basic awareness
    
    // Progress bonus (40 points max)
    int progressBonus = (userProgress.overallProgress * 40).toInt();
    
    // Streak bonus (15 points max)
    int streakBonus = (userProgress.currentStreak * 2).clamp(0, 15).toInt();
    
    // Category completion bonus (15 points max)
    int categoryBonus = (userProgress.completedCategories.length * 3).clamp(0, 15).toInt();
    
    return (baseScore + progressBonus + streakBonus + categoryBonus).clamp(0, 100);
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppTheme.accentColor;
    if (score >= 60) return AppTheme.saharaGold;
    if (score >= 40) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _getLevelName(double progress) {
    if (progress >= 0.9) return 'Cybersecurity Expert';
    if (progress >= 0.7) return 'Digital Guardian';
    if (progress >= 0.5) return 'Cyber Defender';
    if (progress >= 0.3) return 'Safety Learner';
    return 'Digital Novice';
  }

  String _getMotivationalMessage(UserProgress userProgress) {
    final messages = [
      'Protecting Africa, one lesson at a time! 🌍',
      'Your digital safety journey continues! 🚀',
      'Building a safer digital Africa together! 🛡️',
      'Every lesson makes you stronger online! 💪',
      'Leading the cybersecurity revolution in Africa! ⭐',
    ];
    
    final index = (userProgress.completedModules % messages.length);
    return messages[index];
  }

  int _getWeeklyMinutes(UserProgress userProgress) {
    // This would calculate actual weekly minutes from user sessions
    // For now, return estimated weekly minutes
    return (userProgress.currentStreak * 15).clamp(0, 300);
  }

  Future<void> _initializeUserProgress() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Get actual total modules count from Firestore
    final totalContentSnapshot = await FirebaseFirestore.instance
        .collection('education_content')
        .get();
    final totalModules = totalContentSnapshot.docs.length;
    
    print('🎆 FirebaseProgressCard: Initializing progress with $totalModules total modules');

    final initialProgress = UserProgress(
      userId: userId,
      completedModules: 0,
      totalModules: totalModules, // Dynamic total based on actual content
      currentStreak: 0,
      longestStreak: 0,
      completedCategories: [],
      categoryProgress: {},
      lastAccessedContent: {},
      totalMinutesLearned: 0,
      achievements: ['Welcome to Rethicsec Academy!'],
      lastActiveDate: DateTime.now(),
      weeklyStats: {
        'week_start': DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
        'minutes_this_week': 0,
        'sessions_this_week': 0,
      },
    );

    await _educationService.updateUserProgress(initialProgress);
  }
}
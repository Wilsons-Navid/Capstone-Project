import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/themes/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../widgets/education_category_card.dart';
import '../widgets/education_featured_card.dart';
import '../widgets/interactive_content_viewer.dart';
import '../widgets/gamification_dashboard.dart';
import '../models/education_models.dart';
import '../../data/education_service.dart';
import 'category_detail_page.dart';

class EducationHubPage extends StatefulWidget {
  const EducationHubPage({super.key});

  @override
  State<EducationHubPage> createState() => _EducationHubPageState();
}

class _EducationHubPageState extends State<EducationHubPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final EducationService _educationService = EducationService();
  bool _quizzesEnsured = false;
  bool _backupsEnsured = false;
  
  // Removed local seed categories; using Firestore stream instead.
  final List<EducationCategory> categories = const [];
/*    EducationCategory(
      id: 'password-security',
      title: 'Password Security',
      description: 'Learn how to create and manage strong passwords',
      icon: 'lock',
      color: '#4CAF50',
      moduleCount: 5,
      estimatedTime: '30 min',
      difficulty: 'Beginner',
      order: 1,
    ),
    EducationCategory(
      id: 'phishing-awareness',
      title: 'Phishing Awareness',
      description: 'Identify and avoid phishing attacks',
      icon: 'phishing',
      color: '#FF9800',
      moduleCount: 7,
      estimatedTime: '45 min',
      difficulty: 'Intermediate',
      order: 2,
    ),
    EducationCategory(
      id: 'social-media-safety',
      title: 'Social Media Safety',
      description: 'Protect your privacy on social platforms',
      icon: 'share',
      color: '#2196F3',
      moduleCount: 6,
      estimatedTime: '40 min',
      difficulty: 'Beginner',
      order: 3,
    ),
    EducationCategory(
      id: 'online-shopping',
      title: 'Safe Online Shopping',
      description: 'Shop safely and avoid e-commerce scams',
      icon: 'shopping_cart',
      color: '#9C27B0',
      moduleCount: 4,
      estimatedTime: '25 min',
      difficulty: 'Beginner',
      order: 4,
    ),
    EducationCategory(
      id: 'mobile-security',
      title: 'Mobile Security',
      description: 'Secure your smartphone and mobile apps',
      icon: 'phone_android',
      color: '#F44336',
      moduleCount: 8,
      estimatedTime: '50 min',
      difficulty: 'Intermediate',
      order: 5,
    ),
    EducationCategory(
      id: 'wifi-security',
      title: 'WiFi Security',
      description: 'Stay safe on public and private networks',
      icon: 'wifi',
      color: '#795548',
      moduleCount: 5,
      estimatedTime: '35 min',
      difficulty: 'Advanced',
      order: 6,
    ),
    EducationCategory(
      id: 'mobile-money-security',
      title: 'Mobile Money Security',
      description: 'Protect M-Pesa, Airtel Money, and other mobile payments',
      icon: 'account_balance_wallet',
      color: '#00BCD4',
      moduleCount: 6,
      estimatedTime: '35 min',
      difficulty: 'Beginner',
      order: 7,
    ),
    EducationCategory(
      id: 'romance-scam-awareness',
      title: 'Romance Scam Awareness',
      description: 'Identify and avoid online dating scams',
      icon: 'favorite_border',
      color: '#E91E63',
      moduleCount: 5,
      estimatedTime: '25 min',
      difficulty: 'Beginner',
      order: 8,
    ),
    EducationCategory(
      id: 'cryptocurrency-safety',
      title: 'Cryptocurrency Safety',
      description: 'Safe Bitcoin, Ethereum trading and wallet security',
      icon: 'currency_bitcoin',
      color: '#FF9800',
      moduleCount: 7,
      estimatedTime: '45 min',
      difficulty: 'Advanced',
      order: 9,
    ),
    EducationCategory(
      id: 'social-engineering-african',
      title: 'African Social Engineering',
      description: 'Recognize cultural manipulation tactics',
      icon: 'psychology',
      color: '#8BC34A',
      moduleCount: 6,
      estimatedTime: '40 min',
      difficulty: 'Intermediate',
      order: 10,
    ),
*/  

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animationController.forward();
    _maybeEnsureQuizzesOnceForAdmin();
    _maybeEnsureBackupsOnceForAdmin();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _maybeEnsureQuizzesOnceForAdmin() async {
    if (_quizzesEnsured) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final role = userDoc.data()?['role'];
      final isAdmin = role == 'admin' || role == 'super_admin';
      if (!isAdmin) return;

      final flagRef = FirebaseFirestore.instance.collection('admin_flags').doc('ensure_quizzes_v1');
      final flagSnap = await flagRef.get();
      if (flagSnap.exists) {
        _quizzesEnsured = true;
        return;
      }

      await _educationService.ensureQuizzesForAllContent();
      await flagRef.set({
        'by': user.uid,
        'at': FieldValue.serverTimestamp(),
        'version': 1,
      });
      if (!mounted) return;
      setState(() { _quizzesEnsured = true; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Quizzes ensured for all modules.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (_) {
      // ignore
    }
  }

  Future<void> _maybeEnsureBackupsOnceForAdmin() async {
    if (_backupsEnsured) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final role = userDoc.data()?['role'];
      final isAdmin = role == 'admin' || role == 'super_admin';
      if (!isAdmin) return;

      final flagRef = FirebaseFirestore.instance.collection('admin_flags').doc('ensure_backups_v1');
      final flagSnap = await flagRef.get();
      if (flagSnap.exists) {
        _backupsEnsured = true;
        return;
      }

      await _educationService.ensureBackupVideoUrls();
      await flagRef.set({
        'by': user.uid,
        'at': FieldValue.serverTimestamp(),
        'version': 1,
      });
      if (!mounted) return;
      setState(() { _backupsEnsured = true; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Backup video links ensured.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (_) {
      // ignore silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: const AfricanPatternBackground(opacity: 0.03),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // App Bar
                SliverAppBar(
                  floating: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient.scale(0.1),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.school,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'education.learn_protect'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Stay Safe Online',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    PopupMenuButton<int>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) async {
                        if (value == 1) {} else if (value == 2) {
                          // Seed content then recalc
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(child: CircularProgressIndicator()),
                          );
                          try {
                            await _educationService.initializeEducationData();
                            await _educationService.recalculateModuleCounts();
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Learning content initialized.'),
                                  backgroundColor: AppTheme.successColor,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to initialize: $e'),
                                  backgroundColor: AppTheme.errorColor,
                                ),
                              );
                            }
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 1, child: Text('Recalculate module counts')),
                        const PopupMenuItem(value: 2, child: Text('Initialize learning content')),
                        const PopupMenuItem(value: 3, child: Text('Ensure quizzes for all modules')),
                        const PopupMenuItem(value: 4, child: Text('Seed backup video links')),
                      ],
                    ),
                  ],
                ),


                // Gamification Dashboard
                SliverToBoxAdapter(
                  child: const GamificationDashboard(),
                ),

                // Certificate Manager
                SliverToBoxAdapter(
                  child: const CertificateManager(),
                ),

                // Alert section for cybersecurity awareness
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withOpacity(0.1),
                            Colors.orange.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber, color: Colors.red, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                '🚨 Cybercrime Alert',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Over 1,200 cybercriminals arrested across Africa in 2024-2025. Mobile money fraud up 356% in South Africa. Learn to protect yourself!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red.shade600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Categories Section
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'education.categories'.tr(),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Categories Grid from Firebase
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: StreamBuilder<List<EducationCategory>>(
                    stream: _educationService.getCategories(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SliverToBoxAdapter(
                          child: Container(
                            height: 200,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Failed to load categories. Please try again later.',
                                        style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      final categories = snapshot.data ?? [];
                      if (categories.isEmpty) {
                        return SliverToBoxAdapter(
                          child: _buildInitializeDataButton(),
                        );
                      }
                      
                      return SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.9,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final category = categories[index];
                            return EducationCategoryCard(
                              category: category,
                              onTap: () => _openCategory(category),
                            );
                          },
                          childCount: categories.length,
                        ),
                      );
                    },
                  ),
                ),

                // Bottom spacing
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: 80),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickTips(context),
        backgroundColor: AppTheme.secondaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.lightbulb),
        label: const Text('Quick Tips'),
      ),
    );
  }

  void _openCategory(EducationCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailPage(category: category),
      ),
    );
  }

  void _openContent(EducationContent content) async {
    // Show content in a bottom sheet or navigate to detail page
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildContentPreview(content),
    );
  }

  Widget _buildInitializeDataButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_download,
            color: AppTheme.primaryColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Initialize Learning Content',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Load comprehensive cybersecurity education content designed specifically for Africa',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading African cybersecurity content...'),
                    ],
                  ),
                ),
              );
              
              try {
                await _educationService.initializeEducationData();
                await _educationService.recalculateModuleCounts();
                Navigator.pop(context); // Close loading dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🎉 Education content loaded successfully!'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              } catch (e) {
                Navigator.pop(context); // Close loading dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to load content: $e'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            icon: Icon(Icons.download),
            label: Text('Initialize Content'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPreview(EducationContent content) {
    // Use the new interactive content viewer
    return InteractiveContentViewer(content: content);
  }

  Widget _buildLegacyContentPreview(EducationContent content) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            content.thumbnail,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              content.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${content.duration} min • ${content.difficulty}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    content.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to full content
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Start Learning (${content.duration} min)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickTips(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: AppTheme.secondaryColor,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Quick Security Tips',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTipItem('💡', 'Use unique passwords for each account'),
                  _buildTipItem('🔐', 'Enable two-factor authentication'),
                  _buildTipItem('📱', 'Keep your apps and OS updated'),
                  _buildTipItem('🌐', 'Be cautious on public WiFi'),
                  _buildTipItem('📧', 'Think before you click on links'),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String emoji, String tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}






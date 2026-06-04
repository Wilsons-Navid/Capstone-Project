import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../core/constants/app_images.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../../shared/widgets/dashboard_feature_card.dart';
import '../../../../shared/widgets/quick_stats_card.dart';
import '../../../../shared/widgets/recent_activity_card.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _selectedBottomNavIndex = 0;
  String? _userName;
  String? _userEmail;
  String? _userProfilePicture;
  int _unreadNotifications = 0;
  int _totalReports = 0;
  int _resolvedCases = 0;
  int _threatsBlocked = 0;
  bool _isLoadingStats = true;

  List<DashboardFeature> get _features => [
    DashboardFeature(
      title: 'incidents.report_incident',
      subtitle: 'dashboard.secure_reporting',
      icon: Icons.report_problem,
      gradient: AppTheme.primaryGradient,
      route: AppRouter.incidentReport,
      useImage: false,
    ),
    DashboardFeature(
      title: 'ai.assistant_name',
      subtitle: 'dashboard.ai_analysis',
      icon: Icons.psychology,
      gradient: AppTheme.secondaryGradient,
      route: AppRouter.aiChat,
      useImage: false,
    ),
    DashboardFeature(
      title: 'cases.track_cases',
      subtitle: 'dashboard.monitor_reports',
      icon: Icons.track_changes,
      gradient: AppTheme.accentGradient,
      route: AppRouter.caseTracking,
      useImage: false,
    ),
    DashboardFeature(
      title: 'scanner.threat_scanner',
      subtitle: 'dashboard.scan_content',
      icon: Icons.security,
      gradient: const LinearGradient(
        colors: [Color(0xFFE91E63), Color(0xFFF06292)],
      ),
      route: AppRouter.scanner,
      useImage: false,
    ),
    DashboardFeature(
      title: 'SMS Protection',
      subtitle: 'Scan messages for scams',
      icon: Icons.sms_failed,
      gradient: const LinearGradient(
        colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
      ),
      route: AppRouter.smsGuard,
      useImage: false,
    ),
    DashboardFeature(
      title: 'education.learn_protect',
      subtitle: 'education.security_education',
      icon: Icons.school,
      gradient: const LinearGradient(
        colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
      ),
      route: AppRouter.educationHub,
      useImage: false,
    ),
    DashboardFeature(
      title: 'emergency.immediate_help',
      subtitle: 'emergency.immediate_help',
      icon: Icons.emergency,
      gradient: const LinearGradient(
        colors: [Color(0xFFD32F2F), Color(0xFFEF5350)],
      ),
      route: AppRouter.emergencyContacts,
      useImage: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.value = 1.0;
    _loadUserProfile();
    _loadDashboardStats();
    _loadUnreadNotifications();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildPremiumAppBar(context, innerBoxIsScrolled),
        ],
        body: RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.lightImpact();
            await Future.wait([
              _loadUserProfile(),
              _loadDashboardStats(),
              _loadUnreadNotifications(),
            ]);
          },
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildQuickStatsSection(),
                const SizedBox(height: 24),
                _buildPremiumWelcomeCard(),
                const SizedBox(height: 20),
                _buildFeaturesSection(),
                const SizedBox(height: 20),
                _buildInsightsSection(),
                const SizedBox(height: 20),
                _buildRecentActivitySection(),
                const SizedBox(height: 20),
                _buildDatabaseSetupCard(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildPremiumBottomNav(),
      floatingActionButton: _buildPremiumFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildPremiumAppBar(BuildContext context, bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 110,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: Builder(
        builder: (context) => Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Scaffold.of(context).openDrawer();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ),
      ),
      actions: [
        _buildPremiumHeaderAction(
          Icons.notifications_none_rounded,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationsPage(),
            ),
          ),
          showBadge: _unreadNotifications > 0,
          badgeCount: _unreadNotifications,
        ),
        const SizedBox(width: 8),
        _buildProfilePictureAction(
          () => Navigator.pushNamed(context, AppRouter.profile),
        ),
        const SizedBox(width: 12),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.95),
              AppTheme.secondaryColor.withOpacity(0.85),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FlexibleSpaceBar(
          background: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 15),
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'dashboard.welcome'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'dashboard.greeting'.tr(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        String fullName = '';
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          fullName = data['name'] ?? data['displayName'] ?? user.displayName ?? '';
          setState(() {
            _userEmail = data['email'] ?? user.email;
            // Load base64 image from Firestore if available
            if (data['profileImageBase64'] != null) {
              final base64Image = data['profileImageBase64'] as String;
              final imageType = data['profileImageType'] ?? 'image/jpeg';
              _userProfilePicture = 'data:$imageType;base64,$base64Image';
            } else {
              // Fallback to old profileImageUrl for backward compatibility
              _userProfilePicture = data['profilePicture'] ?? data['photoURL'];
            }
          });
        } else {
          fullName = user.displayName ?? '';
          setState(() {
            _userEmail = user.email;
            _userProfilePicture = user.photoURL;
          });
        }
        
        // Extract first name only
        if (fullName.isNotEmpty) {
          setState(() {
            _userName = fullName.split(' ').first;
          });
        } else if (_userEmail != null) {
          setState(() {
            _userName = _userEmail!.split('@').first.split('.').first;
          });
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Future<void> _loadDashboardStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _isLoadingStats = true;
        });

        // Fetch user's incidents/reports
        final incidentsQuery = await FirebaseFirestore.instance
            .collection('incidents')
            .where('user_id', isEqualTo: user.uid)
            .get();

        // Fetch resolved cases (incidents with status 'resolved' or 'closed')
        final resolvedQuery = await FirebaseFirestore.instance
            .collection('incidents')
            .where('user_id', isEqualTo: user.uid)
            .where('status', whereIn: ['resolved', 'closed', 'completed'])
            .get();

        // Fetch threat detections from user activities or scanning results
        final threatQuery = await FirebaseFirestore.instance
            .collection('user_activities')
            .where('userId', isEqualTo: user.uid)
            .where('activityType', isEqualTo: 'threat_detected')
            .get();

        setState(() {
          _totalReports = incidentsQuery.docs.length;
          _resolvedCases = resolvedQuery.docs.length;
          _threatsBlocked = threatQuery.docs.length;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard stats: $e');
      setState(() {
        _isLoadingStats = false;
        // Keep default values or set to 0
        _totalReports = 0;
        _resolvedCases = 0;
        _threatsBlocked = 0;
      });
    }
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get unread notifications from Firebase
        final notificationsQuery = await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .where('read', isEqualTo: false)
            .get();

        setState(() {
          _unreadNotifications = notificationsQuery.docs.length;
        });
      }
    } catch (e) {
      print('Error loading unread notifications: $e');
      setState(() {
        _unreadNotifications = 0;
      });
    }
  }

  Widget _buildPremiumHeaderAction(IconData icon, VoidCallback onPressed, {bool showBadge = false, int? badgeCount}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onPressed();
            },
            icon: Icon(icon, color: Colors.white, size: 20),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
          ),
          if (showBadge && (badgeCount == null || badgeCount > 0))
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: badgeCount != null && badgeCount > 0
                    ? Center(
                        child: Text(
                          badgeCount > 99 ? '99+' : badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfilePictureAction(VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onPressed();
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
              child: _userProfilePicture != null && _userProfilePicture!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _userProfilePicture!.startsWith('data:image')
                          ? Image.memory(
                              base64Decode(_userProfilePicture!.split(',')[1]),
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                );
                              },
                            )
                          : CachedNetworkImage(
                              imageUrl: _userProfilePicture!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              imageBuilder: (context, imageProvider) => Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              placeholder: (context, url) => Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person_outline_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                    )
                  : Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Reports', _isLoadingStats ? '--' : '$_totalReports', Icons.report_outlined, const Color(0xFF3B82F6))),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Resolved', _isLoadingStats ? '--' : '$_resolvedCases', Icons.check_circle_outline, const Color(0xFF10B981))),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Threats', _isLoadingStats ? '--' : '$_threatsBlocked', Icons.shield_outlined, const Color(0xFFEF4444))),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          _isLoadingStats && value == '--'
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            : Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumWelcomeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.9),
            AppTheme.secondaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'dashboard.welcome'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'dashboard.greeting'.tr(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'dashboard.subtitle'.tr(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'dashboard.features_title'.tr(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text('common.view_all'.tr()),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.15,
            ),
            itemCount: _features.length,
            itemBuilder: (context, index) {
              return _buildPremiumFeatureCard(_features[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeatureCard(DashboardFeature feature) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, feature.route);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: feature.gradient.colors.first.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: feature.gradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: feature.gradient.colors.first.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                feature.icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                feature.title.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                feature.subtitle.tr(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.withOpacity(0.8),
              Colors.red.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Threat Intelligence',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Real-time security insights',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildThreatStat('MoMo Scams', '\$1.3B Lost', Icons.phone_android_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _buildThreatStat('Fake Loans', '2M Victims', Icons.money_off_rounded)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildThreatStat('Email Fraud', '89% ↑', Icons.email_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _buildThreatStat('Social Scams', '450% ↑', Icons.warning_rounded)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreatStat(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'dashboard.recent_activity'.tr(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const RecentActivityCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.dashboard_rounded, 'nav.dashboard'.tr(), 0),
              _buildNavItem(Icons.report_rounded, 'nav.report'.tr(), 1),
              const SizedBox(width: 60), // Space for FAB
              _buildNavItem(Icons.track_changes_rounded, 'nav.cases'.tr(), 3),
              _buildNavItem(Icons.person_rounded, 'nav.profile'.tr(), 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedBottomNavIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedBottomNavIndex = index;
        });
        _handleBottomNavTap(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.secondaryColor, AppTheme.secondaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.pushNamed(context, AppRouter.aiChat);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.psychology_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildDatabaseSetupCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.withOpacity(0.1), Colors.red.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.red],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storage,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Database Setup',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      'Initialize Firebase collections & create admin users',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRouter.databaseSetup),
                  icon: const Icon(Icons.settings, size: 20),
                  label: const Text('Setup Database'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRouter.adminDashboard),
                  icon: const Icon(Icons.admin_panel_settings, size: 20),
                  label: const Text('Admin Panel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0:
        // Stay on dashboard
        break;
      case 1:
        Navigator.pushNamed(context, AppRouter.incidentReport);
        break;
      case 2:
        Navigator.pushNamed(context, AppRouter.aiChat);
        break;
      case 3:
        Navigator.pushNamed(context, AppRouter.caseTracking);
        break;
      case 4:
        Navigator.pushNamed(context, AppRouter.profile);
        break;
    }
  }
}

class DashboardFeature {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final String route;
  final String? imagePath;
  final bool useImage;

  const DashboardFeature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.route,
    this.imagePath,
    this.useImage = false,
  });
}

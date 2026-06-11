import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../shared/widgets/recent_activity_card.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/dashboard_bottom_nav.dart';
import '../widgets/dashboard_sections.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedBottomNavIndex = 0;
  String? _userProfilePicture;
  bool _isAdmin = false;
  int _unreadNotifications = 0;
  int _totalReports = 0;
  int _resolvedCases = 0;
  int _threatsBlocked = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadDashboardStats();
    _loadUnreadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      drawer: const AppDrawer(),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          DashboardAppBar(
            unreadNotifications: _unreadNotifications,
            profilePicture: _userProfilePicture,
          ),
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
                QuickStatsRow(
                  totalReports: _totalReports,
                  resolvedCases: _resolvedCases,
                  threatsBlocked: _threatsBlocked,
                  isLoading: _isLoadingStats,
                ),
                const SizedBox(height: 24),
                const WelcomeCard(),
                const SizedBox(height: 20),
                const FeatureGrid(),
                const SizedBox(height: 20),
                const ThreatInsightsCard(),
                const SizedBox(height: 20),
                _buildRecentActivitySection(),
                if (_isAdmin) ...[
                  const SizedBox(height: 20),
                  const DatabaseSetupCard(),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: DashboardBottomNav(
        selectedIndex: _selectedBottomNavIndex,
        onTap: (index) {
          setState(() {
            _selectedBottomNavIndex = index;
          });
          _handleBottomNavTap(index);
        },
      ),
      floatingActionButton: const AiAssistantFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          setState(() {
            _isAdmin =
                data['role'] == 'admin' || data['role'] == 'super_admin';
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
          setState(() {
            _userProfilePicture = user.photoURL;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
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
      debugPrint('Error loading dashboard stats: $e');
      setState(() {
        _isLoadingStats = false;
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
      debugPrint('Error loading unread notifications: $e');
      setState(() {
        _unreadNotifications = 0;
      });
    }
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
              color: AppTheme.onSurface,
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

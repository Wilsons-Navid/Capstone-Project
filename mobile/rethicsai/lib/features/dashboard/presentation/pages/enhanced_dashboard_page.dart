import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../core/constants/app_images.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../../shared/widgets/enhanced_dashboard_components.dart';
import '../../../../shared/widgets/enhanced_states.dart';
import '../../../../shared/widgets/accessibility_features.dart';

class EnhancedDashboardPage extends StatefulWidget {
  const EnhancedDashboardPage({super.key});

  @override
  State<EnhancedDashboardPage> createState() => _EnhancedDashboardPageState();
}

class _EnhancedDashboardPageState extends State<EnhancedDashboardPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  // Sample data - in real app, this would come from BLoC/providers
  final List<ActivityItem> _recentActivities = [
    ActivityItem(
      title: 'Phishing Report Submitted',
      description: 'Case #CC-001234 has been created and assigned to investigation team',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      type: ActivityType.incidentReported,
    ),
    ActivityItem(
      title: 'Security Training Completed',
      description: 'Completed "Mobile Money Safety" course with 95% score',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: ActivityType.educationCompleted,
    ),
    ActivityItem(
      title: 'Wilson AI Consultation',
      description: 'Asked about suspicious email verification',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      type: ActivityType.aiInteraction,
    ),
    ActivityItem(
      title: 'Case Status Update',
      description: 'Case #CC-001230 has been marked as resolved',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: ActivityType.caseUpdated,
    ),
  ];

  final List<ChartData> _threatTrendData = [
    ChartData(label: 'Phishing', value: 45),
    ChartData(label: 'Scam Calls', value: 32),
    ChartData(label: 'Fake Apps', value: 18),
    ChartData(label: 'Identity Theft', value: 12),
    ChartData(label: 'Other', value: 8),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AccessibilitySettings(
      child: Scaffold(
        body: Stack(
          children: [
            // African pattern background
            const Positioned.fill(
              child: AfricanPatternBackground(opacity: 0.03),
            ),
            
            // Skip navigation for accessibility
            SkipNavigationLinks(
              links: [
                SkipLink(
                  label: 'Main Content',
                  action: () => _scrollToSection('main-content'),
                ),
                SkipLink(
                  label: 'Quick Actions',
                  action: () => _scrollToSection('quick-actions'),
                ),
                SkipLink(
                  label: 'Statistics',
                  action: () => _scrollToSection('statistics'),
                ),
              ],
            ),
            
            // Main content
            SafeArea(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  _buildAppBar(),
                ],
                body: _buildDashboardContent(),
              ),
            ),
          ],
        ),
        
        bottomNavigationBar: _buildEnhancedBottomNav(),
        
        floatingActionButton: _buildSmartFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient.scale(0.8),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AccessibleText(
                    'dashboard.welcome_back'.tr(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    isHeading: true,
                    headingLevel: 1,
                  ),
                  const SizedBox(height: 4),
                  AccessibleText(
                    'dashboard.stay_protected'.tr(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        AccessibleTouchTarget(
          onTap: () => Navigator.pushNamed(context, AppRouter.notifications),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(
                    Icons.notifications,
                    color: Colors.white,
                  ),
                ),
                // Notification badge
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ).withAccessibility(
            label: 'Notifications',
            hint: 'View 3 unread notifications',
            isButton: true,
          ),
        ),
        AccessibleTouchTarget(
          onTap: () => Navigator.pushNamed(context, AppRouter.profile),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                color: AppTheme.primaryColor,
              ),
            ),
          ).withAccessibility(
            label: 'Profile',
            hint: 'View and edit your profile',
            isButton: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100), // Space for FAB
      child: Column(
        children: [
          // Quick stats section
          _buildStatsSection().withAccessibility(
            label: 'Security Statistics',
            isHeader: true,
          ),
          
          const SizedBox(height: 24),
          
          // Tabbed content
          _buildTabbedContent(),
          
          const SizedBox(height: 24),
          
          // Threat trends chart
          _buildThreatTrendsSection(),
          
          const SizedBox(height: 24),
          
          // Recent activity
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: EnhancedActivityTimeline(
              activities: _recentActivities,
              maxItems: 5,
            ),
          ).withAccessibility(
            label: 'Recent Activity',
            isHeader: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccessibleText(
            'dashboard.security_overview'.tr(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            isHeading: true,
            headingLevel: 2,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.3,
            children: [
              EnhancedStatsCard(
                title: 'dashboard.active_cases'.tr(),
                value: '3',
                subtitle: 'dashboard.being_investigated'.tr(),
                icon: Icons.pending_actions,
                gradient: AppTheme.primaryGradient,
                trend: '+2',
                isPositiveTrend: false,
                onTap: () => Navigator.pushNamed(context, AppRouter.caseTracking),
              ).animate().slideX(begin: -0.3, duration: 400.ms).fadeIn(),
              
              EnhancedStatsCard(
                title: 'dashboard.resolved_cases'.tr(),
                value: '12',
                subtitle: 'dashboard.this_month'.tr(),
                icon: Icons.check_circle,
                gradient: AppTheme.accentGradient,
                trend: '+150%',
                isPositiveTrend: true,
              ).animate(delay: 100.ms).slideX(begin: -0.3, duration: 400.ms).fadeIn(),
              
              EnhancedStatsCard(
                title: 'dashboard.security_score'.tr(),
                value: '85%',
                subtitle: 'dashboard.excellent'.tr(),
                icon: Icons.security,
                gradient: AppTheme.secondaryGradient,
                trend: '+5%',
                isPositiveTrend: true,
              ).animate(delay: 200.ms).slideX(begin: -0.3, duration: 400.ms).fadeIn(),
              
              EnhancedStatsCard(
                title: 'dashboard.learning_progress'.tr(),
                value: '67%',
                subtitle: 'dashboard.courses_completed'.tr(),
                icon: Icons.school,
                gradient: const LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                ),
                onTap: () => Navigator.pushNamed(context, AppRouter.educationHub),
              ).animate(delay: 300.ms).slideX(begin: -0.3, duration: 400.ms).fadeIn(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabbedContent() {
    return Column(
      children: [
        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(25),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            tabs: [
              Tab(text: 'dashboard.quick_actions'.tr()),
              Tab(text: 'dashboard.security_tips'.tr()),
              Tab(text: 'dashboard.progress'.tr()),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Tab content
        SizedBox(
          height: 280,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildQuickActionsTab(),
              _buildSecurityTipsTab(),
              _buildProgressTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsTab() {
    final actions = [
      QuickAction(
        icon: Icons.report_problem,
        title: 'dashboard.report_incident'.tr(),
        subtitle: 'dashboard.report_cybercrime'.tr(),
        color: AppTheme.errorColor,
        onTap: () => Navigator.pushNamed(context, AppRouter.incidentReport),
      ),
      QuickAction(
        icon: Icons.psychology,
        title: 'dashboard.ask_wilson'.tr(),
        subtitle: 'dashboard.ai_assistance'.tr(),
        color: AppTheme.primaryColor,
        onTap: () => Navigator.pushNamed(context, AppRouter.aiChat),
      ),
      QuickAction(
        icon: Icons.security,
        title: 'dashboard.scan_content'.tr(),
        subtitle: 'dashboard.check_suspicious'.tr(),
        color: AppTheme.secondaryColor,
        onTap: () => Navigator.pushNamed(context, AppRouter.scanner),
      ),
      QuickAction(
        icon: Icons.school,
        title: 'dashboard.learn_security'.tr(),
        subtitle: 'dashboard.improve_knowledge'.tr(),
        color: AppTheme.accentColor,
        onTap: () => Navigator.pushNamed(context, AppRouter.educationHub),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return _buildQuickActionCard(action, index);
        },
      ),
    );
  }

  Widget _buildQuickActionCard(QuickAction action, int index) {
    return AccessibleTouchTarget(
      onTap: action.onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            gradient: LinearGradient(
              colors: [
                action.color.withOpacity(0.1),
                action.color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  action.icon,
                  color: action.color,
                  size: 24,
                ),
              ),
              const Spacer(),
              AccessibleText(
                action.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              AccessibleText(
                action.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ).withAccessibility(
        label: action.title,
        hint: action.subtitle,
        isButton: true,
      ),
    ).animate(delay: Duration(milliseconds: index * 100))
        .slideY(begin: 0.3, duration: 400.ms)
        .fadeIn();
  }

  Widget _buildSecurityTipsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildSecurityTip(
            icon: Icons.phone_android,
            title: 'dashboard.tip_mobile_money'.tr(),
            description: 'dashboard.tip_mobile_money_desc'.tr(),
            index: 0,
          ),
          const SizedBox(height: 12),
          _buildSecurityTip(
            icon: Icons.email,
            title: 'dashboard.tip_email_safety'.tr(),
            description: 'dashboard.tip_email_safety_desc'.tr(),
            index: 1,
          ),
          const SizedBox(height: 12),
          _buildSecurityTip(
            icon: Icons.lock,
            title: 'dashboard.tip_password_strength'.tr(),
            description: 'dashboard.tip_password_strength_desc'.tr(),
            index: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTip({
    required IconData icon,
    required String title,
    required String description,
    required int index,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AccessibleText(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AccessibleText(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 150))
        .slideX(begin: -0.3, duration: 400.ms)
        .fadeIn();
  }

  Widget _buildProgressTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          EnhancedProgressIndicator(
            progress: 0.85,
            label: 'dashboard.overall_security'.tr(),
            sublabel: 'dashboard.excellent_security'.tr(),
            color: AppTheme.successColor,
          ).animate().slideX(begin: -0.3, duration: 400.ms).fadeIn(),
          
          const SizedBox(height: 20),
          
          EnhancedProgressIndicator(
            progress: 0.67,
            label: 'dashboard.education_progress'.tr(),
            sublabel: 'dashboard.courses_progress'.tr(),
            color: AppTheme.accentColor,
          ).animate(delay: 100.ms).slideX(begin: -0.3, duration: 400.ms).fadeIn(),
          
          const SizedBox(height: 20),
          
          EnhancedProgressIndicator(
            progress: 0.92,
            label: 'dashboard.incident_response'.tr(),
            sublabel: 'dashboard.response_rate'.tr(),
            color: AppTheme.primaryColor,
          ).animate(delay: 200.ms).slideX(begin: -0.3, duration: 400.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildThreatTrendsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: EnhancedChart(
        data: _threatTrendData,
        type: ChartType.pie,
        title: 'dashboard.threat_trends'.tr(),
        height: 200,
        animated: true,
      ).withAccessibility(
        label: 'Threat Trends Chart',
        hint: 'Shows distribution of cyberthreats this month',
      ),
    );
  }

  Widget _buildEnhancedBottomNav() {
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
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _handleBottomNavTap,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology),
              label: 'Wilson AI',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school),
              label: 'Learn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartFAB() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 4,
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _showQuickActionMenu(),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_circle_outline),
        label: Text('dashboard.quick_report'.tr()),
      ).withAccessibility(
        label: 'Quick Actions Menu',
        hint: 'Opens menu for quick reporting and actions',
        isButton: true,
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Stay on dashboard
        break;
      case 1:
        Navigator.pushNamed(context, AppRouter.caseTracking);
        break;
      case 2:
        Navigator.pushNamed(context, AppRouter.aiChat);
        break;
      case 3:
        Navigator.pushNamed(context, AppRouter.educationHub);
        break;
      case 4:
        Navigator.pushNamed(context, AppRouter.profile);
        break;
    }
  }

  void _showQuickActionMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQuickActionBottomSheet(),
    );
  }

  Widget _buildQuickActionBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            AccessibleText(
              'dashboard.quick_actions'.tr(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              isHeading: true,
            ),
            const SizedBox(height: 20),
            
            // Quick action buttons
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildBottomSheetAction(
                  icon: Icons.report_problem,
                  title: 'Report Incident',
                  color: AppTheme.errorColor,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.incidentReport);
                  },
                ),
                _buildBottomSheetAction(
                  icon: Icons.security,
                  title: 'Scan Content',
                  color: AppTheme.secondaryColor,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.scanner);
                  },
                ),
                _buildBottomSheetAction(
                  icon: Icons.psychology,
                  title: 'Ask Wilson',
                  color: AppTheme.primaryColor,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.aiChat);
                  },
                ),
                _buildBottomSheetAction(
                  icon: Icons.emergency,
                  title: 'Emergency Help',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.emergencyContacts);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetAction({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AccessibleTouchTarget(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).withAccessibility(
        label: title,
        isButton: true,
      ),
    );
  }

  void _scrollToSection(String sectionId) {
    // Implement smooth scrolling to specific sections
    // This would require ScrollController and section keys
  }
}

// Data model for quick actions
class QuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}
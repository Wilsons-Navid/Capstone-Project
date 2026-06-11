import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/themes/app_theme.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../core/utils/app_router.dart';
import 'premium_animations.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> with TickerProviderStateMixin {
  DrawerThemeMode _themeMode = DrawerThemeMode.normal;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    // Don't call _detectThemeMode here - wait for didChangeDependencies
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final role = doc.data()?['role'];
      if (mounted) {
        setState(() {
          _isAdmin = role == 'admin' || role == 'super_admin';
        });
      }
    } catch (_) {
      // Leave _isAdmin false; server-side rules enforce access anyway.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _detectThemeMode();
  }

  void _detectThemeMode() {
    // Detect context-appropriate theme mode
    final currentHour = DateTime.now().hour;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    // Emergency/crisis detection
    if (currentRoute.contains('incident') || 
        currentRoute.contains('emergency') || 
        currentRoute.contains('report')) {
      _themeMode = DrawerThemeMode.emergency;
    }
    // Night mode detection
    else if (currentHour < 6 || currentHour > 22) {
      _themeMode = DrawerThemeMode.night;
    }
    // Admin/professional mode
    else if (currentRoute.contains('admin')) {
      _themeMode = DrawerThemeMode.professional;
    }
    // Default normal mode
    else {
      _themeMode = DrawerThemeMode.normal;
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getDrawerGradient(_themeMode),
        ),
        child: Stack(
          children: [
            // Floating particles animation just like the loading screen
            const Positioned.fill(
              child: FloatingParticles(
                particleCount: 15,
                colors: [
                  AppTheme.saharaGold,
                  AppTheme.primaryLight,
                  AppTheme.secondaryLight,
                ],
                speed: 0.8,
              ),
            ),
            // Main content - Single ScrollView to prevent overflow
            Positioned.fill(
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: SafeArea(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Rethicssec Logo
                              Container(
                                width: 65,
                                height: 65,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/Rethicsec.png',
                                    width: 65,
                                    height: 65,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Welcome text with improved accessibility
                              Text(
                                _themeMode == DrawerThemeMode.emergency 
                                  ? 'Rethicssec Security Center'
                                  : 'Welcome to Rethicssec',
                                style: TextStyle(
                                  color: AppTheme.getDrawerTextColor(_themeMode),
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  shadows: AppTheme.getDrawerTextShadows(_themeMode),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _themeMode == DrawerThemeMode.emergency
                                  ? 'Safe • Secure • Supported'
                                  : 'Protecting Africa Digitally',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  shadows: AppTheme.getDrawerTextShadows(_themeMode),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ),

                  // Emergency Quick Actions Bar
                  if (_themeMode == DrawerThemeMode.emergency) 
                    SliverToBoxAdapter(
                      child: _buildEmergencyQuickActions(),
                    ),
                  
                  // Menu Items with progressive disclosure
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(_buildProgressiveMenuItems()),
                    ),
                  ),
                  
                  // Footer with trust indicators and crisis mode toggle
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Crisis mode toggle
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Crisis Mode',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    shadows: AppTheme.getDrawerTextShadows(_themeMode),
                                  ),
                                ),
                                Switch(
                                  value: _themeMode == DrawerThemeMode.emergency,
                                  onChanged: (value) {
                                    setState(() {
                                      _themeMode = value 
                                        ? DrawerThemeMode.emergency 
                                        : DrawerThemeMode.normal;
                                    });
                                  },
                                  activeColor: Colors.red,
                                  activeTrackColor: Colors.red.withOpacity(0.3),
                                  inactiveThumbColor: Colors.white,
                                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                                ),
                              ],
                            ),
                          ),
                          // Trust indicators
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildTrustIndicator(Icons.security, 'Secure'),
                                const SizedBox(width: 16),
                                _buildTrustIndicator(Icons.verified, 'Verified'),
                                const SizedBox(width: 16),
                                _buildTrustIndicator(Icons.shield, 'Protected'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rethicssec v1.0.0',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              shadows: AppTheme.getDrawerTextShadows(_themeMode),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Made with ❤️ for Africa',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              shadows: AppTheme.getDrawerTextShadows(_themeMode),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.clayRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.priority_high,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Crisis Support',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  shadows: AppTheme.getDrawerTextShadows(_themeMode),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickAction(
                Icons.report_problem,
                'Report Now',
                AppRouter.incidentReport,
                Colors.red,
              ),
              _buildQuickAction(
                Icons.smart_toy,
                'Get Help',
                AppRouter.aiChat,
                AppTheme.primaryColor,
              ),
              _buildQuickAction(
                Icons.emergency,
                'Emergency',
                AppRouter.emergencyContacts,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, String route, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, route);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  shadows: AppTheme.getDrawerTextShadows(_themeMode),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustIndicator(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w500,
            shadows: AppTheme.getDrawerTextShadows(_themeMode),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildProgressiveMenuItems() {
    List<Widget> items = [];

    // Priority items based on theme mode
    if (_themeMode == DrawerThemeMode.emergency) {
      // Crisis mode - essential items only
      items.addAll([
        _buildSectionHeader('Emergency Actions'),
        _buildDrawerItem(
          context,
          icon: Icons.report_problem,
          title: 'nav.report'.tr(),
          route: AppRouter.incidentReport,
        ),
        _buildDrawerItem(
          context,
          icon: Icons.smart_toy,
          title: 'nav.ai'.tr(),
          route: AppRouter.aiChat,
        ),
        _buildDrawerItem(
          context,
          icon: Icons.folder_open,
          title: 'nav.cases'.tr(),
          route: AppRouter.caseTracking,
        ),
        _buildDrawerItem(
          context,
          icon: Icons.emergency,
          title: 'nav.emergency'.tr(),
          route: AppRouter.emergencyContacts,
        ),
        const Divider(color: Colors.white24),
        _buildSectionHeader('Support'),
        _buildDrawerItem(
          context,
          icon: Icons.help,
          title: 'nav.help'.tr(),
          onTap: () => _showHelpDialog(context),
        ),
      ]);
    } else {
      // Normal mode - full feature set
      items.addAll([
        _buildSectionHeader('Main Features'),
        _buildDrawerItem(
          context,
          icon: Icons.dashboard,
          title: 'nav.dashboard'.tr(),
          route: AppRouter.dashboard,
        ),
        _buildDrawerItem(
          context,
          icon: Icons.report_problem,
          title: 'nav.report'.tr(),
          route: AppRouter.incidentReport,
        ),
        _buildDrawerItem(
          context,
          icon: Icons.smart_toy,
          title: 'nav.ai'.tr(),
          route: AppRouter.aiChat,
        ),
        _buildDrawerItem(
          context,
          icon: Icons.folder_open,
          title: 'nav.cases'.tr(),
          route: AppRouter.caseTracking,
        ),
        const Divider(color: Colors.white24),
        _buildSectionHeader('Security Tools'),
        _buildDrawerItem(
          context,
          icon: Icons.security,
          title: 'nav.scanner'.tr(),
          route: AppRouter.scanner,
        ),
        _buildDrawerItem(
          context,
          icon: Icons.school,
          title: 'nav.education'.tr(),
          route: AppRouter.educationHub,
        ),
        _buildDrawerItem(
          context,
          icon: Icons.emergency,
          title: 'nav.emergency'.tr(),
          route: AppRouter.emergencyContacts,
        ),
      ]);
    }

    // Admin section (only for accounts with the admin/super_admin role)
    if (_isAdmin) {
      items.addAll([
        const Divider(color: Colors.white24),
        _buildDrawerItem(
          context,
          icon: Icons.admin_panel_settings,
          title: 'Admin Panel',
          route: AppRouter.adminDashboard,
          isAdmin: true,
        ),
      ]);
    }

    // User settings (always show)
    items.addAll([
      const Divider(color: Colors.white24),
      _buildSectionHeader('Settings'),
      _buildDrawerItem(
        context,
        icon: Icons.person,
        title: 'nav.profile'.tr(),
        route: AppRouter.profile,
      ),
      _buildDrawerItem(
        context,
        icon: Icons.language,
        title: 'nav.language'.tr(),
        route: AppRouter.languageSelection,
      ),
    ]);

    // Help and info (only in normal mode, already shown in emergency)
    if (_themeMode != DrawerThemeMode.emergency) {
      items.addAll([
        _buildDrawerItem(
          context,
          icon: Icons.help,
          title: 'nav.help'.tr(),
          onTap: () => _showHelpDialog(context),
        ),
        _buildDrawerItem(
          context,
          icon: Icons.info,
          title: 'nav.about'.tr(),
          onTap: () => _showAboutDialog(context),
        ),
      ]);
    }

    // Sign out (always at bottom)
    items.addAll([
      const Divider(color: Colors.white24),
      _buildDrawerItem(
        context,
        icon: Icons.logout,
        title: 'nav.signout'.tr(),
        onTap: () => _signOut(context),
        isDestructive: true,
      ),
    ]);

    return items;
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          shadows: AppTheme.getDrawerTextShadows(_themeMode),
        ),
      ),
    );
  }
  
  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? route,
    VoidCallback? onTap,
    bool isDestructive = false,
    bool isAdmin = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isAdmin 
          ? Colors.white.withOpacity(0.2)
          : Colors.white.withOpacity(0.1),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: isDestructive
              ? LinearGradient(colors: [AppTheme.errorColor, AppTheme.errorLight])
              : isAdmin 
                ? const LinearGradient(colors: [AppTheme.copperAccent, AppTheme.secondaryLight])
                : LinearGradient(colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)]),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isDestructive 
              ? Colors.white 
              : isAdmin 
                ? Colors.white 
                : AppTheme.primaryColor,
            size: 18,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700, // Increased weight
            fontSize: 15, // Increased size
            shadows: AppTheme.getDrawerTextShadows(_themeMode),
          ),
        ),
        trailing: isAdmin 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.copperAccent, AppTheme.secondaryColor],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
        onTap: onTap ?? () {
          Navigator.pop(context);
          if (route != null) {
            Navigator.pushNamed(context, route);
          }
        },
      ),
    );
  }

  
  void _showHelpDialog(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.secondaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.help_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Help & Support',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        contentPadding: EdgeInsets.zero,
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: 450,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Rethicssec Help Center',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                'Getting Started',
                'Learn how to navigate and use Rethicssec effectively for cybersecurity protection.',
              ),
              const SizedBox(height: 12),
              _buildHelpSection(
                'Reporting Incidents',
                'Step-by-step guide on how to report cybercrime incidents and track their progress.',
              ),
              const SizedBox(height: 12),
              _buildHelpSection(
                'Wilson AI Assistant',
                'Discover how to interact with our AI assistant for cybersecurity guidance.',
              ),
              const SizedBox(height: 12),
              _buildHelpSection(
                'Threat Scanner',
                'Learn to use our threat scanner to identify suspicious links and content.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Support',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('📧 Email: support@rethicsai.com'),
                    const Text('📞 Phone: +254 700 000 000'),
                    const Text('🌐 Website: www.rethicsai.com'),
                    const SizedBox(height: 8),
                    const Text(
                      'Emergency Hotline: +254 911',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Could open email app or contact form
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Contact Us'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  void _showAboutDialog(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'About Rethicssec',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
            maxWidth: 400,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.security,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Rethicssec',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Rethicssec is a comprehensive cybersecurity platform designed specifically for Africa. Our mission is to protect African communities from digital threats through advanced technology and education.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Key Features:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('🛡️ Secure incident reporting'),
                    Text('🤖 AI-powered threat analysis'),
                    Text('📚 Community education'),
                    Text('🚨 Emergency response coordination'),
                    Text('🔍 Advanced threat scanning'),
                    Text('🌍 Multi-language support'),
                    Text('📱 Mobile-first design'),
                    Text('🎨 African cultural integration'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Together, we can build a safer digital Africa. 🌍',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Could open website or more info
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Learn More'),
          ),
        ],
      ),
    );
  }
  
  void _signOut(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Sign Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of Rethicssec?\n\nYou can always sign back in to continue protecting your digital life.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Close dialog and drawer first
              Navigator.pop(context); // Close signout dialog
              Navigator.pop(context); // Close drawer
              
              // Trigger sign out - BlocListener in main.dart will handle navigation
              context.read<AuthBloc>().add(AuthSignOutRequested());
              
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 16),
                      Text('Signing out...'),
                    ],
                  ),
                  backgroundColor: AppTheme.primaryColor,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
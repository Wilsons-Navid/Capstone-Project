import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../../shared/widgets/premium_components.dart';
import '../../../../core/utils/app_router.dart';
import 'incident_reports_page.dart';
import 'detected_threats_page.dart';
import 'case_management_page.dart';
import 'content_moderation_page.dart';
import 'system_settings_page.dart';
import 'system_analytics_page.dart';
import 'learning_management_page.dart';
import 'threat_management_page.dart';
import 'emergency_contacts_management_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = true;
  Map<String, int> _platformStats = {
    'totalUsers': 0,
    'activeCases': 0,
    'reportsToday': 0,
    'resolvedCases': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadPlatformStatistics();
  }

  Future<void> _loadPlatformStatistics() async {
    setState(() => _isLoading = true);
    try {
      // Load users count
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      
      // Load incidents count
      final incidentsSnapshot = await FirebaseFirestore.instance.collection('incidents').get();
      
      // Calculate active cases from incidents (cases that are being worked on)
      final activeCases = incidentsSnapshot.docs.where((doc) {
        final status = doc.data()['status'] as String?;
        return status == 'in_progress' || status == 'investigating' || status == 'under_review';
      }).length;
      
      // Calculate resolved cases from incidents  
      final resolvedCases = incidentsSnapshot.docs.where((doc) {
        final status = doc.data()['status'] as String?;
        return status == 'resolved' || status == 'closed';
      }).length;
      
      // Calculate today's reports
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final reportsToday = incidentsSnapshot.docs.where((doc) {
        try {
          final createdAt = DateTime.parse(doc.data()['created_at']);
          return createdAt.isAfter(startOfDay);
        } catch (e) {
          return false;
        }
      }).length;
      
      setState(() {
        _platformStats = {
          'totalUsers': usersSnapshot.docs.length,
          'activeCases': activeCases,
          'reportsToday': reportsToday,
          'resolvedCases': resolvedCases,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading platform statistics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AfricanPatternBackground(opacity: 0.03),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Premium Header
                  PremiumSectionHeader(
                    title: 'Admin Dashboard',
                    subtitle: 'Manage Rethicssec Platform',
                    icon: Icons.admin_panel_settings,
                    gradient: AppTheme.primaryGradient,
                    action: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Admin Functions Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                    children: [
                      _buildAdminCard(
                        context,
                        'User Management',
                        'Manage user accounts and permissions',
                        Icons.people,
                        AppTheme.primaryColor,
                        () {
                          Navigator.pushNamed(context, AppRouter.userManagement);
                        },
                      ),
                      _buildAdminCard(
                        context,
                        'Learning Materials',
                        'Manage educational content and categories',
                        Icons.school,
                        Colors.teal,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LearningManagementPage(),
                            ),
                          );
                        },
                      ),
                      _buildAdminCard(
                        context,
                        'Incident Reports',
                        'View and manage all incident reports',
                        Icons.report_problem,
                        Colors.orange,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const IncidentReportsPage(),
                            ),
                          );
                        },
                      ),
                      _buildAdminCard(
                        context,
                        'Detected Threats',
                        'Scams the AI model flagged from scans & SMS',
                        Icons.shield_moon,
                        Colors.teal,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetectedThreatsPage(),
                            ),
                          );
                        },
                      ),
                      _buildAdminCard(
                        context,
                        'Case Management',
                        'Assign and track investigation cases',
                        Icons.folder_open,
                        Colors.blue,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CaseManagementPage(),
                            ),
                          );
                        },
                      ),
                      _buildAdminCard(
                        context,
                        'System Analytics',
                        'View platform usage and statistics',
                        Icons.analytics,
                        Colors.green,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SystemAnalyticsPage(),
                            ),
                          );
                        },
                      ),
                      _buildAdminCard(
                        context,
                        'Content Moderation',
                        'Moderate user-generated content',
                        Icons.verified_user,
                        Colors.purple,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ContentModerationPage(),
                            ),
                          );
                        },
                      ),
                      _buildAdminCard(
                        context,
                        'System Settings',
                        'Configure platform settings',
                        Icons.settings,
                        Colors.grey[700]!,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SystemSettingsPage(),
                            ),
                          );
                        },
                      ),
                      _buildAdminCard(
                        context,
                        'Threat Management',
                        'Manage verified threat database',
                        Icons.security,
                        Colors.red,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ThreatManagementPage(),
                            ),
                          );
                        },
                      ),
                      _buildAdminCard(
                        context,
                        'Emergency Contacts',
                        'Manage emergency contact database',
                        Icons.contact_phone,
                        Colors.indigo,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EmergencyContactsManagementPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Quick Stats
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
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
                        Text(
                          'Platform Statistics',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem('Total Users', _platformStats['totalUsers']!.toString(), Icons.people),
                              ),
                              Expanded(
                                child: _buildStatItem('Active Cases', _platformStats['activeCases']!.toString(), Icons.folder_open),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem('Reports Today', _platformStats['reportsToday']!.toString(), Icons.report),
                              ),
                              Expanded(
                                child: _buildStatItem('Resolved Cases', _platformStats['resolvedCases']!.toString(), Icons.check_circle),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // Access Instructions
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Admin Access Information',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Admin access is available through the navigation drawer\n'
                          '• In production, this requires user.isAdmin = true\n'
                          '• Access URL: /admin or through the drawer menu\n'
                          '• For testing, admin access is currently enabled for all users',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
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

  Widget _buildAdminCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceVariant,
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: const Text(
          'This admin feature is currently under development. '
          'It will be available in a future update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
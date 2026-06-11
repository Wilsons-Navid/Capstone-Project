import 'package:flutter/material.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../core/utils/app_router.dart';

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

const List<DashboardFeature> dashboardFeatures = [
  DashboardFeature(
    title: 'incidents.report_incident',
    subtitle: 'dashboard.secure_reporting',
    icon: Icons.report_problem,
    gradient: AppTheme.primaryGradient,
    route: AppRouter.incidentReport,
  ),
  DashboardFeature(
    title: 'ai.assistant_name',
    subtitle: 'dashboard.ai_analysis',
    icon: Icons.psychology,
    gradient: AppTheme.secondaryGradient,
    route: AppRouter.aiChat,
  ),
  DashboardFeature(
    title: 'cases.track_cases',
    subtitle: 'dashboard.monitor_reports',
    icon: Icons.track_changes,
    gradient: AppTheme.accentGradient,
    route: AppRouter.caseTracking,
  ),
  DashboardFeature(
    title: 'scanner.threat_scanner',
    subtitle: 'dashboard.scan_content',
    icon: Icons.security,
    gradient: AppTheme.scannerGradient,
    route: AppRouter.scanner,
  ),
  DashboardFeature(
    title: 'sms.title',
    subtitle: 'sms.dashboard_subtitle',
    icon: Icons.sms_failed,
    gradient: AppTheme.smsGuardGradient,
    route: AppRouter.smsGuard,
  ),
  DashboardFeature(
    title: 'education.learn_protect',
    subtitle: 'education.security_education',
    icon: Icons.school,
    gradient: AppTheme.africanSunsetGradient,
    route: AppRouter.educationHub,
  ),
  DashboardFeature(
    title: 'emergency.immediate_help',
    subtitle: 'emergency.immediate_help',
    icon: Icons.emergency,
    gradient: AppTheme.emergencyGradient,
    route: AppRouter.emergencyContacts,
  ),
];

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../themes/app_theme.dart';
import '../../shared/widgets/african_pattern_background.dart';
import '../../shared/widgets/animated_splash_screen.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/incidents/presentation/pages/incident_report_page.dart';
import '../../features/incidents/presentation/pages/incident_details_page.dart';
import '../../features/cases/presentation/pages/case_tracking_page.dart';
import '../../features/cases/presentation/pages/case_details_page.dart';
import '../../features/ai_assistant/presentation/pages/ai_chat_page.dart';
import '../../features/education/presentation/pages/education_hub_page.dart';
import '../../features/education/presentation/pages/education_detail_page.dart';
import '../../features/scanner/presentation/pages/scanner_page.dart';
import '../../features/scanner/presentation/pages/content_scanner_page.dart';
import '../../features/scanner/presentation/pages/test_scanner_page.dart';
import '../../features/scanner/presentation/pages/simple_scanner_page.dart';
import '../../features/emergency/presentation/pages/emergency_contacts_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/user_management_page.dart';
import '../../features/admin/presentation/pages/database_setup_page.dart';
import '../../features/settings/presentation/pages/simple_language_selection_page.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String incidentReport = '/incident-report';
  static const String incidentDetails = '/incident-details';
  static const String caseTracking = '/case-tracking';
  static const String caseDetails = '/case-details';
  static const String aiChat = '/ai-chat';
  static const String educationHub = '/education';
  static const String educationDetail = '/education-detail';
  static const String scanner = '/scanner';
  static const String contentScanner = '/content-scanner';
  static const String emergencyContacts = '/emergency-contacts';
  static const String profile = '/profile';
  static const String adminDashboard = '/admin';
  static const String userManagement = '/admin/users';
  static const String databaseSetup = '/setup';
  static const String languageSelection = '/language-selection';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => AnimatedSplashScreen(
            onAnimationComplete: () {
              Navigator.of(context).pushReplacementNamed(AppRouter.login);
            },
          ),
          transitionDuration: Duration.zero, // Instant transition
          reverseTransitionDuration: Duration.zero,
          settings: settings,
        );

      case login:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
          transitionDuration: Duration.zero, // Instant transition
          reverseTransitionDuration: Duration.zero,
          settings: settings,
        );

      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterPage(),
          settings: settings,
        );

      case forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordPage(),
          settings: settings,
        );

      case dashboard:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const DashboardPage(),
          transitionDuration: Duration.zero, // Instant transition
          reverseTransitionDuration: Duration.zero,
          settings: settings,
        );

      case incidentReport:
        return MaterialPageRoute(
          builder: (_) => const IncidentReportPage(),
          settings: settings,
        );

      case incidentDetails:
        final incidentId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => IncidentDetailsPage(incidentId: incidentId),
          settings: settings,
        );

      case caseTracking:
        return MaterialPageRoute(
          builder: (_) => const CaseTrackingPage(),
          settings: settings,
        );

      case caseDetails:
        final caseId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => CaseDetailsPage(caseId: caseId),
          settings: settings,
        );

      case aiChat:
        return MaterialPageRoute(
          builder: (_) => const RouteErrorBoundary(
            routeName: 'AiChat',
            child: AIChatPage(),
          ),
          settings: settings,
        );

      case educationHub:
        return MaterialPageRoute(
          builder: (_) => const RouteErrorBoundary(
            routeName: 'EducationHub',
            child: EducationHubPage(),
          ),
          settings: settings,
        );

      case educationDetail:
        final arguments = settings.arguments;
        if (arguments is String) {
          return MaterialPageRoute(
            builder: (_) => EducationDetailPage(contentId: arguments),
            settings: settings,
          );
        } else if (arguments is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => EducationDetailPage(contentId: arguments['contentId'] as String),
            settings: settings,
          );
        } else {
          return MaterialPageRoute(
            builder: (_) => const ErrorPage(),
            settings: settings,
          );
        }

      case scanner:
        return MaterialPageRoute(
          builder: (_) => const RouteErrorBoundary(
            routeName: 'Scanner',
            child: SimpleScannerPage(),
          ),
          settings: settings,
        );

      case contentScanner:
        return MaterialPageRoute(
          builder: (_) => const RouteErrorBoundary(
            routeName: 'ContentScanner',
            child: ContentScannerPage(),
          ),
          settings: settings,
        );

      case emergencyContacts:
        return MaterialPageRoute(
          builder: (_) => const RouteErrorBoundary(
            routeName: 'EmergencyContacts',
            child: EmergencyContactsPage(),
          ),
          settings: settings,
        );

      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfilePage(),
          settings: settings,
        );

      case adminDashboard:
        return MaterialPageRoute(
          builder: (_) => const AdminDashboardPage(),
          settings: settings,
        );

      case userManagement:
        return MaterialPageRoute(
          builder: (_) => const UserManagementPage(),
          settings: settings,
        );

      case databaseSetup:
        return MaterialPageRoute(
          builder: (_) => const DatabaseSetupPage(),
          settings: settings,
        );

      case languageSelection:
        return MaterialPageRoute(
          builder: (_) => const SimpleLanguageSelectionPage(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const ErrorPage(),
          settings: settings,
        );
    }
  }
}


// Error page for undefined routes
class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Error boundary wrapper for routes  
class RouteErrorBoundary extends StatelessWidget {
  final Widget child;
  final String routeName;

  const RouteErrorBoundary({
    super.key,
    required this.child,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
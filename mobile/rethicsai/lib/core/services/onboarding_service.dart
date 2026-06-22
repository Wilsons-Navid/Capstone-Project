import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user has seen the first-run onboarding so it shows once.
///
/// Two independent flags: the pre-login intro carousel, and the in-app feature
/// tour (coachmarks) shown on the dashboard. Versioned keys (`_v1`) let us
/// re-show onboarding after a major redesign by bumping the suffix.
class OnboardingService {
  OnboardingService._();

  static const String _kIntroSeen = 'onboarding_intro_seen_v1';
  static const String _kDashboardTourSeen = 'onboarding_dashboard_tour_seen_v1';

  static Future<bool> hasSeenIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIntroSeen) ?? false;
  }

  static Future<void> setIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIntroSeen, true);
  }

  static Future<bool> hasSeenDashboardTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDashboardTourSeen) ?? false;
  }

  static Future<void> setDashboardTourSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDashboardTourSeen, true);
  }

  /// Reset all onboarding flags — handy for a "Replay tutorial" settings action
  /// or for QA/demo runs.
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kIntroSeen);
    await prefs.remove(_kDashboardTourSeen);
  }
}

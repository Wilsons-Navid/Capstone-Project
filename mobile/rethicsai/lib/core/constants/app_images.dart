/// Application Image Assets
/// Centralized image constants for Rethicsec application
class AppImages {
  AppImages._();

  // Base paths
  static const String _imagesPath = 'assets/images';
  static const String _iconsPath = 'assets/icons';

  // Dashboard Feature Images
  static const String dashboardSecurity = '$_imagesPath/dashboard_security.png';
  static const String incidentReport = '$_imagesPath/incident_report.png';
  static const String aiAssistant = '$_imagesPath/ai_asssitant.jpeg';
  static const String threatScanner = '$_imagesPath/Threat_scanner1.jpg';
  static const String educationHub = '$_imagesPath/Security_Education.jpg';
  static const String emergencyHelp = '$_imagesPath/emergency help.jpg';
  static const String caseTracking = '$_imagesPath/Case_tracking.jpg';

  // Cybersecurity Icons
  static const String shieldLock = '$_iconsPath/shield_lock.png';
  static const String mobileSecurity = '$_iconsPath/mobile_security.png';
  static const String wifiSecurity = '$_iconsPath/wifi_security.png';
  static const String passwordSecurity = '$_iconsPath/password_security.png';
  static const String phishingProtection = '$_iconsPath/phishing_protection.png';
  static const String dataProtection = '$_iconsPath/data_protection.png';

  // African Mobile Money
  static const String mobileMoney = '$_imagesPath/mobile_money.png';
  static const String mpesaSecurity = '$_imagesPath/mpesa_security.png';
  static const String bankingSecurity = '$_imagesPath/banking_security.png';
  static const String transactionSecurity = '$_imagesPath/transaction_security.png';

  // Educational Content
  static const String securityTips = '$_imagesPath/security_tips.png';
  static const String scamAwareness = '$_imagesPath/scam_awareness.png';
  static const String digitalLiteracy = '$_imagesPath/digital_literacy.png';
  static const String cyberThreats = '$_imagesPath/cyber_threats.png';

  // Wilson AI Specific
  static const String wilsonAvatar = '$_imagesPath/wilson_avatar.png';
  static const String wilsonBackground = '$_imagesPath/wilson_background.png';
  static const String aiThinking = '$_imagesPath/ai_thinking.png';

  // African Context Images
  static const String africanCybersecurity = '$_imagesPath/african_cybersecurity.jpg';
  static const String communityProtection = '$_imagesPath/community_protection.png';
  static const String digitalInclusion = '$_imagesPath/digital_inclusion.png';

  // Background and Decorative
  static const String africanPattern = '$_imagesPath/african_pattern.png';
  static const String securityBackground = '$_imagesPath/security_background.png';
  static const String gradientOverlay = '$_imagesPath/gradient_overlay.png';

  // Status and Feedback Images
  static const String successCheck = '$_iconsPath/success_check.png';
  static const String warningTriangle = '$_iconsPath/warning_triangle.png';
  static const String errorCross = '$_iconsPath/error_cross.png';
  static const String infoCircle = '$_iconsPath/info_circle.png';

  // Feature Category Icons
  static const String dashboardIcon = '$_iconsPath/dashboard_icon.png';
  static const String reportIcon = '$_iconsPath/report_icon.png';
  static const String aiIcon = '$_iconsPath/ai_icon.png';
  static const String scannerIcon = '$_iconsPath/scanner_icon.png';
  static const String educationIcon = '$_iconsPath/education_icon.png';
  static const String emergencyIcon = '$_iconsPath/emergency_icon.png';
  static const String casesIcon = '$_iconsPath/cases_icon.png';
  static const String profileIcon = '$_iconsPath/profile_icon.png';

  // Placeholder when images are not available
  static const String placeholder = '$_imagesPath/placeholder.png';
  static const String iconPlaceholder = '$_iconsPath/icon_placeholder.png';
}

/// Image configuration utilities
class ImageConfig {
  static const double cardImageHeight = 160.0;
  static const double cardImageWidth = 240.0;
  static const double iconSize = 64.0;
  static const double largeIconSize = 128.0;
  
  /// Returns appropriate placeholder for missing images
  static String getPlaceholder(ImageType type) {
    switch (type) {
      case ImageType.icon:
        return AppImages.iconPlaceholder;
      case ImageType.image:
        return AppImages.placeholder;
    }
  }
}

enum ImageType { icon, image }
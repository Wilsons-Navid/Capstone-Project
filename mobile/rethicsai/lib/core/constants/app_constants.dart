class AppConstants {
  // App Info
  static const String appName = 'Rethicsec';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Comprehensive cybercrime reporting platform for Africa';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String incidentsCollection = 'incidents';
  static const String casesCollection = 'cases';
  static const String emergencyContactsCollection = 'emergency_contacts';
  static const String educationContentCollection = 'education_content';
  static const String threatsCollection = 'threats';
  static const String notificationsCollection = 'notifications';
  
  // Storage Paths
  static const String evidenceStoragePath = 'evidence';
  static const String profileImagesPath = 'profile_images';
  static const String documentsPath = 'documents';
  
  // Regional Support
  static const List<String> supportedCountries = [
    'Nigeria', 'Kenya', 'South Africa', 'Ghana', 'Egypt', 'Morocco',
    'Uganda', 'Tanzania', 'Rwanda', 'Senegal', 'Ethiopia', 'Cameroon',
    'Ivory Coast', 'Botswana', 'Zambia', 'Zimbabwe'
  ];
  
  static const List<String> supportedLanguages = [
    'en', 'sw', 'fr', 'ar', 'ha', 'yo', 'ig', 'zu', 'xh', 'af'
  ];
  
  // Incident Types
  static const List<String> incidentTypes = [
    'Identity Theft',
    'Phishing Attack',
    'Online Fraud',
    'Cyberbullying',
    'Ransomware',
    'Data Breach',
    'Social Media Scam',
    'Romance Scam',
    'Investment Fraud',
    'Mobile Money Fraud',
    'SIM Swapping',
    'Fake Job Offers',
    'Academic Fraud',
    'Healthcare Fraud',
    'Other'
  ];
  
  // Priority Levels
  static const List<String> priorityLevels = ['High', 'Medium', 'Low'];
  
  // Case Status
  static const List<String> caseStatuses = [
    'Submitted',
    'Under Review',
    'In Progress',
    'Investigating',
    'Resolved',
    'Closed'
  ];
  
  // Threat Levels
  static const List<String> threatLevels = [
    'Safe',
    'Low Risk',
    'Medium Risk',
    'High Risk',
    'Critical'
  ];
  
  // Default Values
  static const int defaultPageSize = 20;
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int caseNumberLength = 8;
  static const String defaultCountryCode = '+234'; // Nigeria
  
  // URLs
  static const String privacyPolicyUrl = 'https://rethicsai.com/privacy';
  static const String termsOfServiceUrl = 'https://rethicsai.com/terms';
  static const String supportUrl = 'https://rethicsai.com/support';
  
  // Animation Durations
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);
}
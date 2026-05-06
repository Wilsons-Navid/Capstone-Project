import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? displayName;
  final String? phoneNumber;
  final String? photoURL;
  final String? country;
  final String language;
  final bool isEmailVerified;
  final String? authProvider;
  final NotificationPreferences notificationPreferences;
  final bool isVerified;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActive;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.displayName,
    this.phoneNumber,
    this.photoURL,
    this.country,
    this.language = 'en',
    this.isEmailVerified = false,
    this.authProvider,
    this.notificationPreferences = const NotificationPreferences(),
    this.isVerified = false,
    this.isAdmin = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      displayName: json['displayName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      photoURL: json['photoURL'] as String?,
      country: json['country'] as String?,
      language: json['language'] as String? ?? 'en',
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      authProvider: json['authProvider'] as String?,
      notificationPreferences: json['notificationPreferences'] != null
          ? NotificationPreferences.fromJson(json['notificationPreferences'] as Map<String, dynamic>)
          : const NotificationPreferences(),
      isVerified: json['isVerified'] as bool? ?? false,
      isAdmin: json['isAdmin'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastActive: json['lastActive'] != null ? DateTime.parse(json['lastActive'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'country': country,
      'language': language,
      'isEmailVerified': isEmailVerified,
      'authProvider': authProvider,
      'notificationPreferences': notificationPreferences.toJson(),
      'isVerified': isVerified,
      'isAdmin': isAdmin,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastActive': lastActive?.toIso8601String(),
    };
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson({
      'id': doc.id,
      ...data,
      'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp).toDate().toIso8601String(),
      'lastActive': data['lastActive'] != null
          ? (data['lastActive'] as Timestamp).toDate().toIso8601String()
          : null,
    });
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    json['createdAt'] = Timestamp.fromDate(createdAt);
    json['updatedAt'] = Timestamp.fromDate(updatedAt);
    if (lastActive != null) {
      json['lastActive'] = Timestamp.fromDate(lastActive!);
    }
    return json;
  }
}

class NotificationPreferences {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool marketingEmails;
  final bool caseUpdates;
  final bool securityAlerts;
  final bool educationalContent;

  const NotificationPreferences({
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.smsNotifications = false,
    this.marketingEmails = false,
    this.caseUpdates = true,
    this.securityAlerts = true,
    this.educationalContent = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      pushNotifications: json['pushNotifications'] as bool? ?? true,
      emailNotifications: json['emailNotifications'] as bool? ?? true,
      smsNotifications: json['smsNotifications'] as bool? ?? false,
      marketingEmails: json['marketingEmails'] as bool? ?? false,
      caseUpdates: json['caseUpdates'] as bool? ?? true,
      securityAlerts: json['securityAlerts'] as bool? ?? true,
      educationalContent: json['educationalContent'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'smsNotifications': smsNotifications,
      'marketingEmails': marketingEmails,
      'caseUpdates': caseUpdates,
      'securityAlerts': securityAlerts,
      'educationalContent': educationalContent,
    };
  }
}
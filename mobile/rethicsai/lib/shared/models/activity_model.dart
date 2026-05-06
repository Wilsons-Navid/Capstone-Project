import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity_model.freezed.dart';
part 'activity_model.g.dart';

@freezed
class ActivityModel with _$ActivityModel {
  const factory ActivityModel({
    required String id,
    required String userId,
    required String title,
    required String description,
    required ActivityType type,
    required ActivityStatus status,
    required DateTime timestamp,
    String? relatedEntityId,
    String? relatedEntityType,
    Map<String, dynamic>? metadata,
  }) = _ActivityModel;

  factory ActivityModel.fromJson(Map<String, dynamic> json) =>
      _$ActivityModelFromJson(json);
}

enum ActivityType {
  incidentReported,
  incidentUpdated,
  incidentResolved,
  securityScan,
  profileUpdated,
  loginAttempt,
  passwordChanged,
  aiAssistantQuery,
  educationContentViewed,
  reportGenerated,
  systemNotification,
}

enum ActivityStatus {
  success,
  warning,
  error,
  info,
  pending,
}

extension ActivityTypeExtension on ActivityType {
  String get displayName {
    switch (this) {
      case ActivityType.incidentReported:
        return 'Incident Reported';
      case ActivityType.incidentUpdated:
        return 'Case Status Updated';
      case ActivityType.incidentResolved:
        return 'Case Resolved';
      case ActivityType.securityScan:
        return 'Security Scan';
      case ActivityType.profileUpdated:
        return 'Profile Updated';
      case ActivityType.loginAttempt:
        return 'Login Activity';
      case ActivityType.passwordChanged:
        return 'Password Changed';
      case ActivityType.aiAssistantQuery:
        return 'AI Assistant Used';
      case ActivityType.educationContentViewed:
        return 'Education Content Viewed';
      case ActivityType.reportGenerated:
        return 'Report Generated';
      case ActivityType.systemNotification:
        return 'System Notification';
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityType.incidentReported:
        return Icons.report_problem;
      case ActivityType.incidentUpdated:
        return Icons.update;
      case ActivityType.incidentResolved:
        return Icons.check_circle;
      case ActivityType.securityScan:
        return Icons.security;
      case ActivityType.profileUpdated:
        return Icons.person;
      case ActivityType.loginAttempt:
        return Icons.login;
      case ActivityType.passwordChanged:
        return Icons.lock;
      case ActivityType.aiAssistantQuery:
        return Icons.smart_toy;
      case ActivityType.educationContentViewed:
        return Icons.school;
      case ActivityType.reportGenerated:
        return Icons.description;
      case ActivityType.systemNotification:
        return Icons.notifications;
    }
  }
}

extension ActivityStatusExtension on ActivityStatus {
  Color get color {
    switch (this) {
      case ActivityStatus.success:
        return Colors.green;
      case ActivityStatus.warning:
        return Colors.orange;
      case ActivityStatus.error:
        return Colors.red;
      case ActivityStatus.info:
        return Colors.blue;
      case ActivityStatus.pending:
        return Colors.grey;
    }
  }
}
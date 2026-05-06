import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../shared/models/activity_model.dart';
import 'logging_service.dart';
import 'analytics_service.dart';

class ActivityService {
  static const String _collection = 'user_activities';
  
  static CollectionReference get _activities =>
      FirebaseFirestore.instance.collection(_collection);

  /// Record a new user activity
  static Future<void> recordActivity({
    required ActivityType type,
    required String title,
    required String description,
    ActivityStatus status = ActivityStatus.info,
    String? relatedEntityId,
    String? relatedEntityType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        LoggingService.warning('ActivityService', 'No authenticated user for activity recording');
        return;
      }

      final activity = ActivityModel(
        id: '', // Will be set by Firestore
        userId: currentUser.uid,
        title: title,
        description: description,
        type: type,
        status: status,
        timestamp: DateTime.now(),
        relatedEntityId: relatedEntityId,
        relatedEntityType: relatedEntityType,
        metadata: metadata,
      );

      final docRef = await _activities.add(activity.toJson());
      
      LoggingService.info('ActivityService', 'Activity recorded: $title for user ${currentUser.uid}');

      // Track analytics
      await AnalyticsService.trackEvent(
        name: 'user_activity_recorded',
        parameters: {
          'activity_type': type.name,
          'activity_status': status.name,
          'has_related_entity': relatedEntityId != null,
        },
      );

    } catch (e, stackTrace) {
      LoggingService.error('ActivityService', 'Failed to record activity', e, stackTrace);
    }
  }

  /// Get recent activities for current user
  static Future<List<ActivityModel>> getRecentActivities({int limit = 10}) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        LoggingService.warning('ActivityService', 'No authenticated user for activity retrieval');
        return [];
      }

      // Try with orderBy first, fallback to simple query if index not available
      QuerySnapshot querySnapshot;
      try {
        querySnapshot = await _activities
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .limit(limit)
            .get();
      } catch (e) {
        LoggingService.warning('ActivityService', 'Ordered query failed, using simple query: $e');
        querySnapshot = await _activities
            .where('userId', isEqualTo: currentUser.uid)
            .limit(limit)
            .get();
      }

      final activities = querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            
            // Convert Firestore timestamp to DateTime
            if (data['timestamp'] is Timestamp) {
              data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
            }
            
            return ActivityModel.fromJson(data);
          })
          .toList();

      // Sort by timestamp if we used the simple query
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      LoggingService.info('ActivityService', 'Retrieved ${activities.length} recent activities for user ${currentUser.uid}');
      return activities;

    } catch (e, stackTrace) {
      LoggingService.error('ActivityService', 'Failed to get recent activities', e, stackTrace);
      return [];
    }
  }

  /// Get activities by type
  static Future<List<ActivityModel>> getActivitiesByType(ActivityType type, {int limit = 20}) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];

      final querySnapshot = await _activities
          .where('userId', isEqualTo: currentUser.uid)
          .where('type', isEqualTo: type.name)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            
            // Convert Firestore timestamp to DateTime
            if (data['timestamp'] is Timestamp) {
              data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
            }
            
            return ActivityModel.fromJson(data);
          })
          .toList();

    } catch (e, stackTrace) {
      LoggingService.error('ActivityService', 'Failed to get activities by type', e, stackTrace);
      return [];
    }
  }

  /// Get activities for a specific date range
  static Future<List<ActivityModel>> getActivitiesInRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 50,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];

      final querySnapshot = await _activities
          .where('userId', isEqualTo: currentUser.uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            
            // Convert Firestore timestamp to DateTime
            if (data['timestamp'] is Timestamp) {
              data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
            }
            
            return ActivityModel.fromJson(data);
          })
          .toList();

    } catch (e, stackTrace) {
      LoggingService.error('ActivityService', 'Failed to get activities in range', e, stackTrace);
      return [];
    }
  }

  /// Clear old activities (for cleanup/performance)
  static Future<void> clearOldActivities({int daysToKeep = 90}) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final querySnapshot = await _activities
          .where('userId', isEqualTo: currentUser.uid)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      
      LoggingService.info('ActivityService', 'Cleared ${querySnapshot.docs.length} old activities for user ${currentUser.uid}');

    } catch (e, stackTrace) {
      LoggingService.error('ActivityService', 'Failed to clear old activities', e, stackTrace);
    }
  }

  /// Convenience methods for common activities

  static Future<void> recordIncidentActivity({
    required String incidentId,
    required String title,
    required String description,
    required ActivityType type,
    ActivityStatus status = ActivityStatus.info,
  }) async {
    await recordActivity(
      type: type,
      title: title,
      description: description,
      status: status,
      relatedEntityId: incidentId,
      relatedEntityType: 'incident',
      metadata: {
        'incident_id': incidentId,
        'source': 'incident_management',
      },
    );
  }

  static Future<void> recordLoginActivity({
    required bool success,
    String? deviceInfo,
    String? location,
  }) async {
    await recordActivity(
      type: ActivityType.loginAttempt,
      title: success ? 'Successful Login' : 'Failed Login Attempt',
      description: success 
          ? 'Logged in successfully${location != null ? ' from $location' : ''}'
          : 'Login attempt failed${location != null ? ' from $location' : ''}',
      status: success ? ActivityStatus.success : ActivityStatus.warning,
      metadata: {
        'success': success,
        'device_info': deviceInfo,
        'location': location,
        'source': 'authentication',
      },
    );
  }

  static Future<void> recordProfileActivity({
    required String action,
    String? details,
  }) async {
    await recordActivity(
      type: ActivityType.profileUpdated,
      title: 'Profile Updated',
      description: details ?? 'Profile information was updated',
      status: ActivityStatus.success,
      metadata: {
        'action': action,
        'source': 'profile_management',
      },
    );
  }

  static Future<void> recordSecurityScanActivity({
    required int threatsFound,
    required String scanType,
  }) async {
    await recordActivity(
      type: ActivityType.securityScan,
      title: 'Security Scan Completed',
      description: 'AI security scan found $threatsFound ${threatsFound == 1 ? 'threat' : 'threats'}',
      status: threatsFound == 0 ? ActivityStatus.success : ActivityStatus.warning,
      metadata: {
        'threats_found': threatsFound,
        'scan_type': scanType,
        'source': 'security_scanner',
      },
    );
  }

  static Future<void> recordAIAssistantActivity({
    required String query,
    required String responseType,
  }) async {
    await recordActivity(
      type: ActivityType.aiAssistantQuery,
      title: 'AI Assistant Used',
      description: 'Asked for help with ${responseType.toLowerCase()}',
      status: ActivityStatus.info,
      metadata: {
        'query_length': query.length,
        'response_type': responseType,
        'source': 'ai_assistant',
      },
    );
  }
}
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Notification channels for different types
  static const String _caseUpdatesChannelId = 'case_updates';
  static const String _educationChannelId = 'education';
  static const String _securityAlertsChannelId = 'security_alerts';
  static const String _generalChannelId = 'general';
  
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Request permission for notifications
      await _requestPermissions();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();
      
      // Set up message handlers
      _setupMessageHandlers();
      
      _isInitialized = true;
      print('✅ Notification Service initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize notification service: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    // Request notification permissions
    final NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Request additional permissions for local notifications
    await Permission.notification.request();
    
    print('Notification permission granted: ${settings.authorizationStatus}');
  }

  static Future<void> _initializeLocalNotifications() async {
    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (!kIsWeb) {
      await _createNotificationChannels();
    }
  }

  static Future<void> _createNotificationChannels() async {
    // Case Updates Channel
    const AndroidNotificationChannel caseUpdatesChannel =
        AndroidNotificationChannel(
      _caseUpdatesChannelId,
      'Case Updates',
      description: 'Updates on your reported cases',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification_case'),
    );

    // Education Channel
    const AndroidNotificationChannel educationChannel =
        AndroidNotificationChannel(
      _educationChannelId,
      'Educational Achievements',
      description: 'Learning progress and achievements',
      importance: Importance.defaultImportance,
      sound: RawResourceAndroidNotificationSound('notification_education'),
    );

    // Security Alerts Channel
    const AndroidNotificationChannel securityAlertsChannel =
        AndroidNotificationChannel(
      _securityAlertsChannelId,
      'Security Alerts',
      description: 'Important security notifications',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('notification_security'),
    );

    // General Channel
    const AndroidNotificationChannel generalChannel =
        AndroidNotificationChannel(
      _generalChannelId,
      'General Notifications',
      description: 'General app notifications',
      importance: Importance.defaultImportance,
    );

    // Register channels
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(caseUpdatesChannel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(educationChannel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(securityAlertsChannel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
  }

  static Future<void> _initializeFirebaseMessaging() async {
    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data);
    });

    // Handle messages when app is opened from terminated state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationTap(message.data);
      }
    });
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        print('FCM token saved: ${token.substring(0, 20)}...');
      } catch (e) {
        print('Failed to save FCM token: $e');
      }
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    final AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      // Determine channel based on notification type
      String channelId = _getChannelIdFromData(message.data);
      
      // Create notification details
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: _getImportance(channelId),
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
        color: _getNotificationColor(channelId),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show notification
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformDetails,
        payload: message.data.toString(),
      );
    }
  }

  // Notification type-specific methods
  
  /// Send case update notification
  static Future<void> sendCaseUpdateNotification(String userId, {
    required String caseNumber,
    required String status,
    required String message,
  }) async {
    final notificationData = {
      'type': 'case_update',
      'case_number': caseNumber,
      'status': status,
      'user_id': userId,
      'created_at': FieldValue.serverTimestamp(),
    };

    await _sendNotificationToUser(
      userId: userId,
      title: 'Case Update: $caseNumber',
      body: message,
      data: notificationData,
      type: NotificationType.caseUpdate,
    );
  }

  /// Send educational achievement notification
  static Future<void> sendEducationAchievementNotification(String userId, {
    required String achievement,
    required String description,
    int? progress,
  }) async {
    final notificationData = {
      'type': 'education_achievement',
      'achievement': achievement,
      'progress': progress,
      'user_id': userId,
      'created_at': FieldValue.serverTimestamp(),
    };

    await _sendNotificationToUser(
      userId: userId,
      title: '🎉 Achievement Unlocked!',
      body: '$achievement - $description',
      data: notificationData,
      type: NotificationType.educationAchievement,
    );
  }

  /// Send security alert notification
  static Future<void> sendSecurityAlertNotification(String userId, {
    required String alertType,
    required String message,
    String? actionRequired,
  }) async {
    final notificationData = {
      'type': 'security_alert',
      'alert_type': alertType,
      'action_required': actionRequired,
      'user_id': userId,
      'created_at': FieldValue.serverTimestamp(),
    };

    await _sendNotificationToUser(
      userId: userId,
      title: '🚨 Security Alert',
      body: message,
      data: notificationData,
      type: NotificationType.securityAlert,
    );
  }

  /// Send general notification
  static Future<void> sendGeneralNotification(String userId, {
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    final notificationData = {
      'type': 'general',
      'user_id': userId,
      'created_at': FieldValue.serverTimestamp(),
      ...?additionalData,
    };

    await _sendNotificationToUser(
      userId: userId,
      title: title,
      body: message,
      data: notificationData,
      type: NotificationType.general,
    );
  }

  static Future<void> _sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required NotificationType type,
  }) async {
    try {
      // Store notification in Firestore for notification history
      await _firestore.collection('notifications').add({
        'user_id': userId,
        'title': title,
        'body': body,
        'data': data,
        'type': type.name,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });

      // If the user is currently active, show local notification
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.uid == userId) {
        await _showLocalNotificationDirect(
          title: title,
          body: body,
          type: type,
          data: data,
        );
      }
      
      print('✅ Notification sent to user $userId: $title');
    } catch (e) {
      print('❌ Failed to send notification: $e');
    }
  }

  static Future<void> _showLocalNotificationDirect({
    required String title,
    required String body,
    required NotificationType type,
    required Map<String, dynamic> data,
  }) async {
    final channelId = _getChannelIdFromType(type);
    
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: _getImportance(channelId),
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      color: _getNotificationColor(channelId),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
      payload: data.toString(),
    );
  }

  // Helper methods for notification channels

  static String _getChannelIdFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'case_update':
        return _caseUpdatesChannelId;
      case 'education_achievement':
        return _educationChannelId;
      case 'security_alert':
        return _securityAlertsChannelId;
      default:
        return _generalChannelId;
    }
  }

  static String _getChannelIdFromType(NotificationType type) {
    switch (type) {
      case NotificationType.caseUpdate:
        return _caseUpdatesChannelId;
      case NotificationType.educationAchievement:
        return _educationChannelId;
      case NotificationType.securityAlert:
        return _securityAlertsChannelId;
      case NotificationType.general:
        return _generalChannelId;
    }
  }

  static String _getChannelName(String channelId) {
    switch (channelId) {
      case _caseUpdatesChannelId:
        return 'Case Updates';
      case _educationChannelId:
        return 'Educational Achievements';
      case _securityAlertsChannelId:
        return 'Security Alerts';
      default:
        return 'General Notifications';
    }
  }

  static String _getChannelDescription(String channelId) {
    switch (channelId) {
      case _caseUpdatesChannelId:
        return 'Updates on your reported cases and investigations';
      case _educationChannelId:
        return 'Learning progress, achievements, and course completions';
      case _securityAlertsChannelId:
        return 'Important security notifications and alerts';
      default:
        return 'General app notifications and updates';
    }
  }

  static Importance _getImportance(String channelId) {
    switch (channelId) {
      case _securityAlertsChannelId:
        return Importance.max;
      case _caseUpdatesChannelId:
        return Importance.high;
      default:
        return Importance.defaultImportance;
    }
  }

  static Color? _getNotificationColor(String channelId) {
    switch (channelId) {
      case _caseUpdatesChannelId:
        return const Color(0xFF1a237e); // Rethicssec Primary Blue
      case _educationChannelId:
        return const Color(0xFFDAA520); // Sahara Gold
      case _securityAlertsChannelId:
        return const Color(0xFFCD853F); // Copper Accent
      default:
        return const Color(0xFF3f51b5); // Rethicssec Secondary Blue
    }
  }

  // Notification tap handlers

  static void _onNotificationTapped(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      _handleNotificationTap({'payload': payload});
    }
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    
    // Handle navigation based on notification type
    switch (type) {
      case 'case_update':
        // Navigate to case details
        _navigateToCaseDetails(data['case_number'] as String?);
        break;
      case 'education_achievement':
        // Navigate to education hub
        _navigateToEducationHub();
        break;
      case 'security_alert':
        // Navigate to security settings
        _navigateToSecuritySettings();
        break;
      default:
        // Navigate to home or handle as needed
        break;
    }
  }

  static void _navigateToCaseDetails(String? caseNumber) {
    // Implementation depends on your navigation setup
    print('Navigate to case: $caseNumber');
  }

  static void _navigateToEducationHub() {
    // Implementation depends on your navigation setup
    print('Navigate to education hub');
  }

  static void _navigateToSecuritySettings() {
    // Implementation depends on your navigation setup
    print('Navigate to security settings');
  }

  // Get notification history for a user
  static Stream<List<AppNotification>> getNotificationsForUser(String userId) {
    // First try with orderBy, then fallback to simple query
    return Stream.fromFuture(_getNotificationsQuery(userId))
        .asyncExpand((query) => query.snapshots())
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();
      
      // Sort in Dart if we used the simple query (no orderBy)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return notifications;
    });
  }
  
  static Future<Query> _getNotificationsQuery(String userId) async {
    try {
      // Try with orderBy first
      final query = _firestore
          .collection('notifications')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(50);
      
      // Test the query by getting a snapshot
      await query.limit(1).get();
      return query;
    } catch (e) {
      print('NotificationService: Ordered query failed, using simple query: $e');
      // Fallback to simple query without orderBy
      return _firestore
          .collection('notifications')
          .where('user_id', isEqualTo: userId)
          .limit(50);
    }
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'is_read': true,
        'read_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  static Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('user_id', isEqualTo: userId)
          .where('is_read', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {
          'is_read': true,
          'read_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Failed to mark all notifications as read: $e');
    }
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

// Notification data models
enum NotificationType {
  caseUpdate,
  educationAchievement,
  securityAlert,
  general,
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.data,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AppNotification(
      id: doc.id,
      userId: data['user_id'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      type: NotificationType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'general'),
        orElse: () => NotificationType.general,
      ),
      isRead: data['is_read'] ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (data['read_at'] as Timestamp?)?.toDate(),
    );
  }
}
import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'logging_service.dart';

/// Comprehensive analytics service optimized for African markets
/// Tracks user behavior, performance metrics, and security events
class AnalyticsService {
  static FirebaseAnalytics? _analytics;
  static FirebasePerformance? _performance;
  static bool _isInitialized = false;
  static String? _userId;
  static String? _userCountry;
  static String? _deviceInfo;
  
  // Cache for performance optimization
  static final Map<String, Trace> _activeTraces = {};
  
  /// Initialize analytics with proper configuration for African markets
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Only initialize in production builds
      if (!kDebugMode) {
        _analytics = FirebaseAnalytics.instance;
        _performance = FirebasePerformance.instance;
        
        // Set default parameters for African context
        await _analytics?.setDefaultEventParameters({
          'app_version': await _getAppVersion(),
          'platform': Platform.operatingSystem,
          'device_category': await _getDeviceCategory(),
          'connectivity_type': 'unknown', // Will be updated dynamically
        });
        
        // Configure performance monitoring
        await _performance?.setPerformanceCollectionEnabled(true);
        
        LoggingService.info('AnalyticsService', 'Analytics initialized successfully');
      } else {
        LoggingService.info('AnalyticsService', 'Analytics disabled in debug mode');
      }
      
      _isInitialized = true;
    } catch (e, stackTrace) {
      LoggingService.error('AnalyticsService', 'Failed to initialize analytics', e, stackTrace);
      _isInitialized = true; // Mark as initialized to prevent retry loops
    }
  }
  
  /// Set user properties for better segmentation
  static Future<void> setUserProperties({
    required String userId,
    String? email,
    String? country,
    String? role,
    String? language,
  }) async {
    if (!_isInitialized || _analytics == null) return;
    
    try {
      _userId = userId;
      _userCountry = country;
      
      await _analytics?.setUserId(id: userId);
      
      final properties = <String, String?>{
        'user_role': role,
        'user_country': country,
        'user_language': language,
        'device_info': _deviceInfo ?? await _getDeviceInfo(),
      };
      
      for (final entry in properties.entries) {
        if (entry.value != null) {
          await _analytics?.setUserProperty(
            name: entry.key,
            value: entry.value!,
          );
        }
      }
      
      // Set Crashlytics user context
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
      if (country != null) {
        await FirebaseCrashlytics.instance.setCustomKey('user_country', country);
      }
      if (role != null) {
        await FirebaseCrashlytics.instance.setCustomKey('user_role', role);
      }
      
      LoggingService.info('AnalyticsService', 'User properties set for user: $userId');
    } catch (e, stackTrace) {
      LoggingService.error('AnalyticsService', 'Failed to set user properties', e, stackTrace);
    }
  }
  
  /// Track user actions with African market context
  static Future<void> trackEvent({
    required String name,
    Map<String, Object?>? parameters,
  }) async {
    if (!_isInitialized || _analytics == null) return;
    
    try {
      // Add contextual information for African markets
      final enhancedParameters = <String, Object>{};
      
      // Add non-null parameters
      parameters?.forEach((key, value) {
        if (value != null) {
          enhancedParameters[key] = value;
        }
      });
      
      // Add context
      enhancedParameters['connectivity_status'] = await _getConnectivityStatus();
      enhancedParameters['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      
      if (_userCountry != null) {
        enhancedParameters['user_country'] = _userCountry!;
      }
      
      await _analytics?.logEvent(
        name: _sanitizeEventName(name),
        parameters: enhancedParameters,
      );
      
      LoggingService.debug('AnalyticsService', 'Event tracked: $name');
    } catch (e, stackTrace) {
      LoggingService.error('AnalyticsService', 'Failed to track event: $name', e, stackTrace);
    }
  }
  
  /// Track incident-related events
  static Future<void> trackIncidentEvent({
    required String action,
    required String incidentType,
    String? incidentId,
    String? priority,
    String? status,
  }) async {
    await trackEvent(
      name: 'incident_$action',
      parameters: {
        'incident_type': incidentType,
        'incident_id': incidentId,
        'incident_priority': priority,
        'incident_status': status,
        'action_type': action,
      },
    );
  }
  
  /// Track security-related events
  static Future<void> trackSecurityEvent({
    required String event,
    required String threatLevel,
    String? threatType,
    String? scanType,
    String? details,
  }) async {
    await trackEvent(
      name: 'security_$event',
      parameters: {
        'threat_level': threatLevel,
        'threat_type': threatType,
        'scan_type': scanType,
        'security_details': details,
      },
    );
    
    // Log high-priority security events to Crashlytics
    if (threatLevel == 'high' || threatLevel == 'critical') {
      await FirebaseCrashlytics.instance.recordError(
        'High priority security event: $event',
        StackTrace.current,
        information: [
          DiagnosticsProperty('threat_level', threatLevel),
          DiagnosticsProperty('threat_type', threatType),
          DiagnosticsProperty('details', details),
        ],
      );
    }
  }
  
  /// Track authentication events
  static Future<void> trackAuthEvent({
    required String action,
    String? method,
    bool? success,
    String? error,
  }) async {
    await trackEvent(
      name: 'auth_$action',
      parameters: {
        'auth_method': method,
        'auth_success': success,
        'auth_error': error,
        'action_type': action,
      },
    );
  }
  
  /// Track AI assistant interactions
  static Future<void> trackAIInteraction({
    required String action,
    String? sessionId,
    String? messageType,
    int? messageLength,
    String? responseTime,
  }) async {
    await trackEvent(
      name: 'ai_$action',
      parameters: {
        'session_id': sessionId,
        'message_type': messageType,
        'message_length': messageLength,
        'ai_response_time': responseTime,
        'interaction_type': action,
      },
    );
  }
  
  /// Track education content engagement
  static Future<void> trackEducationEvent({
    required String action,
    String? contentId,
    String? contentType,
    String? category,
    int? engagementTimeSeconds,
  }) async {
    await trackEvent(
      name: 'education_$action',
      parameters: {
        'content_id': contentId,
        'content_type': contentType,
        'content_category': category,
        'engagement_time': engagementTimeSeconds,
        'education_action': action,
      },
    );
  }
  
  /// Start performance trace (e.g., for API calls, screen loads)
  static Future<Trace?> startTrace(String name) async {
    if (!_isInitialized || _performance == null) return null;
    
    try {
      final trace = _performance!.newTrace(_sanitizeTraceName(name));
      await trace.start();
      _activeTraces[name] = trace;
      
      LoggingService.debug('AnalyticsService', 'Performance trace started: $name');
      return trace;
    } catch (e, stackTrace) {
      LoggingService.error('AnalyticsService', 'Failed to start trace: $name', e, stackTrace);
      return null;
    }
  }
  
  /// Stop performance trace
  static Future<void> stopTrace(String name, {Map<String, String>? attributes}) async {
    if (!_isInitialized || !_activeTraces.containsKey(name)) return;
    
    try {
      final trace = _activeTraces[name]!;
      
      // Add contextual attributes
      if (attributes != null) {
        for (final entry in attributes.entries) {
          trace.putAttribute(entry.key, entry.value);
        }
      }
      
      // Add default attributes for African markets
      trace.putAttribute('user_country', _userCountry ?? 'unknown');
      trace.putAttribute('connectivity', await _getConnectivityStatus());
      
      await trace.stop();
      _activeTraces.remove(name);
      
      LoggingService.debug('AnalyticsService', 'Performance trace stopped: $name');
    } catch (e, stackTrace) {
      LoggingService.error('AnalyticsService', 'Failed to stop trace: $name', e, stackTrace);
    }
  }
  
  /// Track screen views
  static Future<void> trackScreenView({
    required String screenName,
    String? screenClass,
    Map<String, Object?>? parameters,
  }) async {
    if (!_isInitialized || _analytics == null) return;
    
    try {
      await _analytics?.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
        parameters: <String, Object>{
          if (_userCountry != null) 'user_country': _userCountry!,
          'screen_load_time': DateTime.now().millisecondsSinceEpoch,
          ...?parameters?.map((key, value) => MapEntry(key, value ?? '')),
        },
      );
      
      LoggingService.debug('AnalyticsService', 'Screen view tracked: $screenName');
    } catch (e, stackTrace) {
      LoggingService.error('AnalyticsService', 'Failed to track screen view: $screenName', e, stackTrace);
    }
  }
  
  /// Track conversion events (key business metrics)
  static Future<void> trackConversion({
    required String conversionType,
    String? value,
    String? currency = 'USD',
    Map<String, Object?>? additionalParameters,
  }) async {
    await trackEvent(
      name: 'conversion',
      parameters: {
        'conversion_type': conversionType,
        'conversion_value': value,
        'conversion_currency': currency,
        ...?additionalParameters?.map((key, value) => MapEntry(key, value ?? '')),
      },
    );
  }
  
  /// Track app lifecycle events
  static Future<void> trackAppLifecycleEvent({
    required String event,
    int? sessionDurationSeconds,
  }) async {
    await trackEvent(
      name: 'app_$event',
      parameters: {
        'lifecycle_event': event,
        'session_duration': sessionDurationSeconds,
        'app_version': await _getAppVersion(),
      },
    );
  }
  
  /// Track performance metrics specific to African markets
  static Future<void> trackPerformanceMetric({
    required String metricName,
    required num value,
    String? unit,
    Map<String, String>? attributes,
  }) async {
    if (!_isInitialized || _performance == null) return;
    
    try {
      // Create a custom metric
      final httpMetric = _performance!.newHttpMetric(
        'custom_metric_$metricName',
        HttpMethod.Get,
      );
      
      if (attributes != null) {
        for (final entry in attributes.entries) {
          httpMetric.putAttribute(entry.key, entry.value);
        }
      }
      
      // Add African market context
      httpMetric.putAttribute('user_country', _userCountry ?? 'unknown');
      httpMetric.putAttribute('metric_unit', unit ?? 'count');
      
      await httpMetric.start();
      await httpMetric.stop();
      
      // Also track as regular event for easier analysis
      await trackEvent(
        name: 'performance_metric',
        parameters: {
          'metric_name': metricName,
          'metric_value': value,
          'metric_unit': unit,
          ...?attributes?.map((key, value) => MapEntry(key, value)),
        },
      );
      
      LoggingService.debug('AnalyticsService', 'Performance metric tracked: $metricName = $value');
    } catch (e, stackTrace) {
      LoggingService.error('AnalyticsService', 'Failed to track performance metric: $metricName', e, stackTrace);
    }
  }
  
  /// Track errors and exceptions
  static Future<void> trackError({
    required String error,
    String? context,
    StackTrace? stackTrace,
    bool fatal = false,
  }) async {
    await trackEvent(
      name: 'app_error',
      parameters: {
        'error_message': error,
        'error_context': context,
        'error_fatal': fatal,
        'error_stack_trace': stackTrace?.toString(),
      },
    );
    
    // Also log to Crashlytics for detailed analysis
    if (!kDebugMode) {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace ?? StackTrace.current,
        fatal: fatal,
        information: [
          DiagnosticsProperty('context', context),
          DiagnosticsProperty('user_country', _userCountry),
        ],
      );
    }
  }
  
  // Helper methods
  
  static String _sanitizeEventName(String name) {
    // Firebase Analytics event names must be alphanumeric with underscores
    return name.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .substring(0, name.length > 40 ? 40 : name.length);
  }
  
  static String _sanitizeTraceName(String name) {
    // Performance trace names have similar restrictions
    return name.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .substring(0, name.length > 100 ? 100 : name.length);
  }
  
  static Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return 'unknown';
    }
  }
  
  static Future<String> _getDeviceCategory() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        final totalMemory = androidInfo.systemFeatures.length; // Approximation
        
        // Categorize based on Android SDK and features
        if (sdkInt >= 28 && totalMemory > 50) {
          return 'high_end';
        } else if (sdkInt >= 24) {
          return 'mid_range';
        } else {
          return 'low_end';
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        final model = iosInfo.model.toLowerCase();
        
        if (model.contains('iphone') && 
            (model.contains('12') || model.contains('13') || model.contains('14') || model.contains('15'))) {
          return 'high_end';
        } else if (model.contains('iphone')) {
          return 'mid_range';
        } else {
          return 'tablet';
        }
      }
      
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }
  
  static Future<String> _getDeviceInfo() async {
    if (_deviceInfo != null) return _deviceInfo!;
    
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceInfo = '${androidInfo.brand}_${androidInfo.model}_${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceInfo = '${iosInfo.model}_${iosInfo.systemVersion}';
      } else {
        _deviceInfo = 'unknown_device';
      }
      
      return _deviceInfo!;
    } catch (e) {
      _deviceInfo = 'unknown_device';
      return _deviceInfo!;
    }
  }
  
  static Future<String> _getConnectivityStatus() async {
    try {
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();
      
      switch (result) {
        case ConnectivityResult.wifi:
          return 'wifi';
        case ConnectivityResult.mobile:
          return 'mobile';
        case ConnectivityResult.ethernet:
          return 'ethernet';
        case ConnectivityResult.none:
          return 'offline';
        default:
          return 'unknown';
      }
    } catch (e) {
      return 'unknown';
    }
  }
  
  /// Clean up resources
  static void dispose() {
    _activeTraces.clear();
    _userId = null;
    _userCountry = null;
    _deviceInfo = null;
    _isInitialized = false;
    
    LoggingService.info('AnalyticsService', 'Analytics service disposed');
  }
}
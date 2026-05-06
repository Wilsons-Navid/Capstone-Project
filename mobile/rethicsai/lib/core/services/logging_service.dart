import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class LoggingService {
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize Crashlytics for production error logging
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
      _isInitialized = true;
      
      if (kDebugMode) {
        info('LoggingService', 'Logging service initialized in debug mode');
      }
    } catch (e) {
      // Fallback if Crashlytics fails to initialize
      if (kDebugMode) {
        developer.log('Failed to initialize Crashlytics: $e');
      }
      _isInitialized = true;
    }
  }
  
  static void debug(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, tag, message, error, stackTrace);
  }
  
  static void info(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, tag, message, error, stackTrace);
  }
  
  static void warning(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, tag, message, error, stackTrace);
  }
  
  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, tag, message, error, stackTrace);
  }
  
  static void critical(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.critical, tag, message, error, stackTrace);
  }
  
  static void _log(LogLevel level, String tag, String message, [Object? error, StackTrace? stackTrace]) {
    final logMessage = '[$tag] $message';
    
    // In debug mode, use developer.log for better debugging experience
    if (kDebugMode) {
      switch (level) {
        case LogLevel.debug:
          developer.log(logMessage, name: tag, level: 500);
          break;
        case LogLevel.info:
          developer.log(logMessage, name: tag, level: 800);
          break;
        case LogLevel.warning:
          developer.log(logMessage, name: tag, level: 900, error: error, stackTrace: stackTrace);
          break;
        case LogLevel.error:
          developer.log(logMessage, name: tag, level: 1000, error: error, stackTrace: stackTrace);
          break;
        case LogLevel.critical:
          developer.log(logMessage, name: tag, level: 1200, error: error, stackTrace: stackTrace);
          break;
      }
    }
    
    // In production, only log warnings and above to Crashlytics
    if (!kDebugMode && _isInitialized) {
      switch (level) {
        case LogLevel.warning:
        case LogLevel.error:
        case LogLevel.critical:
          if (error != null) {
            FirebaseCrashlytics.instance.recordError(
              error,
              stackTrace ?? StackTrace.current,
              information: [DiagnosticsProperty('tag', tag), DiagnosticsProperty('message', message)],
              fatal: level == LogLevel.critical,
            );
          } else {
            FirebaseCrashlytics.instance.log('$tag: $message');
          }
          break;
        case LogLevel.debug:
        case LogLevel.info:
          // Only log to Crashlytics for context, not as errors
          FirebaseCrashlytics.instance.log('$tag: $message');
          break;
      }
    }
  }
  
  // Convenience methods for common scenarios
  static void logUserAction(String action, {String? userId, Map<String, dynamic>? metadata}) {
    final message = 'User action: $action${userId != null ? ' (User: $userId)' : ''}';
    info('UserAction', message);
    
    if (!kDebugMode && metadata != null) {
      FirebaseCrashlytics.instance.setCustomKey('last_user_action', action);
      for (final entry in metadata.entries) {
        FirebaseCrashlytics.instance.setCustomKey(entry.key, entry.value.toString());
      }
    }
  }
  
  static void logIncidentCreation(String incidentId, String userId, String incidentType) {
    info('IncidentService', 'Incident created successfully: $incidentId for user: $userId, type: $incidentType');
    
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.setCustomKey('last_incident_type', incidentType);
      FirebaseCrashlytics.instance.setCustomKey('incidents_created_session', 'true');
    }
  }
  
  static void logAuthEvent(String event, {String? userId, String? method}) {
    final message = 'Auth event: $event${method != null ? ' via $method' : ''}${userId != null ? ' (User: $userId)' : ''}';
    info('AuthService', message);
    
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.setCustomKey('last_auth_event', event);
      if (method != null) {
        FirebaseCrashlytics.instance.setCustomKey('auth_method', method);
      }
    }
  }
  
  static void logSecurityEvent(String event, String threatLevel, {String? details}) {
    final message = 'Security event: $event (Threat Level: $threatLevel)${details != null ? ' - $details' : ''}';
    
    switch (threatLevel.toLowerCase()) {
      case 'critical':
      case 'high':
        error('Security', message);
        break;
      case 'medium':
        warning('Security', message);
        break;
      default:
        info('Security', message);
    }
    
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.setCustomKey('last_security_event', event);
      FirebaseCrashlytics.instance.setCustomKey('last_threat_level', threatLevel);
    }
  }
  
  static void setUserContext(String userId, {String? email, String? role, String? country}) {
    if (!kDebugMode && _isInitialized) {
      FirebaseCrashlytics.instance.setUserIdentifier(userId);
      if (email != null) {
        FirebaseCrashlytics.instance.setCustomKey('user_email', email);
      }
      if (role != null) {
        FirebaseCrashlytics.instance.setCustomKey('user_role', role);
      }
      if (country != null) {
        FirebaseCrashlytics.instance.setCustomKey('user_country', country);
      }
    }
  }
  
  static void clearUserContext() {
    if (!kDebugMode && _isInitialized) {
      FirebaseCrashlytics.instance.setUserIdentifier('');
      FirebaseCrashlytics.instance.setCustomKey('user_email', '');
      FirebaseCrashlytics.instance.setCustomKey('user_role', '');
      FirebaseCrashlytics.instance.setCustomKey('user_country', '');
    }
  }
}
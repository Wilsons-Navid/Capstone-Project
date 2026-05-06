import 'dart:developer' as developer;

class Logger {
  static void i(String tag, String message) {
    developer.log('ℹ️ [$tag] $message');
  }
  
  static void w(String tag, String message) {
    developer.log('⚠️ [$tag] $message');
  }
  
  static void e(String tag, String message, [Object? error]) {
    developer.log('❌ [$tag] $message${error != null ? '\nError: $error' : ''}');
  }
  
  static void d(String tag, String message) {
    developer.log('🐛 [$tag] $message');
  }
}
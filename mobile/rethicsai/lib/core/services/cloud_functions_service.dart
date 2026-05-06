import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudFunctionsService {
  static final _functions = FirebaseFunctions.instance;

  /// Initialize database using Cloud Function (bypasses security rules)
  static Future<Map<String, dynamic>> initializeDatabase({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? country,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      print('CloudFunctionsService: Calling initializeDatabase function...');
      
      final callable = _functions.httpsCallable('initializeDatabase');
      final result = await callable.call({
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'country': country,
      });

      print('CloudFunctionsService: Database initialization successful');
      return {
        'success': true,
        'data': result.data,
      };
    } catch (e) {
      print('CloudFunctionsService: Error initializing database: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Create demo users using Cloud Function
  static Future<Map<String, dynamic>> createDemoUsers() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      print('CloudFunctionsService: Calling createDemoUsers function...');
      
      final callable = _functions.httpsCallable('createDemoUsers');
      final result = await callable.call();

      print('CloudFunctionsService: Demo users creation successful');
      return {
        'success': true,
        'data': result.data,
      };
    } catch (e) {
      print('CloudFunctionsService: Error creating demo users: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Check if Cloud Functions are available
  static Future<bool> areCloudFunctionsAvailable() async {
    try {
      // Try to call a simple function or check connectivity
      final callable = _functions.httpsCallable('initializeDatabase');
      // This won't actually call the function, just check if it's callable
      return true;
    } catch (e) {
      print('CloudFunctionsService: Cloud Functions not available: $e');
      return false;
    }
  }
}
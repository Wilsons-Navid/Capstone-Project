import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../firebase_options.dart';
import '../utils/platform_utils.dart';

class FirebaseService {
  static bool _isInitialized = false;
  
  static FirebaseAuth get auth {
    if (!_isInitialized) {
      throw Exception('Firebase not initialized. Call FirebaseService.initialize() first.');
    }
    return FirebaseAuth.instance;
  }
  
  static FirebaseFirestore get firestore {
    if (!_isInitialized) {
      throw Exception('Firebase not initialized. Call FirebaseService.initialize() first.');
    }
    return FirebaseFirestore.instance;
  }
  
  static FirebaseFunctions get functions {
    if (!_isInitialized) {
      throw Exception('Firebase not initialized. Call FirebaseService.initialize() first.');
    }
    return FirebaseFunctions.instance;
  }
  
  static bool get isInitialized => _isInitialized;
  
  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('Firebase app initialized');
      } else {
        print('Firebase app already initialized');
      }
      
      // Configure Firebase services with error handling
      try {
        await _configureFirestore();
        print('Firestore configured');
      } catch (e) {
        print('Firestore configuration warning: $e');
        // Continue without throwing - Firestore might work anyway
      }
      
      try {
        await _configureFunctions();
        print('Functions configured');
      } catch (e) {
        print('Functions configuration warning: $e');
        // Continue without throwing - Functions are optional for basic functionality
      }
      
      _isInitialized = true;
      print('Firebase initialization completed');
    } catch (e) {
      print('Firebase initialization error: $e');
      _isInitialized = false;
      rethrow; // Re-throw to handle properly in calling code
    }
  }
  
  
  static Future<void> _configureFirestore() async {
    try {
      await FirebaseFirestore.instance.enableNetwork();
    } catch (e) {
      print('Firestore configuration error: $e');
    }
  }
  
  static Future<void> _configureFunctions() async {
    try {
      // Skip emulator configuration for now to avoid connection issues
      // if (PlatformUtils.isDebugMode) {
      //   functions.useFunctionsEmulator('localhost', 5001);
      // }
      print('Functions ready (emulator disabled)');
    } catch (e) {
      print('Functions configuration error: $e');
    }
  }
  
  // Authentication helpers
  static Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }
  
  static Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      return await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }
  
  static Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
  }
  
  static User? get currentUser => auth.currentUser;
  
  static Stream<User?> get authStateChanges => auth.authStateChanges();
}
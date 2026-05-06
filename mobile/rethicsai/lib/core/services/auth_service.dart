import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import '../../shared/models/user_model.dart';
import '../constants/app_constants.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final GoogleSignIn? _googleSignIn;
  
  AuthService() {
    try {
      // Initialize Google Sign-In with error handling for web
      if (kIsWeb) {
        // For web, Google Sign-In requires specific configuration
        // Skip initialization if not properly configured
        _googleSignIn = null;
        print('Google Sign-In disabled for web (requires client ID configuration)');
      } else {
        _googleSignIn = GoogleSignIn();
      }
    } catch (e) {
      print('Google Sign-In initialization error: $e');
      _googleSignIn = null;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email/Password Sign In
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Email/Password Sign Up
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? country,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName('$firstName $lastName');
        
        // Send email verification
        if (!credential.user!.emailVerified) {
          await credential.user!.sendEmailVerification();
        }

        // Create user document in Firestore with role support
        await UserService.createUserDocument(
          userId: credential.user!.uid,
          email: credential.user!.email!,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          country: country,
          role: 'user', // Default role for new users
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Check if Google Sign-In is available
      if (_googleSignIn == null && !kIsWeb) {
        throw Exception('Google Sign-In not available on this platform');
      }
      
      // Check if running on web
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile/Desktop flow
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) return null; // User canceled

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        
        // Create user document if it doesn't exist
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          await _createUserDocumentFromSocialProvider(userCredential.user!, 'google');
        }

        return userCredential;
      }
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  // Apple Sign In
  Future<UserCredential?> signInWithApple() async {
    try {
      // Check if Apple Sign In is available
      if (!Platform.isIOS && !Platform.isMacOS && !kIsWeb) {
        throw Exception('Apple Sign In is not available on this platform');
      }

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      
      // Create user document if it doesn't exist
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await _createUserDocumentFromSocialProvider(userCredential.user!, 'apple');
      }

      return userCredential;
    } catch (e) {
      throw Exception('Apple sign in failed: $e');
    }
  }

  // Phone Number Sign In
  Future<void> signInWithPhoneNumber({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_handleFirebaseAuthException(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      onError('Phone verification failed: $e');
    }
  }

  // Verify Phone Code
  Future<UserCredential?> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Create user document if it doesn't exist
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await _createUserDocumentFromSocialProvider(userCredential.user!, 'phone');
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // Password Reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // Email Verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw Exception('Failed to send verification email: $e');
    }
  }

  // Update Password
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // Update Profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Re-authenticate User
  Future<void> reauthenticate(String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await _firestore.collection(AppConstants.usersCollection).doc(user.uid).delete();
        
        // Delete user account
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      final futures = <Future>[_auth.signOut()];
      if (_googleSignIn != null) {
        futures.add(_googleSignIn!.signOut());
      }
      await Future.wait(futures);
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Get User Document
  Future<UserModel?> getUserDocument(String uid) async {
    try {
      final doc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(
    User user, {
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? country,
  }) async {
    final userDoc = _firestore.collection(AppConstants.usersCollection).doc(user.uid);
    
    final userData = UserModel(
      id: user.uid,
      email: user.email ?? '',
      firstName: firstName,
      lastName: lastName,
      displayName: '$firstName $lastName',
      phoneNumber: phoneNumber,
      photoURL: user.photoURL,
      country: country ?? 'Nigeria',
      language: 'en',
      isEmailVerified: user.emailVerified,
      notificationPreferences: const NotificationPreferences(
        emailNotifications: true,
        pushNotifications: true,
        smsNotifications: false,
        marketingEmails: false,
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await userDoc.set(userData.toJson());
  }

  // Create user document from social provider
  Future<void> _createUserDocumentFromSocialProvider(User user, String provider) async {
    // Check if document already exists
    final exists = await UserService.userExists(user.uid);
    if (exists) return;

    final nameParts = (user.displayName ?? '').split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : 'User';
    final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';

    await UserService.createUserDocument(
      userId: user.uid,
      email: user.email ?? '',
      firstName: firstName,
      lastName: lastName,
      phoneNumber: user.phoneNumber,
      country: 'Nigeria', // Default, can be updated later
      role: 'user', // Default role
    );
  }

  // Handle Firebase Auth exceptions
  String _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      case 'invalid-verification-id':
        return 'Invalid verification ID.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }
}
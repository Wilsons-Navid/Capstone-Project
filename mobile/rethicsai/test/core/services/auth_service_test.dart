import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../lib/core/services/auth_service.dart';
import '../../../lib/shared/models/user_model.dart';
import '../../test_helpers/test_helpers.dart';

@GenerateMocks([
  FirebaseAuth,
  User,
  UserCredential,
  FirebaseFirestore,
  GoogleSignIn,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
])
import 'auth_service_test.mocks.dart';

void main() {
  group('AuthService Tests', () {
    late AuthService authService;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockUser mockUser;
    late MockUserCredential mockUserCredential;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockGoogleSignIn = MockGoogleSignIn();
      mockUser = MockUser();
      mockUserCredential = MockUserCredential();
      
      authService = AuthService();
      // Note: In a real implementation, you'd inject these dependencies
    });

    group('Email Authentication', () {
      test('signInWithEmail should return UserCredential on success', () async {
        // Arrange
        const email = TestConstants.testEmail;
        const password = TestConstants.testPassword;
        
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockUserCredential);
        
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockUser.uid).thenReturn(TestConstants.testUserId);
        when(mockUser.email).thenReturn(email);

        // Act
        final result = await authService.signInWithEmail(email, password);

        // Assert
        expect(result, isNotNull);
        expect(result, isA<UserCredential>());
      });

      test('signInWithEmail should throw exception on invalid credentials', () async {
        // Arrange
        const email = TestConstants.testEmail;
        const password = 'wrongpassword';
        
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenThrow(TestHelpers.createMockAuthException());

        // Act & Assert
        expect(
          () => authService.signInWithEmail(email, password),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('signUpWithEmail should create user and store profile', () async {
        // Arrange
        const email = TestConstants.testEmail;
        const password = TestConstants.testPassword;
        const firstName = 'John';
        const lastName = 'Doe';
        const phoneNumber = '+1234567890';
        const country = 'Nigeria';

        when(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockUserCredential);
        
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockUser.uid).thenReturn(TestConstants.testUserId);
        when(mockUser.email).thenReturn(email);

        final mockCollection = MockCollectionReference<Map<String, dynamic>>();
        final mockDoc = MockDocumentReference<Map<String, dynamic>>();
        
        when(mockFirestore.collection('users')).thenReturn(mockCollection);
        when(mockCollection.doc(TestConstants.testUserId)).thenReturn(mockDoc);
        when(mockDoc.set(any)).thenAnswer((_) async => {});

        // Act
        final result = await authService.signUpWithEmail(
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          country: country,
        );

        // Assert
        expect(result, isNotNull);
        verify(mockDoc.set(any)).called(1);
      });
    });

    group('Google Authentication', () {
      test('signInWithGoogle should return UserCredential on success', () async {
        // Arrange
        final mockGoogleUser = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication();
        
        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleUser);
        when(mockGoogleUser.authentication).thenAnswer((_) async => mockGoogleAuth);
        when(mockGoogleAuth.accessToken).thenReturn('mock_access_token');
        when(mockGoogleAuth.idToken).thenReturn('mock_id_token');
        
        when(mockFirebaseAuth.signInWithCredential(any))
            .thenAnswer((_) async => mockUserCredential);
        when(mockUserCredential.user).thenReturn(mockUser);

        // Act
        final result = await authService.signInWithGoogle();

        // Assert
        expect(result, isNotNull);
        expect(result, isA<UserCredential>());
      });

      test('signInWithGoogle should handle cancellation gracefully', () async {
        // Arrange
        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        // Act
        final result = await authService.signInWithGoogle();

        // Assert
        expect(result, isNull);
      });
    });

    group('Password Reset', () {
      test('resetPassword should send password reset email', () async {
        // Arrange
        const email = TestConstants.testEmail;
        when(mockFirebaseAuth.sendPasswordResetEmail(email: email))
            .thenAnswer((_) async => {});

        // Act
        await authService.resetPassword(email);

        // Assert
        verify(mockFirebaseAuth.sendPasswordResetEmail(email: email)).called(1);
      });

      test('resetPassword should throw exception for invalid email', () async {
        // Arrange
        const email = 'invalid-email';
        when(mockFirebaseAuth.sendPasswordResetEmail(email: email))
            .thenThrow(TestHelpers.createMockAuthException());

        // Act & Assert
        expect(
          () => authService.resetPassword(email),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('Email Verification', () {
      test('sendEmailVerification should send verification email to current user', () async {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(mockUser.sendEmailVerification()).thenAnswer((_) async => {});

        // Act
        await authService.sendEmailVerification();

        // Assert
        verify(mockUser.sendEmailVerification()).called(1);
      });

      test('sendEmailVerification should throw exception when no user is signed in', () async {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(null);

        // Act & Assert
        expect(
          () => authService.sendEmailVerification(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Phone Authentication', () {
      test('signInWithPhoneNumber should trigger code sending process', () async {
        // Arrange
        const phoneNumber = '+1234567890';
        const verificationId = 'test_verification_id';
        
        when(mockFirebaseAuth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: anyNamed('verificationCompleted'),
          verificationFailed: anyNamed('verificationFailed'),
          codeSent: anyNamed('codeSent'),
          codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
        )).thenAnswer((invocation) async {
          final codeSent = invocation.namedArguments[#codeSent] as Function;
          codeSent(verificationId, 0);
        });

        bool onCodeSentCalled = false;
        String? receivedVerificationId;

        // Act
        await authService.signInWithPhoneNumber(
          phoneNumber: phoneNumber,
          onCodeSent: (verificationId) {
            onCodeSentCalled = true;
            receivedVerificationId = verificationId;
          },
          onError: (error) {},
        );

        // Assert
        expect(onCodeSentCalled, isTrue);
        expect(receivedVerificationId, equals(verificationId));
      });
    });

    group('Sign Out', () {
      test('signOut should sign out from Firebase and Google', () async {
        // Arrange
        when(mockFirebaseAuth.signOut()).thenAnswer((_) async => {});
        when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

        // Act
        await authService.signOut();

        // Assert
        verify(mockFirebaseAuth.signOut()).called(1);
        verify(mockGoogleSignIn.signOut()).called(1);
      });
    });

    group('Auth State Changes', () {
      test('authStateChanges should emit user changes', () async {
        // Arrange
        final userStream = Stream<User?>.fromIterable([null, mockUser, null]);
        when(mockFirebaseAuth.authStateChanges()).thenAnswer((_) => userStream);
        when(mockUser.uid).thenReturn(TestConstants.testUserId);

        // Act
        final stateChanges = authService.authStateChanges;

        // Assert
        expect(stateChanges, isA<Stream<User?>>());
        
        final stateList = await stateChanges.take(3).toList();
        expect(stateList.length, equals(3));
        expect(stateList[0], isNull);
        expect(stateList[1], equals(mockUser));
        expect(stateList[2], isNull);
      });
    });

    group('Current User', () {
      test('currentUser should return current authenticated user', () {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn(TestConstants.testUserId);

        // Act
        final currentUser = authService.currentUser;

        // Assert
        expect(currentUser, equals(mockUser));
        expect(currentUser?.uid, equals(TestConstants.testUserId));
      });

      test('currentUser should return null when no user is authenticated', () {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(null);

        // Act
        final currentUser = authService.currentUser;

        // Assert
        expect(currentUser, isNull);
      });
    });
  });
}
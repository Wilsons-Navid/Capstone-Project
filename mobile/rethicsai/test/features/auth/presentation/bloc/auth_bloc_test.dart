import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../lib/features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../lib/features/auth/presentation/bloc/auth_event.dart';
import '../../../../lib/features/auth/presentation/bloc/auth_state.dart';
import '../../../../lib/core/services/auth_service.dart';
import '../../../../lib/core/services/activity_service.dart';
import '../../../test_helpers/test_helpers.dart';

@GenerateMocks([AuthService, ActivityService, User, UserCredential])
import 'auth_bloc_test.mocks.dart';

void main() {
  group('AuthBloc Tests', () {
    late AuthBloc authBloc;
    late MockAuthService mockAuthService;
    late MockActivityService mockActivityService;
    late MockUser mockUser;
    late MockUserCredential mockUserCredential;

    setUp(() {
      mockAuthService = MockAuthService();
      mockActivityService = MockActivityService();
      mockUser = MockUser();
      mockUserCredential = MockUserCredential();
      
      // Setup default auth service behavior
      when(mockAuthService.currentUser).thenReturn(null);
      when(mockAuthService.authStateChanges).thenAnswer((_) => Stream.value(null));
      
      authBloc = AuthBloc();
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state should be AuthInitial', () {
      expect(authBloc.state, equals(AuthInitial()));
    });

    group('AuthStarted Event', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthSuccess] when user is already authenticated',
        build: () {
          when(mockAuthService.currentUser).thenReturn(mockUser);
          when(mockUser.uid).thenReturn(TestConstants.testUserId);
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthStarted()),
        expect: () => [AuthSuccess(mockUser)],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthInitial] when no user is authenticated',
        build: () {
          when(mockAuthService.currentUser).thenReturn(null);
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthStarted()),
        expect: () => [AuthInitial()],
      );
    });

    group('AuthLoginRequested Event', () {
      const email = TestConstants.testEmail;
      const password = TestConstants.testPassword;

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthSuccess] when login succeeds',
        build: () {
          when(mockAuthService.signInWithEmail(email, password))
              .thenAnswer((_) async => mockUserCredential);
          when(mockUserCredential.user).thenReturn(mockUser);
          when(mockUser.uid).thenReturn(TestConstants.testUserId);
          when(ActivityService.recordLoginActivity(
            success: true,
            deviceInfo: 'Mobile App',
          )).thenAnswer((_) async => {});
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthLoginRequested(email, password)),
        expect: () => [AuthLoading(), AuthSuccess(mockUser)],
        verify: (_) {
          verify(mockAuthService.signInWithEmail(email, password)).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthFailure] when login fails with wrong credentials',
        build: () {
          when(mockAuthService.signInWithEmail(email, password))
              .thenThrow(TestHelpers.createMockAuthException());
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthLoginRequested(email, password)),
        expect: () => [
          AuthLoading(),
          const AuthFailure('FirebaseAuthException: [user-not-found] No user found for that email.'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthFailure] when signInWithEmail returns null',
        build: () {
          when(mockAuthService.signInWithEmail(email, password))
              .thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthLoginRequested(email, password)),
        expect: () => [
          AuthLoading(),
          const AuthFailure('Sign in failed. Please check your credentials.'),
        ],
      );
    });

    group('AuthSignUpRequested Event', () {
      const email = TestConstants.testEmail;
      const password = TestConstants.testPassword;
      const firstName = 'John';
      const lastName = 'Doe';
      const phone = '+1234567890';
      const country = 'Nigeria';

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthSuccess] when signup succeeds',
        build: () {
          when(mockAuthService.signUpWithEmail(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phone,
            country: country,
          )).thenAnswer((_) async => mockUserCredential);
          when(mockUserCredential.user).thenReturn(mockUser);
          when(mockUser.uid).thenReturn(TestConstants.testUserId);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSignUpRequested(
          email, password, firstName, lastName, phone, country,
        )),
        expect: () => [AuthLoading(), AuthSuccess(mockUser)],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthFailure] when signup fails',
        build: () {
          when(mockAuthService.signUpWithEmail(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phone,
            country: country,
          )).thenThrow(TestHelpers.createMockAuthException());
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSignUpRequested(
          email, password, firstName, lastName, phone, country,
        )),
        expect: () => [
          AuthLoading(),
          const AuthFailure('FirebaseAuthException: [user-not-found] No user found for that email.'),
        ],
      );
    });

    group('AuthGoogleSignInRequested Event', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthSuccess] when Google sign-in succeeds',
        build: () {
          when(mockAuthService.signInWithGoogle())
              .thenAnswer((_) async => mockUserCredential);
          when(mockUserCredential.user).thenReturn(mockUser);
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthGoogleSignInRequested()),
        expect: () => [AuthLoading(), AuthSuccess(mockUser)],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthFailure] when Google sign-in is cancelled',
        build: () {
          when(mockAuthService.signInWithGoogle()).thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthGoogleSignInRequested()),
        expect: () => [
          AuthLoading(),
          const AuthFailure('Google sign in was cancelled.'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthFailure] when Google sign-in throws error',
        build: () {
          when(mockAuthService.signInWithGoogle())
              .thenThrow(Exception('Google sign-in failed'));
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthGoogleSignInRequested()),
        expect: () => [
          AuthLoading(),
          const AuthFailure('Exception: Google sign-in failed'),
        ],
      );
    });

    group('AuthAppleSignInRequested Event', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthSuccess] when Apple sign-in succeeds',
        build: () {
          when(mockAuthService.signInWithApple())
              .thenAnswer((_) async => mockUserCredential);
          when(mockUserCredential.user).thenReturn(mockUser);
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthAppleSignInRequested()),
        expect: () => [AuthLoading(), AuthSuccess(mockUser)],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthFailure] when Apple sign-in is cancelled',
        build: () {
          when(mockAuthService.signInWithApple()).thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthAppleSignInRequested()),
        expect: () => [
          AuthLoading(),
          const AuthFailure('Apple sign in was cancelled.'),
        ],
      );
    });

    group('AuthPhoneSignInRequested Event', () {
      const phoneNumber = '+1234567890';
      const verificationId = 'test_verification_id';

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthPhoneCodeSent] when phone verification code is sent',
        build: () {
          when(mockAuthService.signInWithPhoneNumber(
            phoneNumber: phoneNumber,
            onCodeSent: anyNamed('onCodeSent'),
            onError: anyNamed('onError'),
          )).thenAnswer((invocation) async {
            final onCodeSent = invocation.namedArguments[#onCodeSent] as Function;
            onCodeSent(verificationId);
          });
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthPhoneSignInRequested(phoneNumber)),
        expect: () => [AuthLoading(), AuthPhoneCodeSent(verificationId)],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthFailure] when phone verification fails',
        build: () {
          when(mockAuthService.signInWithPhoneNumber(
            phoneNumber: phoneNumber,
            onCodeSent: anyNamed('onCodeSent'),
            onError: anyNamed('onError'),
          )).thenAnswer((invocation) async {
            final onError = invocation.namedArguments[#onError] as Function;
            onError('Phone verification failed');
          });
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthPhoneSignInRequested(phoneNumber)),
        expect: () => [AuthLoading(), const AuthFailure('Phone verification failed')],
      );
    });

    group('AuthPasswordResetRequested Event', () {
      const email = TestConstants.testEmail;

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthPasswordResetSent] when password reset succeeds',
        build: () {
          when(mockAuthService.resetPassword(email)).thenAnswer((_) async => {});
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthPasswordResetRequested(email)),
        expect: () => [AuthLoading(), const AuthPasswordResetSent()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthFailure] when password reset fails',
        build: () {
          when(mockAuthService.resetPassword(email))
              .thenThrow(TestHelpers.createMockAuthException());
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthPasswordResetRequested(email)),
        expect: () => [
          AuthLoading(),
          const AuthFailure('FirebaseAuthException: [user-not-found] No user found for that email.'),
        ],
      );
    });

    group('AuthEmailVerificationRequested Event', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthEmailVerificationSent] when email verification succeeds',
        build: () {
          when(mockAuthService.sendEmailVerification()).thenAnswer((_) async => {});
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthEmailVerificationRequested()),
        expect: () => [const AuthEmailVerificationSent()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthFailure] when email verification fails',
        build: () {
          when(mockAuthService.sendEmailVerification())
              .thenThrow(Exception('No user signed in'));
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthEmailVerificationRequested()),
        expect: () => [const AuthFailure('Exception: No user signed in')],
      );
    });

    group('AuthSignOutRequested Event', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthInitial] when sign out succeeds',
        build: () {
          when(mockAuthService.signOut()).thenAnswer((_) async => {});
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthSignOutRequested()),
        expect: () => [AuthLoading(), AuthInitial()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthFailure] when sign out fails',
        build: () {
          when(mockAuthService.signOut()).thenThrow(Exception('Sign out failed'));
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthSignOutRequested()),
        expect: () => [AuthLoading(), const AuthFailure('Exception: Sign out failed')],
      );
    });

    group('Auth State Changes Listener', () {
      test('should listen to auth state changes and add AuthStarted event', () async {
        // Arrange
        final userStream = Stream<User?>.fromIterable([mockUser]);
        when(mockAuthService.authStateChanges).thenAnswer((_) => userStream);
        when(mockAuthService.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn(TestConstants.testUserId);

        // Act - Create new bloc which will trigger the listener
        final testBloc = AuthBloc();
        
        // Wait for the stream to emit
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Assert
        expect(testBloc.state, isA<AuthSuccess>());
        
        // Cleanup
        testBloc.close();
      });
    });
  });
}
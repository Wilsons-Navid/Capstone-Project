import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/activity_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService = AuthService();
  
  AuthBloc() : super(AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthAppleSignInRequested>(_onAppleSignInRequested);
    on<AuthPhoneSignInRequested>(_onPhoneSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthEmailVerificationRequested>(_onEmailVerificationRequested);
    
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        add(AuthStarted());
      }
    });
  }
  
  Future<void> _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final user = _authService.currentUser;
    if (user != null) {
      emit(AuthSuccess(user));
    } else {
      emit(AuthInitial());
    }
  }
  
  Future<void> _onLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      final userCredential = await _authService.signInWithEmail(
        event.email,
        event.password,
      );
      
      if (userCredential?.user != null) {
        // Record successful login activity
        await ActivityService.recordLoginActivity(
          success: true,
          deviceInfo: 'Mobile App',
        );
        
        emit(AuthSuccess(userCredential!.user!));
      } else {
        emit(const AuthFailure('Sign in failed. Please check your credentials.'));
      }
    } catch (e) {
      emit(AuthFailure('$e'));
    }
  }

  Future<void> _onGoogleSignInRequested(AuthGoogleSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential?.user != null) {
        emit(AuthSuccess(userCredential!.user!));
      } else {
        emit(const AuthFailure('Google sign in was cancelled.'));
      }
    } catch (e) {
      emit(AuthFailure('$e'));
    }
  }

  Future<void> _onAppleSignInRequested(AuthAppleSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      final userCredential = await _authService.signInWithApple();
      
      if (userCredential?.user != null) {
        emit(AuthSuccess(userCredential!.user!));
      } else {
        emit(const AuthFailure('Apple sign in was cancelled.'));
      }
    } catch (e) {
      emit(AuthFailure('$e'));
    }
  }

  Future<void> _onPhoneSignInRequested(AuthPhoneSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      await _authService.signInWithPhoneNumber(
        phoneNumber: event.phoneNumber,
        onCodeSent: (verificationId) {
          emit(AuthPhoneCodeSent(verificationId));
        },
        onError: (error) {
          emit(AuthFailure(error));
        },
      );
    } catch (e) {
      emit(AuthFailure('$e'));
    }
  }

  Future<void> _onPasswordResetRequested(AuthPasswordResetRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      await _authService.resetPassword(event.email);
      emit(const AuthPasswordResetSent());
    } catch (e) {
      emit(AuthFailure('$e'));
    }
  }

  Future<void> _onEmailVerificationRequested(AuthEmailVerificationRequested event, Emitter<AuthState> emit) async {
    try {
      await _authService.sendEmailVerification();
      emit(const AuthEmailVerificationSent());
    } catch (e) {
      emit(AuthFailure('$e'));
    }
  }
  
  Future<void> _onSignUpRequested(AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      final userCredential = await _authService.signUpWithEmail(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
        phoneNumber: event.phone,
        country: event.country,
      );
      
      if (userCredential?.user != null) {
        emit(AuthSuccess(userCredential!.user!));
      } else {
        emit(const AuthFailure('Sign up failed. Please try again.'));
      }
    } catch (e) {
      emit(AuthFailure('$e'));
    }
  }
  
  Future<void> _onSignOutRequested(AuthSignOutRequested event, Emitter<AuthState> emit) async {
    print('🔓 Sign out requested');
    emit(AuthLoading());
    
    try {
      print('🔓 Calling auth service sign out');
      await _authService.signOut();
      print('🔓 Sign out successful, emitting AuthInitial');
      emit(AuthInitial());
    } catch (e) {
      print('❌ Sign out error: $e');
      emit(AuthFailure('$e'));
    }
  }
}
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final User user;
  
  const AuthSuccess(this.user);
}

class AuthFailure extends AuthState {
  final String message;
  
  const AuthFailure(this.message);
}

class AuthPhoneCodeSent extends AuthState {
  final String verificationId;
  
  const AuthPhoneCodeSent(this.verificationId);
}

class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}

class AuthEmailVerificationSent extends AuthState {
  const AuthEmailVerificationSent();
}
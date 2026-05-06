abstract class AuthEvent {}

class AuthStarted extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  
  AuthLoginRequested({
    required this.email,
    required this.password,
  });
}

class AuthSignUpRequested extends AuthEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String phone;
  final String country;
  
  AuthSignUpRequested({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phone,
    required this.country,
  });
}

class AuthGoogleSignInRequested extends AuthEvent {}

class AuthAppleSignInRequested extends AuthEvent {}

class AuthPhoneSignInRequested extends AuthEvent {
  final String phoneNumber;
  
  AuthPhoneSignInRequested({required this.phoneNumber});
}

class AuthPhoneVerificationRequested extends AuthEvent {
  final String verificationId;
  final String smsCode;
  
  AuthPhoneVerificationRequested({
    required this.verificationId,
    required this.smsCode,
  });
}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;
  
  AuthPasswordResetRequested({required this.email});
}

class AuthEmailVerificationRequested extends AuthEvent {}

class AuthSignOutRequested extends AuthEvent {}
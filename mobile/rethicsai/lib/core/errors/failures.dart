import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final dynamic details;

  const Failure({
    required this.message,
    this.code,
    this.details,
  });

  @override
  List<Object?> get props => [message, code, details];
}

// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

// Database-related failures
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

// Authentication-related failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

// Authorization-related failures
class AuthorizationFailure extends Failure {
  const AuthorizationFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

// Validation-related failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

// Security-related failures
class SecurityFailure extends Failure {
  const SecurityFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

// Storage-related failures (Firebase Storage, file uploads, etc.)
class StorageFailure extends Failure {
  const StorageFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

// AI Service failures (Wilson AI, threat scanning)
class AIServiceFailure extends Failure {
  const AIServiceFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

// Connectivity failures (specific to African markets with poor connectivity)
class ConnectivityFailure extends Failure {
  const ConnectivityFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

// Parsing failures (JSON, data conversion, etc.)
class ParsingFailure extends Failure {
  const ParsingFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}
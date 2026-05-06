import 'package:dio/dio.dart';

// Simplified DioClient without retrofit for now
class DioClient {
  final Dio _dio;

  DioClient(this._dio);

  Dio get dio => _dio;

  // AI Assistant endpoints
  Future<Map<String, dynamic>> sendAIMessage(Map<String, dynamic> message) async {
    final response = await _dio.post('/ai/chat', data: message);
    return response.data;
  }

  Future<Map<String, dynamic>> analyzeThreat(Map<String, dynamic> content) async {
    final response = await _dio.post('/ai/analyze-threat', data: content);
    return response.data;
  }

  // Threat scanning endpoints
  Future<Map<String, dynamic>> scanUrl(Map<String, String> urlData) async {
    final response = await _dio.post('/scanner/url', data: urlData);
    return response.data;
  }

  Future<Map<String, dynamic>> scanEmail(Map<String, dynamic> emailData) async {
    final response = await _dio.post('/scanner/email', data: emailData);
    return response.data;
  }

  Future<Map<String, dynamic>> scanPhoneNumber(Map<String, String> phoneData) async {
    final response = await _dio.post('/scanner/phone', data: phoneData);
    return response.data;
  }

  // External API integrations
  Future<List<Map<String, dynamic>>> getEmergencyContacts(String countryCode) async {
    final response = await _dio.get('/emergency-contacts/$countryCode');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getEducationContent(String category) async {
    final response = await _dio.get('/education-content/$category');
    return List<Map<String, dynamic>>.from(response.data);
  }

  // Notification endpoints
  Future<Map<String, dynamic>> sendNotification(Map<String, dynamic> notificationData) async {
    final response = await _dio.post('/notifications/send', data: notificationData);
    return response.data;
  }

  // Analytics endpoints
  Future<void> logAnalyticsEvent(Map<String, dynamic> eventData) async {
    await _dio.post('/analytics/event', data: eventData);
  }
}

// Network error handling
class NetworkError implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const NetworkError({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'NetworkError: $message';
}

// Network interceptor for error handling and authentication
class NetworkInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add authentication token if available
    // final token = await SecureStorage.getToken();
    // if (token != null) {
    //   options.headers['Authorization'] = 'Bearer $token';
    // }

    super.onRequest(options, handler);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    final networkError = _handleError(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: networkError,
        type: err.type,
        response: err.response,
      ),
    );
  }

  NetworkError _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkError(
          message: 'Connection timeout. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        return NetworkError(
          message: _getErrorMessage(error.response?.statusCode),
          statusCode: error.response?.statusCode,
          originalError: error,
        );
      case DioExceptionType.cancel:
        return const NetworkError(message: 'Request was cancelled');
      case DioExceptionType.unknown:
        return NetworkError(
          message: 'An unexpected error occurred',
          originalError: error,
        );
      default:
        return NetworkError(
          message: 'Network error occurred',
          originalError: error,
        );
    }
  }

  String _getErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access forbidden. You do not have permission.';
      case 404:
        return 'Resource not found.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Internal server error. Please try again later.';
      case 502:
        return 'Bad gateway. Service temporarily unavailable.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
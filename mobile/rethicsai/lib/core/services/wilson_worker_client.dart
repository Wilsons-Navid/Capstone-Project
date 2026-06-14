import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/wilson_worker.dart';

/// Thin HTTP client for the Wilson AI Cloudflare Worker.
///
/// Attaches the signed-in user's Firebase ID token as a Bearer credential so
/// the Worker can authenticate the caller before reaching Claude.
class WilsonWorkerClient {
  WilsonWorkerClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: WilsonWorkerConfig.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 60),
              contentType: 'application/json',
            ));

  final Dio _dio;

  Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic> body = const {},
  ]) async {
    if (!WilsonWorkerConfig.isConfigured) {
      throw const WilsonWorkerException(
        'Wilson Worker URL is not configured. Set WilsonWorkerConfig.baseUrl.',
      );
    }

    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw const WilsonWorkerException('You must be signed in to use Wilson AI.');
    }

    try {
      final response = await _dio.post(
        path,
        data: body,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      throw const WilsonWorkerException('Unexpected response from Wilson AI.');
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response?.data as Map)['error'] ?? e.message
          : e.message;
      throw WilsonWorkerException('Wilson AI request failed: $detail');
    }
  }
}

class WilsonWorkerException implements Exception {
  final String message;
  const WilsonWorkerException(this.message);

  @override
  String toString() => 'WilsonWorkerException: $message';
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiConfig {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Secure API key management
  static Future<String> getVirusTotalApiKey() async {
    try {
      // Try environment variable first (for server deployments)
      final envKey = Platform.environment['VIRUSTOTAL_API_KEY'];
      if (envKey != null && envKey.isNotEmpty) {
        return envKey;
      }

      // Try secure storage (for mobile apps)
      final storedKey = await _secureStorage.read(key: 'virustotal_api_key');
      if (storedKey != null && storedKey.isNotEmpty) {
        return storedKey;
      }

      // Fallback to build-time configuration (less secure but functional)
      return _getBuildTimeApiKey();
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving VirusTotal API key: $e');
      }
      return '';
    }
  }

  static Future<void> setVirusTotalApiKey(String apiKey) async {
    try {
      await _secureStorage.write(key: 'virustotal_api_key', value: apiKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error storing VirusTotal API key: $e');
      }
    }
  }

  // Build-time configuration - less secure but prevents hardcoding
  static String _getBuildTimeApiKey() {
    // This should be injected during build process
    // For now, return empty to prevent hardcoded keys
    return '';
  }

  // ---- Scam-classifier model API (the project's v3 four-class model) ----
  // Backs the manual scan. Default points at the deployed Hugging Face Space
  // (cmu_v3_serve: TF-IDF + LogReg on the honeynet-enriched v3 corpus, the best
  // four-class model; pure scikit-learn so there is no cold-start model download).
  // Override at build time with:
  //   flutter run --dart-define=SCAM_MODEL_API=https://<space>.hf.space
  static const String _scamModelBuildTimeUrl = String.fromEnvironment(
    'SCAM_MODEL_API',
    defaultValue: 'https://wadotuh-scam-classifier-api-v3.hf.space',
  );

  // ---- Binary inbox detector API (scam-or-not) ----
  // Backs the SMS feature. A fast first-pass yes/no model trained only on the
  // CMU-Africa Upanzi honeynet capture (cmu_inbox_serve). Override at build time
  // with: flutter run --dart-define=SCAM_BINARY_API=https://<space>.hf.space
  static const String _binaryModelBuildTimeUrl = String.fromEnvironment(
    'SCAM_BINARY_API',
    defaultValue: 'https://wadotuh-cmu-scam-inbox-guard.hf.space',
  );

  /// Base URL of the hosted scam-classifier API (e.g. a Hugging Face Space or
  /// Cloud Run service). Empty string => model disabled and the threat scanner
  /// falls back to its heuristic/DB checks.
  static Future<String> getScamModelBaseUrl() async {
    try {
      final envUrl = Platform.environment['SCAM_MODEL_API'];
      if (envUrl != null && envUrl.isNotEmpty) {
        return envUrl;
      }
      final storedUrl = await _secureStorage.read(key: 'scam_model_base_url');
      if (storedUrl != null && storedUrl.isNotEmpty) {
        return storedUrl;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving scam model URL: $e');
      }
    }
    return _scamModelBuildTimeUrl;
  }

  static Future<void> setScamModelBaseUrl(String url) async {
    try {
      await _secureStorage.write(key: 'scam_model_base_url', value: url);
    } catch (e) {
      if (kDebugMode) {
        print('Error storing scam model URL: $e');
      }
    }
  }

  /// Base URL of the hosted binary inbox detector (the SMS feature's model).
  /// Same resolution order as [getScamModelBaseUrl]: env var, then secure
  /// storage, then the build-time default. Empty string => the SMS scanner
  /// falls back to its heuristic checks.
  static Future<String> getBinaryModelBaseUrl() async {
    try {
      final envUrl = Platform.environment['SCAM_BINARY_API'];
      if (envUrl != null && envUrl.isNotEmpty) {
        return envUrl;
      }
      final storedUrl = await _secureStorage.read(key: 'binary_model_base_url');
      if (storedUrl != null && storedUrl.isNotEmpty) {
        return storedUrl;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving binary model URL: $e');
      }
    }
    return _binaryModelBuildTimeUrl;
  }

  static Future<void> setBinaryModelBaseUrl(String url) async {
    try {
      await _secureStorage.write(key: 'binary_model_base_url', value: url);
    } catch (e) {
      if (kDebugMode) {
        print('Error storing binary model URL: $e');
      }
    }
  }

  // Configuration validation
  static Future<bool> validateApiConfiguration() async {
    final apiKey = await getVirusTotalApiKey();
    return apiKey.isNotEmpty && apiKey.length > 32; // VirusTotal keys are longer
  }

  // Rate limiting configuration
  static const Map<String, int> rateLimits = {
    'virustotal_requests_per_minute': 4, // Free tier limit
    'virustotal_requests_per_day': 1000,
    'max_concurrent_requests': 2,
  };

  // Security headers for API requests
  static Map<String, String> getSecurityHeaders() {
    return {
      'User-Agent': 'Rethicsec-Security-Scanner/1.0',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
    };
  }

  // API endpoints with validation
  static const Map<String, String> endpoints = {
    'virustotal_base': 'https://www.virustotal.com/api/v3',
    'virustotal_urls': '/urls',
    'virustotal_files': '/files',
    'virustotal_url_report': '/urls/{id}',
    'virustotal_file_report': '/files/{id}',
  };

  static String getEndpoint(String key, {Map<String, String>? pathParams}) {
    final baseUrl = endpoints['virustotal_base'] ?? '';
    final endpoint = endpoints[key] ?? '';
    
    if (pathParams != null) {
      String finalEndpoint = endpoint;
      pathParams.forEach((key, value) {
        finalEndpoint = finalEndpoint.replaceAll('{$key}', value);
      });
      return baseUrl + finalEndpoint;
    }
    
    return baseUrl + endpoint;
  }
}

class SecurityException implements Exception {
  final String message;
  final String? code;
  
  const SecurityException(this.message, [this.code]);
  
  @override
  String toString() => 'SecurityException: $message${code != null ? ' (Code: $code)' : ''}';
}

class ApiRateLimiter {
  static final Map<String, List<DateTime>> _requests = {};
  
  static bool canMakeRequest(String apiName) {
    final now = DateTime.now();
    final requests = _requests[apiName] ?? [];
    
    // Clean old requests (older than 1 minute)
    requests.removeWhere((timestamp) => 
        now.difference(timestamp).inMinutes >= 1);
    
    final limit = ApiConfig.rateLimits['${apiName}_requests_per_minute'] ?? 10;
    return requests.length < limit;
  }
  
  static void recordRequest(String apiName) {
    final requests = _requests[apiName] ?? [];
    requests.add(DateTime.now());
    _requests[apiName] = requests;
  }
}
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';

/// One prediction from the hosted scam-classifier API
/// (v2: TF-IDF + Logistic Regression, the best model on the expanded
/// English / Portuguese / Swahili corpus, test macro-F1 0.946).
class ScamModelResult {
  /// advance_fee_fraud | mobile_money_fraud | phishing | not_a_scam
  final String category;

  /// Confidence for [category], 0..1.
  final double confidence;

  /// Probability for every class.
  final Map<String, double> scores;

  ScamModelResult({
    required this.category,
    required this.confidence,
    required this.scores,
  });

  bool get isSafe => category == 'not_a_scam';

  /// Human-readable category for display.
  String get readableCategory {
    switch (category) {
      case 'advance_fee_fraud':
        return 'Advance-fee fraud';
      case 'mobile_money_fraud':
        return 'Mobile-money fraud';
      case 'phishing':
        return 'Phishing';
      case 'not_a_scam':
        return 'Not a scam';
      case 'scam':
        return 'Likely scam';
      default:
        return category;
    }
  }

  factory ScamModelResult.fromJson(Map<String, dynamic> json) {
    final raw = (json['scores'] as Map?) ?? const {};
    return ScamModelResult(
      category: json['predicted_category'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      scores: raw.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
    );
  }

  /// Map the binary inbox detector's response ({is_scam, scam_probability})
  /// into the shared result type, so the SMS feature can treat it like any
  /// other verdict. A positive uses the generic `scam` category, a negative
  /// `not_a_scam`; confidence is always the model's confidence in the verdict
  /// that is shown.
  factory ScamModelResult.fromBinaryJson(Map<String, dynamic> json) {
    final isScam = json['is_scam'] == true;
    final p = (json['scam_probability'] as num?)?.toDouble() ?? 0;
    return ScamModelResult(
      category: isScam ? 'scam' : 'not_a_scam',
      confidence: isScam ? p : (1 - p),
      scores: {'scam': p, 'not_a_scam': 1 - p},
    );
  }
}

/// Client for the project's scam-classifier API (the model "understands meaning"
/// rung of the roadmap). Calls the hosted ensemble's `POST /predict`.
///
/// Best-effort by design: if the model URL is unset or the request fails, this
/// returns `null` so the threat scanner degrades to its keyword/DB checks rather
/// than erroring. Configure the URL via `ApiConfig.setScamModelBaseUrl(...)` or
/// the `SCAM_MODEL_API` dart-define / env var.
class ScamModelService {
  ScamModelService({
    Dio? dio,
    Future<String> Function()? baseUrlResolver,
    bool binary = false,
  })  : _dio = dio ?? Dio(),
        _resolveBaseUrl = baseUrlResolver ?? ApiConfig.getScamModelBaseUrl,
        _binary = binary;

  final Dio _dio;

  /// Resolves the base URL to call. Defaults to the four-class model
  /// ([ApiConfig.getScamModelBaseUrl]); the SMS feature passes
  /// [ApiConfig.getBinaryModelBaseUrl] here.
  final Future<String> Function() _resolveBaseUrl;

  /// When true, this client talks to the binary inbox detector and parses its
  /// {is_scam, scam_probability} response instead of the four-class one.
  final bool _binary;

  // The model is hosted on a free Hugging Face Space that sleeps when idle.
  // The v2 model is pure scikit-learn (~1.5 MB, no embedder download), so a warm
  // container answers in ~1s; only the container wake from idle adds a few
  // seconds. We still pre-warm once per session so the user's first scan after
  // the app opens is fast rather than waiting on the cold container.
  // Per-instance: the four-class and binary clients each warm their own Space.
  bool _warmStarted = false;

  /// Fire-and-forget warm-up of the (sleeping) model Space. Hitting POST
  /// /predict — not GET /health — is what actually loads the model, so we send
  /// a tiny throwaway prediction with a long timeout. Safe to call repeatedly;
  /// only the first successful call per session does work.
  Future<void> warmUp() async {
    if (_warmStarted) return;
    _warmStarted = true;

    final baseUrl = await _resolveBaseUrl();
    if (baseUrl.isEmpty) {
      _warmStarted = false;
      return;
    }
    final url = '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/predict';
    try {
      await _dio.post(
        url,
        data: {'text': 'warmup'},
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 90), // cold start can be slow
          headers: {'Content-Type': 'application/json'},
        ),
      );
    } catch (e) {
      // Let a later call retry if this warm-up didn't land.
      _warmStarted = false;
      if (kDebugMode) {
        // ignore: avoid_print
        print('ScamModelService.warmUp failed (will retry later): $e');
      }
    }
  }

  Future<ScamModelResult?> classify(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final baseUrl = await _resolveBaseUrl();
    if (baseUrl.isEmpty) return null; // model not configured → heuristic-only

    final url = '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/predict';
    try {
      final resp = await _dio.post(
        url,
        data: {'text': trimmed},
        options: Options(
          // Longer than before: if the warm-up hasn't finished, a cold-start
          // scan still completes instead of falling back to heuristics.
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          headers: {'Content-Type': 'application/json'},
        ),
      );
      if (resp.statusCode == 200 && resp.data is Map) {
        final map = Map<String, dynamic>.from(resp.data);
        return _binary
            ? ScamModelResult.fromBinaryJson(map)
            : ScamModelResult.fromJson(map);
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('ScamModelService.classify failed: $e');
      }
    }
    return null;
  }
}

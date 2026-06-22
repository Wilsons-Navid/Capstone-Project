import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';

/// One prediction from the hosted scam-classifier ensemble
/// (TF-IDF + multilingual-e5-small soft-voting model, macro-F1 0.955).
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
}

/// Client for the project's scam-classifier API (the model "understands meaning"
/// rung of the roadmap). Calls the hosted ensemble's `POST /predict`.
///
/// Best-effort by design: if the model URL is unset or the request fails, this
/// returns `null` so the threat scanner degrades to its keyword/DB checks rather
/// than erroring. Configure the URL via `ApiConfig.setScamModelBaseUrl(...)` or
/// the `SCAM_MODEL_API` dart-define / env var.
class ScamModelService {
  ScamModelService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  // The model is hosted on a free Hugging Face Space that sleeps when idle.
  // The first request after idle has to wake the container AND lazy-load the
  // e5 weights, which can take 30-60s+. Without a warm-up, that first real scan
  // would exceed the timeout and silently fall back to heuristics (no model
  // verdict). We pre-warm once per session so the user's first scan is fast.
  static bool _warmStarted = false;

  /// Fire-and-forget warm-up of the (sleeping) model Space. Hitting POST
  /// /predict — not GET /health — is what actually loads the model, so we send
  /// a tiny throwaway prediction with a long timeout. Safe to call repeatedly;
  /// only the first successful call per session does work.
  Future<void> warmUp() async {
    if (_warmStarted) return;
    _warmStarted = true;

    final baseUrl = await ApiConfig.getScamModelBaseUrl();
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

    final baseUrl = await ApiConfig.getScamModelBaseUrl();
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
        return ScamModelResult.fromJson(Map<String, dynamic>.from(resp.data));
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

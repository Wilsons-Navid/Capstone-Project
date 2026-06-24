import 'dart:io';

import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';

import 'scam_model_service.dart';
import 'detected_threat_service.dart';

/// One scanned SMS + the model's verdict (null when the message is empty or the
/// model could not be reached).
class SmsScanItem {
  final String address;
  final String body;
  final DateTime date;
  final ScamModelResult? verdict;

  SmsScanItem({
    required this.address,
    required this.body,
    required this.date,
    this.verdict,
  });

  bool get isScam => verdict != null && !verdict!.isSafe;
}

/// Reads incoming / inbox SMS and classifies them with the project's scam model
/// (Thadee's "give the app access to incoming messages"). Android-only.
///
/// v1 does foreground live protection + on-demand inbox scan. Background delivery
/// (an SMS receiver while the app is closed) is a future extension and needs a
/// top-level handler + manifest receiver.
class SmsScannerService {
  SmsScannerService({ScamModelService? model})
      : _model = model ?? ScamModelService();

  final ScamModelService _model;
  final DetectedThreatService _detectedThreats = DetectedThreatService();
  final Telephony _telephony = Telephony.instance;

  bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    final granted = await _telephony.requestPhoneAndSmsPermissions;
    return granted ?? false;
  }

  /// Classify the most recent [limit] inbox messages (newest first).
  Future<List<SmsScanItem>> scanInbox({int limit = 20}) async {
    if (!isSupported) return [];
    // Wake the model first so the per-message classify calls don't each pay the
    // cold-start cost (a sleeping Space would otherwise stall the whole scan).
    await _model.warmUp();
    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
    );
    messages.sort((a, b) => (b.date ?? 0).compareTo(a.date ?? 0));

    final items = <SmsScanItem>[];
    for (final m in messages.take(limit)) {
      items.add(await _classify(m.address, m.body, m.date));
    }
    return items;
  }

  /// Live foreground protection: classify each incoming SMS and call [onResult].
  /// Live detections are persisted for the admin dashboard.
  void startListening(void Function(SmsScanItem) onResult) {
    if (!isSupported) return;
    _model.warmUp(); // warm the model so the first incoming SMS classifies fast
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        onResult(await _classify(message.address, message.body, null, record: true));
      },
      listenInBackground: false,
    );
  }

  Future<SmsScanItem> _classify(String? address, String? body, int? dateMs,
      {bool record = false}) async {
    final text = (body ?? '').trim();
    final verdict = text.isEmpty ? null : await _model.classify(text);

    if (record && verdict != null && !verdict.isSafe) {
      final level = verdict.confidence >= 0.85
          ? 'high'
          : verdict.confidence >= 0.6
              ? 'medium'
              : 'low';
      _detectedThreats.record(
        content: text,
        category: verdict.category,
        confidence: verdict.confidence,
        threatLevel: level,
        scores: verdict.scores,
        source: 'sms',
      );
    }

    return SmsScanItem(
      address: address ?? 'Unknown',
      body: body ?? '',
      date: dateMs != null
          ? DateTime.fromMillisecondsSinceEpoch(dateMs)
          : DateTime.now(),
      verdict: verdict,
    );
  }
}

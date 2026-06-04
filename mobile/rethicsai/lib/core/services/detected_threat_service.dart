import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// A scam detected by the model (from a text scan or an SMS), persisted for the
/// admin dashboard's data collection & analysis.
class DetectedThreat {
  final String id;
  final String content;
  final String category;
  final double confidence;
  final String threatLevel;
  final String source; // 'text_scan' | 'sms'
  final String? userId;
  final DateTime createdAt;

  DetectedThreat({
    required this.id,
    required this.content,
    required this.category,
    required this.confidence,
    required this.threatLevel,
    required this.source,
    required this.createdAt,
    this.userId,
  });

  factory DetectedThreat.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final ts = d['created_at'];
    return DetectedThreat(
      id: doc.id,
      content: d['content'] as String? ?? '',
      category: d['category'] as String? ?? 'unknown',
      confidence: (d['confidence'] as num?)?.toDouble() ?? 0,
      threatLevel: d['threat_level'] as String? ?? 'unknown',
      source: d['source'] as String? ?? 'text_scan',
      userId: d['user_id'] as String?,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

/// Writes model-detected scams to Firestore (`detected_threats`) and streams them
/// for the admin dashboard. Recording is best-effort — a failure never breaks a scan.
class DetectedThreatService {
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('detected_threats');

  Future<void> record({
    required String content,
    required String category,
    required double confidence,
    required String threatLevel,
    required String source,
    Map<String, double>? scores,
  }) async {
    try {
      final snippet = content.length > 500 ? content.substring(0, 500) : content;
      await _col.add({
        'content': snippet,
        'category': category,
        'confidence': confidence,
        'threat_level': threatLevel,
        'scores': scores,
        'source': source,
        'user_id': FirebaseAuth.instance.currentUser?.uid,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('DetectedThreatService.record failed: $e');
      }
    }
  }

  Stream<List<DetectedThreat>> watchRecent({int limit = 100}) {
    return _col
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(DetectedThreat.fromFirestore).toList());
  }
}

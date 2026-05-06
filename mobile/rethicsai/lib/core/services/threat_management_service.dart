import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/security_utils.dart';

class ThreatManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'verified_threats';

  Future<List<VerifiedThreat>> getAllThreats() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => VerifiedThreat.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting threats: $e');
      rethrow;
    }
  }

  Future<List<VerifiedThreat>> getThreatsByType(ThreatContentType type) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('type', isEqualTo: type.toString().split('.').last)
          .where('status', isEqualTo: 'active')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => VerifiedThreat.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting threats by type: $e');
      rethrow;
    }
  }

  Future<VerifiedThreat?> findThreatByValue(String value, ThreatContentType type) async {
    try {
      // Clean and normalize the value
      final cleanValue = _normalizeValue(value, type);
      
      final snapshot = await _firestore
          .collection(_collection)
          .where('type', isEqualTo: type.toString().split('.').last)
          .where('status', isEqualTo: 'active')
          .where('normalized_value', isEqualTo: cleanValue)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return VerifiedThreat.fromFirestore(snapshot.docs.first);
      }

      // Fallback: search by original value
      final fallbackSnapshot = await _firestore
          .collection(_collection)
          .where('type', isEqualTo: type.toString().split('.').last)
          .where('status', isEqualTo: 'active')
          .where('value', isEqualTo: value)
          .limit(1)
          .get();

      if (fallbackSnapshot.docs.isNotEmpty) {
        return VerifiedThreat.fromFirestore(fallbackSnapshot.docs.first);
      }

      return null;
    } catch (e) {
      debugPrint('Error finding threat by value: $e');
      return null;
    }
  }

  Future<bool> addThreat(VerifiedThreat threat) async {
    try {
      // Check if threat already exists
      final existing = await findThreatByValue(threat.value, threat.type);
      if (existing != null) {
        throw Exception('A threat with this value already exists');
      }

      final docRef = _firestore.collection(_collection).doc();
      await docRef.set(threat.copyWith(id: docRef.id).toFirestore());
      return true;
    } catch (e) {
      debugPrint('Error adding threat: $e');
      rethrow;
    }
  }

  Future<bool> updateThreat(VerifiedThreat threat) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(threat.id)
          .update(threat.toFirestore());
      return true;
    } catch (e) {
      debugPrint('Error updating threat: $e');
      rethrow;
    }
  }

  Future<bool> deleteThreat(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting threat: $e');
      rethrow;
    }
  }

  Future<bool> deactivateThreat(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'status': 'inactive',
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error deactivating threat: $e');
      rethrow;
    }
  }

  Future<bool> bulkImportThreats(List<VerifiedThreat> threats) async {
    try {
      final batch = _firestore.batch();
      
      for (final threat in threats) {
        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, threat.copyWith(id: docRef.id).toFirestore());
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error bulk importing threats: $e');
      rethrow;
    }
  }

  Future<List<VerifiedThreat>> searchThreats(String query) async {
    try {
      if (query.isEmpty) return getAllThreats();

      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'active')
          .get();

      final queryLower = query.toLowerCase();
      return snapshot.docs
          .map((doc) => VerifiedThreat.fromFirestore(doc))
          .where((threat) =>
              threat.value.toLowerCase().contains(queryLower) ||
              threat.description.toLowerCase().contains(queryLower) ||
              threat.category.toLowerCase().contains(queryLower))
          .toList();
    } catch (e) {
      debugPrint('Error searching threats: $e');
      rethrow;
    }
  }

  Future<Map<String, int>> getThreatStatistics() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      
      final stats = <String, int>{
        'total': 0,
        'active': 0,
        'inactive': 0,
        'url': 0,
        'email': 0,
        'phone': 0,
        'text': 0,
        'high_risk': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        stats['total'] = stats['total']! + 1;
        
        final status = data['status'] as String? ?? 'active';
        stats[status] = (stats[status] ?? 0) + 1;
        
        final type = data['type'] as String? ?? 'text';
        stats[type] = (stats[type] ?? 0) + 1;
        
        final threatLevel = data['threat_level'] as String? ?? 'medium';
        if (threatLevel == 'high' || threatLevel == 'critical') {
          stats['high_risk'] = stats['high_risk']! + 1;
        }
      }

      return stats;
    } catch (e) {
      debugPrint('Error getting threat statistics: $e');
      return {'total': 0, 'active': 0, 'inactive': 0, 'url': 0, 'email': 0, 'phone': 0, 'text': 0, 'high_risk': 0};
    }
  }

  String _normalizeValue(String value, ThreatContentType type) {
    switch (type) {
      case ThreatContentType.url:
        // Remove protocol and trailing slashes
        return value
            .toLowerCase()
            .replaceAll(RegExp(r'^https?://'), '')
            .replaceAll(RegExp(r'/$'), '')
            .trim();
      case ThreatContentType.email:
        return value.toLowerCase().trim();
      case ThreatContentType.phone:
        // Remove all non-digit characters except +
        return value.replaceAll(RegExp(r'[^\d+]'), '');
      case ThreatContentType.text:
        return value.toLowerCase().trim();
      case ThreatContentType.file:
        // For file hashes, keep as is but ensure lowercase
        return value.toLowerCase().trim();
    }
  }
}

enum ThreatContentType { url, email, phone, text, file }

enum ThreatStatus { active, inactive }

enum ThreatRiskLevel { safe, low, medium, high, critical }

class VerifiedThreat {
  final String id;
  final ThreatContentType type;
  final String value;
  final String normalizedValue;
  final ThreatRiskLevel threatLevel;
  final String category;
  final String description;
  final List<String> recommendations;
  final String source;
  final String addedBy;
  final ThreatStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const VerifiedThreat({
    required this.id,
    required this.type,
    required this.value,
    required this.normalizedValue,
    required this.threatLevel,
    required this.category,
    required this.description,
    required this.recommendations,
    required this.source,
    required this.addedBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory VerifiedThreat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return VerifiedThreat(
      id: doc.id,
      type: ThreatContentType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => ThreatContentType.text,
      ),
      value: data['value'] ?? '',
      normalizedValue: data['normalized_value'] ?? data['value'] ?? '',
      threatLevel: ThreatRiskLevel.values.firstWhere(
        (e) => e.toString().split('.').last == data['threat_level'],
        orElse: () => ThreatRiskLevel.medium,
      ),
      category: data['category'] ?? 'Unknown',
      description: data['description'] ?? '',
      recommendations: List<String>.from(data['recommendations'] ?? []),
      source: data['source'] ?? 'manual',
      addedBy: data['added_by'] ?? 'unknown',
      status: ThreatStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => ThreatStatus.active,
      ),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.toString().split('.').last,
      'value': value,
      'normalized_value': normalizedValue,
      'threat_level': threatLevel.toString().split('.').last,
      'category': category,
      'description': description,
      'recommendations': recommendations,
      'source': source,
      'added_by': addedBy,
      'status': status.toString().split('.').last,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': FieldValue.serverTimestamp(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  VerifiedThreat copyWith({
    String? id,
    ThreatContentType? type,
    String? value,
    String? normalizedValue,
    ThreatRiskLevel? threatLevel,
    String? category,
    String? description,
    List<String>? recommendations,
    String? source,
    String? addedBy,
    ThreatStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return VerifiedThreat(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      normalizedValue: normalizedValue ?? this.normalizedValue,
      threatLevel: threatLevel ?? this.threatLevel,
      category: category ?? this.category,
      description: description ?? this.description,
      recommendations: recommendations ?? this.recommendations,
      source: source ?? this.source,
      addedBy: addedBy ?? this.addedBy,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  factory VerifiedThreat.create({
    required ThreatContentType type,
    required String value,
    required ThreatRiskLevel threatLevel,
    required String category,
    required String description,
    required List<String> recommendations,
    required String addedBy,
    String source = 'manual',
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    final normalizedValue = ThreatManagementService()._normalizeValue(value, type);
    
    return VerifiedThreat(
      id: '',
      type: type,
      value: value,
      normalizedValue: normalizedValue,
      threatLevel: threatLevel,
      category: category,
      description: description,
      recommendations: recommendations,
      source: source,
      addedBy: addedBy,
      status: ThreatStatus.active,
      createdAt: now,
      updatedAt: now,
      metadata: metadata,
    );
  }
}

extension ThreatContentTypeExtension on ThreatContentType {
  String get displayName {
    switch (this) {
      case ThreatContentType.url:
        return 'URL';
      case ThreatContentType.email:
        return 'Email';
      case ThreatContentType.phone:
        return 'Phone';
      case ThreatContentType.text:
        return 'Text';
      case ThreatContentType.file:
        return 'File';
    }
  }
}

extension ThreatRiskLevelExtension on ThreatRiskLevel {
  String get displayName {
    switch (this) {
      case ThreatRiskLevel.safe:
        return 'Safe';
      case ThreatRiskLevel.low:
        return 'Low Risk';
      case ThreatRiskLevel.medium:
        return 'Medium Risk';
      case ThreatRiskLevel.high:
        return 'High Risk';
      case ThreatRiskLevel.critical:
        return 'Critical Risk';
    }
  }
}
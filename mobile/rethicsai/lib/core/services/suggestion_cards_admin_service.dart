import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../shared/models/suggestion_card_model.dart';
import '../../core/themes/app_theme.dart';

class SuggestionCardsAdminService {
  static const String _collection = 'suggestion_cards';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all suggestion cards stream for real-time updates
  Stream<List<SuggestionCardModel>> getSuggestionCardsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('sortOrder')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SuggestionCardModel.fromMap(doc.data()))
            .toList());
  }

  // Get only active suggestion cards for users
  Stream<List<SuggestionCardModel>> getActiveSuggestionCardsStream() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SuggestionCardModel.fromMap(doc.data()))
            .toList());
  }

  // Get single suggestion card
  Future<SuggestionCardModel?> getSuggestionCard(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        return SuggestionCardModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting suggestion card: $e');
      return null;
    }
  }

  // Create new suggestion card
  Future<bool> createSuggestionCard(SuggestionCardModel card) async {
    try {
      await _firestore.collection(_collection).doc(card.id).set(card.toMap());
      return true;
    } catch (e) {
      print('Error creating suggestion card: $e');
      return false;
    }
  }

  // Update suggestion card
  Future<bool> updateSuggestionCard(SuggestionCardModel card) async {
    try {
      final updatedCard = card.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection(_collection)
          .doc(card.id)
          .update(updatedCard.toMap());
      return true;
    } catch (e) {
      print('Error updating suggestion card: $e');
      return false;
    }
  }

  // Delete suggestion card
  Future<bool> deleteSuggestionCard(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting suggestion card: $e');
      return false;
    }
  }

  // Toggle card active status
  Future<bool> toggleCardStatus(String id, bool isActive, String userId) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': isActive,
        'updatedAt': DateTime.now().toIso8601String(),
        'updatedBy': userId,
      });
      return true;
    } catch (e) {
      print('Error toggling card status: $e');
      return false;
    }
  }

  // Update sort order
  Future<bool> updateSortOrder(String id, int sortOrder, String userId) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'sortOrder': sortOrder,
        'updatedAt': DateTime.now().toIso8601String(),
        'updatedBy': userId,
      });
      return true;
    } catch (e) {
      print('Error updating sort order: $e');
      return false;
    }
  }

  // Initialize default cards if collection is empty
  Future<void> initializeDefaultCards() async {
    try {
      final snapshot = await _firestore.collection(_collection).limit(1).get();
      if (snapshot.docs.isEmpty) {
        final defaultCards = _getDefaultSuggestionCards();
        for (final card in defaultCards) {
          await createSuggestionCard(card);
        }
      }
    } catch (e) {
      print('Error initializing default cards: $e');
    }
  }

  // Get default suggestion cards
  List<SuggestionCardModel> _getDefaultSuggestionCards() {
    final now = DateTime.now();
    return [
      SuggestionCardModel(
        id: 'password_security',
        title: 'Password Security',
        subtitle: 'Learn about strong passwords',
        text: 'How can I create a strong password?',
        iconCodePoint: Icons.lock.codePoint.toString(),
        gradientColors: SuggestionCardModel.colorsToStringList([
          AppTheme.primaryColor,
          AppTheme.primaryColor.withOpacity(0.7),
        ]),
        category: 'password_security',
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
        createdBy: 'system',
      ),
      SuggestionCardModel(
        id: 'phishing_protection',
        title: 'Phishing Protection',
        subtitle: 'Identify suspicious emails',
        text: 'How do I identify phishing emails?',
        iconCodePoint: Icons.email.codePoint.toString(),
        gradientColors: SuggestionCardModel.colorsToStringList([
          AppTheme.secondaryColor,
          AppTheme.secondaryColor.withOpacity(0.7),
        ]),
        category: 'phishing_awareness',
        sortOrder: 2,
        createdAt: now,
        updatedAt: now,
        createdBy: 'system',
      ),
      SuggestionCardModel(
        id: 'wifi_security',
        title: 'WiFi Security',
        subtitle: 'Secure your connection',
        text: 'How can I secure my WiFi network?',
        iconCodePoint: Icons.wifi.codePoint.toString(),
        gradientColors: SuggestionCardModel.colorsToStringList([
          AppTheme.accentColor,
          AppTheme.accentColor.withOpacity(0.7),
        ]),
        category: 'wifi_security',
        sortOrder: 3,
        createdAt: now,
        updatedAt: now,
        createdBy: 'system',
      ),
      SuggestionCardModel(
        id: 'mobile_money',
        title: 'Mobile Money',
        subtitle: 'M-Pesa & mobile banking safety',
        text: 'How can I secure my mobile money account?',
        iconCodePoint: Icons.account_balance_wallet.codePoint.toString(),
        gradientColors: ['0xFF2E7D32', '0xFF4CAF50'],
        category: 'mobile_money_security',
        sortOrder: 4,
        createdAt: now,
        updatedAt: now,
        createdBy: 'system',
      ),
      SuggestionCardModel(
        id: 'social_media',
        title: 'Social Media',
        subtitle: 'Privacy settings guide',
        text: 'How do I protect my privacy on social media?',
        iconCodePoint: Icons.groups.codePoint.toString(),
        gradientColors: ['0xFF3F51B5', '0xFF5C6BC0'],
        category: 'social_media_safety',
        sortOrder: 5,
        createdAt: now,
        updatedAt: now,
        createdBy: 'system',
      ),
      SuggestionCardModel(
        id: 'online_shopping',
        title: 'Online Shopping',
        subtitle: 'Safe payment practices',
        text: 'How can I shop safely online?',
        iconCodePoint: Icons.shopping_cart.codePoint.toString(),
        gradientColors: ['0xFF4CAF50', '0xFF66BB6A'],
        category: 'online_shopping_safety',
        sortOrder: 6,
        createdAt: now,
        updatedAt: now,
        createdBy: 'system',
      ),
      SuggestionCardModel(
        id: 'emergency_help',
        title: 'Emergency Help',
        subtitle: 'Been hacked or scammed?',
        text: 'I think I\'ve been hacked or scammed. What do I do?',
        iconCodePoint: Icons.emergency.codePoint.toString(),
        gradientColors: ['0xFFD32F2F', '0xFFEF5350'],
        category: 'incident_response',
        sortOrder: 7,
        createdAt: now,
        updatedAt: now,
        createdBy: 'system',
      ),
      SuggestionCardModel(
        id: 'general_security',
        title: 'General Security',
        subtitle: 'Cybersecurity basics',
        text: 'What are the most important cybersecurity practices for Africa?',
        iconCodePoint: Icons.security.codePoint.toString(),
        gradientColors: ['0xFF455A64', '0xFF607D8B'],
        category: 'general_security',
        sortOrder: 8,
        createdAt: now,
        updatedAt: now,
        createdBy: 'system',
      ),
    ];
  }

  // Bulk operations
  Future<bool> reorderCards(List<String> cardIds, String userId) async {
    try {
      final batch = _firestore.batch();
      for (int i = 0; i < cardIds.length; i++) {
        final docRef = _firestore.collection(_collection).doc(cardIds[i]);
        batch.update(docRef, {
          'sortOrder': i + 1,
          'updatedAt': DateTime.now().toIso8601String(),
          'updatedBy': userId,
        });
      }
      await batch.commit();
      return true;
    } catch (e) {
      print('Error reordering cards: $e');
      return false;
    }
  }

  // Search cards
  Stream<List<SuggestionCardModel>> searchCards(String query) {
    return _firestore
        .collection(_collection)
        .orderBy('title')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SuggestionCardModel.fromMap(doc.data()))
            .where((card) =>
                card.title.toLowerCase().contains(query.toLowerCase()) ||
                card.subtitle.toLowerCase().contains(query.toLowerCase()) ||
                card.category.toLowerCase().contains(query.toLowerCase()))
            .toList());
  }

  // Get statistics
  Future<Map<String, int>> getCardsStatistics() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final cards = snapshot.docs
          .map((doc) => SuggestionCardModel.fromMap(doc.data()))
          .toList();

      return {
        'total': cards.length,
        'active': cards.where((card) => card.isActive).length,
        'inactive': cards.where((card) => !card.isActive).length,
        'categories': cards.map((card) => card.category).toSet().length,
      };
    } catch (e) {
      print('Error getting cards statistics: $e');
      return {'total': 0, 'active': 0, 'inactive': 0, 'categories': 0};
    }
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/education/presentation/models/education_models.dart';

class EducationService {
  static const String _categoriesCollection = 'education_categories';
  static const String _contentCollection = 'education_content';
  static const String _progressCollection = 'user_progress';
  
  static CollectionReference get _categories =>
      FirebaseFirestore.instance.collection(_categoriesCollection);
  
  static CollectionReference get _content =>
      FirebaseFirestore.instance.collection(_contentCollection);
      
  static CollectionReference get _progress =>
      FirebaseFirestore.instance.collection(_progressCollection);

  // Get all education categories
  static Future<List<EducationCategory>> getCategories() async {
    try {
      final snapshot = await _categories.orderBy('order').get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EducationCategory.fromJson({
          ...data,
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      // Return default categories if Firebase fails
      return _getDefaultCategories();
    }
  }

  // Get content for a specific category
  static Future<List<EducationContent>> getCategoryContent(String categoryId) async {
    try {
      final snapshot = await _content
          .where('category_id', isEqualTo: categoryId)
          .orderBy('order')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EducationContent.fromJson({
          ...data,
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch category content: $e');
    }
  }

  // Get featured content
  static Future<List<EducationContent>> getFeaturedContent({int limit = 5}) async {
    try {
      final snapshot = await _content
          .where('is_featured', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EducationContent.fromJson({
          ...data,
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch featured content: $e');
    }
  }

  // Search content
  static Future<List<EducationContent>> searchContent(String query) async {
    try {
      final snapshot = await _content.get();
      
      final results = <EducationContent>[];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final title = (data['title'] as String? ?? '').toLowerCase();
        final description = (data['description'] as String? ?? '').toLowerCase();
        final tags = (data['tags'] as List<dynamic>? ?? [])
            .map((tag) => tag.toString().toLowerCase())
            .toList();
        
        final queryLower = query.toLowerCase();
        
        if (title.contains(queryLower) ||
            description.contains(queryLower) ||
            tags.any((tag) => tag.contains(queryLower))) {
          results.add(EducationContent.fromJson({
            ...data,
            'id': doc.id,
          }));
        }
      }
      
      return results;
    } catch (e) {
      throw Exception('Failed to search content: $e');
    }
  }

  // Get user progress for a category
  static Future<UserProgress?> getUserProgress(String categoryId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      
      final doc = await _progress
          .doc('${user.uid}_$categoryId')
          .get();
      
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>;
      return UserProgress.fromJson({
        ...data,
        'id': doc.id,
      });
    } catch (e) {
      throw Exception('Failed to fetch user progress: $e');
    }
  }

  // Update user progress
  static Future<void> updateProgress(
    String categoryId,
    String contentId, {
    bool completed = false,
    int timeSpent = 0,
    double? score,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      final progressId = '${user.uid}_$categoryId';
      final progressRef = _progress.doc(progressId);
      
      // Get existing progress or create new
      final existingDoc = await progressRef.get();
      
      Map<String, dynamic> progressData;
      if (existingDoc.exists) {
        progressData = existingDoc.data() as Map<String, dynamic>;
      } else {
        progressData = {
          'user_id': user.uid,
          'category_id': categoryId,
          'started_at': DateTime.now().toIso8601String(),
          'completed_content': <String>[],
          'total_time_spent': 0,
          'scores': <String, double>{},
        };
      }
      
      // Update progress
      final completedContent = List<String>.from(progressData['completed_content'] ?? []);
      final scores = Map<String, double>.from(progressData['scores'] ?? {});
      
      if (completed && !completedContent.contains(contentId)) {
        completedContent.add(contentId);
      }
      
      if (score != null) {
        scores[contentId] = score;
      }
      
      progressData.update('completed_content', (value) => completedContent);
      progressData.update('total_time_spent', (value) => (value as int) + timeSpent);
      progressData.update('scores', (value) => scores);
      progressData['updated_at'] = DateTime.now().toIso8601String();
      
      await progressRef.set(progressData);
    } catch (e) {
      throw Exception('Failed to update progress: $e');
    }
  }

  // Get user statistics
  static Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {};
      
      final snapshot = await _progress
          .where('user_id', isEqualTo: user.uid)
          .get();
      
      int totalTimeSpent = 0;
      int completedCategories = 0;
      int totalContentCompleted = 0;
      double averageScore = 0;
      List<double> allScores = [];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalTimeSpent += (data['total_time_spent'] as int? ?? 0);
        
        final completedContent = List.from(data['completed_content'] ?? []);
        totalContentCompleted += completedContent.length;
        
        final scores = Map<String, double>.from(data['scores'] ?? {});
        allScores.addAll(scores.values);
        
        // Check if category is completed (assuming completion is based on content completion)
        if (completedContent.isNotEmpty) {
          completedCategories++;
        }
      }
      
      if (allScores.isNotEmpty) {
        averageScore = allScores.reduce((a, b) => a + b) / allScores.length;
      }
      
      return {
        'total_time_spent': totalTimeSpent,
        'completed_categories': completedCategories,
        'total_content_completed': totalContentCompleted,
        'average_score': averageScore,
      };
    } catch (e) {
      throw Exception('Failed to fetch user statistics: $e');
    }
  }

  // Admin functions
  static Future<void> createCategory(EducationCategory category) async {
    try {
      await _categories.add(category.toJson());
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  static Future<void> updateCategory(String id, EducationCategory category) async {
    try {
      await _categories.doc(id).update(category.toJson());
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  static Future<void> deleteCategory(String id) async {
    try {
      await _categories.doc(id).delete();
      
      // Also delete associated content
      final contentSnapshot = await _content
          .where('category_id', isEqualTo: id)
          .get();
      
      for (final doc in contentSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  static Future<void> createContent(EducationContent content) async {
    try {
      await _content.add(content.toJson());
    } catch (e) {
      throw Exception('Failed to create content: $e');
    }
  }

  static Future<void> updateContent(String id, EducationContent content) async {
    try {
      await _content.doc(id).update(content.toJson());
    } catch (e) {
      throw Exception('Failed to update content: $e');
    }
  }

  static Future<void> deleteContent(String id) async {
    try {
      await _content.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete content: $e');
    }
  }

  // Seed default data
  static Future<void> seedDefaultData() async {
    try {
      final categoriesSnapshot = await _categories.limit(1).get();
      if (categoriesSnapshot.docs.isNotEmpty) {
        return; // Data already exists
      }
      
      final categories = _getDefaultCategories();
      final content = _getDefaultContent();
      
      // Add categories
      for (final category in categories) {
        final docRef = await _categories.add(category.toJson());
        category.id = docRef.id;
      }
      
      // Add content
      for (final contentItem in content) {
        await _content.add(contentItem.toJson());
      }
      
    } catch (e) {
      print('Failed to seed default education data: $e');
    }
  }

  // Default data
  static List<EducationCategory> _getDefaultCategories() {
    return [
      EducationCategory(
        id: 'password-security',
        title: 'Password Security',
        description: 'Learn how to create and manage strong passwords',
        icon: 'lock',
        color: '#4CAF50',
        moduleCount: 5,
        estimatedTime: '30 min',
        difficulty: 'Beginner',
        order: 1,
      ),
      EducationCategory(
        id: 'phishing-awareness',
        title: 'Phishing Awareness',
        description: 'Identify and avoid phishing attacks',
        icon: 'phishing',
        color: '#FF9800',
        moduleCount: 7,
        estimatedTime: '45 min',
        difficulty: 'Intermediate',
        order: 2,
      ),
      EducationCategory(
        id: 'social-media-safety',
        title: 'Social Media Safety',
        description: 'Protect your privacy on social platforms',
        icon: 'share',
        color: '#2196F3',
        moduleCount: 6,
        estimatedTime: '40 min',
        difficulty: 'Beginner',
        order: 3,
      ),
      EducationCategory(
        id: 'online-shopping',
        title: 'Safe Online Shopping',
        description: 'Shop safely and avoid e-commerce scams',
        icon: 'shopping_cart',
        color: '#9C27B0',
        moduleCount: 4,
        estimatedTime: '25 min',
        difficulty: 'Beginner',
        order: 4,
      ),
      EducationCategory(
        id: 'mobile-security',
        title: 'Mobile Security',
        description: 'Secure your smartphone and mobile apps',
        icon: 'phone_android',
        color: '#F44336',
        moduleCount: 8,
        estimatedTime: '50 min',
        difficulty: 'Intermediate',
        order: 5,
      ),
      EducationCategory(
        id: 'wifi-security',
        title: 'WiFi Security',
        description: 'Stay safe on public and private networks',
        icon: 'wifi',
        color: '#795548',
        moduleCount: 5,
        estimatedTime: '35 min',
        difficulty: 'Advanced',
        order: 6,
      ),
    ];
  }

  static List<EducationContent> _getDefaultContent() {
    return [
      EducationContent(
        id: 'password-basics',
        categoryId: 'password-security',
        title: 'Password Basics',
        description: 'Understanding the fundamentals of password security',
        contentType: 'article',
        estimatedTime: '10 min',
        difficulty: 'Beginner',
        isFeatured: true,
        order: 1,
        tags: ['password', 'security', 'basics'],
      ),
      EducationContent(
        id: 'strong-password-creation',
        categoryId: 'password-security',
        title: 'Creating Strong Passwords',
        description: 'Learn techniques for creating unbreakable passwords',
        contentType: 'interactive',
        estimatedTime: '15 min',
        difficulty: 'Beginner',
        isFeatured: false,
        order: 2,
        tags: ['password', 'creation', 'security'],
      ),
      // Add more default content as needed
    ];
  }
}

// Extended education models for Firebase
class EducationContent {
  final String id;
  final String categoryId;
  final String title;
  final String description;
  final String contentType; // article, video, interactive, quiz
  final String? contentUrl;
  final String? videoUrl;
  final String? content; // HTML or markdown content
  final List<String> tags;
  final String estimatedTime;
  final String difficulty;
  final bool isFeatured;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EducationContent({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.contentType,
    this.contentUrl,
    this.videoUrl,
    this.content,
    required this.tags,
    required this.estimatedTime,
    required this.difficulty,
    required this.isFeatured,
    required this.order,
    this.createdAt,
    this.updatedAt,
  });

  factory EducationContent.fromJson(Map<String, dynamic> json) {
    return EducationContent(
      id: json['id'] ?? '',
      categoryId: json['category_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      contentType: json['content_type'] ?? 'article',
      contentUrl: json['content_url'],
      videoUrl: json['video_url'],
      content: json['content'],
      tags: List<String>.from(json['tags'] ?? []),
      estimatedTime: json['estimated_time'] ?? '10 min',
      difficulty: json['difficulty'] ?? 'Beginner',
      isFeatured: json['is_featured'] ?? false,
      order: json['order'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'title': title,
      'description': description,
      'content_type': contentType,
      'content_url': contentUrl,
      'video_url': videoUrl,
      'content': content,
      'tags': tags,
      'estimated_time': estimatedTime,
      'difficulty': difficulty,
      'is_featured': isFeatured,
      'order': order,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

class UserProgress {
  final String id;
  final String userId;
  final String categoryId;
  final List<String> completedContent;
  final int totalTimeSpent;
  final Map<String, double> scores;
  final DateTime startedAt;
  final DateTime? updatedAt;

  UserProgress({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.completedContent,
    required this.totalTimeSpent,
    required this.scores,
    required this.startedAt,
    this.updatedAt,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      categoryId: json['category_id'] ?? '',
      completedContent: List<String>.from(json['completed_content'] ?? []),
      totalTimeSpent: json['total_time_spent'] ?? 0,
      scores: Map<String, double>.from(json['scores'] ?? {}),
      startedAt: DateTime.parse(json['started_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'completed_content': completedContent,
      'total_time_spent': totalTimeSpent,
      'scores': scores,
      'started_at': startedAt.toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
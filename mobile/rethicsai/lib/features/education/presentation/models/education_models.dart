import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EducationCategory {
  String id;
  final String title;
  final String description;
  final String icon; // Store as string for Firebase
  final String color; // Store as hex string for Firebase
  final int moduleCount;
  final String estimatedTime;
  final String difficulty;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EducationCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.moduleCount,
    required this.estimatedTime,
    required this.difficulty,
    required this.order,
    this.createdAt,
    this.updatedAt,
  });

  // Convert string icon to IconData
  IconData get iconData {
    switch (icon.toLowerCase()) {
      case 'lock':
        return Icons.lock;
      case 'phishing':
        return Icons.phishing;
      case 'share':
        return Icons.share;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'phone_android':
        return Icons.phone_android;
      case 'wifi':
        return Icons.wifi;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'favorite_border':
        return Icons.favorite_border;
      case 'currency_bitcoin':
        return Icons.currency_bitcoin;
      case 'psychology':
        return Icons.psychology;
      default:
        return Icons.school;
    }
  }

  // Convert hex string to Color
  Color get colorValue {
    try {
      return Color(int.parse(color.replaceAll('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF4CAF50); // Default green
    }
  }

  factory EducationCategory.fromJson(Map<String, dynamic> json) {
    return EducationCategory(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'school',
      color: json['color'] ?? '#4CAF50',
      moduleCount: json['module_count'] ?? 0,
      estimatedTime: json['estimated_time'] ?? '0 min',
      difficulty: json['difficulty'] ?? 'Beginner',
      order: json['order'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  factory EducationCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EducationCategory(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? 'school',
      color: data['color'] ?? '#4CAF50',
      moduleCount: data['module_count'] ?? 0,
      estimatedTime: data['estimated_time'] ?? '0 min',
      difficulty: data['difficulty'] ?? 'Beginner',
      order: data['order'] ?? 0,
      createdAt: data['created_at']?.toDate(),
      updatedAt: data['updated_at']?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'icon': icon,
      'color': color,
      'module_count': moduleCount,
      'estimated_time': estimatedTime,
      'difficulty': difficulty,
      'order': order,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

class EducationContent {
  final String id;
  final String title;
  final String description;
  final String thumbnail;
  final int duration; // in minutes
  final String difficulty;
  final String type; // Article, Video, Interactive, Quiz
  final String? videoUrl;
  final List<String>? backupVideoUrls;
  final String? mp4Url;
  final String? articleContent;
  final List<QuizQuestion>? quizQuestions;
  final Map<String, String>? resources; // Links to external resources
  final List<String> tags;
  final String categoryId;
  final bool isFeatured;
  final int viewCount;
  final double rating;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EducationContent({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.duration,
    required this.difficulty,
    required this.type,
    required this.categoryId,
    this.videoUrl,
    this.backupVideoUrls,
    this.mp4Url,
    this.articleContent,
    this.quizQuestions,
    this.resources,
    this.tags = const [],
    this.isFeatured = false,
    this.viewCount = 0,
    this.rating = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  factory EducationContent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EducationContent(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      thumbnail: data['thumbnail'] ?? '',
      duration: data['duration'] ?? 0,
      difficulty: data['difficulty'] ?? 'Beginner',
      type: data['type'] ?? 'Article',
      categoryId: data['category_id'] ?? '',
      videoUrl: data['video_url'],
      backupVideoUrls: data['backup_video_urls'] != null ? List<String>.from(data['backup_video_urls']) : null,
      mp4Url: data['mp4_url'],
      articleContent: data['article_content'],
      quizQuestions: data['quiz_questions'] != null
          ? (data['quiz_questions'] as List)
              .map((q) => QuizQuestion.fromJson(q))
              .toList()
          : null,
      resources: data['resources'] != null
          ? Map<String, String>.from(data['resources'])
          : null,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      isFeatured: data['is_featured'] ?? false,
      viewCount: data['view_count'] ?? 0,
      rating: (data['rating'] ?? 0.0).toDouble(),
      createdAt: data['created_at']?.toDate(),
      updatedAt: data['updated_at']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'thumbnail': thumbnail,
      'duration': duration,
      'difficulty': difficulty,
      'type': type,
      'category_id': categoryId,
      'video_url': videoUrl,
      'backup_video_urls': backupVideoUrls,
      'mp4_url': mp4Url,
      'article_content': articleContent,
      'quiz_questions': quizQuestions?.map((q) => q.toJson()).toList(),
      'resources': resources,
      'tags': tags,
      'is_featured': isFeatured,
      'view_count': viewCount,
      'rating': rating,
      'created_at': createdAt ?? FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}

class EducationModule {
  final String id;
  final String title;
  final String description;
  final List<EducationContent> contents;
  final bool isCompleted;
  final double progress; // 0.0 to 1.0

  EducationModule({
    required this.id,
    required this.title,
    required this.description,
    required this.contents,
    this.isCompleted = false,
    this.progress = 0.0,
  });
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final String difficulty;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    this.difficulty = 'Medium',
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswerIndex: json['correct_answer_index'] ?? 0,
      explanation: json['explanation'] ?? '',
      difficulty: json['difficulty'] ?? 'Medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correct_answer_index': correctAnswerIndex,
      'explanation': explanation,
      'difficulty': difficulty,
    };
  }
}

class UserProgress {
  final String userId;
  final int completedModules;
  final int totalModules;
  final int currentStreak;
  final int longestStreak;
  final List<String> completedCategories;
  final Map<String, double> categoryProgress;
  final Map<String, DateTime> lastAccessedContent;
  final int totalMinutesLearned;
  final List<String> achievements;
  final DateTime lastActiveDate;
  final Map<String, dynamic> weeklyStats;

  UserProgress({
    required this.userId,
    required this.completedModules,
    required this.totalModules,
    required this.currentStreak,
    required this.longestStreak,
    required this.completedCategories,
    required this.categoryProgress,
    required this.lastAccessedContent,
    required this.totalMinutesLearned,
    required this.achievements,
    required this.lastActiveDate,
    required this.weeklyStats,
  });

  double get overallProgress => totalModules > 0 ? completedModules / totalModules : 0.0;

  factory UserProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProgress(
      userId: doc.id,
      completedModules: data['completed_modules'] ?? 0,
      totalModules: data['total_modules'] ?? 0,
      currentStreak: data['current_streak'] ?? 0,
      longestStreak: data['longest_streak'] ?? 0,
      completedCategories: List<String>.from(data['completed_categories'] ?? []),
      categoryProgress: Map<String, double>.from(data['category_progress'] ?? {}),
      lastAccessedContent: (data['last_accessed_content'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, (value as Timestamp).toDate())),
      totalMinutesLearned: data['total_minutes_learned'] ?? 0,
      achievements: List<String>.from(data['achievements'] ?? []),
      lastActiveDate: (data['last_active_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weeklyStats: data['weekly_stats'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'completed_modules': completedModules,
      'total_modules': totalModules,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'completed_categories': completedCategories,
      'category_progress': categoryProgress,
      'last_accessed_content': lastAccessedContent.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
      'total_minutes_learned': totalMinutesLearned,
      'achievements': achievements,
      'last_active_date': Timestamp.fromDate(lastActiveDate),
      'weekly_stats': weeklyStats,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}

class EducationProgress {
  final int completedModules;
  final int totalModules;
  final int currentStreak;
  final List<String> completedCategories;
  final Map<String, double> categoryProgress;

  EducationProgress({
    required this.completedModules,
    required this.totalModules,
    required this.currentStreak,
    required this.completedCategories,
    required this.categoryProgress,
  });

  double get overallProgress => totalModules > 0 ? completedModules / totalModules : 0.0;
}

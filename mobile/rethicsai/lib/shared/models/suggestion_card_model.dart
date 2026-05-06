import 'package:flutter/material.dart';

class SuggestionCardModel {
  final String id;
  final String title;
  final String subtitle;
  final String text;
  final String iconCodePoint;
  final List<String> gradientColors;
  final String category;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;

  const SuggestionCardModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.text,
    required this.iconCodePoint,
    required this.gradientColors,
    required this.category,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'text': text,
      'iconCodePoint': iconCodePoint,
      'gradientColors': gradientColors,
      'category': category,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  // Create from Firebase Map
  factory SuggestionCardModel.fromMap(Map<String, dynamic> map) {
    return SuggestionCardModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      text: map['text'] ?? '',
      iconCodePoint: map['iconCodePoint'] ?? '',
      gradientColors: List<String>.from(map['gradientColors'] ?? []),
      category: map['category'] ?? '',
      sortOrder: map['sortOrder']?.toInt() ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      createdBy: map['createdBy'],
      updatedBy: map['updatedBy'],
    );
  }

  // Copy with method for updates
  SuggestionCardModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? text,
    String? iconCodePoint,
    List<String>? gradientColors,
    String? category,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return SuggestionCardModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      text: text ?? this.text,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      gradientColors: gradientColors ?? this.gradientColors,
      category: category ?? this.category,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  // Convert to IconData
  IconData get iconData {
    try {
      return IconData(int.parse(iconCodePoint), fontFamily: 'MaterialIcons');
    } catch (e) {
      return Icons.help_outline; // Default icon if parsing fails
    }
  }

  // Convert to LinearGradient
  LinearGradient get gradient {
    try {
      final colors = gradientColors
          .map((colorString) => Color(int.parse(colorString)))
          .toList();
      return LinearGradient(colors: colors.isNotEmpty ? colors : [Colors.blue, Colors.lightBlue]);
    } catch (e) {
      return const LinearGradient(colors: [Colors.blue, Colors.lightBlue]);
    }
  }

  // Helper method to convert IconData to string
  static String iconToString(IconData icon) {
    return icon.codePoint.toString();
  }

  // Helper method to convert Color list to string list
  static List<String> colorsToStringList(List<Color> colors) {
    return colors.map((color) => color.value.toString()).toList();
  }

  @override
  String toString() {
    return 'SuggestionCardModel(id: $id, title: $title, category: $category, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SuggestionCardModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
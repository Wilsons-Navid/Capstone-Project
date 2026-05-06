import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Enhanced Wilson AI Service using Vertex AI Gemini
/// Provides advanced cybersecurity assistance with African context
class WilsonAIVertexService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  static const String _wilsonVertexFunction = 'wilsonAIVertex';
  static const String _threatIntelFunction = 'getAfricanThreatIntelligence';
  static const String _trainingContentFunction = 'generateSecurityTraining';

  /// Chat with Wilson AI using advanced Vertex AI Gemini model
  /// Provides enhanced cybersecurity guidance with African context
  Future<WilsonVertexChatResponse> chatWithWilsonVertex({
    required List<ChatMessage> messages,
    String? sessionId,
    WilsonContextType contextType = WilsonContextType.chat,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      final callable = _functions.httpsCallable(_wilsonVertexFunction);
      final result = await callable.call({
        'messages': messages.map((m) => m.toJson()).toList(),
        'userId': user?.uid,
        'sessionId': sessionId,
        'contextType': contextType.name,
      });

      return WilsonVertexChatResponse.fromJson(result.data);
    } catch (e) {
      if (kDebugMode) {
        print('Wilson AI Vertex Error: $e');
      }
      throw WilsonAIException('Failed to get response from Wilson AI Vertex: $e');
    }
  }

  /// Get real-time cybersecurity threat intelligence for African regions
  Future<AfricanThreatIntelligence> getAfricanThreatIntelligence({
    String region = 'africa',
  }) async {
    try {
      final callable = _functions.httpsCallable(_threatIntelFunction);
      final result = await callable.call({
        'region': region,
      });

      return AfricanThreatIntelligence.fromJson(result.data);
    } catch (e) {
      if (kDebugMode) {
        print('African Threat Intelligence Error: $e');
      }
      throw WilsonAIException('Failed to get threat intelligence: $e');
    }
  }

  /// Generate customized cybersecurity training content
  Future<SecurityTrainingContent> generateSecurityTraining({
    required String topic,
    required TrainingLevel level,
    String language = 'english',
  }) async {
    try {
      final callable = _functions.httpsCallable(_trainingContentFunction);
      final result = await callable.call({
        'topic': topic,
        'level': level.name,
        'language': language,
      });

      return SecurityTrainingContent.fromJson(result.data);
    } catch (e) {
      if (kDebugMode) {
        print('Security Training Generation Error: $e');
      }
      throw WilsonAIException('Failed to generate training content: $e');
    }
  }

  /// Create a new chat session with enhanced tracking
  String generateEnhancedSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'wilson_vertex_${timestamp}_$random';
  }

  /// Analyze message for threat level (client-side pre-screening)
  ThreatLevel analyzeMessageThreatLevel(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Critical indicators
    final criticalKeywords = [
      'hacked', 'compromised', 'stolen money', 'unauthorized transaction',
      'sim swap', 'account takeover', 'identity theft', 'fraud alert'
    ];
    
    // High threat indicators  
    final highKeywords = [
      'suspicious message', 'phishing', 'scam call', 'fake email',
      'won lottery', 'urgent payment', 'verify account', 'click link'
    ];
    
    // Medium threat indicators
    final mediumKeywords = [
      'forgot password', 'security question', 'wifi security',
      'unknown caller', 'suspicious link', 'safe to click'
    ];

    if (criticalKeywords.any((keyword) => lowerMessage.contains(keyword))) {
      return ThreatLevel.critical;
    } else if (highKeywords.any((keyword) => lowerMessage.contains(keyword))) {
      return ThreatLevel.high;
    } else if (mediumKeywords.any((keyword) => lowerMessage.contains(keyword))) {
      return ThreatLevel.medium;
    }
    
    return ThreatLevel.low;
  }
}

/// Enhanced chat message with threat analysis
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime? timestamp;
  final ThreatLevel? threatLevel;

  const ChatMessage({
    required this.role,
    required this.content,
    this.timestamp,
    this.threatLevel,
  });

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    if (timestamp != null) 'timestamp': timestamp!.millisecondsSinceEpoch,
    if (threatLevel != null) 'threatLevel': threatLevel!.name,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    role: json['role'],
    content: json['content'],
    timestamp: json['timestamp'] != null 
      ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
      : null,
    threatLevel: json['threatLevel'] != null 
      ? ThreatLevel.values.firstWhere((e) => e.name == json['threatLevel'])
      : null,
  );
}

/// Enhanced Wilson AI response with threat analysis
class WilsonVertexChatResponse {
  final String response;
  final String messageId;
  final int timestamp;
  final String sessionId;
  final String? threatLevel;
  final List<String>? recommendations;

  const WilsonVertexChatResponse({
    required this.response,
    required this.messageId,
    required this.timestamp,
    required this.sessionId,
    this.threatLevel,
    this.recommendations,
  });

  factory WilsonVertexChatResponse.fromJson(Map<String, dynamic> json) => 
    WilsonVertexChatResponse(
      response: json['response'] ?? '',
      messageId: json['messageId'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      sessionId: json['sessionId'] ?? '',
      threatLevel: json['threatLevel'],
      recommendations: json['recommendations']?.cast<String>(),
    );

  ThreatLevel get threatLevelEnum {
    switch (threatLevel?.toUpperCase()) {
      case 'CRITICAL':
        return ThreatLevel.critical;
      case 'HIGH':
        return ThreatLevel.high;
      case 'MEDIUM':
        return ThreatLevel.medium;
      case 'LOW':
        return ThreatLevel.low;
      default:
        return ThreatLevel.low;
    }
  }
}

/// African-focused threat intelligence
class AfricanThreatIntelligence {
  final String region;
  final List<CybersecurityThreat> threats;
  final int timestamp;
  final int expiresAt;

  const AfricanThreatIntelligence({
    required this.region,
    required this.threats,
    required this.timestamp,
    required this.expiresAt,
  });

  factory AfricanThreatIntelligence.fromJson(Map<String, dynamic> json) => 
    AfricanThreatIntelligence(
      region: json['region'] ?? 'africa',
      threats: (json['threats'] as List?)
        ?.map((t) => CybersecurityThreat.fromJson(t))
        .toList() ?? [],
      timestamp: json['timestamp'] ?? 0,
      expiresAt: json['expires_at'] ?? 0,
    );

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;
}

/// Cybersecurity threat definition
class CybersecurityThreat {
  final String category;
  final String severity;
  final String description;
  final String recommendation;

  const CybersecurityThreat({
    required this.category,
    required this.severity,
    required this.description,
    required this.recommendation,
  });

  factory CybersecurityThreat.fromJson(Map<String, dynamic> json) => 
    CybersecurityThreat(
      category: json['category'] ?? '',
      severity: json['severity'] ?? 'MEDIUM',
      description: json['description'] ?? '',
      recommendation: json['recommendation'] ?? '',
    );

  ThreatLevel get severityLevel {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return ThreatLevel.critical;
      case 'HIGH':
        return ThreatLevel.high;
      case 'MEDIUM':
        return ThreatLevel.medium;
      case 'LOW':
        return ThreatLevel.low;
      default:
        return ThreatLevel.medium;
    }
  }
}

/// Security training content
class SecurityTrainingContent {
  final String topic;
  final String level;
  final String language;
  final String content;
  final int generatedAt;
  final int expiresAt;

  const SecurityTrainingContent({
    required this.topic,
    required this.level,
    required this.language,
    required this.content,
    required this.generatedAt,
    required this.expiresAt,
  });

  factory SecurityTrainingContent.fromJson(Map<String, dynamic> json) => 
    SecurityTrainingContent(
      topic: json['topic'] ?? '',
      level: json['level'] ?? '',
      language: json['language'] ?? 'english',
      content: json['content'] ?? '',
      generatedAt: json['generated_at'] ?? 0,
      expiresAt: json['expires_at'] ?? 0,
    );

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;
}

/// Context type for Wilson AI interactions
enum WilsonContextType {
  chat,
  emergency,
  analysis,
}

/// Threat level enumeration
enum ThreatLevel {
  low,
  medium, 
  high,
  critical,
}

/// Training level enumeration
enum TrainingLevel {
  beginner,
  intermediate,
  advanced,
  expert,
}

/// Wilson AI exception class
class WilsonAIException implements Exception {
  final String message;
  
  const WilsonAIException(this.message);

  @override
  String toString() => 'WilsonAIException: $message';
}
import 'wilson_ai_vertex_service.dart' as vertex_ai;
import 'wilson_worker_client.dart';
import '../constants/wilson_worker.dart';

/// Wilson AI service.
///
/// Talks to the Wilson Cloudflare Worker (see `wilson-worker/`), which holds the
/// Claude API key, verifies the Firebase ID token, and proxies to Claude Haiku.
/// This replaces the old Firebase Cloud Functions path (which needs the paid
/// Blaze plan). Model classes and method signatures are unchanged, so callers
/// need no modifications.
class WilsonAIService {
  WilsonAIService({WilsonWorkerClient? client})
      : _client = client ?? WilsonWorkerClient();

  final WilsonWorkerClient _client;
  final vertex_ai.WilsonAIVertexService _vertexService =
      vertex_ai.WilsonAIVertexService();

  // Chat with Wilson AI (Claude Haiku via the Worker).
  Future<WilsonChatResponse> chatWithWilson({
    required List<ChatMessage> messages,
    String? sessionId,
  }) async {
    try {
      final lastMessage = messages.isNotEmpty ? messages.last.content : '';
      final contextType = _determineContextType(lastMessage);

      final data = await _client.post(WilsonWorkerConfig.chatPath, {
        'messages': messages.map((m) => m.toJson()).toList(),
        'sessionId': sessionId,
        'contextType': contextType.name,
      });

      return WilsonChatResponse.fromJson(data);
    } catch (e) {
      throw WilsonAIException('Failed to get response from Wilson AI: $e');
    }
  }

  // Determine appropriate context type from message content.
  vertex_ai.WilsonContextType _determineContextType(String message) {
    final lowerMessage = message.toLowerCase();

    final emergencyKeywords = [
      'hacked', 'compromised', 'stolen', 'fraud', 'scammed',
      'urgent', 'help', 'emergency', 'unauthorized', 'suspicious'
    ];
    final analysisKeywords = [
      'analyze', 'check', 'examine', 'scan', 'threat',
      'malware', 'virus', 'phishing', 'spam'
    ];

    if (emergencyKeywords.any((keyword) => lowerMessage.contains(keyword))) {
      return vertex_ai.WilsonContextType.emergency;
    } else if (analysisKeywords.any((keyword) => lowerMessage.contains(keyword))) {
      return vertex_ai.WilsonContextType.analysis;
    }
    return vertex_ai.WilsonContextType.chat;
  }

  // Analyze suspicious content.
  Future<ContentAnalysisResult> analyzeSuspiciousContent({
    required String content,
    String? contentType,
  }) async {
    try {
      final data = await _client.post(WilsonWorkerConfig.analyzePath, {
        'content': content,
        'contentType': contentType ?? 'text',
      });
      return ContentAnalysisResult.fromJson(data);
    } catch (e) {
      throw WilsonAIException('Failed to analyze content: $e');
    }
  }

  // Get daily cyber insights.
  Future<CyberInsightsResponse> getDailyCyberInsights() async {
    try {
      final data = await _client.post(WilsonWorkerConfig.insightsPath);
      return CyberInsightsResponse.fromJson(data);
    } catch (e) {
      throw WilsonAIException('Failed to get cyber insights: $e');
    }
  }

  // Create a new chat session.
  String generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Get African-specific threat intelligence.
  Future<vertex_ai.AfricanThreatIntelligence> getAfricanThreatIntelligence({
    String region = 'africa',
  }) async {
    try {
      final data = await _client.post(WilsonWorkerConfig.threatIntelPath, {
        'region': region,
      });
      return vertex_ai.AfricanThreatIntelligence.fromJson(data);
    } catch (e) {
      throw WilsonAIException('Failed to get African threat intelligence: $e');
    }
  }

  /// Generate customized security training content.
  Future<vertex_ai.SecurityTrainingContent> generateSecurityTraining({
    required String topic,
    required vertex_ai.TrainingLevel level,
    String language = 'english',
  }) async {
    try {
      final data = await _client.post(WilsonWorkerConfig.trainingPath, {
        'topic': topic,
        'level': level.name,
        'language': language,
      });
      return vertex_ai.SecurityTrainingContent.fromJson(data);
    } catch (e) {
      throw WilsonAIException('Failed to generate security training: $e');
    }
  }

  /// Analyze threat level of a message (client-side keyword pre-screen).
  vertex_ai.ThreatLevel analyzeMessageThreatLevel(String message) {
    return _vertexService.analyzeMessageThreatLevel(message);
  }

  /// Generate enhanced session ID with better tracking.
  String generateEnhancedSessionId() {
    return _vertexService.generateEnhancedSessionId();
  }
}

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  const ChatMessage({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    role: json['role'],
    content: json['content'],
  );
}

class WilsonChatResponse {
  final String response;
  final String messageId;
  final int timestamp;
  final String sessionId;

  const WilsonChatResponse({
    required this.response,
    required this.messageId,
    required this.timestamp,
    required this.sessionId,
  });

  factory WilsonChatResponse.fromJson(Map<String, dynamic> json) => WilsonChatResponse(
    response: json['response'] ?? '',
    messageId: json['messageId'] ?? '',
    timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
    sessionId: json['sessionId'] ?? '',
  );
}

class ContentAnalysisResult {
  final String threatLevel; // LOW, MEDIUM, HIGH, CRITICAL
  final List<String>? threatTypes;
  final List<String>? redFlags;
  final List<String>? recommendations;
  final String? analysis;
  final String analysisId;
  final int timestamp;

  const ContentAnalysisResult({
    required this.threatLevel,
    this.threatTypes,
    this.redFlags,
    this.recommendations,
    this.analysis,
    required this.analysisId,
    required this.timestamp,
  });

  factory ContentAnalysisResult.fromJson(Map<String, dynamic> json) => ContentAnalysisResult(
    threatLevel: json['threatLevel'] ?? 'UNKNOWN',
    threatTypes: json['threatTypes']?.cast<String>(),
    redFlags: json['redFlags']?.cast<String>(),
    recommendations: json['recommendations']?.cast<String>(),
    analysis: json['analysis'],
    analysisId: json['analysisId'] ?? '',
    timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
  );

  ThreatLevel get threatLevelEnum {
    switch (threatLevel.toUpperCase()) {
      case 'LOW':
        return ThreatLevel.low;
      case 'MEDIUM':
        return ThreatLevel.medium;
      case 'HIGH':
        return ThreatLevel.high;
      case 'CRITICAL':
        return ThreatLevel.critical;
      default:
        return ThreatLevel.unknown;
    }
  }
}

class CyberInsight {
  final String title;
  final String description;
  final String category;
  final String priority;
  final String actionableTip;

  const CyberInsight({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.actionableTip,
  });

  factory CyberInsight.fromJson(Map<String, dynamic> json) => CyberInsight(
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    category: json['category'] ?? 'general',
    priority: json['priority'] ?? 'medium',
    actionableTip: json['actionable_tip'] ?? '',
  );
}

class CyberInsightsResponse {
  final List<CyberInsight> insights;
  final int generatedAt;
  final int expiresAt;

  const CyberInsightsResponse({
    required this.insights,
    required this.generatedAt,
    required this.expiresAt,
  });

  factory CyberInsightsResponse.fromJson(Map<String, dynamic> json) => CyberInsightsResponse(
    insights: (json['insights'] as List?)
        ?.map((i) => CyberInsight.fromJson(i))
        .toList() ?? [],
    generatedAt: json['generated_at'] ?? 0,
    expiresAt: json['expires_at'] ?? 0,
  );

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;
}

enum ThreatLevel {
  low,
  medium,
  high,
  critical,
  unknown,
}

class WilsonAIException implements Exception {
  final String message;

  const WilsonAIException(this.message);

  @override
  String toString() => 'WilsonAIException: $message';
}

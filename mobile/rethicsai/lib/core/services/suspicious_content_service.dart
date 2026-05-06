import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'wilson_ai_service.dart';
import 'threat_scanner_service.dart' as threat;

class SuspiciousContentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WilsonAIService _wilsonAI = WilsonAIService();
  
  static const String _contentAnalysisCollection = 'content_analysis';
  static const String _suspiciousContentCollection = 'suspicious_content';
  
  // Analyze content for threats
  Future<ContentAnalysisResult> analyzeContent({
    required String content,
    required String contentType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Use Wilson AI to analyze content
      final analysisResult = await _wilsonAI.analyzeSuspiciousContent(
        content: content,
        contentType: contentType,
      );
      
      // Store analysis result for future reference
      await _storeAnalysisResult(analysisResult, content, contentType, metadata);
      
      return analysisResult;
    } catch (e) {
      // Fallback to local pattern matching
      return await _localContentAnalysis(content, contentType);
    }
  }
  
  // Store analysis results
  Future<void> _storeAnalysisResult(
    ContentAnalysisResult result,
    String content,
    String contentType,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      await _firestore.collection(_contentAnalysisCollection).doc(result.analysisId).set({
        'analysisId': result.analysisId,
        'content': content,
        'contentType': contentType,
        'threatLevel': result.threatLevel,
        'threatTypes': result.threatTypes,
        'redFlags': result.redFlags,
        'recommendations': result.recommendations,
        'analysis': result.analysis,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user?.uid,
        'metadata': metadata,
      });
      
      // If threat level is HIGH or CRITICAL, flag for review
      if (result.threatLevelEnum == threat.ThreatLevel.high || 
          result.threatLevelEnum == threat.ThreatLevel.critical) {
        await _flagForReview(result, content, contentType);
      }
    } catch (e) {
      print('Error storing analysis result: $e');
    }
  }
  
  // Flag high-threat content for admin review
  Future<void> _flagForReview(
    ContentAnalysisResult result,
    String content,
    String contentType,
  ) async {
    try {
      await _firestore.collection(_suspiciousContentCollection).add({
        'analysisId': result.analysisId,
        'content': _sanitizeContent(content), // Store sanitized version
        'contentType': contentType,
        'threatLevel': result.threatLevel,
        'threatTypes': result.threatTypes,
        'redFlags': result.redFlags,
        'flaggedAt': FieldValue.serverTimestamp(),
        'reviewStatus': 'pending',
        'reviewedBy': null,
        'reviewedAt': null,
        'actionTaken': null,
      });
    } catch (e) {
      print('Error flagging content for review: $e');
    }
  }
  
  // Local content analysis as fallback
  Future<ContentAnalysisResult> _localContentAnalysis(
    String content,
    String contentType,
  ) async {
    final threats = <String>[];
    final redFlags = <String>[];
    final recommendations = <String>[];
    threat.ThreatLevel threatLevel = threat.ThreatLevel.low;
    
    final lowerContent = content.toLowerCase();
    
    // Handle email address scanning specifically
    if (contentType == 'email') {
      return await _analyzeEmailAddress(content, threats, redFlags, recommendations);
    }
    
    // Handle text scanning - coming soon
    if (contentType == 'text') {
      return ContentAnalysisResult(
        threatLevel: 'UNKNOWN',
        threatTypes: ['Feature Coming Soon'],
        redFlags: ['Text scanning feature is under development'],
        recommendations: ['Text content analysis will be available soon', 'Please use other scanning options for now'],
        analysis: 'Text scanning feature coming soon',
        analysisId: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }
    
    // Common African scam patterns
    final africanScamPatterns = [
      'prince', 'inheritance', 'lottery', 'winner', 'million dollars',
      'bank transfer', 'urgent assistance', 'confidential business',
      'beneficiary', 'next of kin', 'diplomatic', 'consignment',
      'mpesa', 'mobile money', 'airtel money', 'western union',
      'bitcoin investment', 'forex trading', 'quick money',
    ];
    
    // Phishing patterns
    final phishingPatterns = [
      'verify account', 'suspend account', 'click here immediately',
      'urgent security alert', 'update payment info', 'confirm identity',
      'your account will be closed', 'temporary suspension',
    ];
    
    // Romance scam patterns
    final romanceScamPatterns = [
      'deployed overseas', 'military officer', 'widowed',
      'need money for', 'stuck in', 'customs fee', 'medical emergency',
      'love you', 'soulmate', 'destiny', 'meant to be',
    ];
    
    // Check for African-specific scam patterns
    for (final pattern in africanScamPatterns) {
      if (lowerContent.contains(pattern)) {
        threats.add('African Advance Fee Fraud (419 Scam)');
        redFlags.add('Contains suspicious keyword: $pattern');
        threatLevel = threat.ThreatLevel.high;
      }
    }
    
    // Check for phishing patterns
    for (final pattern in phishingPatterns) {
      if (lowerContent.contains(pattern)) {
        threats.add('Phishing Attempt');
        redFlags.add('Phishing indicator: $pattern');
        if (threatLevel == threat.ThreatLevel.low) threatLevel = threat.ThreatLevel.medium;
      }
    }
    
    // Check for romance scam patterns
    for (final pattern in romanceScamPatterns) {
      if (lowerContent.contains(pattern)) {
        threats.add('Romance Scam');
        redFlags.add('Romance scam indicator: $pattern');
        if (threatLevel == threat.ThreatLevel.low) threatLevel = threat.ThreatLevel.medium;
      }
    }
    
    // Check for suspicious URLs
    final urlRegex = RegExp(r'https?://[^\s]+');
    final urls = urlRegex.allMatches(content);
    for (final url in urls) {
      final urlString = url.group(0) ?? '';
      if (_isSuspiciousUrl(urlString)) {
        threats.add('Suspicious URL');
        redFlags.add('Suspicious link detected');
        if (threatLevel == threat.ThreatLevel.low) threatLevel = threat.ThreatLevel.medium;
      }
    }
    
    // Generate recommendations
    if (threats.isNotEmpty) {
      recommendations.addAll([
        'Do not respond to this message',
        'Do not click any links or download attachments',
        'Do not provide personal or financial information',
        'Report this content to authorities if requested money',
        'Block the sender immediately',
      ]);
    } else {
      recommendations.add('Content appears safe, but always remain vigilant online');
    }
    
    return ContentAnalysisResult(
      threatLevel: threatLevel.name.toUpperCase(),
      threatTypes: threats,
      redFlags: redFlags,
      recommendations: recommendations,
      analysis: 'Local pattern-based analysis completed',
      analysisId: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }
  
  // Check if URL is suspicious
  bool _isSuspiciousUrl(String url) {
    final suspiciousDomains = [
      'bit.ly', 'tinyurl.com', 'goo.gl', 'ow.ly',
      'clickhere', 'freebie', 'winner', 'claim',
    ];
    
    final lowerUrl = url.toLowerCase();
    return suspiciousDomains.any((domain) => lowerUrl.contains(domain));
  }
  
  // Sanitize content for storage (remove sensitive info)
  String _sanitizeContent(String content) {
    // Remove potential personal information patterns
    var sanitized = content;
    
    // Remove phone numbers
    sanitized = sanitized.replaceAll(RegExp(r'\+?[\d\s\-\(\)]{10,}'), '[PHONE_REDACTED]');
    
    // Remove email addresses
    sanitized = sanitized.replaceAll(RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), '[EMAIL_REDACTED]');
    
    // Remove potential account numbers or IDs
    sanitized = sanitized.replaceAll(RegExp(r'\b\d{8,}\b'), '[NUMBER_REDACTED]');
    
    return sanitized;
  }
  
  // Get analysis history for current user
  Future<List<ContentAnalysisResult>> getUserAnalysisHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];
      
      final querySnapshot = await _firestore
          .collection(_contentAnalysisCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ContentAnalysisResult.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting analysis history: $e');
      return [];
    }
  }
  
  // Get threat statistics
  Future<ThreatStatistics> getThreatStatistics() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const ThreatStatistics(
          totalAnalyses: 0,
          lowThreats: 0,
          mediumThreats: 0,
          highThreats: 0,
          criticalThreats: 0,
        );
      }
      
      final querySnapshot = await _firestore
          .collection(_contentAnalysisCollection)
          .where('userId', isEqualTo: user.uid)
          .get();
      
      int totalAnalyses = querySnapshot.docs.length;
      int lowThreats = 0;
      int mediumThreats = 0;
      int highThreats = 0;
      int criticalThreats = 0;
      
      for (final doc in querySnapshot.docs) {
        final threatLevel = doc.data()['threatLevel'] as String?;
        switch (threatLevel?.toUpperCase()) {
          case 'LOW':
            lowThreats++;
            break;
          case 'MEDIUM':
            mediumThreats++;
            break;
          case 'HIGH':
            highThreats++;
            break;
          case 'CRITICAL':
            criticalThreats++;
            break;
        }
      }
      
      return ThreatStatistics(
        totalAnalyses: totalAnalyses,
        lowThreats: lowThreats,
        mediumThreats: mediumThreats,
        highThreats: highThreats,
        criticalThreats: criticalThreats,
      );
    } catch (e) {
      print('Error getting threat statistics: $e');
      return const ThreatStatistics(
        totalAnalyses: 0,
        lowThreats: 0,
        mediumThreats: 0,
        highThreats: 0,
        criticalThreats: 0,
      );
    }
  }

  // Analyze email address for threats
  Future<ContentAnalysisResult> _analyzeEmailAddress(
    String emailAddress,
    List<String> threats,
    List<String> redFlags,
    List<String> recommendations,
  ) async {
    threat.ThreatLevel threatLevel = threat.ThreatLevel.low;
    
    final email = emailAddress.trim().toLowerCase();
    
    // Check for valid email format
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      threats.add('Invalid Email Format');
      redFlags.add('Email address format is invalid');
      threatLevel = threat.ThreatLevel.medium;
    }
    
    // Suspicious domain indicators
    final suspiciousDomains = [
      '.tk', '.ml', '.ga', '.cf', '.top', '.xyz', '.click', '.download',
      'tempmail', 'guerrillamail', '10minutemail', 'mailinator',
      'throwaway', 'disposable', 'tempinbox'
    ];
    
    // Check for suspicious domain extensions and temporary email services
    for (final suspiciousDomain in suspiciousDomains) {
      if (email.contains(suspiciousDomain)) {
        threats.add('Suspicious Domain');
        redFlags.add('Email uses suspicious or temporary domain: $suspiciousDomain');
        threatLevel = threat.ThreatLevel.high;
      }
    }
    
    // Check for typosquatting of popular email providers
    final legitimateDomains = ['gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com'];
    final emailDomain = email.split('@').last;
    
    for (final legitDomain in legitimateDomains) {
      // Check for character substitutions (e.g., gmai1.com instead of gmail.com)
      if (_isTyposquattingDomain(emailDomain, legitDomain)) {
        threats.add('Domain Spoofing');
        redFlags.add('Email domain may be impersonating $legitDomain');
        threatLevel = threat.ThreatLevel.high;
      }
    }
    
    // Check for suspicious patterns in email address
    final suspiciousPatterns = [
      'noreply', 'support', 'admin', 'service', 'security', 'account',
      'verification', 'notification', 'update', 'alert'
    ];
    
    final emailLocalPart = email.split('@').first;
    for (final pattern in suspiciousPatterns) {
      if (emailLocalPart.contains(pattern) && !_isFromLegitimateProvider(emailDomain)) {
        threats.add('Impersonation Attempt');
        redFlags.add('Email may be impersonating official accounts: $pattern');
        if (threatLevel == threat.ThreatLevel.low) threatLevel = threat.ThreatLevel.medium;
      }
    }
    
    // Generate appropriate recommendations
    if (threats.isNotEmpty) {
      recommendations.addAll([
        'Be cautious when interacting with this email address',
        'Verify sender identity through alternative means',
        'Do not provide personal or financial information',
        'Check for official communications through legitimate channels',
      ]);
      
      if (threatLevel == threat.ThreatLevel.high) {
        recommendations.addAll([
          'Consider blocking this email address',
          'Report as suspicious if used in scam attempts',
          'Do not click any links from this sender',
        ]);
      }
    } else {
      recommendations.add('Email address appears legitimate, but always exercise caution online');
      threatLevel = threat.ThreatLevel.low;
    }
    
    return ContentAnalysisResult(
      threatLevel: threatLevel.name.toUpperCase(),
      threatTypes: threats,
      redFlags: redFlags,
      recommendations: recommendations,
      analysis: 'Email address analysis completed - focusing on domain reputation and impersonation detection',
      analysisId: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }
  
  // Check if domain is attempting typosquatting
  bool _isTyposquattingDomain(String domain, String legitimateDomain) {
    // Simple Levenshtein distance check for typosquatting
    if (domain == legitimateDomain) return false;
    
    // Check for single character substitutions
    if (domain.length == legitimateDomain.length) {
      int differences = 0;
      for (int i = 0; i < domain.length; i++) {
        if (domain[i] != legitimateDomain[i]) {
          differences++;
          if (differences > 1) break;
        }
      }
      return differences == 1;
    }
    
    // Check for single character insertions/deletions
    if ((domain.length - legitimateDomain.length).abs() == 1) {
      final shorter = domain.length < legitimateDomain.length ? domain : legitimateDomain;
      final longer = domain.length > legitimateDomain.length ? domain : legitimateDomain;
      
      for (int i = 0; i < shorter.length; i++) {
        if (shorter.substring(0, i) + shorter.substring(i + 1) == 
            longer.substring(0, i) + longer.substring(i + 2)) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  // Check if domain is from a legitimate email provider
  bool _isFromLegitimateProvider(String domain) {
    final legitimateProviders = [
      'gmail.com', 'googlemail.com', 'yahoo.com', 'ymail.com', 'yahoo.co.uk',
      'hotmail.com', 'outlook.com', 'live.com', 'msn.com',
      'icloud.com', 'me.com', 'mac.com',
      'aol.com', 'zoho.com', 'protonmail.com'
    ];
    
    return legitimateProviders.contains(domain.toLowerCase());
  }
}

class ThreatStatistics {
  final int totalAnalyses;
  final int lowThreats;
  final int mediumThreats;
  final int highThreats;
  final int criticalThreats;
  
  const ThreatStatistics({
    required this.totalAnalyses,
    required this.lowThreats,
    required this.mediumThreats,
    required this.highThreats,
    required this.criticalThreats,
  });
  
  double get threatScore {
    if (totalAnalyses == 0) return 0.0;
    
    final weightedScore = 
        (lowThreats * 1) +
        (mediumThreats * 2) +
        (highThreats * 4) +
        (criticalThreats * 8);
    
    return weightedScore / (totalAnalyses * 8); // Normalize to 0-1
  }
  
  String get overallRiskLevel {
    if (threatScore >= 0.75) return 'CRITICAL';
    if (threatScore >= 0.5) return 'HIGH';
    if (threatScore >= 0.25) return 'MEDIUM';
    return 'LOW';
  }
}
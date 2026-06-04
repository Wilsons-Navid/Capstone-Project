import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../constants/app_constants.dart';
import '../config/api_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'threat_management_service.dart';
import 'suspicious_content_service.dart';
import 'scam_model_service.dart';
import 'detected_threat_service.dart';

class ThreatScannerService {
  final Dio _dio = Dio();
  final ThreatManagementService _threatManagementService = ThreatManagementService();
  final ScamModelService _scamModel = ScamModelService();
  final DetectedThreatService _detectedThreats = DetectedThreatService();
  
  // Comprehensive scanning method that combines all detection sources
  Future<ScanResult> comprehensiveScan(String input, ScanType type) async {
    switch (type) {
      case ScanType.url:
        return await scanUrl(input);
      case ScanType.email:
        return await scanEmailContent(input);
      case ScanType.phone:
        return await scanPhoneNumber(input);
      case ScanType.text:
        return await scanTextContent(input);
      case ScanType.file:
        return await scanFileHash(input);
    }
  }
  
  // Enhanced URL scanning that shows dual detection system status
  Future<Map<String, ScanResult>> dualUrlScan(String url) async {
    final results = <String, ScanResult>{};
    
    try {
      // Firestore database check
      final verifiedThreat = await _threatManagementService.findThreatByValue(url, ThreatContentType.url);
      if (verifiedThreat != null) {
        results['firestore'] = ScanResult(
          type: ScanType.url,
          input: url,
          threatLevel: _mapRiskLevelToThreatLevel(verifiedThreat.threatLevel),
          isComplete: true,
          result: 'Found in admin-verified threats database',
          recommendations: verifiedThreat.recommendations,
          threatCategories: [verifiedThreat.category],
          details: {'detection_source': 'firestore_db', 'admin_verified': true},
        );
      } else {
        results['firestore'] = ScanResult(
          type: ScanType.url,
          input: url,
          threatLevel: ThreatLevel.safe,
          isComplete: true,
          result: 'Not found in verified threats database',
          recommendations: ['URL not in local threat database'],
          details: {'detection_source': 'firestore_db', 'admin_verified': false},
        );
      }
      
      // VirusTotal API check
      try {
        final vtResult = await _virusTotalUrlScan(url);
        results['virustotal'] = vtResult;
      } catch (e) {
        results['virustotal'] = ScanResult(
          type: ScanType.url,
          input: url,
          threatLevel: ThreatLevel.unknown,
          isComplete: true,
          result: 'VirusTotal scan failed',
          recommendations: ['External threat intelligence unavailable'],
          details: {'detection_source': 'virustotal_api', 'error': e.toString()},
        );
      }
      
    } catch (e) {
      results['error'] = ScanResult(
        type: ScanType.url,
        input: url,
        threatLevel: ThreatLevel.unknown,
        isComplete: true,
        result: 'Dual scan failed: $e',
        recommendations: ['Try scanning again'],
      );
    }
    
    return results;
  }
  
  // VirusTotal API configuration - now using secure configuration
  static String? _cachedApiKey;
  
  static Future<String> get _virusTotalApiKey async {
    _cachedApiKey ??= await ApiConfig.getVirusTotalApiKey();
    return _cachedApiKey ?? '';
  }
  
  static String get _virusTotalBaseUrl => ApiConfig.getEndpoint('virustotal_base');
  
  // URL Scanner
  Future<ScanResult> scanUrl(String url) async {
    try {
      // Basic URL validation
      final uri = Uri.tryParse(url);
      if (uri == null || (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https'))) {
        return ScanResult(
          type: ScanType.url,
          input: url,
          threatLevel: ThreatLevel.safe,
          isComplete: true,
          result: 'Invalid URL format',
          recommendations: ['Please enter a valid URL starting with http:// or https://'],
        );
      }

      // First, check against verified threats database (Firestore)
      final verifiedThreat = await _threatManagementService.findThreatByValue(url, ThreatContentType.url);
      if (verifiedThreat != null) {
        return ScanResult(
          type: ScanType.url,
          input: url,
          threatLevel: _mapRiskLevelToThreatLevel(verifiedThreat.threatLevel),
          isComplete: true,
          result: 'FIRESTORE DB: This URL has been identified as fraudulent in our verified threats database: ${verifiedThreat.description}',
          recommendations: verifiedThreat.recommendations,
          threatCategories: [verifiedThreat.category],
          details: {
            'detection_source': 'firestore_verified_threats',
            'threat_id': verifiedThreat.id,
            'admin_verified': true,
          },
        );
      }

      // Check against comprehensive threat database
      final threatAnalysis = await _analyzeThreatFromDatabase(url, ThreatType.url);
      if (threatAnalysis.isThreat) {
        return ScanResult(
          type: ScanType.url,
          input: url,
          threatLevel: threatAnalysis.threatLevel,
          isComplete: true,
          result: threatAnalysis.description,
          recommendations: threatAnalysis.recommendations,
          threatCategories: threatAnalysis.categories,
        );
      }

      // Check for suspicious TLDs and domains
      final suspiciousResult = _checkSuspiciousDomain(uri.host);
      if (suspiciousResult != null) {
        return suspiciousResult.copyWith(input: url, type: ScanType.url);
      }

      // Use real VirusTotal API
      final scanResult = await _virusTotalUrlScan(url);
      
      return scanResult;
    } catch (e) {
      return ScanResult(
        type: ScanType.url,
        input: url,
        threatLevel: ThreatLevel.unknown,
        isComplete: true,
        result: 'Scan failed: $e',
        recommendations: ['Try scanning again', 'Check your internet connection'],
      );
    }
  }

  // Email Address Scanner
  Future<ScanResult> scanEmailAddress(String emailAddress) async {
    try {
      final threats = <String>[];
      final recommendations = <String>[];

      // First, check against verified threats database for email addresses
      final verifiedThreat = await _threatManagementService.findThreatByValue(emailAddress, ThreatContentType.email);
      if (verifiedThreat != null) {
        return ScanResult(
          type: ScanType.email,
          input: emailAddress,
          threatLevel: _mapRiskLevelToThreatLevel(verifiedThreat.threatLevel),
          isComplete: true,
          result: 'This email address has been identified as fraudulent in our database: ${verifiedThreat.description}',
          recommendations: verifiedThreat.recommendations,
          threatCategories: [verifiedThreat.category],
        );
      }

      // Use the SuspiciousContentService for detailed email address analysis
      final suspiciousContentService = SuspiciousContentService();
      final analysisResult = await suspiciousContentService.analyzeContent(
        content: emailAddress,
        contentType: 'email',
      );

      // Convert ContentAnalysisResult to ScanResult
      return ScanResult(
        type: ScanType.email,
        input: emailAddress,
        threatLevel: _mapStringToThreatLevel(analysisResult.threatLevel),
        isComplete: true,
        result: analysisResult.analysis ?? 'Email address analysis completed',
        recommendations: analysisResult.recommendations ?? [],
        threatCategories: analysisResult.threatTypes ?? [],
      );

    } catch (e) {
      return ScanResult(
        type: ScanType.email,
        input: emailAddress,
        threatLevel: ThreatLevel.unknown,
        isComplete: true,
        result: 'Email address scan failed: $e',
        recommendations: ['Try scanning again', 'Check your internet connection'],
      );
    }
  }

  // Email Content Scanner
  Future<ScanResult> scanEmailContent(String content) async {
    try {
      final threats = <String>[];
      final recommendations = <String>[];

      // First, check against verified threats database
      final verifiedThreat = await _threatManagementService.findThreatByValue(content, ThreatContentType.email);
      if (verifiedThreat != null) {
        return ScanResult(
          type: ScanType.email,
          input: content,
          threatLevel: _mapRiskLevelToThreatLevel(verifiedThreat.threatLevel),
          isComplete: true,
          result: 'This email content has been identified as fraudulent in our database: ${verifiedThreat.description}',
          recommendations: verifiedThreat.recommendations,
          threatCategories: [verifiedThreat.category],
        );
      }
      
      // Check for phishing indicators
      final phishingPatterns = _getPhishingPatterns();
      for (final pattern in phishingPatterns) {
        if (content.toLowerCase().contains(pattern.toLowerCase())) {
          threats.add('Phishing indicator: $pattern');
        }
      }
      
      // Check for suspicious links
      final urlRegex = RegExp(r'https?://[^\s]+');
      final urls = urlRegex.allMatches(content);
      for (final match in urls) {
        final url = content.substring(match.start, match.end);
        final urlScan = await scanUrl(url);
        if (urlScan.threatLevel == ThreatLevel.high || urlScan.threatLevel == ThreatLevel.critical) {
          threats.add('Suspicious URL found: $url');
        }
      }
      
      // Check for social engineering tactics
      final socialEngineeringPatterns = _getSocialEngineeringPatterns();
      for (final pattern in socialEngineeringPatterns) {
        if (content.toLowerCase().contains(pattern.toLowerCase())) {
          threats.add('Social engineering tactic: $pattern');
        }
      }
      
      // Determine threat level
      ThreatLevel threatLevel;
      if (threats.isEmpty) {
        threatLevel = ThreatLevel.safe;
        recommendations.add('Email content appears safe');
      } else if (threats.length <= 2) {
        threatLevel = ThreatLevel.low;
        recommendations.addAll([
          'Be cautious with this email',
          'Verify sender identity',
          'Do not click suspicious links'
        ]);
      } else if (threats.length <= 4) {
        threatLevel = ThreatLevel.medium;
        recommendations.addAll([
          'This email is likely suspicious',
          'Do not respond or click any links',
          'Consider reporting as spam'
        ]);
      } else {
        threatLevel = ThreatLevel.critical;
        recommendations.addAll([
          'This email is highly suspicious',
          'Delete immediately',
          'Report to IT/Security team',
          'Check for similar emails'
        ]);
      }
      
      return ScanResult(
        type: ScanType.email,
        input: content,
        threatLevel: threatLevel,
        isComplete: true,
        result: threats.isEmpty ? 'No threats detected' : 'Threats found: ${threats.join(', ')}',
        recommendations: recommendations,
        details: threats.isNotEmpty ? {'threats': threats} : null,
      );
    } catch (e) {
      return ScanResult(
        type: ScanType.email,
        input: content,
        threatLevel: ThreatLevel.unknown,
        isComplete: true,
        result: 'Scan failed: $e',
        recommendations: ['Try scanning again'],
      );
    }
  }

  // Phone Number Scanner
  Future<ScanResult> scanPhoneNumber(String phoneNumber) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final threats = <String>[];
      final recommendations = <String>[];

      // First, check against verified threats database
      final verifiedThreat = await _threatManagementService.findThreatByValue(phoneNumber, ThreatContentType.phone);
      if (verifiedThreat != null) {
        return ScanResult(
          type: ScanType.phone,
          input: phoneNumber,
          threatLevel: _mapRiskLevelToThreatLevel(verifiedThreat.threatLevel),
          isComplete: true,
          result: 'This phone number has been identified as fraudulent in our database: ${verifiedThreat.description}',
          recommendations: verifiedThreat.recommendations,
          threatCategories: [verifiedThreat.category],
        );
      }
      
      // Check format validity
      if (!_isValidPhoneNumber(cleanNumber)) {
        return ScanResult(
          type: ScanType.phone,
          input: phoneNumber,
          threatLevel: ThreatLevel.low,
          isComplete: true,
          result: 'Invalid phone number format',
          recommendations: ['Verify the phone number format', 'Be cautious of incorrectly formatted numbers'],
        );
      }
      
      // Check against known scam patterns
      final scamPatterns = _getScamPhonePatterns();
      for (final pattern in scamPatterns) {
        if (cleanNumber.contains(pattern)) {
          threats.add('Matches known scam pattern');
        }
      }
      
      // Check country code and prefix patterns
      final suspiciousCountryCodes = ['234', '233', '254']; // Common scam origins
      for (final code in suspiciousCountryCodes) {
        if (cleanNumber.startsWith('+$code') && _hasMultipleConsecutiveDigits(cleanNumber)) {
          threats.add('Suspicious pattern from high-risk country code');
        }
      }
      
      // Check for premium rate numbers
      if (_isPremiumRateNumber(cleanNumber)) {
        threats.add('Premium rate number detected');
        recommendations.add('Calling this number may incur high charges');
      }
      
      ThreatLevel threatLevel;
      if (threats.isEmpty) {
        threatLevel = ThreatLevel.safe;
        recommendations.add('Phone number appears legitimate');
      } else if (threats.length == 1) {
        threatLevel = ThreatLevel.low;
        recommendations.addAll([
          'Exercise caution',
          'Verify caller identity',
          'Do not provide personal information'
        ]);
      } else {
        threatLevel = ThreatLevel.high;
        recommendations.addAll([
          'High risk phone number',
          'Do not answer or call back',
          'Block this number',
          'Report to authorities if harassment occurs'
        ]);
      }
      
      return ScanResult(
        type: ScanType.phone,
        input: phoneNumber,
        threatLevel: threatLevel,
        isComplete: true,
        result: threats.isEmpty ? 'No threats detected' : 'Threats found: ${threats.join(', ')}',
        recommendations: recommendations,
        details: threats.isNotEmpty ? {'threats': threats} : null,
      );
    } catch (e) {
      return ScanResult(
        type: ScanType.phone,
        input: phoneNumber,
        threatLevel: ThreatLevel.unknown,
        isComplete: true,
        result: 'Scan failed: $e',
        recommendations: ['Try scanning again'],
      );
    }
  }

  // File Hash Scanner (for checking file hashes against VirusTotal)
  Future<ScanResult> scanFileHash(String fileHash, {String? fileName}) async {
    try {
      // First, check against verified threats database
      final verifiedThreat = await _threatManagementService.findThreatByValue(fileHash, ThreatContentType.file);
      if (verifiedThreat != null) {
        return ScanResult(
          type: ScanType.file,
          input: fileName ?? fileHash,
          threatLevel: _mapRiskLevelToThreatLevel(verifiedThreat.threatLevel),
          isComplete: true,
          result: 'This file hash has been identified as malicious in our database: ${verifiedThreat.description}',
          recommendations: verifiedThreat.recommendations,
          threatCategories: [verifiedThreat.category],
        );
      }

      // Use VirusTotal API for file hash scanning
      final scanResult = await _virusTotalFileHashScan(fileHash, fileName);
      return scanResult;
    } catch (e) {
      return ScanResult(
        type: ScanType.file,
        input: fileName ?? fileHash,
        threatLevel: ThreatLevel.unknown,
        isComplete: true,
        result: 'File hash scan failed: $e',
        recommendations: ['Try scanning again', 'Check hash format'],
      );
    }
  }

  // Text Content Scanner
  Future<ScanResult> scanTextContent(String content) async {
    try {
      final threats = <String>[];
      final recommendations = <String>[];

      // First, check against verified threats database
      final verifiedThreat = await _threatManagementService.findThreatByValue(content, ThreatContentType.text);
      if (verifiedThreat != null) {
        return ScanResult(
          type: ScanType.text,
          input: content,
          threatLevel: _mapRiskLevelToThreatLevel(verifiedThreat.threatLevel),
          isComplete: true,
          result: 'This text content has been identified as fraudulent in our database: ${verifiedThreat.description}',
          recommendations: verifiedThreat.recommendations,
          threatCategories: [verifiedThreat.category],
        );
      }
      
      // Check for malware-related content
      final malwareKeywords = _getMalwareKeywords();
      for (final keyword in malwareKeywords) {
        if (content.toLowerCase().contains(keyword.toLowerCase())) {
          threats.add('Malware-related keyword: $keyword');
        }
      }
      
      // Check for scam indicators
      final scamPhrases = _getScamPhrases();
      for (final phrase in scamPhrases) {
        if (content.toLowerCase().contains(phrase.toLowerCase())) {
          threats.add('Scam phrase: $phrase');
        }
      }
      
      // Check for personal information harvesting
      final personalInfoPatterns = _getPersonalInfoPatterns();
      for (final pattern in personalInfoPatterns) {
        if (content.toLowerCase().contains(pattern.toLowerCase())) {
          threats.add('Personal information request: $pattern');
        }
      }

      // AI semantic classifier — the project's e5 + ensemble model. Language-agnostic
      // (English / French / Portuguese + more), so it catches scams the keyword lists
      // above miss. Best-effort: returns null when unreachable/unconfigured, leaving the
      // heuristic checks as the fallback.
      final modelResult = await _scamModel.classify(content);
      final threatCategories = <String>[];
      if (modelResult != null && !modelResult.isSafe) {
        threatCategories.add(modelResult.category);
        threats.add(
          '${'scanner.ai_model'.tr()}: ${'scanner.cat_${modelResult.category}'.tr()} '
          '(${(modelResult.confidence * 100).round()}% ${'scanner.confidence_pct'.tr()})',
        );
      }

      ThreatLevel threatLevel;
      if (threats.isEmpty) {
        threatLevel = ThreatLevel.safe;
        recommendations.add('scanner.rec_safe'.tr());
      } else if (threats.length <= 2) {
        threatLevel = ThreatLevel.medium;
        recommendations.addAll([
          'scanner.rec_suspicious_elements'.tr(),
          'scanner.rec_no_personal_info'.tr(),
          'scanner.rec_verify_sender'.tr(),
        ]);
      } else {
        threatLevel = ThreatLevel.high;
        recommendations.addAll([
          'scanner.rec_high_risk'.tr(),
          'scanner.rec_no_engage'.tr(),
          'scanner.rec_report_fraud'.tr(),
          'scanner.rec_delete'.tr(),
        ]);
      }

      // Let the model's confidence escalate the level when it flags a scam.
      if (modelResult != null && !modelResult.isSafe) {
        final modelLevel = modelResult.confidence >= 0.85
            ? ThreatLevel.high
            : modelResult.confidence >= 0.6
                ? ThreatLevel.medium
                : ThreatLevel.low;
        threatLevel = _maxThreatLevel(threatLevel, modelLevel);
      }

      final details = <String, dynamic>{};
      if (threats.isNotEmpty) details['threats'] = threats;
      if (modelResult != null) {
        details['ai_model'] = {
          'category': modelResult.category,
          'confidence': modelResult.confidence,
          'scores': modelResult.scores,
        };
      }

      // Persist model-detected scams for the admin dashboard (best-effort).
      if (modelResult != null && !modelResult.isSafe) {
        _detectedThreats.record(
          content: content,
          category: modelResult.category,
          confidence: modelResult.confidence,
          threatLevel: threatLevel.name,
          scores: modelResult.scores,
          source: 'text_scan',
        );
      }

      return ScanResult(
        type: ScanType.text,
        input: content,
        threatLevel: threatLevel,
        isComplete: true,
        result: threats.isEmpty
            ? 'scanner.no_threats'.tr()
            : '${'scanner.threats_found'.tr()}: ${threats.join(', ')}',
        recommendations: recommendations,
        threatCategories: threatCategories.isNotEmpty ? threatCategories : null,
        details: details.isNotEmpty ? details : null,
      );
    } catch (e) {
      return ScanResult(
        type: ScanType.text,
        input: content,
        threatLevel: ThreatLevel.unknown,
        isComplete: true,
        result: 'Scan failed: $e',
        recommendations: ['Try scanning again'],
      );
    }
  }

  // Returns the more severe of two threat levels.
  ThreatLevel _maxThreatLevel(ThreatLevel a, ThreatLevel b) {
    const rank = {
      ThreatLevel.unknown: 0,
      ThreatLevel.safe: 1,
      ThreatLevel.low: 2,
      ThreatLevel.medium: 3,
      ThreatLevel.high: 4,
      ThreatLevel.critical: 5,
    };
    return (rank[a] ?? 0) >= (rank[b] ?? 0) ? a : b;
  }

  // Helper methods for pattern matching
  List<String> _getMaliciousUrlPatterns() {
    return [
      'bit.ly', 'tinyurl', 'goo.gl', 't.co', // URL shorteners often used in phishing
      'secure-update', 'account-verification', 'security-alert',
      'click-here', 'verify-now', 'urgent-action',
      'phishing', 'malware', 'virus',
      'free-money', 'lottery-winner', 'congratulations-winner'
    ];
  }

  ScanResult? _checkSuspiciousDomain(String? domain) {
    if (domain == null) return null;
    
    final suspiciousTlds = ['.tk', '.ml', '.ga', '.cf', '.top'];
    final suspiciousKeywords = ['paypal', 'amazon', 'microsoft', 'google', 'apple', 'facebook'];
    
    for (final tld in suspiciousTlds) {
      if (domain.endsWith(tld)) {
        return ScanResult(
          type: ScanType.url,
          input: domain,
          threatLevel: ThreatLevel.medium,
          isComplete: true,
          result: 'Suspicious top-level domain: $tld',
          recommendations: [
            'Be cautious with websites using this domain extension',
            'Verify the legitimacy of the website',
            'Check for official company domains'
          ],
        );
      }
    }
    
    for (final keyword in suspiciousKeywords) {
      if (domain.toLowerCase().contains(keyword) && !domain.toLowerCase().contains('$keyword.com')) {
        return ScanResult(
          type: ScanType.url,
          input: domain,
          threatLevel: ThreatLevel.high,
          isComplete: true,
          result: 'Potential domain spoofing detected',
          recommendations: [
            'This may be a fake website imitating $keyword',
            'Always use official websites',
            'Check the URL carefully for misspellings'
          ],
        );
      }
    }
    
    return null;
  }

  // Real VirusTotal API URL scanning
  Future<ScanResult> _virusTotalUrlScan(String url) async {
    try {
      // Check rate limits
      if (!ApiRateLimiter.canMakeRequest('virustotal')) {
        return ScanResult(
          type: ScanType.url,
          input: url,
          threatLevel: ThreatLevel.unknown,
          isComplete: true,
          result: 'Rate limit exceeded. Please try again later.',
          recommendations: ['Wait before making another request'],
        );
      }

      // Configure Dio with secure headers
      final dio = Dio();
      final apiKey = await _virusTotalApiKey;
      if (apiKey.isEmpty) {
        throw SecurityException('VirusTotal API key not configured');
      }
      
      dio.options.headers.addAll({
        'x-apikey': apiKey,
        ...ApiConfig.getSecurityHeaders(),
      });
      
      // Record API request for rate limiting
      ApiRateLimiter.recordRequest('virustotal');
      
      // URL-safe base64 encode the URL for VirusTotal v3 API
      final encodedUrl = base64Url.encode(utf8.encode(url)).replaceAll('=', '');
      
      // Get URL analysis from VirusTotal
      final response = await dio.get(
        '$_virusTotalBaseUrl/urls/$encodedUrl',
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        final attributes = data['attributes'];
        final lastAnalysisStats = attributes['last_analysis_stats'];
        
        final maliciousCount = lastAnalysisStats['malicious'] ?? 0;
        final suspiciousCount = lastAnalysisStats['suspicious'] ?? 0;
        final totalEngines = lastAnalysisStats['total'] ?? 0;
        
        // Determine threat level based on detection results
        ThreatLevel threatLevel;
        String result;
        List<String> recommendations;
        
        if (maliciousCount > 0) {
          threatLevel = maliciousCount >= 5 ? ThreatLevel.critical : ThreatLevel.high;
          result = 'VIRUSTOTAL: Detected as malicious by $maliciousCount/$totalEngines security vendors';
          recommendations = [
            'Do not visit this website',
            'The URL is flagged as malicious by VirusTotal security vendors',
            'Report if received via email or message',
            'Check for similar suspicious communications',
            'This threat was detected by external threat intelligence'
          ];
        } else if (suspiciousCount > 0) {
          threatLevel = ThreatLevel.medium;
          result = 'VIRUSTOTAL: Flagged as suspicious by $suspiciousCount/$totalEngines security vendors';
          recommendations = [
            'Proceed with extreme caution',
            'Verify the website legitimacy through official channels',
            'Use additional security measures if accessing',
            'Consider using a sandbox environment',
            'This threat was detected by external threat intelligence'
          ];
        } else {
          threatLevel = ThreatLevel.safe;
          result = 'VIRUSTOTAL: No threats detected ($totalEngines vendors checked)';
          recommendations = [
            'URL appears safe according to VirusTotal external scan',
            'Still exercise normal web browsing caution'
          ];
        }
        
        return ScanResult(
          type: ScanType.url,
          input: url,
          threatLevel: threatLevel,
          isComplete: true,
          result: result,
          recommendations: recommendations,
          details: {
            'detection_source': 'virustotal_api',
            'malicious_count': maliciousCount,
            'suspicious_count': suspiciousCount,
            'total_engines': totalEngines,
            'scan_date': attributes['last_analysis_date'],
            'external_intelligence': true,
          },
        );
      } else {
        // If URL not found in VirusTotal, submit for analysis
        return await _submitUrlToVirusTotal(url);
      }
    } catch (e) {
      // Fallback to local analysis if VirusTotal fails
      if (kDebugMode) {
        print('VirusTotal API error: $e');
      }
      
      return ScanResult(
        type: ScanType.url,
        input: url,
        threatLevel: ThreatLevel.unknown,
        isComplete: true,
        result: 'VirusTotal scan unavailable, using local analysis',
        recommendations: [
          'External threat intelligence unavailable',
          'Exercise caution when visiting unknown websites',
          'Try scanning again later'
        ],
      );
    }
  }
  
  // Submit URL to VirusTotal for analysis if not found
  Future<ScanResult> _submitUrlToVirusTotal(String url) async {
    try {
      final dio = Dio();
      final apiKey = await _virusTotalApiKey;
      if (apiKey.isEmpty) {
        throw SecurityException('VirusTotal API key not configured');
      }
      
      dio.options.headers.addAll({
        'x-apikey': apiKey,
        'Content-Type': 'application/x-www-form-urlencoded',
        ...ApiConfig.getSecurityHeaders(),
      });
      
      // Submit URL for analysis
      await dio.post(
        '$_virusTotalBaseUrl/urls',
        data: {'url': url},
      );
      
      return ScanResult(
        type: ScanType.url,
        input: url,
        threatLevel: ThreatLevel.unknown,
        isComplete: false,
        result: 'URL submitted to VirusTotal for analysis',
        recommendations: [
          'URL analysis in progress',
          'Try scanning again in a few minutes',
          'Exercise caution until analysis is complete'
        ],
      );
    } catch (e) {
      return ScanResult(
        type: ScanType.url,
        input: url,
        threatLevel: ThreatLevel.unknown,
        isComplete: true,
        result: 'Unable to submit URL for analysis',
        recommendations: [
          'External threat intelligence unavailable',
          'Exercise caution when visiting unknown websites'
        ],
      );
    }
  }

  // Real VirusTotal API file hash scanning
  Future<ScanResult> _virusTotalFileHashScan(String fileHash, String? fileName) async {
    try {
      // Check rate limits
      if (!ApiRateLimiter.canMakeRequest('virustotal')) {
        return ScanResult(
          type: ScanType.file,
          input: fileName ?? fileHash,
          threatLevel: ThreatLevel.unknown,
          isComplete: true,
          result: 'Rate limit exceeded. Please try again later.',
          recommendations: ['Wait before making another request'],
        );
      }

      final dio = Dio();
      final apiKey = await _virusTotalApiKey;
      if (apiKey.isEmpty) {
        throw SecurityException('VirusTotal API key not configured');
      }
      
      dio.options.headers.addAll({
        'x-apikey': apiKey,
        ...ApiConfig.getSecurityHeaders(),
      });
      
      // Record API request for rate limiting
      ApiRateLimiter.recordRequest('virustotal');
      
      // Get file analysis from VirusTotal using hash
      final response = await dio.get(
        '$_virusTotalBaseUrl/files/$fileHash',
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        final attributes = data['attributes'];
        final lastAnalysisStats = attributes['last_analysis_stats'];
        final lastAnalysisResults = attributes['last_analysis_results'];
        
        final maliciousCount = lastAnalysisStats['malicious'] ?? 0;
        final suspiciousCount = lastAnalysisStats['suspicious'] ?? 0;
        final totalEngines = lastAnalysisStats['total'] ?? 0;
        final detectionNames = <String>[];
        
        // Extract detection names from malicious engines
        if (lastAnalysisResults != null) {
          lastAnalysisResults.forEach((engine, result) {
            if (result['category'] == 'malicious' && result['result'] != null) {
              detectionNames.add('${result['engine_name']}: ${result['result']}');
            }
          });
        }
        
        // Determine threat level based on detection results
        ThreatLevel threatLevel;
        String result;
        List<String> recommendations;
        
        if (maliciousCount > 0) {
          threatLevel = maliciousCount >= 5 ? ThreatLevel.critical : ThreatLevel.high;
          result = 'Detected as malware by $maliciousCount/$totalEngines security vendors';
          recommendations = [
            'Do not execute or open this file',
            'Delete the file immediately',
            'Run a full system scan',
            'Report if file was received unexpectedly'
          ];
          if (detectionNames.isNotEmpty) {
            recommendations.add('Detections: ${detectionNames.take(3).join(', ')}');
          }
        } else if (suspiciousCount > 0) {
          threatLevel = ThreatLevel.medium;
          result = 'Flagged as suspicious by $suspiciousCount/$totalEngines security vendors';
          recommendations = [
            'Exercise extreme caution with this file',
            'Scan in an isolated environment if needed',
            'Verify file source and legitimacy',
            'Consider alternative file sources'
          ];
        } else {
          threatLevel = ThreatLevel.safe;
          result = 'No threats detected by VirusTotal ($totalEngines vendors checked)';
          recommendations = [
            'File appears clean according to VirusTotal',
            'Still exercise caution with files from unknown sources'
          ];
        }
        
        return ScanResult(
          type: ScanType.file,
          input: fileName ?? fileHash,
          threatLevel: threatLevel,
          isComplete: true,
          result: result,
          recommendations: recommendations,
          details: {
            'file_hash': fileHash,
            'malicious_count': maliciousCount,
            'suspicious_count': suspiciousCount,
            'total_engines': totalEngines,
            'scan_date': attributes['last_analysis_date'],
            'file_size': attributes['size'],
            'file_type': attributes['type_description'],
            'detection_names': detectionNames,
          },
        );
      } else {
        return ScanResult(
          type: ScanType.file,
          input: fileName ?? fileHash,
          threatLevel: ThreatLevel.unknown,
          isComplete: true,
          result: 'File hash not found in VirusTotal database',
          recommendations: [
            'File may be new or uncommon',
            'Exercise caution with unknown files',
            'Consider submitting file for analysis if suspicious'
          ],
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('VirusTotal file hash scan error: $e');
      }
      
      return ScanResult(
        type: ScanType.file,
        input: fileName ?? fileHash,
        threatLevel: ThreatLevel.unknown,
        isComplete: true,
        result: 'VirusTotal file scan unavailable',
        recommendations: [
          'External threat intelligence unavailable',
          'Exercise caution with files from unknown sources',
          'Try scanning again later'
        ],
      );
    }
  }

  // Comprehensive threat database analysis
  Future<ThreatAnalysis> _analyzeThreatFromDatabase(String content, ThreatType type) async {
    try {
      // Check local threat database
      final localAnalysis = _analyzeWithLocalDatabase(content, type);
      if (localAnalysis.isThreat) return localAnalysis;
      
      // Check Firestore threat intelligence database
      final firestoreAnalysis = await _analyzeWithFirestoreDatabase(content, type);
      if (firestoreAnalysis.isThreat) return firestoreAnalysis;
      
      return ThreatAnalysis(
        isThreat: false,
        threatLevel: ThreatLevel.safe,
        description: 'No threats detected in database',
        recommendations: ['Content appears safe'],
        categories: [],
      );
    } catch (e) {
      return ThreatAnalysis(
        isThreat: false,
        threatLevel: ThreatLevel.unknown,
        description: 'Database analysis failed: $e',
        recommendations: ['Manual verification recommended'],
        categories: [],
      );
    }
  }

  ThreatAnalysis _analyzeWithLocalDatabase(String content, ThreatType type) {
    final lowercaseContent = content.toLowerCase();
    
    // African-specific threat patterns
    final africanThreats = _getAfricanThreatPatterns();
    for (final threat in africanThreats) {
      if (lowercaseContent.contains(threat.pattern.toLowerCase())) {
        return ThreatAnalysis(
          isThreat: true,
          threatLevel: threat.level,
          description: 'Matches African-specific threat: ${threat.description}',
          recommendations: threat.recommendations,
          categories: [threat.category],
        );
      }
    }
    
    // Global threat patterns
    final globalThreats = _getGlobalThreatPatterns();
    for (final threat in globalThreats) {
      if (lowercaseContent.contains(threat.pattern.toLowerCase())) {
        return ThreatAnalysis(
          isThreat: true,
          threatLevel: threat.level,
          description: 'Matches global threat: ${threat.description}',
          recommendations: threat.recommendations,
          categories: [threat.category],
        );
      }
    }
    
    return ThreatAnalysis(
      isThreat: false,
      threatLevel: ThreatLevel.safe,
      description: 'No local threats detected',
      recommendations: [],
      categories: [],
    );
  }

  Future<ThreatAnalysis> _analyzeWithFirestoreDatabase(String content, ThreatType type) async {
    try {
      final threatCollection = FirebaseFirestore.instance.collection('threat_intelligence');
      
      // Query for matching threats
      final snapshot = await threatCollection
          .where('type', isEqualTo: type.toString())
          .where('isActive', isEqualTo: true)
          .limit(100)
          .get();
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final pattern = data['pattern'] as String;
        final threatLevel = ThreatLevel.values.firstWhere(
          (level) => level.toString() == data['threatLevel'],
          orElse: () => ThreatLevel.medium,
        );
        
        if (content.toLowerCase().contains(pattern.toLowerCase())) {
          return ThreatAnalysis(
            isThreat: true,
            threatLevel: threatLevel,
            description: data['description'] as String,
            recommendations: List<String>.from(data['recommendations'] ?? []),
            categories: List<String>.from(data['categories'] ?? []),
          );
        }
      }
      
      return ThreatAnalysis(
        isThreat: false,
        threatLevel: ThreatLevel.safe,
        description: 'No Firestore threats detected',
        recommendations: [],
        categories: [],
      );
    } catch (e) {
      return ThreatAnalysis(
        isThreat: false,
        threatLevel: ThreatLevel.unknown,
        description: 'Firestore analysis error: $e',
        recommendations: ['Manual verification recommended'],
        categories: [],
      );
    }
  }

  List<ThreatPattern> _getAfricanThreatPatterns() {
    return [
      ThreatPattern(
        pattern: 'm-pesa',
        level: ThreatLevel.high,
        description: 'Mobile money scam targeting M-Pesa users',
        category: 'mobile_money_scam',
        recommendations: [
          'Never share M-Pesa PIN with anyone',
          'Verify sender through official channels',
          'Report suspicious M-Pesa messages to Safaricom',
        ],
      ),
      ThreatPattern(
        pattern: 'airtel money',
        level: ThreatLevel.high,
        description: 'Mobile money scam targeting Airtel Money users',
        category: 'mobile_money_scam',
        recommendations: [
          'Never share Airtel Money PIN',
          'Contact Airtel customer service to verify',
          'Block and report suspicious numbers',
        ],
      ),
      ThreatPattern(
        pattern: 'nigerian prince',
        level: ThreatLevel.critical,
        description: 'Classic Nigerian Prince advance fee fraud',
        category: 'advance_fee_fraud',
        recommendations: [
          'Delete immediately',
          'Never send money or personal information',
          'Report to local authorities',
        ],
      ),
      ThreatPattern(
        pattern: 'inheritance fund',
        level: ThreatLevel.critical,
        description: 'Inheritance fraud common in African regions',
        category: 'inheritance_fraud',
        recommendations: [
          'This is a well-known scam',
          'No legitimate inheritance requires upfront fees',
          'Report to cybercrime authorities',
        ],
      ),
      ThreatPattern(
        pattern: 'ecowas',
        level: ThreatLevel.high,
        description: 'Fake ECOWAS documentation scam',
        category: 'document_fraud',
        recommendations: [
          'Verify through official ECOWAS channels',
          'Government agencies don\'t request payments via email',
          'Report to relevant authorities',
        ],
      ),
    ];
  }

  List<ThreatPattern> _getGlobalThreatPatterns() {
    return [
      ThreatPattern(
        pattern: 'click here immediately',
        level: ThreatLevel.medium,
        description: 'Urgency-based phishing attempt',
        category: 'phishing',
        recommendations: [
          'Avoid clicking suspicious links',
          'Verify through official channels',
          'Take time to assess legitimacy',
        ],
      ),
      ThreatPattern(
        pattern: 'suspended account',
        level: ThreatLevel.high,
        description: 'Account suspension phishing scam',
        category: 'phishing',
        recommendations: [
          'Log in through official website',
          'Never click email links for account issues',
          'Contact customer support directly',
        ],
      ),
      ThreatPattern(
        pattern: 'cryptocurrency investment',
        level: ThreatLevel.high,
        description: 'Cryptocurrency investment fraud',
        category: 'investment_scam',
        recommendations: [
          'Research investment opportunities thoroughly',
          'Be wary of guaranteed returns',
          'Consult financial advisors',
        ],
      ),
    ];
  }

  List<String> _getPhishingPatterns() {
    return [
      'verify your account', 'suspended account', 'click here immediately',
      'update your information', 'confirm your identity', 'urgent action required',
      'your account will be closed', 'security alert', 'unusual activity',
      'prize winner', 'congratulations you won', 'claim your reward',
      'nigerian prince', 'inheritance fund', 'business opportunity'
    ];
  }

  List<String> _getSocialEngineeringPatterns() {
    return [
      'act now', 'limited time offer', 'expires today',
      'don\'t tell anyone', 'confidential', 'secret information',
      'you have been selected', 'exclusive offer', 'special invitation',
      'immediate response required', 'time sensitive', 'urgent matter'
    ];
  }

  List<String> _getScamPhonePatterns() {
    return [
      '1234567890', '0987654321', '1111111111',
      '0000000000', '9999999999', '5555555555'
    ];
  }

  List<String> _getMalwareKeywords() {
    return [
      'download now', 'install immediately', 'update required',
      'security scan', 'virus detected', 'system infected',
      'clean your pc', 'speed up computer', 'free antivirus'
    ];
  }

  List<String> _getScamPhrases() {
    return [
      'western union', 'money transfer', 'wire money',
      'send payment', 'advance fee', 'processing fee',
      'lottery winner', 'inheritance money', 'tax refund',
      'government grant', 'free money', 'cash prize'
    ];
  }

  List<String> _getPersonalInfoPatterns() {
    return [
      'social security', 'bank account', 'credit card',
      'password', 'pin number', 'security code',
      'mothers maiden name', 'date of birth', 'id number'
    ];
  }

  bool _isValidPhoneNumber(String number) {
    final phoneRegex = RegExp(r'^\+?[1-9]\d{6,14}$');
    return phoneRegex.hasMatch(number);
  }

  bool _hasMultipleConsecutiveDigits(String number) {
    for (int i = 0; i < number.length - 2; i++) {
      if (number[i] == number[i + 1] && number[i + 1] == number[i + 2]) {
        return true;
      }
    }
    return false;
  }

  bool _isPremiumRateNumber(String number) {
    final premiumPrefixes = ['1900', '1800', '+2349'];
    for (final prefix in premiumPrefixes) {
      if (number.startsWith(prefix)) return true;
    }
    return false;
  }

  // Helper method to map ThreatRiskLevel to ThreatLevel
  ThreatLevel _mapRiskLevelToThreatLevel(ThreatRiskLevel riskLevel) {
    switch (riskLevel) {
      case ThreatRiskLevel.safe:
        return ThreatLevel.safe;
      case ThreatRiskLevel.low:
        return ThreatLevel.low;
      case ThreatRiskLevel.medium:
        return ThreatLevel.medium;
      case ThreatRiskLevel.high:
        return ThreatLevel.high;
      case ThreatRiskLevel.critical:
        return ThreatLevel.critical;
    }
  }

  ThreatLevel _mapStringToThreatLevel(String threatLevel) {
    switch (threatLevel.toUpperCase()) {
      case 'SAFE':
        return ThreatLevel.safe;
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

// Enums and Data Classes
enum ScanType { url, email, phone, text, file }
enum ThreatType { url, email, phone, text, file }
enum ThreatLevel { safe, low, medium, high, critical, unknown }

class ScanResult {
  final ScanType type;
  final String input;
  final ThreatLevel threatLevel;
  final bool isComplete;
  final String result;
  final List<String> recommendations;
  final List<String>? threatCategories;
  final Map<String, dynamic>? details;
  final DateTime scannedAt;

  ScanResult({
    required this.type,
    required this.input,
    required this.threatLevel,
    required this.isComplete,
    required this.result,
    required this.recommendations,
    this.threatCategories,
    this.details,
    DateTime? scannedAt,
  }) : scannedAt = scannedAt ?? DateTime.now();

  ScanResult copyWith({
    ScanType? type,
    String? input,
    ThreatLevel? threatLevel,
    bool? isComplete,
    String? result,
    List<String>? recommendations,
    List<String>? threatCategories,
    Map<String, dynamic>? details,
    DateTime? scannedAt,
  }) {
    return ScanResult(
      type: type ?? this.type,
      input: input ?? this.input,
      threatLevel: threatLevel ?? this.threatLevel,
      isComplete: isComplete ?? this.isComplete,
      result: result ?? this.result,
      recommendations: recommendations ?? this.recommendations,
      threatCategories: threatCategories ?? this.threatCategories,
      details: details ?? this.details,
      scannedAt: scannedAt ?? this.scannedAt,
    );
  }

  String get threatLevelString {
    switch (threatLevel) {
      case ThreatLevel.safe:
        return 'Safe';
      case ThreatLevel.low:
        return 'Low Risk';
      case ThreatLevel.medium:
        return 'Medium Risk';
      case ThreatLevel.high:
        return 'High Risk';
      case ThreatLevel.critical:
        return 'Critical';
      case ThreatLevel.unknown:
        return 'Unknown';
    }
  }

  Color get threatLevelColor {
    switch (threatLevel) {
      case ThreatLevel.safe:
        return const Color(0xFF4CAF50); // Green
      case ThreatLevel.low:
        return const Color(0xFF8BC34A); // Light Green
      case ThreatLevel.medium:
        return const Color(0xFFFF9800); // Orange
      case ThreatLevel.high:
        return const Color(0xFFFF5722); // Deep Orange
      case ThreatLevel.critical:
        return const Color(0xFFF44336); // Red
      case ThreatLevel.unknown:
        return const Color(0xFF9E9E9E); // Grey
    }
  }
}

extension ThreatLevelExtension on ThreatLevel {
  String get displayName {
    switch (this) {
      case ThreatLevel.safe:
        return 'Safe';
      case ThreatLevel.low:
        return 'Low Risk';
      case ThreatLevel.medium:
        return 'Medium Risk';
      case ThreatLevel.high:
        return 'High Risk';
      case ThreatLevel.critical:
        return 'Critical Risk';
      case ThreatLevel.unknown:
        return 'Unknown';
    }
  }
}

// New classes for comprehensive threat analysis
class ThreatAnalysis {
  final bool isThreat;
  final ThreatLevel threatLevel;
  final String description;
  final List<String> recommendations;
  final List<String> categories;

  const ThreatAnalysis({
    required this.isThreat,
    required this.threatLevel,
    required this.description,
    required this.recommendations,
    required this.categories,
  });
}

class ThreatPattern {
  final String pattern;
  final ThreatLevel level;
  final String description;
  final String category;
  final List<String> recommendations;

  const ThreatPattern({
    required this.pattern,
    required this.level,
    required this.description,
    required this.category,
    required this.recommendations,
  });
}
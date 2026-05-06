import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class SecurityUtils {
  // Email validation with comprehensive checks
  static bool isValidEmail(String email) {
    if (email.isEmpty || email.length > 254) return false;
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      caseSensitive: false,
    );
    
    if (!emailRegex.hasMatch(email)) return false;
    
    // Check for common email security issues
    final parts = email.split('@');
    if (parts.length != 2) return false;
    
    final localPart = parts[0];
    final domain = parts[1];
    
    // Local part validation
    if (localPart.isEmpty || localPart.length > 64) return false;
    if (localPart.startsWith('.') || localPart.endsWith('.')) return false;
    if (localPart.contains('..')) return false;
    
    // Domain validation
    if (domain.isEmpty || domain.length > 253) return false;
    if (domain.startsWith('.') || domain.endsWith('.')) return false;
    if (domain.startsWith('-') || domain.endsWith('-')) return false;
    
    return true;
  }
  
  // Enhanced phone number validation for African markets
  static bool isValidPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty || phoneNumber.length > 25) return false;
    
    // Remove all non-digit characters except +
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Basic length and format check
    if (cleanNumber.length < 7 || cleanNumber.length > 16) return false;
    
    // More specific regex for international and local numbers
    final internationalRegex = RegExp(r'^\+[1-9]\d{6,14}$');
    final localRegex = RegExp(r'^0[1-9]\d{6,13}$|^[1-9]\d{6,13}$');
    
    if (cleanNumber.startsWith('+')) {
      if (!internationalRegex.hasMatch(cleanNumber)) return false;
      return _validateAfricanCountryCode(cleanNumber);
    } else {
      return localRegex.hasMatch(cleanNumber);
    }
  }
  
  // Validate African country codes with specific rules
  static bool _validateAfricanCountryCode(String internationalNumber) {
    final africanCountryCodes = {
      '+234': {'minLength': 13, 'maxLength': 14}, // Nigeria
      '+254': {'minLength': 12, 'maxLength': 13}, // Kenya  
      '+233': {'minLength': 12, 'maxLength': 13}, // Ghana
      '+27': {'minLength': 11, 'maxLength': 12},  // South Africa
      '+256': {'minLength': 12, 'maxLength': 13}, // Uganda
      '+255': {'minLength': 12, 'maxLength': 13}, // Tanzania
      '+263': {'minLength': 12, 'maxLength': 13}, // Zimbabwe
      '+260': {'minLength': 12, 'maxLength': 13}, // Zambia
      '+231': {'minLength': 11, 'maxLength': 12}, // Liberia
      '+232': {'minLength': 11, 'maxLength': 12}, // Sierra Leone
      '+237': {'minLength': 12, 'maxLength': 13}, // Cameroon
      '+221': {'minLength': 12, 'maxLength': 13}, // Senegal
      '+226': {'minLength': 11, 'maxLength': 12}, // Burkina Faso
      '+227': {'minLength': 11, 'maxLength': 12}, // Niger
      '+228': {'minLength': 11, 'maxLength': 12}, // Togo
      '+229': {'minLength': 11, 'maxLength': 12}, // Benin
      '+225': {'minLength': 12, 'maxLength': 13}, // Ivory Coast
      '+224': {'minLength': 12, 'maxLength': 13}, // Guinea
    };
    
    for (final code in africanCountryCodes.keys) {
      if (internationalNumber.startsWith(code)) {
        final config = africanCountryCodes[code]!;
        final length = internationalNumber.length;
        return length >= config['minLength']! && length <= config['maxLength']!;
      }
    }
    
    return false; // Unknown African country code
  }
  
  // Comprehensive input sanitization with safe UTF-8 handling
  static String sanitizeInput(String input, {bool allowHtml = false, int maxLength = 10000}) {
    if (input.isEmpty) return input;
    
    String sanitized = input;
    
    // Remove or escape potentially dangerous characters
    if (!allowHtml) {
      // Strip all HTML/XML tags
      sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');
      
      // Escape HTML entities
      sanitized = sanitized
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;')
          .replaceAll("'", '&#x27;');
    }
    
    // Remove SQL injection patterns
    final sqlPatterns = [
      RegExp(r'\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION)\b', caseSensitive: false),
      RegExp(r'''[;'"\\]'''),
      RegExp(r'--'),
      RegExp(r'/\*.*?\*/', dotAll: true),
    ];
    
    for (final pattern in sqlPatterns) {
      sanitized = sanitized.replaceAll(pattern, '');
    }
    
    // Remove potentially dangerous script patterns
    final scriptPatterns = [
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'vbscript:', caseSensitive: false),
      RegExp(r'onload=', caseSensitive: false),
      RegExp(r'onerror=', caseSensitive: false),
      RegExp(r'onclick=', caseSensitive: false),
    ];
    
    for (final pattern in scriptPatterns) {
      sanitized = sanitized.replaceAll(pattern, '');
    }
    
    // Trim whitespace and normalize
    sanitized = sanitized.trim();
    
    // Safe UTF-8 truncation to prevent buffer overflow
    sanitized = _safeUtf8Truncate(sanitized, maxLength);
    
    return sanitized;
  }
  
  // Safe UTF-8 string truncation that preserves character boundaries
  static String _safeUtf8Truncate(String input, int maxLength) {
    if (input.length <= maxLength) return input;
    
    try {
      final bytes = utf8.encode(input);
      if (bytes.length <= maxLength) return input;
      
      // Find the last valid UTF-8 character boundary
      List<int> truncatedBytes = bytes.take(maxLength).toList();
      
      // Remove incomplete UTF-8 sequences at the end
      while (truncatedBytes.isNotEmpty && 
             (truncatedBytes.last & 0xC0) == 0x80) {
        truncatedBytes.removeLast();
      }
      
      // Decode safely
      return utf8.decode(truncatedBytes, allowMalformed: false);
    } catch (e) {
      // Fallback to simple character-based truncation if UTF-8 handling fails
      return input.length > maxLength ? input.substring(0, maxLength) : input;
    }
  }
  
  // Sanitize text content specifically for incident reports
  static String sanitizeIncidentContent(String content) {
    if (content.isEmpty) return content;
    
    String sanitized = sanitizeInput(content);
    
    // Remove potential file paths that could leak system information
    sanitized = sanitized.replaceAll(RegExp(r'[A-Za-z]:\\[^\\]*\\'), '[PATH]\\');
    sanitized = sanitized.replaceAll(RegExp(r'/[^/\s]+/[^/\s]+/'), '[PATH]/');
    
    // Remove potential email addresses from descriptions to prevent harvesting
    // (unless it's clearly the user's own email)
    final emailPattern = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    sanitized = sanitized.replaceAllMapped(emailPattern, (match) => '[EMAIL_REDACTED]');
    
    // Remove potential credit card numbers
    final ccPattern = RegExp(r'\b(?:\d{4}[-\s]?){3}\d{4}\b');
    sanitized = sanitized.replaceAll(ccPattern, '[CARD_NUMBER_REDACTED]');
    
    // Remove potential phone numbers from descriptions
    final phonePattern = RegExp(r'\b\+?[\d\-\s\(\)]{10,}\b');
    sanitized = sanitized.replaceAllMapped(phonePattern, (match) {
      final phone = match.group(0)!.replaceAll(RegExp(r'[^\d]'), '');
      return phone.length >= 10 ? '[PHONE_REDACTED]' : match.group(0)!;
    });
    
    return sanitized;
  }
  
  // Validate and sanitize URLs
  static String? sanitizeUrl(String url) {
    if (url.isEmpty) return null;
    
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return null;
      
      // Only allow http/https schemes
      if (!['http', 'https'].contains(uri.scheme.toLowerCase())) {
        return null;
      }
      
      // Block suspicious domains
      final suspiciousTlds = ['.tk', '.ml', '.ga', '.cf', '.top'];
      final host = uri.host.toLowerCase();
      
      for (final tld in suspiciousTlds) {
        if (host.endsWith(tld)) {
          return null; // Block suspicious TLDs
        }
      }
      
      // Block localhost/internal addresses in production
      if (!kDebugMode) {
        if (host == 'localhost' || 
            host.startsWith('127.') || 
            host.startsWith('192.168.') ||
            host.startsWith('10.') ||
            host.contains('local')) {
          return null;
        }
      }
      
      return uri.toString();
    } catch (e) {
      return null;
    }
  }
  
  // Password strength validation for African users
  static PasswordStrength validatePassword(String password) {
    if (password.isEmpty) {
      return PasswordStrength(
        isValid: false,
        strength: 0,
        feedback: ['Password is required'],
      );
    }
    
    final feedback = <String>[];
    int strength = 0;
    
    // Length check (more lenient for African markets with mobile-first approach)
    if (password.length >= 8) {
      strength += 2;
    } else if (password.length >= 6) {
      strength += 1;
      feedback.add('Consider using at least 8 characters for better security');
    } else {
      feedback.add('Password must be at least 6 characters long');
    }
    
    // Character diversity
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 1;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 1;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 1;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 1;
    
    // Common patterns check
    final commonPatterns = [
      'password', 'admin', '123456', 'qwerty', 'nigeria', 'kenya',
      'southafrica', 'ghana', 'uganda', 'tanzania', 'ethiopia'
    ];
    
    final lowerPassword = password.toLowerCase();
    for (final pattern in commonPatterns) {
      if (lowerPassword.contains(pattern)) {
        strength = strength > 0 ? strength - 1 : 0;
        feedback.add('Avoid using common words or country names');
        break;
      }
    }
    
    // Sequential characters
    if (RegExp(r'(012|123|234|345|456|567|678|789|890|abc|bcd|cde)').hasMatch(lowerPassword)) {
      strength = strength > 0 ? strength - 1 : 0;
      feedback.add('Avoid sequential characters');
    }
    
    // Repeated characters
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) {
      strength = strength > 0 ? strength - 1 : 0;
      feedback.add('Avoid repeating the same character');
    }
    
    // Generate feedback based on strength
    if (strength < 3) {
      feedback.add('Use a mix of uppercase, lowercase, numbers, and symbols');
    }
    
    final isValid = strength >= 3 && password.length >= 6;
    
    if (isValid && feedback.isEmpty) {
      feedback.add('Good password strength!');
    }
    
    return PasswordStrength(
      isValid: isValid,
      strength: strength,
      feedback: feedback,
    );
  }
  
  // Generate secure hash for sensitive data
  static String generateSecureHash(String input, [String? salt]) {
    final saltValue = salt ?? 'Rethicssec_SecureSalt_2024';
    final bytes = utf8.encode(input + saltValue);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Validate case numbers for incident tracking
  static bool isValidCaseNumber(String caseNumber) {
    // Format: RET + YYYYMMDD + 4 digits
    final caseRegex = RegExp(r'^RET\d{12}$');
    return caseRegex.hasMatch(caseNumber);
  }
  
  // Check if content contains sensitive personal information
  static List<String> detectSensitiveInfo(String content) {
    final sensitiveItems = <String>[];
    
    // Credit card patterns
    if (RegExp(r'\b(?:\d{4}[-\s]?){3}\d{4}\b').hasMatch(content)) {
      sensitiveItems.add('Potential credit card number detected');
    }
    
    // Bank account patterns (basic)
    if (RegExp(r'\b\d{10,16}\b').hasMatch(content)) {
      sensitiveItems.add('Potential bank account number detected');
    }
    
    // ID number patterns (various African formats)
    if (RegExp(r'\b\d{13}\b').hasMatch(content) || // South African ID
        RegExp(r'\b\d{8}\b').hasMatch(content)) {   // Kenyan ID
      sensitiveItems.add('Potential ID number detected');
    }
    
    // Phone numbers
    if (RegExp(r'\+?\d{10,15}').hasMatch(content)) {
      sensitiveItems.add('Phone number detected');
    }
    
    // Email addresses
    if (RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b').hasMatch(content)) {
      sensitiveItems.add('Email address detected');
    }
    
    return sensitiveItems;
  }
}

class PasswordStrength {
  final bool isValid;
  final int strength; // 0-6 scale
  final List<String> feedback;
  
  const PasswordStrength({
    required this.isValid,
    required this.strength,
    required this.feedback,
  });
  
  String get strengthLabel {
    switch (strength) {
      case 0:
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Fair';
      case 4:
        return 'Good';
      case 5:
        return 'Strong';
      case 6:
        return 'Very Strong';
      default:
        return 'Unknown';
    }
  }
  
  double get strengthPercentage => (strength / 6.0).clamp(0.0, 1.0);
}
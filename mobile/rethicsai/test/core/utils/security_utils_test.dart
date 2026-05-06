import 'package:flutter_test/flutter_test.dart';
import 'package:rethicsai/core/utils/security_utils.dart';

void main() {
  group('SecurityUtils', () {
    group('Email Validation', () {
      test('should accept valid email addresses', () {
        final validEmails = [
          'user@example.com',
          'test.user@domain.co.ke',
          'admin@rethicsai.org',
          'user+tag@example.com',
          'user123@test-domain.com',
        ];
        
        for (final email in validEmails) {
          expect(SecurityUtils.isValidEmail(email), isTrue, 
              reason: 'Email $email should be valid');
        }
      });
      
      test('should reject invalid email addresses', () {
        final invalidEmails = [
          '',
          'invalid',
          '@domain.com',
          'user@',
          'user@domain',
          'user..double@domain.com',
          'user@domain..com',
          '.user@domain.com',
          'user.@domain.com',
          'user@.domain.com',
          'user@domain.com.',
          'a' * 65 + '@domain.com', // Local part too long
          'user@' + 'a' * 250 + '.com', // Domain too long
        ];
        
        for (final email in invalidEmails) {
          expect(SecurityUtils.isValidEmail(email), isFalse,
              reason: 'Email $email should be invalid');
        }
      });
    });

    group('African Phone Number Validation', () {
      test('should accept valid African phone numbers', () {
        final validPhones = [
          '+254712345678', // Kenya
          '+234123456789', // Nigeria
          '+233123456789', // Ghana
          '+27123456789',  // South Africa
          '0712345678',    // Local format
        ];
        
        for (final phone in validPhones) {
          expect(SecurityUtils.isValidPhoneNumber(phone), isTrue,
              reason: 'Phone $phone should be valid');
        }
      });
      
      test('should reject invalid phone numbers', () {
        final invalidPhones = [
          '',
          '123',
          '1234567890123456', // Too long
          '+1234', // Too short
          'abcd1234567',
          '+999123456789', // Invalid country code
        ];
        
        for (final phone in invalidPhones) {
          expect(SecurityUtils.isValidPhoneNumber(phone), isFalse,
              reason: 'Phone $phone should be invalid');
        }
      });
    });

    group('Input Sanitization', () {
      test('should remove HTML tags by default', () {
        final input = '<script>alert("xss")</script>Hello <b>World</b>';
        final result = SecurityUtils.sanitizeInput(input);
        
        expect(result, equals('Hello World'));
      });
      
      test('should escape dangerous characters', () {
        final input = 'User input with <>&"\' characters';
        final result = SecurityUtils.sanitizeInput(input);
        
        expect(result, contains('&lt;'));
        expect(result, contains('&gt;'));
        expect(result, contains('&amp;'));
        expect(result, contains('&quot;'));
        expect(result, contains('&#x27;'));
      });
      
      test('should remove SQL injection patterns', () {
        final inputs = [
          'SELECT * FROM users',
          'DROP TABLE incidents',
          'admin\'; DROP TABLE users; --',
          'UNION SELECT password FROM users',
        ];
        
        for (final input in inputs) {
          final result = SecurityUtils.sanitizeInput(input);
          expect(result, isNot(contains(RegExp(r'\b(SELECT|DROP|UNION)\b', caseSensitive: false))));
        }
      });
      
      test('should remove script injection patterns', () {
        final inputs = [
          'javascript:alert(1)',
          'vbscript:msgbox(1)',
          'onload="alert(1)"',
          'onclick="steal()"',
        ];
        
        for (final input in inputs) {
          final result = SecurityUtils.sanitizeInput(input);
          expect(result, isNot(contains('javascript:')));
          expect(result, isNot(contains('vbscript:')));
          expect(result, isNot(contains('onload=')));
          expect(result, isNot(contains('onclick=')));
        }
      });

      test('should limit input length to prevent buffer overflow', () {
        final longInput = 'A' * 15000;
        final result = SecurityUtils.sanitizeInput(longInput);
        
        expect(result.length, lessThanOrEqualTo(10000));
      });
    });

    group('Incident Content Sanitization', () {
      test('should redact email addresses', () {
        final input = 'Contact me at user@example.com for more info';
        final result = SecurityUtils.sanitizeIncidentContent(input);
        
        expect(result, contains('[EMAIL_REDACTED]'));
        expect(result, isNot(contains('user@example.com')));
      });
      
      test('should redact credit card numbers', () {
        final input = 'My card number is 1234 5678 9012 3456';
        final result = SecurityUtils.sanitizeIncidentContent(input);
        
        expect(result, contains('[CARD_NUMBER_REDACTED]'));
        expect(result, isNot(contains('1234 5678 9012 3456')));
      });
      
      test('should redact phone numbers', () {
        final input = 'Call me at +254712345678 or 0712345678';
        final result = SecurityUtils.sanitizeIncidentContent(input);
        
        expect(result, contains('[PHONE_REDACTED]'));
        expect(result, isNot(contains('+254712345678')));
      });
      
      test('should redact file paths', () {
        final input = 'File saved at C:\\Users\\Admin\\Documents\\secret.txt';
        final result = SecurityUtils.sanitizeIncidentContent(input);
        
        expect(result, contains('[PATH]'));
        expect(result, isNot(contains('C:\\Users\\Admin')));
      });
    });

    group('Password Validation', () {
      test('should accept strong passwords', () {
        final strongPasswords = [
          'MyStr0ng@Pass!',
          'AfricanSun2024#',
          'SecureP@ssw0rd',
        ];
        
        for (final password in strongPasswords) {
          final result = SecurityUtils.validatePassword(password);
          expect(result.isValid, isTrue, reason: 'Password $password should be valid');
          expect(result.strength, greaterThanOrEqualTo(3));
        }
      });
      
      test('should reject weak passwords', () {
        final weakPasswords = [
          '',
          '123',
          'password',
          '12345678',
          'nigeria123', // Contains country name
          'admin',
        ];
        
        for (final password in weakPasswords) {
          final result = SecurityUtils.validatePassword(password);
          expect(result.isValid, isFalse, reason: 'Password $password should be invalid');
        }
      });
      
      test('should detect common patterns', () {
        final result = SecurityUtils.validatePassword('nigeria123');
        expect(result.feedback, contains('Avoid using common words or country names'));
      });
      
      test('should detect sequential characters', () {
        final result = SecurityUtils.validatePassword('abc123456');
        expect(result.feedback, contains('Avoid sequential characters'));
      });
      
      test('should detect repeated characters', () {
        final result = SecurityUtils.validatePassword('aaa123456');
        expect(result.feedback, contains('Avoid repeating the same character'));
      });
    });

    group('URL Sanitization', () {
      test('should accept valid HTTP/HTTPS URLs', () {
        final validUrls = [
          'https://www.google.com',
          'http://example.com',
          'https://rethicsai.org/docs',
        ];
        
        for (final url in validUrls) {
          final result = SecurityUtils.sanitizeUrl(url);
          expect(result, isNotNull, reason: 'URL $url should be valid');
        }
      });
      
      test('should reject non-HTTP schemes', () {
        final invalidUrls = [
          'javascript:alert(1)',
          'file:///etc/passwd',
          'ftp://example.com',
          'data:text/html,<script>alert(1)</script>',
        ];
        
        for (final url in invalidUrls) {
          final result = SecurityUtils.sanitizeUrl(url);
          expect(result, isNull, reason: 'URL $url should be rejected');
        }
      });
      
      test('should reject suspicious TLDs', () {
        final suspiciousUrls = [
          'https://phishing-site.tk',
          'https://malware.ml',
          'https://scam.ga',
        ];
        
        for (final url in suspiciousUrls) {
          final result = SecurityUtils.sanitizeUrl(url);
          expect(result, isNull, reason: 'Suspicious URL $url should be rejected');
        }
      });
    });

    group('Sensitive Information Detection', () {
      test('should detect credit card numbers', () {
        final content = 'Payment made with card 1234-5678-9012-3456';
        final result = SecurityUtils.detectSensitiveInfo(content);
        
        expect(result, contains('Potential credit card number detected'));
      });
      
      test('should detect phone numbers', () {
        final content = 'Contact: +254712345678';
        final result = SecurityUtils.detectSensitiveInfo(content);
        
        expect(result, contains('Phone number detected'));
      });
      
      test('should detect email addresses', () {
        final content = 'Email me at user@example.com';
        final result = SecurityUtils.detectSensitiveInfo(content);
        
        expect(result, contains('Email address detected'));
      });
      
      test('should detect ID numbers', () {
        final content = 'My ID is 1234567890123'; // 13 digits (SA format)
        final result = SecurityUtils.detectSensitiveInfo(content);
        
        expect(result, contains('Potential ID number detected'));
      });
    });

    group('Case Number Validation', () {
      test('should validate correct case number format', () {
        final validCaseNumbers = [
          'RET202412250001',
          'RET202401011234',
        ];
        
        for (final caseNumber in validCaseNumbers) {
          expect(SecurityUtils.isValidCaseNumber(caseNumber), isTrue,
              reason: 'Case number $caseNumber should be valid');
        }
      });
      
      test('should reject invalid case number formats', () {
        final invalidCaseNumbers = [
          '',
          'RET123',
          'INVALID202412250001',
          'RET20241225000A',
          'ret202412250001', // Wrong case
        ];
        
        for (final caseNumber in invalidCaseNumbers) {
          expect(SecurityUtils.isValidCaseNumber(caseNumber), isFalse,
              reason: 'Case number $caseNumber should be invalid');
        }
      });
    });

    group('Secure Hash Generation', () {
      test('should generate consistent hashes for same input', () {
        final input = 'test-data';
        final hash1 = SecurityUtils.generateSecureHash(input);
        final hash2 = SecurityUtils.generateSecureHash(input);
        
        expect(hash1, equals(hash2));
      });
      
      test('should generate different hashes for different inputs', () {
        final hash1 = SecurityUtils.generateSecureHash('input1');
        final hash2 = SecurityUtils.generateSecureHash('input2');
        
        expect(hash1, isNot(equals(hash2)));
      });
      
      test('should generate different hashes with different salts', () {
        final input = 'test-data';
        final hash1 = SecurityUtils.generateSecureHash(input, 'salt1');
        final hash2 = SecurityUtils.generateSecureHash(input, 'salt2');
        
        expect(hash1, isNot(equals(hash2)));
      });
    });
  });
}
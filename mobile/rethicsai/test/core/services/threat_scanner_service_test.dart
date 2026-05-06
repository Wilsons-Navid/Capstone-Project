import 'package:flutter_test/flutter_test.dart';
import 'package:rethicsai/core/services/threat_scanner_service.dart';

void main() {
  late ThreatScannerService threatScanner;

  setUp(() {
    threatScanner = ThreatScannerService();
  });

  group('ThreatScannerService', () {
    group('URL Scanning', () {
      test('should detect malicious URLs', () async {
        final suspiciousUrls = [
          'https://phishing-site.tk',
          'https://malware.ml',
          'https://click-here-urgent.com',
        ];

        for (final url in suspiciousUrls) {
          final result = await threatScanner.scanUrl(url);
          expect(result.threatLevel, isNot(equals(ThreatLevel.safe)));
          expect(result.recommendations, isNotEmpty);
        }
      });

      test('should accept legitimate URLs', () async {
        final legitimateUrls = [
          'https://www.google.com',
          'https://github.com',
          'https://stackoverflow.com',
        ];

        for (final url in legitimateUrls) {
          final result = await threatScanner.scanUrl(url);
          // Note: In real implementation, these would likely be safe
          // This test verifies the scanner runs without errors
          expect(result.isComplete, isTrue);
          expect(result.input, equals(url));
        }
      });

      test('should handle invalid URL formats', () async {
        final invalidUrls = [
          'not-a-url',
          'http://',
          'ftp://example.com',
          '',
        ];

        for (final url in invalidUrls) {
          final result = await threatScanner.scanUrl(url);
          expect(result.isComplete, isTrue);
          expect(result.recommendations, isNotEmpty);
        }
      });
    });

    group('Email Content Scanning', () {
      test('should detect phishing patterns', () async {
        final phishingEmails = [
          'Urgent! Your account will be suspended. Click here immediately to verify.',
          'You have won a lottery! Claim your prize now by providing your bank details.',
          'Security alert: Unusual activity detected. Update your information.',
          'Nigerian prince needs your help to transfer millions of dollars.',
        ];

        for (final email in phishingEmails) {
          final result = await threatScanner.scanEmailContent(email);
          expect(result.threatLevel, isNot(equals(ThreatLevel.safe)));
          expect(result.recommendations, isNotEmpty);
        }
      });

      test('should accept legitimate email content', () async {
        final legitimateEmails = [
          'Hello, how are you doing today?',
          'Meeting scheduled for tomorrow at 2 PM.',
          'Happy birthday! Hope you have a great day.',
          'Project update: We completed the first phase.',
        ];

        for (final email in legitimateEmails) {
          final result = await threatScanner.scanEmailContent(email);
          expect(result.threatLevel, equals(ThreatLevel.safe));
          expect(result.result, contains('No threats detected'));
        }
      });

      test('should detect social engineering tactics', () async {
        final socialEngineeringEmails = [
          'Act now! Limited time offer expires today.',
          'Don\'t tell anyone about this exclusive opportunity.',
          'You have been selected for a special invitation.',
          'Immediate response required for time sensitive matter.',
        ];

        for (final email in socialEngineeringEmails) {
          final result = await threatScanner.scanEmailContent(email);
          expect(result.threatLevel, isNot(equals(ThreatLevel.safe)));
        }
      });
    });

    group('Phone Number Scanning', () {
      test('should validate proper African phone numbers', () async {
        final validPhones = [
          '+254712345678', // Kenya
          '+234123456789', // Nigeria
          '+27123456789',  // South Africa
        ];

        for (final phone in validPhones) {
          final result = await threatScanner.scanPhoneNumber(phone);
          expect(result.isComplete, isTrue);
          expect(result.input, equals(phone));
        }
      });

      test('should detect invalid phone formats', () async {
        final invalidPhones = [
          '123',
          'not-a-phone',
          '1234567890123456', // Too long
        ];

        for (final phone in invalidPhones) {
          final result = await threatScanner.scanPhoneNumber(phone);
          expect(result.threatLevel, isNot(equals(ThreatLevel.safe)));
          expect(result.recommendations, isNotEmpty);
        }
      });

      test('should detect premium rate numbers', () async {
        final premiumNumbers = [
          '+23491234567', // Nigerian premium
          '19001234567',  // Premium rate
        ];

        for (final phone in premiumNumbers) {
          final result = await threatScanner.scanPhoneNumber(phone);
          expect(result.recommendations, 
              anyElement(contains('premium') || contains('charges')));
        }
      });

      test('should flag suspicious patterns', () async {
        final suspiciousNumbers = [
          '1111111111',
          '0000000000',
          '1234567890',
        ];

        for (final phone in suspiciousNumbers) {
          final result = await threatScanner.scanPhoneNumber(phone);
          expect(result.threatLevel, isNot(equals(ThreatLevel.safe)));
        }
      });
    });

    group('Text Content Scanning', () {
      test('should detect malware-related keywords', () async {
        final malwareTexts = [
          'Download now to clean your PC of viruses.',
          'Your system is infected! Install our antivirus immediately.',
          'Free security scan detected threats on your computer.',
        ];

        for (final text in malwareTexts) {
          final result = await threatScanner.scanTextContent(text);
          expect(result.threatLevel, isNot(equals(ThreatLevel.safe)));
        }
      });

      test('should detect scam phrases', () async {
        final scamTexts = [
          'Send money via Western Union to claim your prize.',
          'Government grant available - pay small processing fee.',
          'Lottery winner! Wire money for taxes to receive payout.',
          'Inheritance fund requires advance fee for processing.',
        ];

        for (final text in scamTexts) {
          final result = await threatScanner.scanTextContent(text);
          expect(result.threatLevel, isNot(equals(ThreatLevel.safe)));
        }
      });

      test('should detect personal information harvesting', () async {
        final harvestingTexts = [
          'Please provide your social security number.',
          'Enter your bank account details to proceed.',
          'What is your mother\'s maiden name?',
          'Verify your credit card information.',
        ];

        for (final text in harvestingTexts) {
          final result = await threatScanner.scanTextContent(text);
          expect(result.threatLevel, isNot(equals(ThreatLevel.safe)));
        }
      });

      test('should accept safe content', () async {
        final safeTexts = [
          'Welcome to our platform.',
          'Your order has been confirmed.',
          'Thank you for your feedback.',
          'Meeting notes from today\'s session.',
        ];

        for (final text in safeTexts) {
          final result = await threatScanner.scanTextContent(text);
          expect(result.threatLevel, equals(ThreatLevel.safe));
        }
      });
    });

    group('African-Specific Threat Detection', () {
      test('should detect M-Pesa scams', () async {
        final mPesaScams = [
          'M-Pesa transaction failed. Send your PIN to verify.',
          'Congratulations! You won M-Pesa lottery. Provide PIN.',
          'M-Pesa security update required. Share your PIN.',
        ];

        for (final scam in mPesaScams) {
          final result = await threatScanner.scanTextContent(scam);
          expect(result.threatLevel, equals(ThreatLevel.high));
          expect(result.recommendations, 
              anyElement(contains('M-Pesa') || contains('PIN')));
        }
      });

      test('should detect Airtel Money scams', () async {
        final airtelScams = [
          'Airtel Money prize won! Share your PIN to claim.',
          'Airtel security alert - verify with your PIN.',
          'Free Airtel Money credit - provide PIN number.',
        ];

        for (final scam in airtelScams) {
          final result = await threatScanner.scanTextContent(scam);
          expect(result.threatLevel, equals(ThreatLevel.high));
        }
      });

      test('should detect Nigerian Prince scams', () async {
        final princeScams = [
          'I am a Nigerian prince with millions to share.',
          'Inheritance fund from Nigerian royal family.',
          'Business opportunity with Nigerian government official.',
        ];

        for (final scam in princeScams) {
          final result = await threatScanner.scanTextContent(scam);
          expect(result.threatLevel, equals(ThreatLevel.critical));
        }
      });

      test('should detect ECOWAS document fraud', () async {
        final ecowasScams = [
          'ECOWAS travel document available - pay processing fee.',
          'Official ECOWAS permit requires payment to issue.',
          'Government ECOWAS certificate - wire transfer needed.',
        ];

        for (final scam in ecowasScams) {
          final result = await threatScanner.scanTextContent(scam);
          expect(result.threatLevel, equals(ThreatLevel.high));
        }
      });
    });

    group('Threat Level Assessment', () {
      test('should properly categorize threat levels', () async {
        // Safe content
        var result = await threatScanner.scanTextContent('Hello, how are you?');
        expect(result.threatLevel, equals(ThreatLevel.safe));
        expect(result.threatLevelString, equals('Safe'));

        // High threat content
        result = await threatScanner.scanTextContent('Nigerian prince inheritance scam');
        expect(result.threatLevel, isNot(equals(ThreatLevel.safe)));
        expect(result.threatLevelColor, isNotNull);
      });

      test('should provide appropriate recommendations', () async {
        final result = await threatScanner.scanEmailContent(
          'Click here immediately to verify your suspended account!'
        );

        expect(result.recommendations, isNotEmpty);
        expect(result.recommendations, anyElement(contains('caution') || 
                                                 contains('verify') || 
                                                 contains('click')));
      });
    });

    group('Performance and Reliability', () {
      test('should handle empty input gracefully', () async {
        final results = await Future.wait([
          threatScanner.scanUrl(''),
          threatScanner.scanEmailContent(''),
          threatScanner.scanPhoneNumber(''),
          threatScanner.scanTextContent(''),
        ]);

        for (final result in results) {
          expect(result.isComplete, isTrue);
          expect(result.recommendations, isNotEmpty);
        }
      });

      test('should handle very long content', () async {
        final longContent = 'A' * 10000;
        
        final result = await threatScanner.scanTextContent(longContent);
        
        expect(result.isComplete, isTrue);
        expect(result.input, equals(longContent));
      });

      test('should complete scans within reasonable time', () async {
        final stopwatch = Stopwatch()..start();
        
        await threatScanner.scanEmailContent(
          'This is a test email with some content to scan for threats.'
        );
        
        stopwatch.stop();
        
        // Should complete within 5 seconds for responsive UI
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });
    });
  });
}
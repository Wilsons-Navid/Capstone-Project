# Security Setup Guide

## API Key Configuration

### VirusTotal API Key Setup

To enable threat scanning functionality, you need to configure a VirusTotal API key:

1. **Get a VirusTotal API Key:**
   - Visit https://www.virustotal.com/gui/join-us
   - Sign up for a free account
   - Navigate to your profile and copy your API key

2. **Configure the API Key (Choose one method):**

   **Method 1: Environment Variable (Recommended for production)**
   ```bash
   export VIRUSTOTAL_API_KEY="your_api_key_here"
   ```

   **Method 2: Secure Storage (For mobile apps)**
   ```dart
   await ApiConfig.setVirusTotalApiKey("your_api_key_here");
   ```

   **Method 3: Build-time configuration**
   Update `lib/core/config/api_config.dart` and modify `_getBuildTimeApiKey()`:
   ```dart
   static String _getBuildTimeApiKey() {
     return const String.fromEnvironment('VIRUSTOTAL_API_KEY', defaultValue: '');
   }
   ```

   Then build with:
   ```bash
   flutter build --dart-define=VIRUSTOTAL_API_KEY=your_api_key_here
   ```

## Security Features Implemented

### 1. Buffer Overflow Protection
- Safe UTF-8 string truncation
- Bounds checking for array access
- Memory-safe buffer operations

### 2. File Upload Security
- File size limits (50MB per file)
- File count limits (10 files per incident)
- MIME type validation
- Magic number verification
- Malicious file detection

### 3. Input Validation
- XSS prevention
- SQL injection protection
- Path traversal prevention
- Enhanced phone number validation for African markets

### 4. API Security
- Rate limiting
- Secure header configuration
- API key protection
- Request validation

## File Upload Constraints

The following file types are allowed:
- **Images**: jpg, jpeg, png, gif, bmp, webp
- **Documents**: pdf, doc, docx, txt, rtf
- **Videos**: mp4, mov, avi, mkv (limited)
- **Archives**: zip, rar (with extra validation)

**Blocked file types:**
- Executables: exe, bat, cmd, scr, vbs, js, jar
- Scripts and potentially dangerous files

## Testing Security Features

### 1. Test File Upload Security
```dart
// This should fail with SecurityException
try {
  final largeFile = FileUploadData(
    fileName: 'large_file.pdf',
    fileSize: 100 * 1024 * 1024, // 100MB - exceeds limit
    fileBytes: [],
  );
  IncidentService._validateSingleFile(largeFile, 0);
} catch (e) {
  print('Security validation working: $e');
}
```

### 2. Test Input Sanitization
```dart
final maliciousInput = '<script>alert("xss")</script>DROP TABLE users;';
final sanitized = SecurityUtils.sanitizeInput(maliciousInput);
// Should return clean text without HTML/SQL
```

### 3. Test Phone Validation
```dart
final validNigerian = '+2348012345678';
final invalidNumber = '+1234567890123456789';
assert(SecurityUtils.isValidPhoneNumber(validNigerian)); // Should pass
assert(!SecurityUtils.isValidPhoneNumber(invalidNumber)); // Should fail
```

## Monitoring and Logging

All security events are logged through the `LoggingService`:
- File validation failures
- API key access attempts
- Rate limiting violations
- Input sanitization events

## Migration Notes

If upgrading from a previous version:

1. **Update imports** in files that use:
   - `ThreatScannerService` (now requires API key configuration)
   - `IncidentService` (now has file validation)
   - Array/string operations (use safe collection extensions)

2. **Configure API keys** before using threat scanning features

3. **Update file upload handling** to handle new `SecurityException`s

## Production Deployment

For production deployment:

1. **Never hardcode API keys** in source code
2. **Use environment variables** or secure key management
3. **Enable rate limiting** on your API endpoints
4. **Monitor security logs** for suspicious activity
5. **Regularly update** VirusTotal API keys
6. **Test file upload limits** match your storage constraints

## Emergency Response

If a security issue is discovered:

1. **Disable affected features** immediately
2. **Check logs** for evidence of exploitation  
3. **Update security rules** in Firestore
4. **Rotate API keys** if compromised
5. **Notify users** if data may be affected
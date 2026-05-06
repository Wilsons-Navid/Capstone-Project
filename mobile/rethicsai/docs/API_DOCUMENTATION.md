# 📚 RethicsAI API Documentation

## 🌟 Overview

RethicsAI provides a comprehensive set of APIs and services for cybersecurity incident reporting, AI-powered assistance, and security education specifically designed for African users. This documentation covers all public APIs, service methods, and integration patterns.

### 📋 Table of Contents

1. [Authentication API](#authentication-api)
2. [Wilson AI Service](#wilson-ai-service)
3. [Incident Management API](#incident-management-api)
4. [Cache Service](#cache-service)
5. [Network Cache Service](#network-cache-service)
6. [Firebase Services](#firebase-services)
7. [Education Service](#education-service)
8. [Threat Scanner Service](#threat-scanner-service)
9. [Activity Service](#activity-service)
10. [Error Handling](#error-handling)
11. [Data Models](#data-models)

---

## 🔐 Authentication API

### AuthService

**Purpose**: Manages user authentication using Firebase Auth with support for email, Google, Apple, and phone authentication.

#### Methods

##### `signInWithEmail(String email, String password)`
```dart
Future<UserCredential?> signInWithEmail(String email, String password)
```

**Description**: Authenticates user with email and password.

**Parameters**:
- `email` (String): User's email address
- `password` (String): User's password

**Returns**: `Future<UserCredential?>` - Firebase user credential or null

**Throws**: `FirebaseAuthException` for auth errors

**Example**:
```dart
try {
  final credential = await authService.signInWithEmail(
    'user@example.com', 
    'securePassword123'
  );
  if (credential != null) {
    print('Login successful: ${credential.user?.uid}');
  }
} catch (e) {
  print('Login failed: $e');
}
```

##### `signUpWithEmail({required String email, required String password, String? firstName, String? lastName, String? phoneNumber, String? country})`
```dart
Future<UserCredential?> signUpWithEmail({
  required String email,
  required String password,
  String? firstName,
  String? lastName,
  String? phoneNumber,
  String? country,
})
```

**Description**: Creates new user account with email and additional profile information.

**Parameters**:
- `email` (String, required): User's email address
- `password` (String, required): User's password
- `firstName` (String, optional): User's first name
- `lastName` (String, optional): User's last name
- `phoneNumber` (String, optional): User's phone number
- `country` (String, optional): User's country

**Returns**: `Future<UserCredential?>` - Firebase user credential or null

**Example**:
```dart
final credential = await authService.signUpWithEmail(
  email: 'newuser@example.com',
  password: 'securePassword123',
  firstName: 'John',
  lastName: 'Doe',
  phoneNumber: '+1234567890',
  country: 'Nigeria',
);
```

##### `signInWithGoogle()`
```dart
Future<UserCredential?> signInWithGoogle()
```

**Description**: Authenticates user with Google Sign-In.

**Returns**: `Future<UserCredential?>` - Firebase user credential or null if cancelled

**Example**:
```dart
final credential = await authService.signInWithGoogle();
if (credential != null) {
  print('Google sign-in successful');
}
```

##### `signInWithApple()`
```dart
Future<UserCredential?> signInWithApple()
```

**Description**: Authenticates user with Apple Sign-In (iOS only).

**Returns**: `Future<UserCredential?>` - Firebase user credential or null if cancelled

##### `signInWithPhoneNumber({required String phoneNumber, required Function(String) onCodeSent, required Function(String) onError})`
```dart
Future<void> signInWithPhoneNumber({
  required String phoneNumber,
  required Function(String) onCodeSent,
  required Function(String) onError,
})
```

**Description**: Initiates phone number verification process.

**Parameters**:
- `phoneNumber` (String): Phone number in international format
- `onCodeSent` (Function): Callback when verification code is sent
- `onError` (Function): Callback for error handling

##### `resetPassword(String email)`
```dart
Future<void> resetPassword(String email)
```

**Description**: Sends password reset email to user.

**Parameters**:
- `email` (String): User's email address

##### `signOut()`
```dart
Future<void> signOut()
```

**Description**: Signs out current user from Firebase and Google.

#### Properties

##### `currentUser`
```dart
User? get currentUser
```

**Description**: Gets current authenticated Firebase user.

##### `authStateChanges`
```dart
Stream<User?> get authStateChanges
```

**Description**: Stream of authentication state changes.

---

## 🤖 Wilson AI Service

### WilsonAIService

**Purpose**: Provides AI-powered cybersecurity assistance with context-aware responses and African-specific threat intelligence.

#### Methods

##### `chatWithWilson({required List<ChatMessage> messages, String? sessionId})`
```dart
Future<WilsonChatResponse> chatWithWilson({
  required List<ChatMessage> messages,
  String? sessionId,
})
```

**Description**: Initiates chat conversation with Wilson AI assistant.

**Parameters**:
- `messages` (List<ChatMessage>): Conversation history
- `sessionId` (String, optional): Unique session identifier

**Returns**: `Future<WilsonChatResponse>` - AI response with metadata

**Throws**: `WilsonAIException` for AI service errors

**Example**:
```dart
final messages = [
  ChatMessage(role: 'user', content: 'How can I protect myself from phishing?'),
];

try {
  final response = await wilsonService.chatWithWilson(
    messages: messages,
    sessionId: 'user-session-123',
  );
  print('AI Response: ${response.response}');
} catch (e) {
  print('AI Error: $e');
}
```

##### `analyzeSuspiciousContent({required String content, String? contentType})`
```dart
Future<ContentAnalysisResult> analyzeSuspiciousContent({
  required String content,
  String? contentType,
})
```

**Description**: Analyzes content for potential cybersecurity threats.

**Parameters**:
- `content` (String): Content to analyze (URL, email, text, etc.)
- `contentType` (String, optional): Type of content ('url', 'email', 'text')

**Returns**: `Future<ContentAnalysisResult>` - Analysis results with threat level

**Example**:
```dart
final result = await wilsonService.analyzeSuspiciousContent(
  content: 'https://suspicious-link.com',
  contentType: 'url',
);

print('Threat Level: ${result.threatLevel}');
print('Red Flags: ${result.redFlags}');
```

##### `getDailyCyberInsights()`
```dart
Future<CyberInsightsResponse> getDailyCyberInsights()
```

**Description**: Retrieves daily cybersecurity insights and tips.

**Returns**: `Future<CyberInsightsResponse>` - Daily insights with actionable tips

##### `getAfricanThreatIntelligence({String region = 'africa'})`
```dart
Future<AfricanThreatIntelligence> getAfricanThreatIntelligence({
  String region = 'africa',
})
```

**Description**: Gets threat intelligence specific to African regions.

**Parameters**:
- `region` (String): Geographic region for threat data

##### `generateSessionId()`
```dart
String generateSessionId()
```

**Description**: Generates unique session ID for chat conversations.

**Returns**: `String` - Unique session identifier

---

## 📋 Incident Management API

### IncidentService

**Purpose**: Manages cybercrime incident reporting, tracking, and case management.

#### Methods

##### `reportIncident(IncidentModel incident)`
```dart
Future<Either<Failure, String>> reportIncident(IncidentModel incident)
```

**Description**: Submits new cybercrime incident report.

**Parameters**:
- `incident` (IncidentModel): Complete incident report data

**Returns**: `Future<Either<Failure, String>>` - Success with incident ID or failure

**Example**:
```dart
final incident = IncidentModel(
  id: uuid.v4(),
  caseNumber: 'CC-${DateTime.now().millisecondsSinceEpoch}',
  userId: currentUser.uid,
  incidentType: 'phishing',
  title: 'Suspicious Email Received',
  description: 'Received email claiming to be from my bank...',
  dateOccurred: DateTime.now(),
  status: 'submitted',
  priorityLevel: 'medium',
  contactPreference: 'email',
  contactDetails: 'user@example.com',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

final result = await incidentService.reportIncident(incident);
result.fold(
  (failure) => print('Error: ${failure.message}'),
  (incidentId) => print('Incident reported: $incidentId'),
);
```

##### `getIncident(String incidentId)`
```dart
Future<Either<Failure, IncidentModel>> getIncident(String incidentId)
```

**Description**: Retrieves specific incident by ID.

**Parameters**:
- `incidentId` (String): Unique incident identifier

##### `getUserIncidents(String userId)`
```dart
Future<Either<Failure, List<IncidentModel>>> getUserIncidents(String userId)
```

**Description**: Gets all incidents reported by a specific user.

**Parameters**:
- `userId` (String): Firebase user UID

##### `updateIncidentStatus(String incidentId, String newStatus)`
```dart
Future<Either<Failure, bool>> updateIncidentStatus(String incidentId, String newStatus)
```

**Description**: Updates incident status (admin function).

**Parameters**:
- `incidentId` (String): Incident identifier
- `newStatus` (String): New status ('submitted', 'under_review', 'in_progress', 'resolved', 'closed')

##### `addInvestigationNote(String incidentId, InvestigationNote note)`
```dart
Future<Either<Failure, bool>> addInvestigationNote(String incidentId, InvestigationNote note)
```

**Description**: Adds investigation note to incident (admin function).

##### `uploadEvidence(String incidentId, EvidenceFile evidence)`
```dart
Future<Either<Failure, String>> uploadEvidence(String incidentId, EvidenceFile evidence)
```

**Description**: Uploads evidence file for incident.

**Returns**: Evidence file ID on success

---

## 🗂️ Cache Service

### CacheService

**Purpose**: Provides advanced caching capabilities for offline functionality and performance optimization.

#### Methods

##### `store<T>({required String key, required T data, CacheCategory category, Duration? ttl, CachePriority priority})`
```dart
Future<Either<Failure, bool>> store<T>({
  required String key,
  required T data,
  CacheCategory category = CacheCategory.general,
  Duration? ttl,
  CachePriority priority = CachePriority.normal,
})
```

**Description**: Stores data in cache with specified parameters.

**Parameters**:
- `key` (String): Unique cache key
- `data` (T): Data to cache
- `category` (CacheCategory): Cache category for organization
- `ttl` (Duration, optional): Time to live (default: 24 hours)
- `priority` (CachePriority): Cache priority level

**Example**:
```dart
await cacheService.store<List<IncidentModel>>(
  key: 'user_incidents_${userId}',
  data: incidents,
  category: CacheCategory.incidents,
  ttl: Duration(hours: 6),
  priority: CachePriority.high,
);
```

##### `retrieve<T>({required String key, CacheCategory category, T Function(Map<String, dynamic>)? fromJson})`
```dart
Future<Either<Failure, T?>> retrieve<T>({
  required String key,
  CacheCategory category = CacheCategory.general,
  T Function(Map<String, dynamic>)? fromJson,
})
```

**Description**: Retrieves data from cache.

**Parameters**:
- `key` (String): Cache key
- `category` (CacheCategory): Cache category
- `fromJson` (Function, optional): JSON deserialization function for complex objects

##### `getOrFetch<T>({required String key, required Future<T> Function() fetchFunction, CacheCategory category, Duration? ttl, bool forceRefresh})`
```dart
Future<Either<Failure, T>> getOrFetch<T>({
  required String key,
  required Future<T> Function() fetchFunction,
  CacheCategory category = CacheCategory.general,
  Duration? ttl,
  T Function(Map<String, dynamic>)? fromJson,
  bool forceRefresh = false,
})
```

**Description**: Gets cached data or fetches fresh data if not available.

**Example**:
```dart
final result = await cacheService.getOrFetch<List<IncidentModel>>(
  key: 'user_incidents_${userId}',
  fetchFunction: () => incidentService.getUserIncidentsFromAPI(userId),
  category: CacheCategory.incidents,
  ttl: Duration(hours: 2),
  fromJson: (json) => (json['data'] as List)
      .map((item) => IncidentModel.fromJson(item))
      .toList(),
);
```

##### `isOnline()`
```dart
Future<bool> isOnline()
```

**Description**: Checks if device has network connectivity.

##### `clearCategory(CacheCategory category)`
```dart
Future<Either<Failure, bool>> clearCategory(CacheCategory category)
```

**Description**: Clears all cached data for specific category.

##### `getStatistics()`
```dart
Future<CacheStatistics> getStatistics()
```

**Description**: Gets comprehensive cache usage statistics.

#### Enums

##### CacheCategory
```dart
enum CacheCategory {
  general,
  incidents,
  education,
  user,
  aiChat,
  images,
}
```

##### CachePriority
```dart
enum CachePriority {
  low,
  normal,
  high,
  critical,
}
```

---

## 🌐 Network Cache Service

### NetworkCacheService

**Purpose**: Provides intelligent network request caching with offline support.

#### Methods

##### `cachedRequest({required String url, required RequestOptions options, Duration? cacheTtl, bool forceRefresh, CacheCategory category, CachePriority priority})`
```dart
Future<Either<Failure, Response>> cachedRequest({
  required String url,
  required RequestOptions options,
  Duration? cacheTtl,
  bool forceRefresh = false,
  CacheCategory category = CacheCategory.general,
  CachePriority priority = CachePriority.normal,
})
```

**Description**: Makes HTTP request with intelligent caching.

**Example**:
```dart
final result = await networkCacheService.cachedRequest(
  url: 'https://api.rethicsai.com/incidents',
  options: RequestOptions(
    path: '/incidents',
    method: 'GET',
    headers: {'Authorization': 'Bearer $token'},
  ),
  cacheTtl: Duration(minutes: 30),
  category: CacheCategory.incidents,
);
```

##### `cacheImage({required String imageUrl, Duration? ttl, int? maxWidth, int? maxHeight, bool forceRefresh})`
```dart
Future<Either<Failure, String>> cacheImage({
  required String imageUrl,
  Duration? ttl,
  int? maxWidth,
  int? maxHeight,
  bool forceRefresh = false,
})
```

**Description**: Downloads and caches image from URL with optimization.

##### `preloadCriticalResources({required List<String> urls, CacheCategory category, Duration? ttl})`
```dart
Future<void> preloadCriticalResources({
  required List<String> urls,
  CacheCategory category = CacheCategory.general,
  Duration? ttl,
})
```

**Description**: Preloads critical resources for better performance.

##### `warmCache({required String userId, required List<String> frequentUrls, Duration? ttl})`
```dart
Future<void> warmCache({
  required String userId,
  required List<String> frequentUrls,
  Duration? ttl,
})
```

**Description**: Warms cache with user-specific frequently accessed content.

---

## 🔥 Firebase Services

### FirebaseService

**Purpose**: Manages Firebase initialization and configuration.

#### Methods

##### `initialize()`
```dart
Future<void> initialize()
```

**Description**: Initializes Firebase services with proper configuration.

##### `isInitialized`
```dart
bool get isInitialized
```

**Description**: Checks if Firebase has been properly initialized.

---

## 📚 Education Service

### EducationService

**Purpose**: Manages security education content, courses, and user progress tracking.

#### Methods

##### `getEducationCategories()`
```dart
Future<Either<Failure, List<EducationCategory>>> getEducationCategories()
```

**Description**: Retrieves all education categories.

##### `getCategoryContent(String categoryId)`
```dart
Future<Either<Failure, List<EducationContent>>> getCategoryContent(String categoryId)
```

**Description**: Gets all content for specific education category.

##### `trackProgress(String userId, String contentId, double progress)`
```dart
Future<Either<Failure, bool>> trackProgress(String userId, String contentId, double progress)
```

**Description**: Records user's learning progress for content.

##### `getUserProgress(String userId)`
```dart
Future<Either<Failure, Map<String, double>>> getUserProgress(String userId)
```

**Description**: Gets user's progress across all education content.

---

## 🔍 Threat Scanner Service

### ThreatScannerService

**Purpose**: Provides content analysis and threat detection capabilities.

#### Methods

##### `scanContent(String content, ContentType type)`
```dart
Future<Either<Failure, ScanResult>> scanContent(String content, ContentType type)
```

**Description**: Scans content for potential security threats.

**Parameters**:
- `content` (String): Content to scan
- `type` (ContentType): Type of content (URL, email, text, phone)

**Returns**: `Future<Either<Failure, ScanResult>>` - Scan results with threat assessment

**Example**:
```dart
final result = await scannerService.scanContent(
  'https://suspicious-website.com/login',
  ContentType.url,
);

result.fold(
  (failure) => print('Scan failed: ${failure.message}'),
  (scanResult) => {
    print('Threat Level: ${scanResult.threatLevel}'),
    print('Is Safe: ${scanResult.isSafe}'),
    print('Warnings: ${scanResult.warnings}'),
  },
);
```

##### `scanURL(String url)`
```dart
Future<Either<Failure, URLScanResult>> scanURL(String url)
```

**Description**: Specialized URL scanning with detailed analysis.

##### `scanEmail(String email)`
```dart
Future<Either<Failure, EmailScanResult>> scanEmail(String email)
```

**Description**: Analyzes email content for phishing and spam indicators.

---

## 📊 Activity Service

### ActivityService

**Purpose**: Tracks user activities and system events for analytics and audit purposes.

#### Methods

##### `recordLoginActivity({required bool success, String? deviceInfo})`
```dart
static Future<void> recordLoginActivity({
  required bool success,
  String? deviceInfo,
})
```

**Description**: Records user login activity.

##### `recordIncidentActivity(String incidentId, String action)`
```dart
static Future<void> recordIncidentActivity(String incidentId, String action)
```

**Description**: Records incident-related activities.

##### `recordAIInteraction(String sessionId, String query, String response)`
```dart
static Future<void> recordAIInteraction(String sessionId, String query, String response)
```

**Description**: Records AI chat interactions for improvement.

---

## ⚠️ Error Handling

### Failure Classes

All services use a consistent error handling pattern with `Either<Failure, T>` return types.

#### Base Failure Class
```dart
abstract class Failure {
  final String message;
  const Failure(this.message);
}
```

#### Specific Failure Types

##### `NetworkFailure`
```dart
class NetworkFailure extends Failure {
  NetworkFailure(super.message);
}
```
**Used for**: Network connectivity issues, timeouts, and HTTP errors.

##### `ServerFailure`
```dart
class ServerFailure extends Failure {
  ServerFailure(super.message);
}
```
**Used for**: Server-side errors and API failures.

##### `CacheFailure`
```dart
class CacheFailure extends Failure {
  CacheFailure(super.message);
}
```
**Used for**: Cache storage and retrieval issues.

##### `ValidationFailure`
```dart
class ValidationFailure extends Failure {
  ValidationFailure(super.message);
}
```
**Used for**: Input validation and data format errors.

### Error Handling Pattern

```dart
final result = await someService.performOperation();

result.fold(
  (failure) {
    // Handle error
    if (failure is NetworkFailure) {
      showSnackBar('Network error: Please check your connection');
    } else if (failure is ServerFailure) {
      showSnackBar('Server error: Please try again later');
    } else {
      showSnackBar('An error occurred: ${failure.message}');
    }
  },
  (success) {
    // Handle success
    print('Operation successful: $success');
  },
);
```

---

## 📋 Data Models

### IncidentModel

**Purpose**: Represents a cybercrime incident report with all associated data.

#### Properties
```dart
class IncidentModel {
  final String id;
  final String caseNumber;
  final String userId;
  final String incidentType;
  final String title;
  final String description;
  final DateTime dateOccurred;
  final String? locationOccurred;
  final double? financialLoss;
  final String? suspectInformation;
  final List<EvidenceFile> evidenceFiles;
  final String contactPreference;
  final String contactDetails;
  final String priorityLevel;
  final String status;
  final String? assignedOfficer;
  final List<InvestigationNote> investigationNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
}
```

#### Factory Methods
```dart
factory IncidentModel.fromJson(Map<String, dynamic> json)
Map<String, dynamic> toJson()
```

### UserModel

**Purpose**: Represents user profile and account information.

#### Properties
```dart
class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String country;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isVerified;
  final String role;
  final Map<String, dynamic>? preferences;
}
```

### ChatMessage

**Purpose**: Represents a message in Wilson AI chat conversation.

#### Properties
```dart
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
}
```

### WilsonChatResponse

**Purpose**: Response from Wilson AI service.

#### Properties
```dart
class WilsonChatResponse {
  final String response;
  final String messageId;
  final int timestamp;
  final String sessionId;
}
```

### ContentAnalysisResult

**Purpose**: Result of content threat analysis.

#### Properties
```dart
class ContentAnalysisResult {
  final String threatLevel; // 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
  final List<String>? threatTypes;
  final List<String>? redFlags;
  final List<String>? recommendations;
  final String? analysis;
  final String analysisId;
  final int timestamp;
}
```

### EvidenceFile

**Purpose**: Represents an uploaded evidence file.

#### Properties
```dart
class EvidenceFile {
  final String id;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String? fileData; // Base64 encoded or URL
  final String? filePath;
  final String? description;
  final DateTime uploadedAt;
}
```

---

## 🔧 Integration Examples

### Complete Incident Reporting Flow
```dart
class IncidentReportingExample {
  final AuthService _authService = AuthService();
  final IncidentService _incidentService = IncidentService();
  final WilsonAIService _wilsonService = WilsonAIService();
  
  Future<void> reportIncidentWithAIAssistance() async {
    // 1. Ensure user is authenticated
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to report incident');
    }
    
    // 2. Get AI assistance for incident classification
    final aiResponse = await _wilsonService.chatWithWilson(
      messages: [
        ChatMessage(
          role: 'user',
          content: 'I received a suspicious email claiming to be from my bank asking for my login details',
        ),
      ],
    );
    
    // 3. Create incident based on AI suggestions
    final incident = IncidentModel(
      id: uuid.v4(),
      caseNumber: 'CC-${DateTime.now().millisecondsSinceEpoch}',
      userId: user.uid,
      incidentType: 'phishing', // AI suggested classification
      title: 'Suspicious Banking Email',
      description: 'Received email claiming to be from bank requesting login details',
      dateOccurred: DateTime.now(),
      status: 'submitted',
      priorityLevel: 'high', // AI determined priority
      contactPreference: 'email',
      contactDetails: user.email ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // 4. Submit incident report
    final result = await _incidentService.reportIncident(incident);
    
    result.fold(
      (failure) => print('Failed to report incident: ${failure.message}'),
      (incidentId) => print('Incident reported successfully: $incidentId'),
    );
  }
}
```

### Offline-First Data Loading
```dart
class OfflineFirstExample {
  final CacheService _cacheService = CacheService.instance;
  final NetworkCacheService _networkCache = NetworkCacheService.instance;
  
  Future<List<IncidentModel>> getUserIncidentsOfflineFirst(String userId) async {
    final result = await _cacheService.getOrFetch<List<IncidentModel>>(
      key: 'user_incidents_$userId',
      fetchFunction: () async {
        // This only runs if cache miss or force refresh
        final response = await _networkCache.cachedRequest(
          url: 'https://api.rethicsai.com/users/$userId/incidents',
          options: RequestOptions(
            path: '/users/$userId/incidents',
            method: 'GET',
          ),
          category: CacheCategory.incidents,
          cacheTtl: Duration(hours: 2),
        );
        
        return response.fold(
          (failure) => throw Exception(failure.message),
          (httpResponse) {
            final data = httpResponse.data as List;
            return data.map((json) => IncidentModel.fromJson(json)).toList();
          },
        );
      },
      category: CacheCategory.incidents,
      ttl: Duration(hours: 4),
      fromJson: (json) => (json['data'] as List)
          .map((item) => IncidentModel.fromJson(item))
          .toList(),
    );
    
    return result.fold(
      (failure) => throw Exception(failure.message),
      (incidents) => incidents,
    );
  }
}
```

---

## 🎯 Best Practices

### 1. Error Handling
Always use the `Either<Failure, T>` pattern and handle both success and failure cases:

```dart
final result = await service.performOperation();
result.fold(
  (failure) => handleError(failure),
  (success) => handleSuccess(success),
);
```

### 2. Caching Strategy
Use appropriate cache categories and TTL values:

```dart
// Short-lived data (30 minutes)
await cacheService.store(
  key: 'daily_insights',
  data: insights,
  category: CacheCategory.general,
  ttl: Duration(minutes: 30),
);

// User-specific data (6 hours)
await cacheService.store(
  key: 'user_profile_$userId',
  data: userProfile,
  category: CacheCategory.user,
  ttl: Duration(hours: 6),
  priority: CachePriority.high,
);
```

### 3. Authentication Checks
Always verify authentication before sensitive operations:

```dart
final user = authService.currentUser;
if (user == null) {
  return Left(ValidationFailure('Authentication required'));
}
```

### 4. Offline Handling
Design for offline-first experiences:

```dart
if (!await cacheService.isOnline()) {
  // Use cached data or show appropriate offline message
  return getCachedData();
}
```

---

## 📞 Support and Contact

For API support, integration questions, or bug reports:

- **Email**: api-support@rethicsai.com
- **Documentation**: https://docs.rethicsai.com
- **Status Page**: https://status.rethicsai.com
- **Community Forum**: https://community.rethicsai.com

---

**Last Updated**: December 2024  
**API Version**: v1.0.0  
**SDK Version**: Flutter 3.24+
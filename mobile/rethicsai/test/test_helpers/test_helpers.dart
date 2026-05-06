import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../lib/core/services/auth_service.dart';
import '../../lib/core/services/firebase_service.dart';
import '../../lib/core/services/wilson_ai_service.dart';
import '../../lib/core/services/incident_service.dart';
import '../../lib/shared/models/incident_model.dart';
import '../../lib/shared/models/user_model.dart';

// Mock classes
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockUserCredential extends Mock implements UserCredential {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockAuthService extends Mock implements AuthService {}
class MockFirebaseService extends Mock implements FirebaseService {}
class MockWilsonAIService extends Mock implements WilsonAIService {}
class MockIncidentService extends Mock implements IncidentService {}

class TestHelpers {
  // Test data generators
  static IncidentModel createMockIncident({
    String? id,
    String? caseNumber,
    String? userId,
    String? incidentType,
    String? title,
    String? description,
    DateTime? dateOccurred,
    String? status,
    String? priorityLevel,
  }) {
    return IncidentModel(
      id: id ?? 'test-incident-1',
      caseNumber: caseNumber ?? 'CC-001234',
      userId: userId ?? 'test-user-1',
      incidentType: incidentType ?? 'phishing',
      title: title ?? 'Test Phishing Incident',
      description: description ?? 'Test description for phishing incident',
      dateOccurred: dateOccurred ?? DateTime.now().subtract(const Duration(days: 1)),
      status: status ?? 'submitted',
      priorityLevel: priorityLevel ?? 'medium',
      contactPreference: 'email',
      contactDetails: 'test@example.com',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static UserModel createMockUser({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? country,
  }) {
    return UserModel(
      uid: uid ?? 'test-user-1',
      email: email ?? 'test@example.com',
      firstName: firstName ?? 'John',
      lastName: lastName ?? 'Doe',
      phoneNumber: phoneNumber ?? '+1234567890',
      country: country ?? 'Nigeria',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isVerified: true,
      role: 'user',
    );
  }

  static List<IncidentModel> createMockIncidentList({int count = 3}) {
    return List.generate(count, (index) => createMockIncident(
      id: 'test-incident-${index + 1}',
      caseNumber: 'CC-00123${index + 1}',
      title: 'Test Incident ${index + 1}',
    ));
  }

  static ChatMessage createMockChatMessage({
    String? role,
    String? content,
  }) {
    return ChatMessage(
      role: role ?? 'user',
      content: content ?? 'Test message content',
    );
  }

  static WilsonChatResponse createMockWilsonResponse({
    String? response,
    String? messageId,
    String? sessionId,
  }) {
    return WilsonChatResponse(
      response: response ?? 'Test AI response',
      messageId: messageId ?? 'msg-123',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      sessionId: sessionId ?? 'session-123',
    );
  }

  // Widget test helpers
  static Widget createTestApp({
    required Widget child,
    List<Locale>? supportedLocales,
  }) {
    return EasyLocalization(
      supportedLocales: supportedLocales ?? const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    );
  }

  static Widget createTestScaffold({
    required Widget body,
    AppBar? appBar,
  }) {
    return Scaffold(
      appBar: appBar,
      body: body,
    );
  }

  // Service injection helpers
  static void setupMockServices() {
    GetIt.instance.reset();
    
    GetIt.instance.registerLazySingleton<AuthService>(() => MockAuthService());
    GetIt.instance.registerLazySingleton<FirebaseService>(() => MockFirebaseService());
    GetIt.instance.registerLazySingleton<WilsonAIService>(() => MockWilsonAIService());
    GetIt.instance.registerLazySingleton<IncidentService>(() => MockIncidentService());
  }

  static void tearDownMockServices() {
    GetIt.instance.reset();
  }

  // Assertion helpers
  static void expectWidgetToBePresent(WidgetTester tester, Type widgetType) {
    expect(find.byType(widgetType), findsOneWidget);
  }

  static void expectWidgetNotToBePresent(WidgetTester tester, Type widgetType) {
    expect(find.byType(widgetType), findsNothing);
  }

  static void expectTextToBePresent(WidgetTester tester, String text) {
    expect(find.text(text), findsOneWidget);
  }

  static void expectTextNotToBePresent(WidgetTester tester, String text) {
    expect(find.text(text), findsNothing);
  }

  // Firebase test helpers
  static void setupFirebaseMocks(MockFirebaseAuth mockAuth, MockFirebaseFirestore mockFirestore) {
    // Setup common Firebase auth mocks
    when(mockAuth.currentUser).thenReturn(null);
    when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));
    
    // Setup common Firestore mocks
    final mockCollection = MockCollectionReference();
    when(mockFirestore.collection(any)).thenReturn(mockCollection);
  }

  // Animation test helpers
  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  static Future<void> pumpFrame(WidgetTester tester, {Duration duration = const Duration(milliseconds: 16)}) async {
    await tester.pump(duration);
  }

  // Error simulation helpers
  static Exception createMockNetworkException() {
    return Exception('Network error occurred');
  }

  static FirebaseAuthException createMockAuthException() {
    return FirebaseAuthException(
      code: 'user-not-found',
      message: 'No user found for that email.',
    );
  }

  static FirebaseException createMockFirestoreException() {
    return FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'Insufficient permissions.',
    );
  }
}

// Test constants
class TestConstants {
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'testPassword123';
  static const String testUserId = 'test-user-123';
  static const String testIncidentId = 'test-incident-123';
  static const String testCaseNumber = 'CC-001234';
  static const String testSessionId = 'test-session-123';
  
  static const Duration shortDelay = Duration(milliseconds: 100);
  static const Duration mediumDelay = Duration(milliseconds: 500);
  static const Duration longDelay = Duration(seconds: 1);
}

// Custom matchers
class IsEmptyWidget extends Matcher {
  @override
  bool matches(dynamic item, Map matchState) {
    if (item is Widget) {
      return item is SizedBox && (item.width == 0 || item.height == 0);
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('is an empty widget');
}

Matcher isEmptyWidget() => IsEmptyWidget();
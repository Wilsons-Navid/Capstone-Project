# 🧪 RethicsAI Testing Guide

## 📋 Overview

This guide provides comprehensive instructions for testing the RethicsAI application, including unit tests, widget tests, integration tests, and testing best practices.

## 🛠️ Test Setup

### Prerequisites

Ensure you have the following dependencies in your `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  bloc_test: ^9.1.5
  integration_test:
    sdk: flutter
  firebase_auth_mocks: ^0.13.0
  fake_cloud_firestore: ^2.4.4
  build_runner: ^2.4.13
```

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/core/services/auth_service_test.dart

# Run integration tests
flutter test integration_test/
```

## 🔧 Test Architecture

### Test Helper Setup

Our test helpers provide common utilities and mocks:

```dart
// test/test_helpers/test_helpers.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class TestHelpers {
  // Mock data generators
  static IncidentModel createMockIncident({...}) { ... }
  static UserModel createMockUser({...}) { ... }
  
  // Widget test helpers
  static Widget createTestApp({required Widget child}) { ... }
  
  // Service injection helpers
  static void setupMockServices() { ... }
  
  // Assertion helpers
  static void expectWidgetToBePresent(WidgetTester tester, Type widgetType) { ... }
}
```

### Mock Generation

Generate mocks using Mockito:

```bash
dart run build_runner build
```

## 🧪 Unit Tests

### Service Testing Example

```dart
// test/core/services/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([FirebaseAuth, User, UserCredential])
import 'auth_service_test.mocks.dart';

void main() {
  group('AuthService Tests', () {
    late AuthService authService;
    late MockFirebaseAuth mockFirebaseAuth;
    
    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      authService = AuthService();
    });

    test('signInWithEmail should return UserCredential on success', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      final mockUserCredential = MockUserCredential();
      
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      )).thenAnswer((_) async => mockUserCredential);

      // Act
      final result = await authService.signInWithEmail(email, password);

      // Assert
      expect(result, isNotNull);
      expect(result, isA<UserCredential>());
    });
  });
}
```

### BLoC Testing Example

```dart
// test/features/auth/presentation/bloc/auth_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthBloc Tests', () {
    late AuthBloc authBloc;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      authBloc = AuthBloc();
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when login succeeds',
      build: () {
        when(mockAuthService.signInWithEmail(any, any))
            .thenAnswer((_) async => mockUserCredential);
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthLoginRequested('email', 'password')),
      expect: () => [AuthLoading(), AuthSuccess(mockUser)],
    );
  });
}
```

## 🎨 Widget Tests

### Basic Widget Testing

```dart
// test/features/dashboard/presentation/pages/dashboard_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  group('DashboardPage Widget Tests', () {
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      TestHelpers.setupMockServices();
    });

    tearDown(() {
      TestHelpers.tearDownMockServices();
    });

    testWidgets('should display welcome message', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthSuccess(mockUser));

      // Act
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: BlocProvider<AuthBloc>(
            create: (_) => mockAuthBloc,
            child: const DashboardPage(),
          ),
        ),
      );

      // Assert
      expect(find.text('Welcome to RethicsAI'), findsOneWidget);
      expect(find.byType(DashboardFeatureCard), findsWidgets);
    });

    testWidgets('should navigate to incident report on FAB tap', 
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: BlocProvider<AuthBloc>(
            create: (_) => mockAuthBloc,
            child: const DashboardPage(),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Assert
      // Verify navigation occurred (implementation depends on your routing)
      expect(find.text('Quick Report'), findsOneWidget);
    });
  });
}
```

### Form Testing

```dart
testWidgets('should validate email field', (WidgetTester tester) async {
  await tester.pumpWidget(
    TestHelpers.createTestApp(child: const LoginPage()),
  );

  // Find email field
  final emailField = find.byKey(const ValueKey('email_field'));
  
  // Enter invalid email
  await tester.enterText(emailField, 'invalid-email');
  await tester.pump();

  // Tap login button to trigger validation
  await tester.tap(find.text('Sign In'));
  await tester.pump();

  // Expect validation error
  expect(find.text('Please enter a valid email'), findsOneWidget);
});
```

## 🔄 Integration Tests

### Full App Flow Testing

```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rethicsai/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Tests', () {
    testWidgets('Complete incident reporting flow', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate through authentication
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Fill login form
      await tester.enterText(
        find.byKey(const ValueKey('email_field')), 
        'test@example.com'
      );
      await tester.enterText(
        find.byKey(const ValueKey('password_field')), 
        'testPassword123'
      );
      
      // Tap sign in
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to incident reporting
      await tester.tap(find.text('Report Incident'));
      await tester.pumpAndSettle();

      // Fill incident report
      await tester.enterText(
        find.byKey(const ValueKey('incident_title')), 
        'Test Incident'
      );
      await tester.enterText(
        find.byKey(const ValueKey('incident_description')), 
        'This is a test incident description'
      );

      // Select incident type
      await tester.tap(find.text('Phishing'));
      await tester.pumpAndSettle();

      // Submit report
      await tester.tap(find.text('Submit Report'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify success
      expect(find.text('Incident reported successfully'), findsOneWidget);
    });

    testWidgets('AI Chat interaction flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to AI chat (assuming user is logged in)
      await tester.tap(find.text('Wilson AI'));
      await tester.pumpAndSettle();

      // Send a message
      await tester.enterText(
        find.byKey(const ValueKey('chat_input')), 
        'How can I protect myself from phishing?'
      );
      await tester.tap(find.byKey(const ValueKey('send_button')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify AI response appears
      expect(find.textContaining('phishing'), findsWidgets);
      expect(find.byType(ChatMessageBubble), findsAtLeastNWidgets(2));
    });
  });
}
```

## 🚦 Test Coverage

### Generating Coverage Reports

```bash
# Generate coverage
flutter test --coverage

# Generate HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html

# Open coverage report
open coverage/html/index.html
```

### Coverage Goals

- **Unit Tests**: Aim for 90%+ coverage on services and business logic
- **Widget Tests**: 80%+ coverage on UI components
- **Integration Tests**: Cover all critical user flows

## 🎯 Testing Best Practices

### 1. Test Structure (AAA Pattern)

```dart
test('description of what is being tested', () async {
  // Arrange - Set up test data and mocks
  final mockService = MockService();
  when(mockService.getData()).thenReturn(testData);
  
  // Act - Execute the function being tested
  final result = await serviceUnderTest.processData();
  
  // Assert - Verify the results
  expect(result, equals(expectedResult));
  verify(mockService.getData()).called(1);
});
```

### 2. Mock Hierarchy

```dart
// Create a base mock for common functionality
class MockBaseService extends Mock implements BaseService {
  @override
  Future<Either<Failure, T>> performOperation<T>() {
    return super.noSuchMethod(
      Invocation.method(#performOperation, []),
      returnValue: Future.value(Right(null as T)),
    );
  }
}
```

### 3. Test Data Management

```dart
class TestData {
  static final validIncident = IncidentModel(
    id: 'test-id',
    caseNumber: 'CC-123456',
    userId: 'user-123',
    // ... other required fields
  );
  
  static final invalidIncident = IncidentModel(
    id: '', // Invalid empty ID
    // ... other fields
  );
}
```

### 4. Async Testing

```dart
testWidgets('should handle async operations correctly', (tester) async {
  // Pump widget
  await tester.pumpWidget(widget);
  
  // Trigger async operation
  await tester.tap(find.text('Load Data'));
  
  // Wait for loading indicator
  await tester.pump();
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  
  // Wait for operation to complete
  await tester.pumpAndSettle();
  
  // Verify final state
  expect(find.text('Data Loaded'), findsOneWidget);
});
```

### 5. Error Testing

```dart
blocTest<DataBloc, DataState>(
  'emits error state when service fails',
  build: () {
    when(() => mockService.getData())
        .thenThrow(NetworkFailure('Connection failed'));
    return dataBloc;
  },
  act: (bloc) => bloc.add(LoadData()),
  expect: () => [
    DataLoading(),
    DataError('Connection failed'),
  ],
);
```

## 🐛 Testing Common Issues

### 1. Firebase Testing

```dart
// Use Firebase mocks for testing
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

setUp(() {
  // Setup Firebase mocks
  TestHelpers.setupFirebaseMocks(mockAuth, mockFirestore);
});
```

### 2. Provider/BLoC Testing

```dart
testWidgets('should provide correct bloc instance', (tester) async {
  await tester.pumpWidget(
    BlocProvider<AuthBloc>(
      create: (_) => mockAuthBloc,
      child: TestWidget(),
    ),
  );

  final authBloc = BlocProvider.of<AuthBloc>(tester.element(find.byType(TestWidget)));
  expect(authBloc, equals(mockAuthBloc));
});
```

### 3. Navigation Testing

```dart
testWidgets('should navigate to correct page', (tester) async {
  final mockNavigator = MockNavigatorObserver();
  
  await tester.pumpWidget(
    MaterialApp(
      home: const HomePage(),
      navigatorObservers: [mockNavigator],
    ),
  );

  await tester.tap(find.text('Go to Settings'));
  await tester.pumpAndSettle();

  verify(mockNavigator.didPush(any, any));
});
```

## 📊 Performance Testing

### Memory Leak Testing

```dart
testWidgets('should not leak memory', (tester) async {
  // Create and dispose widget multiple times
  for (int i = 0; i < 10; i++) {
    await tester.pumpWidget(const ExpensiveWidget());
    await tester.pumpWidget(Container()); // Dispose
  }
  
  // Force garbage collection
  await tester.binding.delayed(const Duration(milliseconds: 100));
  
  // Memory checks would go here (implementation specific)
});
```

### Animation Performance

```dart
testWidgets('animations should perform smoothly', (tester) async {
  await tester.pumpWidget(const AnimatedWidget());
  
  // Start animation
  await tester.tap(find.text('Animate'));
  
  // Check animation doesn't drop frames
  await tester.pumpAndSettle(const Duration(seconds: 1));
  
  // Verify animation completed
  expect(find.byKey(const ValueKey('animated_element')), findsOneWidget);
});
```

## 🔧 Test Utilities

### Custom Matchers

```dart
Matcher isValidIncident() => predicate<IncidentModel>(
  (incident) => 
      incident.id.isNotEmpty &&
      incident.caseNumber.startsWith('CC-') &&
      incident.userId.isNotEmpty,
  'is a valid incident',
);

// Usage
expect(incident, isValidIncident());
```

### Test Extensions

```dart
extension WidgetTesterExtensions on WidgetTester {
  Future<void> pumpUntilFound(
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final end = DateTime.now().add(timeout);
    
    do {
      await pump();
      if (any(finder)) return;
      await Future.delayed(const Duration(milliseconds: 100));
    } while (DateTime.now().isBefore(end));
    
    throw Exception('Widget not found within timeout');
  }
}
```

## 🚀 Continuous Integration

### GitHub Actions Example

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v1
        with:
          file: coverage/lcov.info
```

## 📝 Test Documentation

### Writing Test Documentation

```dart
/// Tests the AuthService authentication flows
/// 
/// Coverage:
/// - Email/password authentication
/// - Google Sign-In integration
/// - Apple Sign-In integration (iOS)
/// - Phone number verification
/// - Password reset functionality
/// - Error handling for various scenarios
group('AuthService Authentication Tests', () {
  // Test implementations...
});
```

### Test Checklists

Before submitting code:
- [ ] All tests pass locally
- [ ] New features have corresponding tests
- [ ] Edge cases are covered
- [ ] Error scenarios are tested
- [ ] Performance impacts are considered
- [ ] Test documentation is updated

---

## 📞 Support

For testing support or questions:
- **Email**: dev-support@rethicsai.com
- **Documentation**: https://docs.rethicsai.com/testing
- **Community**: https://community.rethicsai.com/testing

---

**Last Updated**: December 2024  
**Testing Framework**: Flutter Test + Mockito + BlocTest
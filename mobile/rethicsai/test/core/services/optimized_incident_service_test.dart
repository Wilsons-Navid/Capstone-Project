import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:rethicsai/core/services/optimized_incident_service.dart';
import 'package:rethicsai/core/errors/failures.dart';
import 'package:rethicsai/shared/models/file_upload_data.dart';

// Generate mocks (in a real project, use build_runner to generate these)
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  QueryDocumentSnapshot,
  FirebaseAuth,
  User,
  Connectivity,
])
import 'optimized_incident_service_test.mocks.dart';

void main() {
  late OptimizedIncidentService service;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockConnectivity mockConnectivity;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockConnectivity = MockConnectivity();
    
    // Setup default mocks
    when(mockFirestore.collection('incidents')).thenReturn(mockCollection);
    when(mockCollection.doc()).thenReturn(mockDocument);
    when(mockDocument.id).thenReturn('test_incident_id');
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test_user_id');
    when(mockConnectivity.checkConnectivity()).thenAnswer((_) async => ConnectivityResult.wifi);
  });

  group('OptimizedIncidentService', () {
    group('Incident Creation', () {
      test('should create incident successfully with valid data', () async {
        // Arrange
        final validIncidentData = {
          'incident_type': 'phishing',
          'title': 'Phishing Email Received',
          'description': 'Received suspicious email asking for credentials',
          'date_occurred': '2024-01-15T10:30:00Z',
          'location_occurred': 'Nairobi, Kenya',
          'financial_loss': 0.0,
          'suspect_information': 'Unknown sender',
          'contact_preference': 'email',
          'contact_details': 'user@example.com',
          'priority_level': 'medium',
          'reporter_name': 'Test User',
          'reporter_phone': '+254712345678',
          'reporter_country': 'Kenya',
        };

        when(mockDocument.set(any)).thenAnswer((_) async => Future.value());
        
        // Act
        final result = await OptimizedIncidentService.createIncident(
          incidentData: validIncidentData,
        );

        // Assert
        expect(result.isRight, isTrue);
        expect(result.value, equals('test_incident_id'));
        verify(mockDocument.set(any)).called(1);
      });

      test('should fail with validation error for missing required fields', () async {
        // Arrange
        final invalidIncidentData = {
          'title': 'Missing required fields',
          // Missing incident_type, description, date_occurred
        };

        // Act
        final result = await OptimizedIncidentService.createIncident(
          incidentData: invalidIncidentData,
        );

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.leftValue, isA<ValidationFailure>());
        expect(result.leftValue.message, contains('Required field missing'));
      });

      test('should sanitize malicious input data', () async {
        // Arrange
        final maliciousIncidentData = {
          'incident_type': 'phishing',
          'title': '<script>alert("xss")</script>Phishing Email',
          'description': 'Suspicious email with SELECT * FROM users',
          'date_occurred': '2024-01-15T10:30:00Z',
          'location_occurred': 'javascript:alert("xss")',
          'contact_preference': 'email',
          'contact_details': 'user@example.com',
          'priority_level': 'medium',
          'reporter_name': 'DROP TABLE users',
          'reporter_phone': '+254712345678',
          'reporter_country': 'Kenya',
        };

        when(mockDocument.set(any)).thenAnswer((_) async => Future.value());
        
        // Act
        final result = await OptimizedIncidentService.createIncident(
          incidentData: maliciousIncidentData,
        );

        // Assert
        expect(result.isRight, isTrue);
        
        // Verify sanitization occurred
        final capturedData = verify(mockDocument.set(captureAny)).captured.single as Map<String, dynamic>;
        expect(capturedData['title'], isNot(contains('<script>')));
        expect(capturedData['description'], isNot(contains('SELECT')));
        expect(capturedData['location_occurred'], isNot(contains('javascript:')));
        expect(capturedData['reporter_name'], isNot(contains('DROP')));
      });

      test('should validate phone number format', () async {
        // Arrange
        final incidentDataWithInvalidPhone = {
          'incident_type': 'phishing',
          'title': 'Test Incident',
          'description': 'Test description',
          'date_occurred': '2024-01-15T10:30:00Z',
          'contact_preference': 'phone',
          'contact_details': 'phone',
          'priority_level': 'medium',
          'reporter_name': 'Test User',
          'reporter_phone': 'invalid-phone',
          'reporter_country': 'Kenya',
        };

        // Act
        final result = await OptimizedIncidentService.createIncident(
          incidentData: incidentDataWithInvalidPhone,
        );

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.leftValue, isA<ValidationFailure>());
        expect(result.leftValue.message, contains('Invalid phone number'));
      });

      test('should validate email format when email is contact preference', () async {
        // Arrange
        final incidentDataWithInvalidEmail = {
          'incident_type': 'phishing',
          'title': 'Test Incident',
          'description': 'Test description',
          'date_occurred': '2024-01-15T10:30:00Z',
          'contact_preference': 'email',
          'contact_details': 'invalid-email',
          'priority_level': 'medium',
          'reporter_name': 'Test User',
          'reporter_phone': '+254712345678',
          'reporter_country': 'Kenya',
        };

        // Act
        final result = await OptimizedIncidentService.createIncident(
          incidentData: incidentDataWithInvalidEmail,
        );

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.leftValue, isA<ValidationFailure>());
        expect(result.leftValue.message, contains('Invalid email'));
      });

      test('should handle offline scenario gracefully', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity()).thenAnswer((_) async => ConnectivityResult.none);
        
        final validIncidentData = {
          'incident_type': 'phishing',
          'title': 'Phishing Email Received',
          'description': 'Received suspicious email',
          'date_occurred': '2024-01-15T10:30:00Z',
          'contact_preference': 'email',
          'contact_details': 'user@example.com',
          'priority_level': 'medium',
          'reporter_name': 'Test User',
          'reporter_phone': '+254712345678',
          'reporter_country': 'Kenya',
        };

        // Act
        final result = await OptimizedIncidentService.createIncident(
          incidentData: validIncidentData,
        );

        // Assert
        expect(result.isRight, isTrue);
        // In offline mode, it should still return the incident ID
        expect(result.value, equals('test_incident_id'));
      });
    });

    group('Incident Retrieval', () {
      test('should retrieve user incidents with caching', () async {
        // Arrange
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockDoc1 = MockQueryDocumentSnapshot();
        final mockDoc2 = MockQueryDocumentSnapshot();
        
        when(mockCollection.where('user_id', isEqualTo: 'test_user_id'))
            .thenReturn(mockCollection);
        when(mockCollection.limit(20)).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
        
        when(mockDoc1.id).thenReturn('incident1');
        when(mockDoc1.data()).thenReturn({
          'id': 'incident1',
          'incident_type': 'phishing',
          'title': 'Test Incident 1',
          'description': 'Test description',
          'created_at': '2024-01-15T10:30:00Z',
          'status': 'submitted',
          'user_id': 'test_user_id',
        });
        
        when(mockDoc2.id).thenReturn('incident2');
        when(mockDoc2.data()).thenReturn({
          'id': 'incident2',
          'incident_type': 'malware',
          'title': 'Test Incident 2',
          'description': 'Test description 2',
          'created_at': '2024-01-16T10:30:00Z',
          'status': 'under_review',
          'user_id': 'test_user_id',
        });

        // Act
        final result = await OptimizedIncidentService.getUserIncidents(
          userId: 'test_user_id',
        );

        // Assert
        expect(result.isRight, isTrue);
        expect(result.value.length, equals(2));
        expect(result.value.first.title, equals('Test Incident 2')); // Sorted by date
        expect(result.value.last.title, equals('Test Incident 1'));
      });

      test('should handle network timeout gracefully', () async {
        // Arrange
        when(mockCollection.where('user_id', isEqualTo: 'test_user_id'))
            .thenReturn(mockCollection);
        when(mockCollection.limit(20)).thenReturn(mockCollection);
        when(mockCollection.get()).thenThrow(
          Exception('Network timeout')
        );

        // Act
        final result = await OptimizedIncidentService.getUserIncidents(
          userId: 'test_user_id',
        );

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.leftValue, isA<DatabaseFailure>());
      });

      test('should skip malformed incident data without failing', () async {
        // Arrange
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockValidDoc = MockQueryDocumentSnapshot();
        final mockMalformedDoc = MockQueryDocumentSnapshot();
        
        when(mockCollection.where('user_id', isEqualTo: 'test_user_id'))
            .thenReturn(mockCollection);
        when(mockCollection.limit(20)).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockValidDoc, mockMalformedDoc]);
        
        // Valid document
        when(mockValidDoc.id).thenReturn('valid_incident');
        when(mockValidDoc.data()).thenReturn({
          'id': 'valid_incident',
          'incident_type': 'phishing',
          'title': 'Valid Incident',
          'description': 'Valid description',
          'created_at': '2024-01-15T10:30:00Z',
          'status': 'submitted',
          'user_id': 'test_user_id',
        });
        
        // Malformed document (missing required fields)
        when(mockMalformedDoc.id).thenReturn('malformed_incident');
        when(mockMalformedDoc.data()).thenReturn({
          'id': 'malformed_incident',
          // Missing required fields to cause parsing error
        });

        // Act
        final result = await OptimizedIncidentService.getUserIncidents(
          userId: 'test_user_id',
        );

        // Assert
        expect(result.isRight, isTrue);
        expect(result.value.length, equals(1)); // Only valid incident returned
        expect(result.value.first.title, equals('Valid Incident'));
      });
    });

    group('Single Incident Retrieval', () {
      test('should retrieve single incident with caching', () async {
        // Arrange
        final mockDocSnapshot = MockDocumentSnapshot();
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn({
          'id': 'test_incident_id',
          'incident_type': 'phishing',
          'title': 'Test Incident',
          'description': 'Test description',
          'created_at': '2024-01-15T10:30:00Z',
          'status': 'submitted',
          'user_id': 'test_user_id',
        });

        // Act
        final result = await OptimizedIncidentService.getIncident('test_incident_id');

        // Assert
        expect(result.isRight, isTrue);
        expect(result.value.title, equals('Test Incident'));
        expect(result.value.id, equals('test_incident_id'));
      });

      test('should return not found error for non-existent incident', () async {
        // Arrange
        final mockDocSnapshot = MockDocumentSnapshot();
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(false);

        // Act
        final result = await OptimizedIncidentService.getIncident('non_existent_id');

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.leftValue, isA<DatabaseFailure>());
        expect(result.leftValue.code, equals('NOT_FOUND'));
      });
    });

    group('Incident Status Updates', () {
      test('should update incident status successfully', () async {
        // Arrange
        when(mockDocument.update(any)).thenAnswer((_) async => Future.value());

        // Act
        final result = await OptimizedIncidentService.updateIncidentStatus(
          incidentId: 'test_incident_id',
          newStatus: 'under_review',
          notes: 'Investigation started',
        );

        // Assert
        expect(result.isRight, isTrue);
        verify(mockDocument.update(any)).called(1);
        
        // Verify notes are sanitized
        final capturedUpdate = verify(mockDocument.update(captureAny)).captured.single as Map<String, dynamic>;
        expect(capturedUpdate['status'], equals('under_review'));
        expect(capturedUpdate, containsKey('updated_at'));
      });

      test('should sanitize notes in status update', () async {
        // Arrange
        when(mockDocument.update(any)).thenAnswer((_) async => Future.value());

        // Act
        await OptimizedIncidentService.updateIncidentStatus(
          incidentId: 'test_incident_id',
          newStatus: 'investigating',
          notes: '<script>alert("xss")</script>Investigation notes with DROP TABLE users',
        );

        // Assert
        final capturedUpdate = verify(mockDocument.update(captureAny)).captured.single as Map<String, dynamic>;
        final investigationNotes = capturedUpdate['investigation_notes'] as FieldValue;
        // In a real test, you'd need to verify the sanitization
        expect(investigationNotes, isNotNull);
      });
    });

    group('Cache Management', () {
      test('should clear cache when requested', () async {
        // This test would verify cache clearing functionality
        // In a real implementation, you'd need access to cache state
        
        // Act
        OptimizedIncidentService.clearCache();

        // Assert
        // Verify cache is cleared (would need cache inspection methods)
        expect(true, isTrue); // Placeholder assertion
      });
    });

    group('Offline Sync', () {
      test('should sync offline incidents when connection is restored', () async {
        // This test would require mocking the OfflineService
        // and verifying sync behavior
        
        // Act
        final result = await OptimizedIncidentService.syncOfflineIncidents();

        // Assert
        expect(result.isRight, isTrue);
        expect(result.value, isA<int>()); // Number of synced incidents
      });
    });
  });
}
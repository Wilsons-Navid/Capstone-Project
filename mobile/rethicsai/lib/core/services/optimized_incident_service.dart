import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../shared/models/incident_model.dart';
import '../../shared/models/file_upload_data.dart';
import '../errors/failures.dart';
import '../utils/either.dart';
import 'logging_service.dart';
import 'offline_service.dart';
import '../utils/security_utils.dart';

/// Optimized Incident Service with proper error handling, caching, and performance optimizations
/// Specifically designed for African markets with poor connectivity
class OptimizedIncidentService {
  static const String _collection = 'incidents';
  static const String _storagePrefix = 'evidence';
  static const int _defaultPageSize = 20;
  static const Duration _cacheTimeout = Duration(minutes: 5);
  
  static final CollectionReference _incidents = 
      FirebaseFirestore.instance.collection(_collection);
  static final Reference _storage = FirebaseStorage.instance.ref();
  static final Connectivity _connectivity = Connectivity();
  
  // Local cache for performance optimization
  static final Map<String, CachedResult<List<IncidentModel>>> _incidentsCache = {};
  static final Map<String, CachedResult<IncidentModel>> _incidentCache = {};

  /// Create incident with comprehensive error handling and offline support
  static Future<Either<Failure, String>> createIncident({
    required Map<String, dynamic> incidentData,
    List<FileUploadData>? fileUploads,
  }) async {
    try {
      // Check connectivity for African markets with poor internet
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;
      
      LoggingService.info('OptimizedIncidentService', 'Creating incident with connectivity: $connectivityResult');
      
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'offline_user';
      
      // Validate and sanitize input data
      final sanitizeResult = _validateAndSanitizeIncidentData(incidentData);
      if (sanitizeResult.isLeft) {
        return sanitizeResult.map((data) => ''); // Convert to Either<Failure, String>
      }
      
      final sanitizedData = sanitizeResult.value;
      final caseNumber = _generateCaseNumber();
      final incidentId = _incidents.doc().id;
      
      // Handle file uploads with error recovery
      Either<Failure, List<EvidenceFile>> uploadResult = const Right([]);
      if (fileUploads != null && fileUploads.isNotEmpty) {
        uploadResult = await _handleFileUploads(incidentId, fileUploads, isOnline);
        if (uploadResult.isLeft) {
          LoggingService.warning('OptimizedIncidentService', 'File upload failed but continuing with incident creation');
        }
      }
      
      final evidenceFiles = uploadResult.getOrElse(() => []);
      
      // Create incident data
      final firestoreData = _createFirestoreData(
        incidentId, 
        caseNumber, 
        userId, 
        sanitizedData, 
        evidenceFiles,
      );
      
      if (isOnline) {
        // Online: Save directly to Firestore
        final saveResult = await _saveIncidentOnline(incidentId, firestoreData);
        if (saveResult.isLeft) {
          // If online save fails, try offline
          await _saveIncidentOffline(incidentId, firestoreData);
          return Right(incidentId);
        }
        
        // Post-creation tasks (non-blocking)
        _executePostCreationTasks(incidentId, firestoreData, userId, caseNumber);
        
        return Right(incidentId);
      } else {
        // Offline: Save locally and sync later
        await _saveIncidentOffline(incidentId, firestoreData);
        LoggingService.info('OptimizedIncidentService', 'Incident saved offline, will sync when online');
        return Right(incidentId);
      }
      
    } catch (e, stackTrace) {
      LoggingService.error('OptimizedIncidentService', 'Failed to create incident', e, stackTrace);
      return Left(DatabaseFailure(message: 'Failed to create incident: ${e.toString()}'));
    }
  }

  /// Get user incidents with caching and pagination for performance
  static Future<Either<Failure, List<IncidentModel>>> getUserIncidents({
    required String userId,
    int limit = _defaultPageSize,
    DocumentSnapshot? startAfter,
    bool useCache = true,
  }) async {
    try {
      final cacheKey = '${userId}_$limit';
      
      // Check cache first
      if (useCache && _incidentsCache.containsKey(cacheKey)) {
        final cached = _incidentsCache[cacheKey]!;
        if (!cached.isExpired) {
          LoggingService.debug('OptimizedIncidentService', 'Returning cached incidents for user: $userId');
          return Right(cached.data);
        }
      }
      
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;
      
      if (!isOnline) {
        // Try to get from offline storage
        final offlineIncidents = await OfflineService.getOfflineIncidents(userId);
        return Right(offlineIncidents);
      }
      
      // Online query with optimization
      Query query = _incidents
          .where('user_id', isEqualTo: userId)
          .limit(limit);
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      // Execute query with timeout for poor connectivity
      final querySnapshot = await query
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw const NetworkFailure(
              message: 'Request timed out - poor connectivity detected',
              code: 'TIMEOUT',
            ),
          );
      
      final incidents = <IncidentModel>[];
      for (final doc in querySnapshot.docs) {
        try {
          final incident = IncidentModel.fromJson({
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          });
          incidents.add(incident);
        } catch (e) {
          LoggingService.warning('OptimizedIncidentService', 'Failed to parse incident ${doc.id}', e);
          continue; // Skip malformed data instead of failing entirely
        }
      }
      
      // Sort locally to avoid Firestore index requirements
      incidents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Cache the results
      _incidentsCache[cacheKey] = CachedResult(incidents, DateTime.now());
      
      LoggingService.info('OptimizedIncidentService', 'Retrieved ${incidents.length} incidents for user: $userId');
      return Right(incidents);
      
    } catch (e, stackTrace) {
      LoggingService.error('OptimizedIncidentService', 'Failed to get user incidents', e, stackTrace);
      
      // Fallback to offline data
      try {
        final offlineIncidents = await OfflineService.getOfflineIncidents(userId);
        if (offlineIncidents.isNotEmpty) {
          LoggingService.info('OptimizedIncidentService', 'Returning offline incidents as fallback');
          return Right(offlineIncidents);
        }
      } catch (_) {}
      
      if (e is NetworkFailure) return Left(e);
      return Left(DatabaseFailure(message: 'Failed to retrieve incidents: ${e.toString()}'));
    }
  }

  /// Get single incident with caching
  static Future<Either<Failure, IncidentModel>> getIncident(String incidentId) async {
    try {
      // Check cache first
      if (_incidentCache.containsKey(incidentId)) {
        final cached = _incidentCache[incidentId]!;
        if (!cached.isExpired) {
          return Right(cached.data);
        }
      }
      
      final doc = await _incidents.doc(incidentId).get().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw const NetworkFailure(
          message: 'Request timed out',
          code: 'TIMEOUT',
        ),
      );
      
      if (!doc.exists) {
        return const Left(DatabaseFailure(
          message: 'Incident not found',
          code: 'NOT_FOUND',
        ));
      }
      
      final incident = IncidentModel.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      });
      
      // Cache the result
      _incidentCache[incidentId] = CachedResult(incident, DateTime.now());
      
      return Right(incident);
      
    } catch (e, stackTrace) {
      LoggingService.error('OptimizedIncidentService', 'Failed to get incident', e, stackTrace);
      
      if (e is NetworkFailure) return Left(e);
      return Left(DatabaseFailure(message: 'Failed to retrieve incident: ${e.toString()}'));
    }
  }

  /// Update incident status with optimistic updates
  static Future<Either<Failure, void>> updateIncidentStatus({
    required String incidentId,
    required String newStatus,
    String? assignedTo,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (assignedTo != null) {
        updateData['assigned_investigator'] = assignedTo;
      }
      
      if (notes != null) {
        updateData['investigation_notes'] = FieldValue.arrayUnion([{
          'note': SecurityUtils.sanitizeInput(notes),
          'timestamp': DateTime.now().toIso8601String(),
          'author': FirebaseAuth.instance.currentUser?.uid ?? 'system',
        }]);
      }
      
      // Optimistically update cache
      if (_incidentCache.containsKey(incidentId)) {
        final cachedIncident = _incidentCache[incidentId]!.data;
        // Update local copy for immediate UI feedback
        _incidentCache[incidentId] = CachedResult(
          cachedIncident.copyWith(
            status: newStatus,
            updatedAt: DateTime.now(),
          ),
          DateTime.now(),
        );
      }
      
      await _incidents.doc(incidentId).update(updateData);
      
      LoggingService.info('OptimizedIncidentService', 'Updated incident $incidentId status to $newStatus');
      return const Right(null);
      
    } catch (e, stackTrace) {
      LoggingService.error('OptimizedIncidentService', 'Failed to update incident status', e, stackTrace);
      return Left(DatabaseFailure(message: 'Failed to update incident: ${e.toString()}'));
    }
  }

  /// Clear cache - useful for forced refresh
  static void clearCache() {
    _incidentsCache.clear();
    _incidentCache.clear();
    LoggingService.info('OptimizedIncidentService', 'Cache cleared');
  }

  /// Sync offline incidents when connection is restored
  static Future<Either<Failure, int>> syncOfflineIncidents() async {
    try {
      final offlineIncidents = await OfflineService.getAllOfflineIncidents();
      int syncedCount = 0;
      
      for (final incident in offlineIncidents) {
        try {
          await _incidents.doc(incident.id).set(incident.toJson());
          await OfflineService.removeOfflineIncident(incident.id);
          syncedCount++;
        } catch (e) {
          LoggingService.warning('OptimizedIncidentService', 'Failed to sync incident ${incident.id}', e);
          continue; // Continue with other incidents
        }
      }
      
      LoggingService.info('OptimizedIncidentService', 'Synced $syncedCount offline incidents');
      return Right(syncedCount);
      
    } catch (e, stackTrace) {
      LoggingService.error('OptimizedIncidentService', 'Failed to sync offline incidents', e, stackTrace);
      return Left(DatabaseFailure(message: 'Sync failed: ${e.toString()}'));
    }
  }

  // Private helper methods
  
  static Either<Failure, Map<String, dynamic>> _validateAndSanitizeIncidentData(
    Map<String, dynamic> incidentData,
  ) {
    try {
      final sanitizedData = <String, dynamic>{};
      final requiredFields = ['incident_type', 'title', 'description', 'date_occurred'];
      
      // Check required fields
      for (final field in requiredFields) {
        if (!incidentData.containsKey(field) || incidentData[field]?.toString().trim().isEmpty == true) {
          return Left(ValidationFailure(
            message: 'Required field missing or empty: $field',
            code: 'MISSING_FIELD',
          ));
        }
      }
      
      // Sanitize text fields
      final textFields = [
        'incident_type', 'title', 'description', 'location_occurred',
        'suspect_information', 'contact_preference', 'contact_details',
        'reporter_name', 'reporter_country', 'priority_level',
        'financial_loss_currency'
      ];
      
      for (final field in textFields) {
        final value = incidentData[field];
        if (value is String && value.isNotEmpty) {
          if (field == 'description' || field == 'suspect_information') {
            sanitizedData[field] = SecurityUtils.sanitizeIncidentContent(value);
          } else {
            sanitizedData[field] = SecurityUtils.sanitizeInput(value);
          }
          
          // Check for sensitive information
          final sensitiveInfo = SecurityUtils.detectSensitiveInfo(value);
          if (sensitiveInfo.isNotEmpty) {
            LoggingService.logSecurityEvent(
              'sensitive_data_detected',
              'medium',
              details: 'Field: $field, Types: ${sensitiveInfo.join(', ')}',
            );
          }
        } else {
          sanitizedData[field] = value;
        }
      }
      
      // Validate and sanitize specific fields
      final reporterPhone = incidentData['reporter_phone'];
      if (reporterPhone is String && reporterPhone.isNotEmpty) {
        if (!SecurityUtils.isValidPhoneNumber(reporterPhone)) {
          return const Left(ValidationFailure(
            message: 'Invalid phone number format',
            code: 'INVALID_PHONE',
          ));
        }
        sanitizedData['reporter_phone'] = SecurityUtils.sanitizeInput(reporterPhone);
      }
      
      if (incidentData['contact_preference'] == 'email') {
        final email = incidentData['contact_details'];
        if (email is String && !SecurityUtils.isValidEmail(email)) {
          return const Left(ValidationFailure(
            message: 'Invalid email address',
            code: 'INVALID_EMAIL',
          ));
        }
      }
      
      // Preserve other fields
      final preserveFields = ['date_occurred', 'financial_loss'];
      for (final field in preserveFields) {
        sanitizedData[field] = incidentData[field];
      }
      
      return Right(sanitizedData);
      
    } catch (e, stackTrace) {
      LoggingService.error('OptimizedIncidentService', 'Validation failed', e, stackTrace);
      return Left(ValidationFailure(message: 'Validation failed: ${e.toString()}'));
    }
  }
  
  static Future<Either<Failure, List<EvidenceFile>>> _handleFileUploads(
    String incidentId,
    List<FileUploadData> files,
    bool isOnline,
  ) async {
    if (!isOnline) {
      // Store files locally for later upload
      await OfflineService.storeOfflineFiles(incidentId, files);
      return Right(files.map((file) => EvidenceFile(
        id: file.id,
        fileName: file.fileName,
        fileType: file.fileType,
        fileSize: file.fileSize,
        fileData: null,
        filePath: 'offline_${file.fileName}',
        description: 'Stored offline, will upload when online',
        uploadedAt: file.uploadedAt,
      )).toList());
    }
    
    final uploadedFiles = <EvidenceFile>[];
    
    for (final file in files) {
      try {
        if (file.fileBytes.isEmpty) continue;
        
        final fileName = '${incidentId}_evidence_${file.id}_${file.fileName}';
        final storagePath = '$_storagePrefix/$incidentId/$fileName';
        final ref = _storage.child(storagePath);
        
        final uploadTask = await ref.putData(
          file.fileBytes,
          SettableMetadata(contentType: _getContentType(file.fileType)),
        );
        
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        
        uploadedFiles.add(EvidenceFile(
          id: file.id,
          fileName: file.fileName,
          fileType: file.fileType,
          fileSize: file.fileSize,
          fileData: downloadUrl,
          filePath: storagePath,
          description: file.description,
          uploadedAt: file.uploadedAt,
        ));
        
      } catch (e) {
        LoggingService.warning('OptimizedIncidentService', 'Failed to upload file ${file.fileName}', e);
        // Add placeholder for failed upload
        uploadedFiles.add(EvidenceFile(
          id: file.id,
          fileName: file.fileName,
          fileType: file.fileType,
          fileSize: file.fileSize,
          fileData: null,
          filePath: 'upload_failed',
          description: 'Upload failed: ${e.toString()}',
          uploadedAt: file.uploadedAt,
        ));
      }
    }
    
    return Right(uploadedFiles);
  }
  
  static Map<String, dynamic> _createFirestoreData(
    String incidentId,
    String caseNumber,
    String userId,
    Map<String, dynamic> sanitizedData,
    List<EvidenceFile> evidenceFiles,
  ) {
    final now = DateTime.now();
    
    return {
      'id': incidentId,
      'case_number': caseNumber,
      'user_id': userId,
      'incident_type': sanitizedData['incident_type'],
      'title': sanitizedData['title'],
      'description': sanitizedData['description'],
      'date_occurred': DateTime.parse(sanitizedData['date_occurred']).toIso8601String(),
      'location_occurred': sanitizedData['location_occurred'],
      'financial_loss': sanitizedData['financial_loss']?.toDouble(),
      'financial_loss_currency': sanitizedData['financial_loss_currency'],
      'suspect_information': sanitizedData['suspect_information'],
      'evidence_files': evidenceFiles.map((file) => {
        'id': file.id,
        'file_name': file.fileName,
        'file_type': file.fileType,
        'file_size': file.fileSize,
        'file_data': file.fileData,
        'file_path': file.filePath,
        'description': file.description,
        'uploaded_at': file.uploadedAt.toIso8601String(),
      }).toList(),
      'contact_preference': sanitizedData['contact_preference'],
      'contact_details': sanitizedData['contact_details'],
      'priority_level': sanitizedData['priority_level'],
      'status': 'Submitted',
      'assigned_officer': null,
      'investigation_notes': <Map<String, dynamic>>[],
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'resolved_at': null,
      'reporter_name': sanitizedData['reporter_name'],
      'reporter_phone': sanitizedData['reporter_phone'],
      'reporter_country': sanitizedData['reporter_country'],
      'sync_status': 'synced', // For offline/online sync tracking
    };
  }
  
  static Future<Either<Failure, void>> _saveIncidentOnline(
    String incidentId,
    Map<String, dynamic> firestoreData,
  ) async {
    try {
      await _incidents.doc(incidentId).set(firestoreData).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw const NetworkFailure(
          message: 'Save operation timed out',
          code: 'SAVE_TIMEOUT',
        ),
      );
      return const Right(null);
    } catch (e) {
      if (e is NetworkFailure) return Left(e);
      return Left(DatabaseFailure(message: 'Failed to save online: ${e.toString()}'));
    }
  }
  
  static Future<void> _saveIncidentOffline(
    String incidentId,
    Map<String, dynamic> firestoreData,
  ) async {
    final incident = IncidentModel.fromJson(firestoreData);
    await OfflineService.saveOfflineIncident(incident);
  }
  
  static void _executePostCreationTasks(
    String incidentId,
    Map<String, dynamic> firestoreData,
    String userId,
    String caseNumber,
  ) {
    // Execute non-critical tasks asynchronously
    Future.microtask(() async {
      try {
        // These are fire-and-forget operations
        await Future.wait([
          _createActivityLog(incidentId, 'Incident reported', 'system'),
          _syncToGlobalIncidents(firestoreData),
          _createCaseTrackingEntry(firestoreData),
          _notifyAdminDashboard(firestoreData),
        ]);
      } catch (e) {
        LoggingService.warning('OptimizedIncidentService', 'Some post-creation tasks failed', e);
      }
    });
  }
  
  static String _generateCaseNumber() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final randomPart = now.millisecondsSinceEpoch % 10000;
    return 'RET$year$month$day$randomPart';
  }
  
  static String _getContentType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt': return 'text/plain';
      default: return 'application/octet-stream';
    }
  }
  
  // Placeholder methods for background tasks
  static Future<void> _createActivityLog(String incidentId, String activity, String actorId) async {
    // Implementation would go here
  }
  
  static Future<void> _syncToGlobalIncidents(Map<String, dynamic> incidentData) async {
    // Implementation would go here
  }
  
  static Future<void> _createCaseTrackingEntry(Map<String, dynamic> incidentData) async {
    // Implementation would go here
  }
  
  static Future<void> _notifyAdminDashboard(Map<String, dynamic> incidentData) async {
    // Implementation would go here
  }
}

/// Cache wrapper for performance optimization
class CachedResult<T> {
  final T data;
  final DateTime cachedAt;
  
  CachedResult(this.data, this.cachedAt);
  
  bool get isExpired => 
      DateTime.now().difference(cachedAt) > OptimizedIncidentService._cacheTimeout;
}

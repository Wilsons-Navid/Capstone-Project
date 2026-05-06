import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../shared/models/incident_model.dart';
import '../../shared/models/file_upload_data.dart';
import '../../shared/models/activity_model.dart';
import 'notification_service.dart';
import 'logging_service.dart';
import 'activity_service.dart';
import '../utils/security_utils.dart';
import '../utils/safe_collections.dart';
import '../config/api_config.dart';

class IncidentService {
  static const String _collection = 'incidents';
  static const String _storagePrefix = 'evidence';
  
  // File upload security constraints
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const int maxFilesPerIncident = 10;
  static const List<String> allowedFileExtensions = [
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', // Images
    'pdf', 'doc', 'docx', 'txt', 'rtf', // Documents
    'mp4', 'mov', 'avi', 'mkv', // Videos (limited)
    'zip', 'rar', // Archives (with caution)
  ];
  
  static CollectionReference get _incidents =>
      FirebaseFirestore.instance.collection(_collection);
  
  static Reference get _storage => FirebaseStorage.instance.ref();

  static Future<String> createIncident(
    Map<String, dynamic> incidentData, {
    List<FileUploadData>? fileUploads,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'demo_user'; // Use demo user if not authenticated
      
      LoggingService.logUserAction('incident_creation_started', userId: user?.uid);
      LoggingService.info('IncidentService', 'Starting incident creation for user: ${user != null ? 'authenticated' : 'demo'}');
      
      final caseNumber = _generateCaseNumber();
      final now = DateTime.now();
      final incidentId = _incidents.doc().id;
      
      // Validate and upload evidence files if any
      List<EvidenceFile> uploadedFiles = [];
      if (fileUploads != null && fileUploads.isNotEmpty) {
        try {
          // Validate files before upload
          _validateFileUploads(fileUploads);
          uploadedFiles = await _uploadFilesAndCreateEvidenceFiles(incidentId, fileUploads);
        } catch (e) {
          LoggingService.warning('IncidentService', 'Evidence upload failed, continuing without files', e);
          // Continue with incident creation even if file upload fails
          uploadedFiles = fileUploads.map((file) => EvidenceFile(
            id: file.id,
            fileName: file.fileName,
            fileType: file.fileType,
            fileSize: file.fileSize,
            fileData: null,
            filePath: 'upload_failed_${file.fileName}',
            description: 'Upload failed: ${e.toString()}',
            uploadedAt: file.uploadedAt,
          )).toList();
        }
      }
      
      // Convert evidence files to plain maps first
      final evidenceFilesData = uploadedFiles.map((file) => {
        'id': file.id,
        'file_name': file.fileName,
        'file_type': file.fileType,
        'file_size': file.fileSize,
        'file_data': file.fileData,
        'file_path': file.filePath,
        'description': file.description,
        'uploaded_at': file.uploadedAt.toIso8601String(),
      }).toList();
      
      // Create plain Map directly for Firestore (no Freezed serialization)
      LoggingService.info('IncidentService', 'Creating sanitized incident data for Firestore');
      
      // Sanitize all user input data
      final sanitizedData = _sanitizeIncidentData(incidentData);
      
      final firestoreData = {
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
        'evidence_files': evidenceFilesData, // Plain List<Map>
        'contact_preference': incidentData['contact_preference'],
        'contact_details': incidentData['contact_details'],
        'priority_level': incidentData['priority_level'],
        'status': 'Submitted',
        'assigned_officer': null,
        'investigation_notes': <Map<String, dynamic>>[], // Empty list
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'resolved_at': null,
        // Additional user info for better tracking
        'reporter_name': sanitizedData['reporter_name'],
        'reporter_phone': sanitizedData['reporter_phone'],
        'reporter_country': sanitizedData['reporter_country'],
      };
      
      // Save to main incidents collection
      LoggingService.info('IncidentService', 'Saving incident to Firestore with ID: $incidentId');
      await _incidents.doc(incidentId).set(firestoreData);
      LoggingService.logIncidentCreation(incidentId, userId, sanitizedData['incident_type']);
      
      // Create initial activity log
      try {
        await _createActivityLog(incidentId, 'Incident reported', 'system');
        print('IncidentService: Activity log created successfully');
      } catch (e) {
        print('IncidentService: Failed to create activity log: $e');
      }
      
      // Sync with global incidents collection for admin dashboard
      try {
        await _syncToGlobalIncidents(firestoreData);
        print('IncidentService: Successfully synced to global incidents');
      } catch (e) {
        print('IncidentService: Failed to sync to global incidents: $e');
      }
      
      // Create case tracking entry
      try {
        await _createCaseTrackingEntry(firestoreData, evidenceFilesData);
        print('IncidentService: Case tracking entry created successfully');
      } catch (e) {
        print('IncidentService: Failed to create case tracking entry: $e');
      }
      
      // Notify admin dashboard
      try {
        await _notifyAdminDashboard(firestoreData);
        print('IncidentService: Admin dashboard notified successfully');
      } catch (e) {
        print('IncidentService: Failed to notify admin dashboard: $e');
      }
      
      // Send notification to user about successful case creation
      try {
        await _sendCaseCreationNotification(userId, caseNumber);
        print('IncidentService: Case creation notification sent successfully');
      } catch (e) {
        print('IncidentService: Failed to send case creation notification: $e');
      }
      
      print('IncidentService: Incident creation completed successfully with ID: $incidentId');
      return incidentId;
    } catch (e) {
      throw Exception('Failed to create incident: $e');
    }
  }
  
  static Future<List<EvidenceFile>> _uploadFilesAndCreateEvidenceFiles(
    String incidentId, 
    List<FileUploadData> files,
  ) async {
    final uploadedFiles = <EvidenceFile>[];
    
    print('Uploading ${files.length} evidence files for incident: $incidentId');
    
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      print('Processing file ${i + 1}/${files.length}: ${file.fileName}');
      
      if (file.fileBytes.isNotEmpty) {
        final fileName = '${incidentId}_evidence_${i}_${file.fileName}';
        final storagePath = '$_storagePrefix/$incidentId/$fileName';
        final ref = _storage.child(storagePath);
        
        try {
          print('Uploading ${file.fileName} (${file.fileSize} bytes) to path: $storagePath');
          
          final uploadTask = await ref.putData(
            file.fileBytes,
            SettableMetadata(contentType: _getContentType(file.fileType)),
          );
          
          final downloadUrl = await uploadTask.ref.getDownloadURL();
          final actualBucket = uploadTask.ref.bucket;
          
          print('Successfully uploaded ${file.fileName}: $downloadUrl');
          print('Storage bucket: $actualBucket, path: $storagePath');
          
          // Create clean EvidenceFile for storage
          uploadedFiles.add(EvidenceFile(
            id: file.id,
            fileName: file.fileName,
            fileType: file.fileType,
            fileSize: file.fileSize,
            fileData: downloadUrl,
            filePath: 'gs://$actualBucket/$storagePath',
            description: file.description,
            uploadedAt: file.uploadedAt,
          ));
        } catch (e) {
          print('Failed to upload file ${file.fileName}: $e');
          print('Storage error details: ${e.toString()}');
          // Add file metadata without upload (for offline scenarios)
          uploadedFiles.add(EvidenceFile(
            id: file.id,
            fileName: file.fileName,
            fileType: file.fileType,
            fileSize: file.fileSize,
            fileData: null,
            filePath: 'failed_upload_${file.fileName}',
            description: 'Upload failed: ${e.toString()}',
            uploadedAt: file.uploadedAt,
          ));
        }
      } else {
        print('File ${file.fileName} has no data, adding metadata only');
        uploadedFiles.add(EvidenceFile(
          id: file.id,
          fileName: file.fileName,
          fileType: file.fileType,
          fileSize: file.fileSize,
          fileData: null,
          filePath: 'no_data_${file.fileName}',
          description: 'File selected but no data available',
          uploadedAt: file.uploadedAt,
        ));
      }
    }
    
    print('Completed processing ${uploadedFiles.length} evidence files');
    return uploadedFiles;
  }
  
  static String _getContentType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
  
  // File upload validation
  static void _validateFileUploads(List<FileUploadData> fileUploads) {
    // Check file count limit
    if (fileUploads.length > maxFilesPerIncident) {
      throw SecurityException(
        'Too many files: ${fileUploads.length}. Maximum allowed: $maxFilesPerIncident',
        'FILE_COUNT_EXCEEDED'
      );
    }

    // Validate each file
    for (int i = 0; i < fileUploads.length; i++) {
      final file = fileUploads.safeElementAt(i);
      if (file == null) continue;
      
      try {
        _validateSingleFile(file, i);
      } catch (e) {
        throw SecurityException(
          'File validation failed for ${file.fileName}: $e',
          'FILE_VALIDATION_FAILED'
        );
      }
    }

    // Check total upload size
    final totalSize = fileUploads.fold<int>(0, (sum, file) => sum + file.fileSize);
    const maxTotalSize = maxFileSize * 2; // Allow 2x single file limit for total
    if (totalSize > maxTotalSize) {
      throw SecurityException(
        'Total upload size too large: ${_formatFileSize(totalSize)}. Maximum: ${_formatFileSize(maxTotalSize)}',
        'TOTAL_SIZE_EXCEEDED'
      );
    }
  }

  static void _validateSingleFile(FileUploadData file, int index) {
    // Validate file size
    if (file.fileSize > maxFileSize) {
      throw SecurityException(
        'File too large: ${_formatFileSize(file.fileSize)}. Maximum: ${_formatFileSize(maxFileSize)}'
      );
    }

    if (file.fileSize <= 0) {
      throw SecurityException('File is empty or invalid size');
    }

    // Validate file extension
    final extension = file.fileName.safeFileExtension;
    if (extension.isEmpty) {
      throw SecurityException('File has no extension: ${file.fileName}');
    }

    if (!allowedFileExtensions.contains(extension)) {
      throw SecurityException(
        'File type not allowed: $extension. Allowed: ${allowedFileExtensions.join(', ')}'
      );
    }

    // Validate filename
    if (file.fileName.isEmpty || file.fileName.length > 255) {
      throw SecurityException('Invalid filename length');
    }

    // Check for suspicious filenames
    final suspiciousPatterns = [
      RegExp(r'\.exe$', caseSensitive: false),
      RegExp(r'\.bat$', caseSensitive: false),
      RegExp(r'\.cmd$', caseSensitive: false),
      RegExp(r'\.scr$', caseSensitive: false),
      RegExp(r'\.vbs$', caseSensitive: false),
      RegExp(r'\.js$', caseSensitive: false),
      RegExp(r'\.jar$', caseSensitive: false),
    ];

    for (final pattern in suspiciousPatterns) {
      if (pattern.hasMatch(file.fileName)) {
        throw SecurityException('Potentially dangerous file type detected: ${file.fileName}');
      }
    }

    // Basic MIME type validation (if available)
    if (file.fileType.isNotEmpty) {
      if (!_isAllowedMimeType(file.fileType, extension)) {
        throw SecurityException(
          'File content type ${file.fileType} does not match extension $extension'
        );
      }
    }

    // Validate file content header (basic magic number check)
    if (file.fileBytes.isNotEmpty) {
      _validateFileHeader(file.fileBytes, extension);
    }
  }

  static bool _isAllowedMimeType(String mimeType, String extension) {
    final allowedMimeTypes = {
      'jpg': ['image/jpeg'],
      'jpeg': ['image/jpeg'],
      'png': ['image/png'],
      'gif': ['image/gif'],
      'bmp': ['image/bmp'],
      'webp': ['image/webp'],
      'pdf': ['application/pdf'],
      'doc': ['application/msword'],
      'docx': ['application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
      'txt': ['text/plain'],
      'rtf': ['application/rtf', 'text/rtf'],
      'mp4': ['video/mp4'],
      'mov': ['video/quicktime'],
      'avi': ['video/x-msvideo'],
      'mkv': ['video/x-matroska'],
      'zip': ['application/zip'],
      'rar': ['application/x-rar-compressed'],
    };

    final allowed = allowedMimeTypes[extension] ?? [];
    return allowed.contains(mimeType.toLowerCase());
  }

  static void _validateFileHeader(List<int> bytes, String extension) {
    if (bytes.length < 4) return; // Need at least 4 bytes for magic number

    final header = bytes.safeTake(10);
    
    // Check common file signatures (magic numbers)
    switch (extension) {
      case 'pdf':
        if (!(header[0] == 0x25 && header[1] == 0x50 && header[2] == 0x44 && header[3] == 0x46)) {
          throw SecurityException('Invalid PDF file header');
        }
        break;
      case 'jpg':
      case 'jpeg':
        if (!(header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF)) {
          throw SecurityException('Invalid JPEG file header');
        }
        break;
      case 'png':
        if (!(header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47)) {
          throw SecurityException('Invalid PNG file header');
        }
        break;
      case 'gif':
        if (!((header[0] == 0x47 && header[1] == 0x49 && header[2] == 0x46) && 
              (header[3] == 0x38 && (header[4] == 0x37 || header[4] == 0x39)))) {
          throw SecurityException('Invalid GIF file header');
        }
        break;
      case 'zip':
        if (!(header[0] == 0x50 && header[1] == 0x4B)) {
          throw SecurityException('Invalid ZIP file header');
        }
        break;
    }
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  static String _generateCaseNumber() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final randomPart = now.millisecondsSinceEpoch % 10000;
    return 'RET$year$month$day$randomPart';
  }
  
  // Sanitize incident data to prevent security vulnerabilities
  static Map<String, dynamic> _sanitizeIncidentData(Map<String, dynamic> incidentData) {
    final sanitizedData = <String, dynamic>{};
    
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
          // Use specialized sanitization for sensitive content
          sanitizedData[field] = SecurityUtils.sanitizeIncidentContent(value);
        } else {
          sanitizedData[field] = SecurityUtils.sanitizeInput(value);
        }
        
        // Log if sensitive information was detected
        final sensitiveInfo = SecurityUtils.detectSensitiveInfo(value);
        if (sensitiveInfo.isNotEmpty) {
          LoggingService.warning(
            'IncidentService', 
            'Sensitive information detected in field $field: ${sensitiveInfo.join(', ')}'
          );
        }
      } else {
        sanitizedData[field] = value;
      }
    }
    
    // Validate and sanitize phone number
    final reporterPhone = incidentData['reporter_phone'];
    if (reporterPhone is String && reporterPhone.isNotEmpty) {
      if (SecurityUtils.isValidPhoneNumber(reporterPhone)) {
        sanitizedData['reporter_phone'] = SecurityUtils.sanitizeInput(reporterPhone);
      } else {
        LoggingService.warning('IncidentService', 'Invalid phone number format provided');
        sanitizedData['reporter_phone'] = '[INVALID_PHONE_REDACTED]';
      }
    } else {
      sanitizedData['reporter_phone'] = reporterPhone;
    }
    
    // Validate email in contact details if email is the contact preference
    if (incidentData['contact_preference'] == 'email') {
      final contactDetails = incidentData['contact_details'];
      if (contactDetails is String && !SecurityUtils.isValidEmail(contactDetails)) {
        LoggingService.warning('IncidentService', 'Invalid email address provided in contact details');
        sanitizedData['contact_details'] = '[INVALID_EMAIL_REDACTED]';
      }
    }
    
    // Preserve other fields as-is (dates, numbers, etc.)
    final preserveFields = ['date_occurred', 'financial_loss'];
    for (final field in preserveFields) {
      sanitizedData[field] = incidentData[field];
    }
    
    return sanitizedData;
  }
  
  
  static Future<IncidentModel?> getIncidentById(String id) async {
    try {
      final docSnapshot = await _incidents.doc(id).get();
      
      if (!docSnapshot.exists) return null;
      
      return IncidentModel.fromJson({
        ...docSnapshot.data() as Map<String, dynamic>,
        'id': docSnapshot.id,
      });
    } catch (e) {
      throw Exception('Failed to fetch incident: $e');
    }
  }
  
  static Future<IncidentModel?> getIncidentByCaseNumber(String caseNumber) async {
    try {
      final querySnapshot = await _incidents
          .where('case_number', isEqualTo: caseNumber)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) return null;
      
      final doc = querySnapshot.docs.first;
      return IncidentModel.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      });
    } catch (e) {
      throw Exception('Failed to fetch incident by case number: $e');
    }
  }
  
  static Future<IncidentModel?> getIncident(String incidentId) async {
    try {
      final doc = await _incidents.doc(incidentId).get();
      if (!doc.exists) return null;
      
      return IncidentModel.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      });
    } catch (e) {
      return null;
    }
  }

  static Future<List<IncidentModel>> getUserIncidents(String userId) async {
    try {
      print('IncidentService: Fetching incidents for user: $userId');
      
      // Try both field variations for backward compatibility
      Query query = _incidents.where('user_id', isEqualTo: userId);
      
      QuerySnapshot querySnapshot;
      try {
        // Try with created_at ordering first
        querySnapshot = await query
            .orderBy('created_at', descending: true)
            .get();
        
        print('IncidentService: Found ${querySnapshot.docs.length} incidents for user: $userId');
      } catch (e) {
        print('IncidentService: Error with ordered query, trying without orderBy: $e');
        // Fallback: try without orderBy in case index doesn't exist
        querySnapshot = await query.get();
        
        print('IncidentService: Fallback query found ${querySnapshot.docs.length} incidents');
      }
      
      final incidents = querySnapshot.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              return IncidentModel.fromJson({
                    ...data,
                    'id': doc.id,
                  });
            } catch (e) {
              print('IncidentService: Error parsing incident ${doc.id}: $e');
              return null;
            }
          })
          .where((incident) => incident != null)
          .cast<IncidentModel>()
          .toList();
      
      // Sort by creation date if available
      incidents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('IncidentService: Successfully parsed ${incidents.length} incidents');
      return incidents;
    } catch (e) {
      print('IncidentService: Error fetching user incidents: $e');
      return [];
    }
  }

  // Method to verify incident was saved
  static Future<bool> verifyIncidentExists(String incidentId) async {
    try {
      final doc = await _incidents.doc(incidentId).get();
      final exists = doc.exists;
      print('IncidentService: Incident $incidentId exists: $exists');
      if (exists) {
        final data = doc.data() as Map<String, dynamic>;
        print('IncidentService: Incident data keys: ${data.keys.toList()}');
      }
      return exists;
    } catch (e) {
      print('IncidentService: Error verifying incident: $e');
      return false;
    }
  }
  
  static Future<void> addInvestigationNote(
    String incidentId, 
    String note,
    String officerId,
    String officerName,
  ) async {
    try {
      final investigationNote = InvestigationNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        officerId: officerId,
        officerName: officerName,
        note: note,
        createdAt: DateTime.now(),
      );
      
      await _incidents.doc(incidentId).update({
        'investigation_notes': FieldValue.arrayUnion([investigationNote.toJson()]),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Create activity log
      await _createActivityLog(incidentId, 'Investigation note added', officerId);
    } catch (e) {
      throw Exception('Failed to add investigation note: $e');
    }
  }
  
  static Future<void> _createActivityLog(
    String incidentId, 
    String activity, 
    String actorId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('incident_activities')
          .add({
        'incident_id': incidentId,
        'activity': activity,
        'actor_id': actorId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to create activity log: $e');
      // Don't throw - activity logging is not critical
    }
  }
  
  static Stream<List<IncidentModel>> watchUserIncidents([String? userId]) {
    final user = FirebaseAuth.instance.currentUser;
    final targetUserId = userId ?? user?.uid;
    
    if (targetUserId == null) {
      return Stream.value([]);
    }
    
    return _incidents
        .where('user_id', isEqualTo: targetUserId)
        .snapshots()
        .map((snapshot) {
          final incidents = snapshot.docs
              .map((doc) => IncidentModel.fromJson({
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  }))
              .toList();
          // Sort locally to avoid Firestore composite index requirement
          incidents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return incidents;
        });
  }
  
  static Stream<IncidentModel?> watchIncident(String incidentId) {
    return _incidents.doc(incidentId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      
      return IncidentModel.fromJson({
        ...snapshot.data() as Map<String, dynamic>,
        'id': snapshot.id,
      });
    });
  }
  
  // Admin functions
  static Future<List<IncidentModel>> getAllIncidents({
    String? status,
    String? priority,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    try {
      Query query = _incidents;
      
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      
      if (priority != null) {
        query = query.where('priority_level', isEqualTo: priority);
      }
      
      if (fromDate != null) {
        query = query.where('created_at', isGreaterThanOrEqualTo: fromDate.toIso8601String());
      }
      
      if (toDate != null) {
        query = query.where('created_at', isLessThanOrEqualTo: toDate.toIso8601String());
      }
      
      // Remove orderBy to avoid composite index requirement - sort locally instead
      if (limit != null) {
        query = query.limit(limit * 2); // Get more to account for local sorting
      }
      
      final querySnapshot = await query.get();
      
      final incidents = querySnapshot.docs
          .map((doc) => IncidentModel.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
      
      // Sort locally by creation date (newest first)
      incidents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Apply limit after local sorting
      if (limit != null && incidents.length > limit) {
        return incidents.take(limit).toList();
      }
      
      return incidents;
    } catch (e) {
      throw Exception('Failed to fetch incidents: $e');
    }
  }
  
  static Future<Map<String, int>> getIncidentStatistics() async {
    try {
      final snapshot = await _incidents.get();
      final incidents = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      
      final stats = <String, int>{
        'total': incidents.length,
        'submitted': 0,
        'under_review': 0,
        'in_progress': 0,
        'investigating': 0,
        'resolved': 0,
        'closed': 0,
        'high_priority': 0,
        'medium_priority': 0,
        'low_priority': 0,
      };
      
      for (final incident in incidents) {
        final status = incident['status'] as String?;
        final priority = incident['priority_level'] as String?;
        
        if (status != null && stats.containsKey(status)) {
          stats[status] = stats[status]! + 1;
        }
        
        if (priority != null && stats.containsKey('${priority}_priority')) {
          stats['${priority}_priority'] = stats['${priority}_priority']! + 1;
        }
      }
      
      return stats;
    } catch (e) {
      throw Exception('Failed to fetch incident statistics: $e');
    }
  }

  // Sync methods for database integration
  static Future<void> _syncToGlobalIncidents(Map<String, dynamic> incidentData) async {
    try {
      // Add to global incidents collection for admin dashboard
      await FirebaseFirestore.instance
          .collection('global_incidents')
          .doc(incidentData['id'])
          .set({
        ...incidentData,
        'sync_timestamp': FieldValue.serverTimestamp(),
        'region': 'africa', // Default region
        'requires_admin_review': incidentData['priority_level'] == 'high' || incidentData['priority_level'] == 'critical',
      });
    } catch (e) {
      print('Failed to sync to global incidents: $e');
      // Continue execution even if sync fails
    }
  }

  static Future<void> _createCaseTrackingEntry(Map<String, dynamic> incidentData, List<Map<String, dynamic>> evidenceFiles) async {
    try {
      // Create case tracking entry
      final caseData = {
        'incident_id': incidentData['id'],
        'case_number': incidentData['case_number'],
        'user_id': incidentData['user_id'],
        'status': 'Submitted',
        'priority': incidentData['priority_level'],
        'case_type': incidentData['incident_type'],
        'title': incidentData['title'],
        'description': incidentData['description'],
        'reporter_email': incidentData['contact_details'],
        'reporter_name': incidentData['reporter_name'],
        'reporter_phone': incidentData['reporter_phone'],
        'reporter_country': incidentData['reporter_country'],
        'location_occurred': incidentData['location_occurred'],
        'financial_loss': incidentData['financial_loss'],
        'created_at': incidentData['created_at'],
        'last_updated': incidentData['updated_at'],
        'timeline': [
          {
            'status': 'Submitted',
            'timestamp': incidentData['created_at'],
            'description': 'Case submitted by ${incidentData['reporter_name'] ?? 'user'}',
            'actor': 'user',
          }
        ],
        'investigation_status': 'pending_review',
        'assigned_investigator': null,
        'evidence_count': evidenceFiles.length,
      };

      // Add to user's cases collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(incidentData['user_id'])
          .collection('cases')
          .doc(incidentData['id'])
          .set(caseData);

      // Add to global cases collection for admin access
      await FirebaseFirestore.instance
          .collection('cases')
          .doc(incidentData['id'])
          .set({
        ...caseData,
        'sync_timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to create case tracking entry: $e');
      // Continue execution even if case creation fails
    }
  }

  static Future<void> _notifyAdminDashboard(Map<String, dynamic> incidentData) async {
    try {
      // Create admin notification
      final notificationData = {
        'type': 'new_incident',
        'incident_id': incidentData['id'],
        'case_number': incidentData['case_number'],
        'priority': incidentData['priority_level'],
        'incident_type': incidentData['incident_type'],
        'title': incidentData['title'],
        'user_id': incidentData['user_id'],
        'created_at': incidentData['created_at'],
        'requires_immediate_attention': incidentData['priority_level'] == 'critical',
        'is_read': false,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add to admin notifications
      await FirebaseFirestore.instance
          .collection('admin')
          .doc('notifications')
          .collection('incidents')
          .add(notificationData);

      // Update admin dashboard stats
      await _updateAdminDashboardStats(incidentData);
    } catch (e) {
      print('Failed to notify admin dashboard: $e');
      // Continue execution even if notification fails
    }
  }

  static Future<void> _updateAdminDashboardStats(Map<String, dynamic> incidentData) async {
    try {
      final adminStatsRef = FirebaseFirestore.instance
          .collection('admin')
          .doc('dashboard_stats');

      // Use transaction to update stats atomically
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(adminStatsRef);
        
        final currentStats = snapshot.exists 
            ? snapshot.data() as Map<String, dynamic>
            : <String, dynamic>{};

        // Update incident counts
        final totalIncidents = (currentStats['total_incidents'] as int? ?? 0) + 1;
        final pendingReview = (currentStats['pending_review'] as int? ?? 0) + 1;
        final todayIncidents = (currentStats['today_incidents'] as int? ?? 0) + 1;
        
        // Update priority counts
        final priorityKey = '${incidentData['priority_level']}_priority_count';
        final priorityCount = (currentStats[priorityKey] as int? ?? 0) + 1;

        // Update incident type counts
        final typeKey = '${incidentData['incident_type']}_count';
        final typeCount = (currentStats[typeKey] as int? ?? 0) + 1;

        transaction.set(adminStatsRef, {
          ...currentStats,
          'total_incidents': totalIncidents,
          'pending_review': pendingReview,
          'today_incidents': todayIncidents,
          priorityKey: priorityCount,
          typeKey: typeCount,
          'last_updated': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Failed to update admin dashboard stats: $e');
      // Continue execution even if stats update fails
    }
  }

  // Update incident status and sync across all systems
  static Future<void> updateIncidentStatus(
    String incidentId, 
    String newStatus, {
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
          'note': notes,
          'timestamp': DateTime.now().toIso8601String(),
          'author': FirebaseAuth.instance.currentUser?.uid ?? 'system',
        }]);
      }

      // Update incident
      await _incidents.doc(incidentId).update(updateData);

      // Update global incidents
      await FirebaseFirestore.instance
          .collection('global_incidents')
          .doc(incidentId)
          .update({
        ...updateData,
        'sync_timestamp': FieldValue.serverTimestamp(),
      });

      // Update case tracking
      await _updateCaseStatus(incidentId, newStatus, notes);

      // Create activity log
      await _createActivityLog(
        incidentId, 
        'Status updated to $newStatus${notes != null ? ": $notes" : ""}', 
        FirebaseAuth.instance.currentUser?.uid ?? 'system',
      );
      
      // Send notification to user about case update
      await _sendCaseUpdateNotification(incidentId, newStatus, notes);
      
      // Record activity for incident status update
      final activityType = newStatus.toLowerCase() == 'resolved' || newStatus.toLowerCase() == 'closed' 
          ? ActivityType.incidentResolved 
          : ActivityType.incidentUpdated;
      
      final activityStatus = newStatus.toLowerCase() == 'resolved' || newStatus.toLowerCase() == 'closed'
          ? ActivityStatus.success
          : ActivityStatus.info;
      
      await ActivityService.recordIncidentActivity(
        incidentId: incidentId,
        title: 'Case Status Updated',
        description: 'Status changed to $newStatus${notes != null ? " - $notes" : ""}',
        type: activityType,
        status: activityStatus,
      );
      
    } catch (e) {
      throw Exception('Failed to update incident status: $e');
    }
  }
  
  static Future<void> _sendCaseUpdateNotification(
    String incidentId, 
    String newStatus, 
    String? notes,
  ) async {
    try {
      // Get the incident to find the user and case number
      final incidentDoc = await _incidents.doc(incidentId).get();
      if (!incidentDoc.exists) return;
      
      final incidentData = incidentDoc.data() as Map<String, dynamic>;
      final userId = incidentData['user_id'] as String?;
      final caseNumber = incidentData['case_number'] as String?;
      
      if (userId == null || caseNumber == null) return;
      
      // Create appropriate notification message based on status
      String message;
      switch (newStatus.toLowerCase()) {
        case 'submitted':
          message = 'Your case has been submitted and is awaiting review.';
          break;
        case 'under_review':
        case 'under review':
          message = 'Your case is now under review by our security team.';
          break;
        case 'investigating':
        case 'in_progress':
          message = 'Investigation has begun on your case. We\'re working to resolve this matter.';
          break;
        case 'resolved':
          message = 'Great news! Your case has been resolved. Thank you for reporting this incident.';
          break;
        case 'closed':
          message = 'Your case has been closed. If you have additional concerns, please file a new report.';
          break;
        default:
          message = 'Your case status has been updated to: $newStatus';
      }
      
      if (notes != null && notes.isNotEmpty) {
        message += '\n\nAdditional notes: $notes';
      }
      
      // Send the notification
      await NotificationService.sendCaseUpdateNotification(
        userId,
        caseNumber: caseNumber,
        status: newStatus,
        message: message,
      );
      
    } catch (e) {
      // Don't throw error for notification failure, just log it
      print('Failed to send case update notification: $e');
    }
  }

  static Future<void> _updateCaseStatus(
    String incidentId, 
    String newStatus, 
    String? notes,
  ) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus,
        'last_updated': DateTime.now().toIso8601String(),
        'timeline': FieldValue.arrayUnion([{
          'status': newStatus,
          'timestamp': DateTime.now().toIso8601String(),
          'description': notes ?? 'Status updated to $newStatus',
          'actor': FirebaseAuth.instance.currentUser?.uid ?? 'system',
        }]),
      };

      // Update in cases collection
      final casesQuery = await FirebaseFirestore.instance
          .collection('cases')
          .where('incident_id', isEqualTo: incidentId)
          .limit(1)
          .get();

      if (casesQuery.docs.isNotEmpty) {
        await casesQuery.docs.first.reference.update(updateData);
      }

      // Update in user's cases collection
      final incident = await getIncident(incidentId);
      if (incident != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(incident.userId)
            .collection('cases')
            .doc(incidentId)
            .update(updateData);
      }
    } catch (e) {
      print('Failed to update case status: $e');
    }
  }
  
  static Future<void> _sendCaseCreationNotification(
    String userId, 
    String caseNumber,
  ) async {
    try {
      final message = 'Your case $caseNumber has been successfully submitted. '
          'We\'ve received your report and will begin reviewing it shortly. '
          'You\'ll receive updates as we investigate this matter.';
      
      await NotificationService.sendCaseUpdateNotification(
        userId,
        caseNumber: caseNumber,
        status: 'Submitted',
        message: message,
      );
      
    } catch (e) {
      // Don't throw error for notification failure, just log it
      print('Failed to send case creation notification: $e');
    }
  }
}

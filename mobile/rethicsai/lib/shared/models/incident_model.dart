import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:typed_data';
import '../../core/utils/safe_collections.dart';

part 'incident_model.freezed.dart';
part 'incident_model.g.dart';

@freezed
class IncidentModel with _$IncidentModel {
  const IncidentModel._();
  
  const factory IncidentModel({
    required String id,
    @JsonKey(name: 'case_number') required String caseNumber,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'incident_type') required String incidentType,
    required String title,
    required String description,
    @JsonKey(name: 'date_occurred') required DateTime dateOccurred,
    @JsonKey(name: 'location_occurred') String? locationOccurred,
    @JsonKey(name: 'location_latitude') double? locationLatitude,
    @JsonKey(name: 'location_longitude') double? locationLongitude,
    @JsonKey(name: 'financial_loss') double? financialLoss,
    @JsonKey(name: 'suspect_information') String? suspectInformation,
    @JsonKey(name: 'evidence_files') @Default([]) List<EvidenceFile> evidenceFiles,
    @JsonKey(name: 'contact_preference') required String contactPreference,
    @JsonKey(name: 'contact_details') required String contactDetails,
    @JsonKey(name: 'priority_level') required String priorityLevel,
    required String status,
    @JsonKey(name: 'assigned_officer') String? assignedOfficer,
    @JsonKey(name: 'investigation_notes') @Default([]) List<InvestigationNote> investigationNotes,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'resolved_at') DateTime? resolvedAt,
    // Additional reporter information
    @JsonKey(name: 'reporter_name') String? reporterName,
    @JsonKey(name: 'reporter_phone') String? reporterPhone,
    @JsonKey(name: 'reporter_country') String? reporterCountry,
  }) = _IncidentModel;

  factory IncidentModel.fromJson(Map<String, dynamic> json) =>
      _$IncidentModelFromJson(json);

  // For demo mode without Firebase
  Map<String, dynamic> toMap() {
    return toJson();
  }

  // Additional getters for compatibility
  String get priority => priorityLevel;
  double? get amountLost => financialLoss;
  String get type => incidentType;
}

@freezed
class InvestigationNote with _$InvestigationNote {
  const factory InvestigationNote({
    required String id,
    @JsonKey(name: 'officer_id') required String officerId,
    @JsonKey(name: 'officer_name') required String officerName,
    required String note,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _InvestigationNote;

  factory InvestigationNote.fromJson(Map<String, dynamic> json) =>
      _$InvestigationNoteFromJson(json);
}

@freezed
class EvidenceFile with _$EvidenceFile {
  const EvidenceFile._();
  
  const factory EvidenceFile({
    required String id,
    @JsonKey(name: 'file_name') required String fileName,
    @JsonKey(name: 'file_type') required String fileType,
    @JsonKey(name: 'file_size') required int fileSize,
    @JsonKey(name: 'file_data') String? fileData, // Base64 encoded data or download URL
    @JsonKey(name: 'file_path') String? filePath, // File path
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'uploaded_at') required DateTime uploadedAt,
  }) = _EvidenceFile;

  factory EvidenceFile.fromJson(Map<String, dynamic> json) =>
      _$EvidenceFileFromJson(json);

  // Helper method to get file data as bytes
  Uint8List? get fileBytes {
    if (fileData == null) return null;
    try {
      return Uint8List.fromList(
        fileData!.codeUnits.map((e) => e & 0xFF).toList()
      );
    } catch (e) {
      return null;
    }
  }

  // Helper method to get file extension safely
  String get fileExtension {
    return fileName.safeFileExtension;
  }

  // Helper method to check if file is an image
  bool get isImage {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageExtensions.contains(fileExtension);
  }

  // Helper method to check if file is a document
  bool get isDocument {
    const docExtensions = ['pdf', 'doc', 'docx', 'txt', 'rtf'];
    return docExtensions.contains(fileExtension);
  }

  // Helper method to format file size
  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

enum IncidentStatus {
  @JsonValue('submitted')
  submitted,
  @JsonValue('under_review')
  underReview,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('investigating')
  investigating,
  @JsonValue('resolved')
  resolved,
  @JsonValue('closed')
  closed,
}

enum PriorityLevel {
  @JsonValue('high')
  high,
  @JsonValue('medium')
  medium,
  @JsonValue('low')
  low,
}

extension IncidentStatusExtension on IncidentStatus {
  String get displayName {
    switch (this) {
      case IncidentStatus.submitted:
        return 'Submitted';
      case IncidentStatus.underReview:
        return 'Under Review';
      case IncidentStatus.inProgress:
        return 'In Progress';
      case IncidentStatus.investigating:
        return 'Investigating';
      case IncidentStatus.resolved:
        return 'Resolved';
      case IncidentStatus.closed:
        return 'Closed';
    }
  }

  String get description {
    switch (this) {
      case IncidentStatus.submitted:
        return 'Your report has been submitted and is awaiting review';
      case IncidentStatus.underReview:
        return 'Our team is reviewing your report';
      case IncidentStatus.inProgress:
        return 'Investigation is currently in progress';
      case IncidentStatus.investigating:
        return 'Detailed investigation is underway';
      case IncidentStatus.resolved:
        return 'The incident has been resolved';
      case IncidentStatus.closed:
        return 'The case has been closed';
    }
  }
}

extension PriorityLevelExtension on PriorityLevel {
  String get displayName {
    switch (this) {
      case PriorityLevel.high:
        return 'High Priority';
      case PriorityLevel.medium:
        return 'Medium Priority';
      case PriorityLevel.low:
        return 'Low Priority';
    }
  }
}

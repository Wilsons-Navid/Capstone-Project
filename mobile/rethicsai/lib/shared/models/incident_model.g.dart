// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incident_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IncidentModelImpl _$$IncidentModelImplFromJson(Map<String, dynamic> json) =>
    _$IncidentModelImpl(
      id: json['id'] as String,
      caseNumber: json['case_number'] as String,
      userId: json['user_id'] as String,
      incidentType: json['incident_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      dateOccurred: DateTime.parse(json['date_occurred'] as String),
      locationOccurred: json['location_occurred'] as String?,
      locationLatitude: (json['location_latitude'] as num?)?.toDouble(),
      locationLongitude: (json['location_longitude'] as num?)?.toDouble(),
      financialLoss: (json['financial_loss'] as num?)?.toDouble(),
      financialLossCurrency: json['financial_loss_currency'] as String?,
      suspectInformation: json['suspect_information'] as String?,
      evidenceFiles: (json['evidence_files'] as List<dynamic>?)
              ?.map((e) => EvidenceFile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      contactPreference: json['contact_preference'] as String,
      contactDetails: json['contact_details'] as String,
      priorityLevel: json['priority_level'] as String,
      status: json['status'] as String,
      assignedOfficer: json['assigned_officer'] as String?,
      investigationNotes: (json['investigation_notes'] as List<dynamic>?)
              ?.map(
                  (e) => InvestigationNote.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      resolvedAt: json['resolved_at'] == null
          ? null
          : DateTime.parse(json['resolved_at'] as String),
      reporterName: json['reporter_name'] as String?,
      reporterPhone: json['reporter_phone'] as String?,
      reporterCountry: json['reporter_country'] as String?,
    );

Map<String, dynamic> _$$IncidentModelImplToJson(_$IncidentModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'case_number': instance.caseNumber,
      'user_id': instance.userId,
      'incident_type': instance.incidentType,
      'title': instance.title,
      'description': instance.description,
      'date_occurred': instance.dateOccurred.toIso8601String(),
      'location_occurred': instance.locationOccurred,
      'location_latitude': instance.locationLatitude,
      'location_longitude': instance.locationLongitude,
      'financial_loss': instance.financialLoss,
      'financial_loss_currency': instance.financialLossCurrency,
      'suspect_information': instance.suspectInformation,
      'evidence_files': instance.evidenceFiles,
      'contact_preference': instance.contactPreference,
      'contact_details': instance.contactDetails,
      'priority_level': instance.priorityLevel,
      'status': instance.status,
      'assigned_officer': instance.assignedOfficer,
      'investigation_notes': instance.investigationNotes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'resolved_at': instance.resolvedAt?.toIso8601String(),
      'reporter_name': instance.reporterName,
      'reporter_phone': instance.reporterPhone,
      'reporter_country': instance.reporterCountry,
    };

_$InvestigationNoteImpl _$$InvestigationNoteImplFromJson(
        Map<String, dynamic> json) =>
    _$InvestigationNoteImpl(
      id: json['id'] as String,
      officerId: json['officer_id'] as String,
      officerName: json['officer_name'] as String,
      note: json['note'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$InvestigationNoteImplToJson(
        _$InvestigationNoteImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'officer_id': instance.officerId,
      'officer_name': instance.officerName,
      'note': instance.note,
      'created_at': instance.createdAt.toIso8601String(),
    };

_$EvidenceFileImpl _$$EvidenceFileImplFromJson(Map<String, dynamic> json) =>
    _$EvidenceFileImpl(
      id: json['id'] as String,
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String,
      fileSize: (json['file_size'] as num).toInt(),
      fileData: json['file_data'] as String?,
      filePath: json['file_path'] as String?,
      description: json['description'] as String?,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );

Map<String, dynamic> _$$EvidenceFileImplToJson(_$EvidenceFileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'file_name': instance.fileName,
      'file_type': instance.fileType,
      'file_size': instance.fileSize,
      'file_data': instance.fileData,
      'file_path': instance.filePath,
      'description': instance.description,
      'uploaded_at': instance.uploadedAt.toIso8601String(),
    };

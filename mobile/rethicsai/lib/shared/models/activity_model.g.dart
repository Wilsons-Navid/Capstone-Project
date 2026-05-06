// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ActivityModelImpl _$$ActivityModelImplFromJson(Map<String, dynamic> json) =>
    _$ActivityModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$ActivityTypeEnumMap, json['type']),
      status: $enumDecode(_$ActivityStatusEnumMap, json['status']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      relatedEntityId: json['relatedEntityId'] as String?,
      relatedEntityType: json['relatedEntityType'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$ActivityModelImplToJson(_$ActivityModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'title': instance.title,
      'description': instance.description,
      'type': _$ActivityTypeEnumMap[instance.type]!,
      'status': _$ActivityStatusEnumMap[instance.status]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'relatedEntityId': instance.relatedEntityId,
      'relatedEntityType': instance.relatedEntityType,
      'metadata': instance.metadata,
    };

const _$ActivityTypeEnumMap = {
  ActivityType.incidentReported: 'incidentReported',
  ActivityType.incidentUpdated: 'incidentUpdated',
  ActivityType.incidentResolved: 'incidentResolved',
  ActivityType.securityScan: 'securityScan',
  ActivityType.profileUpdated: 'profileUpdated',
  ActivityType.loginAttempt: 'loginAttempt',
  ActivityType.passwordChanged: 'passwordChanged',
  ActivityType.aiAssistantQuery: 'aiAssistantQuery',
  ActivityType.educationContentViewed: 'educationContentViewed',
  ActivityType.reportGenerated: 'reportGenerated',
  ActivityType.systemNotification: 'systemNotification',
};

const _$ActivityStatusEnumMap = {
  ActivityStatus.success: 'success',
  ActivityStatus.warning: 'warning',
  ActivityStatus.error: 'error',
  ActivityStatus.info: 'info',
  ActivityStatus.pending: 'pending',
};

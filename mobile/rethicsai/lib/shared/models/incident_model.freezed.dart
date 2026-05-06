// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'incident_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

IncidentModel _$IncidentModelFromJson(Map<String, dynamic> json) {
  return _IncidentModel.fromJson(json);
}

/// @nodoc
mixin _$IncidentModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'case_number')
  String get caseNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'incident_type')
  String get incidentType => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_occurred')
  DateTime get dateOccurred => throw _privateConstructorUsedError;
  @JsonKey(name: 'location_occurred')
  String? get locationOccurred => throw _privateConstructorUsedError;
  @JsonKey(name: 'location_latitude')
  double? get locationLatitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'location_longitude')
  double? get locationLongitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'financial_loss')
  double? get financialLoss => throw _privateConstructorUsedError;
  @JsonKey(name: 'financial_loss_currency')
  String? get financialLossCurrency => throw _privateConstructorUsedError;
  @JsonKey(name: 'suspect_information')
  String? get suspectInformation => throw _privateConstructorUsedError;
  @JsonKey(name: 'evidence_files')
  List<EvidenceFile> get evidenceFiles => throw _privateConstructorUsedError;
  @JsonKey(name: 'contact_preference')
  String get contactPreference => throw _privateConstructorUsedError;
  @JsonKey(name: 'contact_details')
  String get contactDetails => throw _privateConstructorUsedError;
  @JsonKey(name: 'priority_level')
  String get priorityLevel => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'assigned_officer')
  String? get assignedOfficer => throw _privateConstructorUsedError;
  @JsonKey(name: 'investigation_notes')
  List<InvestigationNote> get investigationNotes =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'resolved_at')
  DateTime? get resolvedAt =>
      throw _privateConstructorUsedError; // Additional reporter information
  @JsonKey(name: 'reporter_name')
  String? get reporterName => throw _privateConstructorUsedError;
  @JsonKey(name: 'reporter_phone')
  String? get reporterPhone => throw _privateConstructorUsedError;
  @JsonKey(name: 'reporter_country')
  String? get reporterCountry => throw _privateConstructorUsedError;

  /// Serializes this IncidentModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IncidentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IncidentModelCopyWith<IncidentModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IncidentModelCopyWith<$Res> {
  factory $IncidentModelCopyWith(
          IncidentModel value, $Res Function(IncidentModel) then) =
      _$IncidentModelCopyWithImpl<$Res, IncidentModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'case_number') String caseNumber,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'incident_type') String incidentType,
      String title,
      String description,
      @JsonKey(name: 'date_occurred') DateTime dateOccurred,
      @JsonKey(name: 'location_occurred') String? locationOccurred,
      @JsonKey(name: 'location_latitude') double? locationLatitude,
      @JsonKey(name: 'location_longitude') double? locationLongitude,
      @JsonKey(name: 'financial_loss') double? financialLoss,
      @JsonKey(name: 'financial_loss_currency') String? financialLossCurrency,
      @JsonKey(name: 'suspect_information') String? suspectInformation,
      @JsonKey(name: 'evidence_files') List<EvidenceFile> evidenceFiles,
      @JsonKey(name: 'contact_preference') String contactPreference,
      @JsonKey(name: 'contact_details') String contactDetails,
      @JsonKey(name: 'priority_level') String priorityLevel,
      String status,
      @JsonKey(name: 'assigned_officer') String? assignedOfficer,
      @JsonKey(name: 'investigation_notes')
      List<InvestigationNote> investigationNotes,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'resolved_at') DateTime? resolvedAt,
      @JsonKey(name: 'reporter_name') String? reporterName,
      @JsonKey(name: 'reporter_phone') String? reporterPhone,
      @JsonKey(name: 'reporter_country') String? reporterCountry});
}

/// @nodoc
class _$IncidentModelCopyWithImpl<$Res, $Val extends IncidentModel>
    implements $IncidentModelCopyWith<$Res> {
  _$IncidentModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IncidentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? caseNumber = null,
    Object? userId = null,
    Object? incidentType = null,
    Object? title = null,
    Object? description = null,
    Object? dateOccurred = null,
    Object? locationOccurred = freezed,
    Object? locationLatitude = freezed,
    Object? locationLongitude = freezed,
    Object? financialLoss = freezed,
    Object? financialLossCurrency = freezed,
    Object? suspectInformation = freezed,
    Object? evidenceFiles = null,
    Object? contactPreference = null,
    Object? contactDetails = null,
    Object? priorityLevel = null,
    Object? status = null,
    Object? assignedOfficer = freezed,
    Object? investigationNotes = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? resolvedAt = freezed,
    Object? reporterName = freezed,
    Object? reporterPhone = freezed,
    Object? reporterCountry = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      caseNumber: null == caseNumber
          ? _value.caseNumber
          : caseNumber // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      incidentType: null == incidentType
          ? _value.incidentType
          : incidentType // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      dateOccurred: null == dateOccurred
          ? _value.dateOccurred
          : dateOccurred // ignore: cast_nullable_to_non_nullable
              as DateTime,
      locationOccurred: freezed == locationOccurred
          ? _value.locationOccurred
          : locationOccurred // ignore: cast_nullable_to_non_nullable
              as String?,
      locationLatitude: freezed == locationLatitude
          ? _value.locationLatitude
          : locationLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      locationLongitude: freezed == locationLongitude
          ? _value.locationLongitude
          : locationLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      financialLoss: freezed == financialLoss
          ? _value.financialLoss
          : financialLoss // ignore: cast_nullable_to_non_nullable
              as double?,
      financialLossCurrency: freezed == financialLossCurrency
          ? _value.financialLossCurrency
          : financialLossCurrency // ignore: cast_nullable_to_non_nullable
              as String?,
      suspectInformation: freezed == suspectInformation
          ? _value.suspectInformation
          : suspectInformation // ignore: cast_nullable_to_non_nullable
              as String?,
      evidenceFiles: null == evidenceFiles
          ? _value.evidenceFiles
          : evidenceFiles // ignore: cast_nullable_to_non_nullable
              as List<EvidenceFile>,
      contactPreference: null == contactPreference
          ? _value.contactPreference
          : contactPreference // ignore: cast_nullable_to_non_nullable
              as String,
      contactDetails: null == contactDetails
          ? _value.contactDetails
          : contactDetails // ignore: cast_nullable_to_non_nullable
              as String,
      priorityLevel: null == priorityLevel
          ? _value.priorityLevel
          : priorityLevel // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      assignedOfficer: freezed == assignedOfficer
          ? _value.assignedOfficer
          : assignedOfficer // ignore: cast_nullable_to_non_nullable
              as String?,
      investigationNotes: null == investigationNotes
          ? _value.investigationNotes
          : investigationNotes // ignore: cast_nullable_to_non_nullable
              as List<InvestigationNote>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      resolvedAt: freezed == resolvedAt
          ? _value.resolvedAt
          : resolvedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reporterName: freezed == reporterName
          ? _value.reporterName
          : reporterName // ignore: cast_nullable_to_non_nullable
              as String?,
      reporterPhone: freezed == reporterPhone
          ? _value.reporterPhone
          : reporterPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      reporterCountry: freezed == reporterCountry
          ? _value.reporterCountry
          : reporterCountry // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$IncidentModelImplCopyWith<$Res>
    implements $IncidentModelCopyWith<$Res> {
  factory _$$IncidentModelImplCopyWith(
          _$IncidentModelImpl value, $Res Function(_$IncidentModelImpl) then) =
      __$$IncidentModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'case_number') String caseNumber,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'incident_type') String incidentType,
      String title,
      String description,
      @JsonKey(name: 'date_occurred') DateTime dateOccurred,
      @JsonKey(name: 'location_occurred') String? locationOccurred,
      @JsonKey(name: 'location_latitude') double? locationLatitude,
      @JsonKey(name: 'location_longitude') double? locationLongitude,
      @JsonKey(name: 'financial_loss') double? financialLoss,
      @JsonKey(name: 'financial_loss_currency') String? financialLossCurrency,
      @JsonKey(name: 'suspect_information') String? suspectInformation,
      @JsonKey(name: 'evidence_files') List<EvidenceFile> evidenceFiles,
      @JsonKey(name: 'contact_preference') String contactPreference,
      @JsonKey(name: 'contact_details') String contactDetails,
      @JsonKey(name: 'priority_level') String priorityLevel,
      String status,
      @JsonKey(name: 'assigned_officer') String? assignedOfficer,
      @JsonKey(name: 'investigation_notes')
      List<InvestigationNote> investigationNotes,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'resolved_at') DateTime? resolvedAt,
      @JsonKey(name: 'reporter_name') String? reporterName,
      @JsonKey(name: 'reporter_phone') String? reporterPhone,
      @JsonKey(name: 'reporter_country') String? reporterCountry});
}

/// @nodoc
class __$$IncidentModelImplCopyWithImpl<$Res>
    extends _$IncidentModelCopyWithImpl<$Res, _$IncidentModelImpl>
    implements _$$IncidentModelImplCopyWith<$Res> {
  __$$IncidentModelImplCopyWithImpl(
      _$IncidentModelImpl _value, $Res Function(_$IncidentModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of IncidentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? caseNumber = null,
    Object? userId = null,
    Object? incidentType = null,
    Object? title = null,
    Object? description = null,
    Object? dateOccurred = null,
    Object? locationOccurred = freezed,
    Object? locationLatitude = freezed,
    Object? locationLongitude = freezed,
    Object? financialLoss = freezed,
    Object? financialLossCurrency = freezed,
    Object? suspectInformation = freezed,
    Object? evidenceFiles = null,
    Object? contactPreference = null,
    Object? contactDetails = null,
    Object? priorityLevel = null,
    Object? status = null,
    Object? assignedOfficer = freezed,
    Object? investigationNotes = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? resolvedAt = freezed,
    Object? reporterName = freezed,
    Object? reporterPhone = freezed,
    Object? reporterCountry = freezed,
  }) {
    return _then(_$IncidentModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      caseNumber: null == caseNumber
          ? _value.caseNumber
          : caseNumber // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      incidentType: null == incidentType
          ? _value.incidentType
          : incidentType // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      dateOccurred: null == dateOccurred
          ? _value.dateOccurred
          : dateOccurred // ignore: cast_nullable_to_non_nullable
              as DateTime,
      locationOccurred: freezed == locationOccurred
          ? _value.locationOccurred
          : locationOccurred // ignore: cast_nullable_to_non_nullable
              as String?,
      locationLatitude: freezed == locationLatitude
          ? _value.locationLatitude
          : locationLatitude // ignore: cast_nullable_to_non_nullable
              as double?,
      locationLongitude: freezed == locationLongitude
          ? _value.locationLongitude
          : locationLongitude // ignore: cast_nullable_to_non_nullable
              as double?,
      financialLoss: freezed == financialLoss
          ? _value.financialLoss
          : financialLoss // ignore: cast_nullable_to_non_nullable
              as double?,
      financialLossCurrency: freezed == financialLossCurrency
          ? _value.financialLossCurrency
          : financialLossCurrency // ignore: cast_nullable_to_non_nullable
              as String?,
      suspectInformation: freezed == suspectInformation
          ? _value.suspectInformation
          : suspectInformation // ignore: cast_nullable_to_non_nullable
              as String?,
      evidenceFiles: null == evidenceFiles
          ? _value._evidenceFiles
          : evidenceFiles // ignore: cast_nullable_to_non_nullable
              as List<EvidenceFile>,
      contactPreference: null == contactPreference
          ? _value.contactPreference
          : contactPreference // ignore: cast_nullable_to_non_nullable
              as String,
      contactDetails: null == contactDetails
          ? _value.contactDetails
          : contactDetails // ignore: cast_nullable_to_non_nullable
              as String,
      priorityLevel: null == priorityLevel
          ? _value.priorityLevel
          : priorityLevel // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      assignedOfficer: freezed == assignedOfficer
          ? _value.assignedOfficer
          : assignedOfficer // ignore: cast_nullable_to_non_nullable
              as String?,
      investigationNotes: null == investigationNotes
          ? _value._investigationNotes
          : investigationNotes // ignore: cast_nullable_to_non_nullable
              as List<InvestigationNote>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      resolvedAt: freezed == resolvedAt
          ? _value.resolvedAt
          : resolvedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reporterName: freezed == reporterName
          ? _value.reporterName
          : reporterName // ignore: cast_nullable_to_non_nullable
              as String?,
      reporterPhone: freezed == reporterPhone
          ? _value.reporterPhone
          : reporterPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      reporterCountry: freezed == reporterCountry
          ? _value.reporterCountry
          : reporterCountry // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$IncidentModelImpl extends _IncidentModel {
  const _$IncidentModelImpl(
      {required this.id,
      @JsonKey(name: 'case_number') required this.caseNumber,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'incident_type') required this.incidentType,
      required this.title,
      required this.description,
      @JsonKey(name: 'date_occurred') required this.dateOccurred,
      @JsonKey(name: 'location_occurred') this.locationOccurred,
      @JsonKey(name: 'location_latitude') this.locationLatitude,
      @JsonKey(name: 'location_longitude') this.locationLongitude,
      @JsonKey(name: 'financial_loss') this.financialLoss,
      @JsonKey(name: 'financial_loss_currency') this.financialLossCurrency,
      @JsonKey(name: 'suspect_information') this.suspectInformation,
      @JsonKey(name: 'evidence_files')
      final List<EvidenceFile> evidenceFiles = const [],
      @JsonKey(name: 'contact_preference') required this.contactPreference,
      @JsonKey(name: 'contact_details') required this.contactDetails,
      @JsonKey(name: 'priority_level') required this.priorityLevel,
      required this.status,
      @JsonKey(name: 'assigned_officer') this.assignedOfficer,
      @JsonKey(name: 'investigation_notes')
      final List<InvestigationNote> investigationNotes = const [],
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      @JsonKey(name: 'resolved_at') this.resolvedAt,
      @JsonKey(name: 'reporter_name') this.reporterName,
      @JsonKey(name: 'reporter_phone') this.reporterPhone,
      @JsonKey(name: 'reporter_country') this.reporterCountry})
      : _evidenceFiles = evidenceFiles,
        _investigationNotes = investigationNotes,
        super._();

  factory _$IncidentModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$IncidentModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'case_number')
  final String caseNumber;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'incident_type')
  final String incidentType;
  @override
  final String title;
  @override
  final String description;
  @override
  @JsonKey(name: 'date_occurred')
  final DateTime dateOccurred;
  @override
  @JsonKey(name: 'location_occurred')
  final String? locationOccurred;
  @override
  @JsonKey(name: 'location_latitude')
  final double? locationLatitude;
  @override
  @JsonKey(name: 'location_longitude')
  final double? locationLongitude;
  @override
  @JsonKey(name: 'financial_loss')
  final double? financialLoss;
  @override
  @JsonKey(name: 'financial_loss_currency')
  final String? financialLossCurrency;
  @override
  @JsonKey(name: 'suspect_information')
  final String? suspectInformation;
  final List<EvidenceFile> _evidenceFiles;
  @override
  @JsonKey(name: 'evidence_files')
  List<EvidenceFile> get evidenceFiles {
    if (_evidenceFiles is EqualUnmodifiableListView) return _evidenceFiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_evidenceFiles);
  }

  @override
  @JsonKey(name: 'contact_preference')
  final String contactPreference;
  @override
  @JsonKey(name: 'contact_details')
  final String contactDetails;
  @override
  @JsonKey(name: 'priority_level')
  final String priorityLevel;
  @override
  final String status;
  @override
  @JsonKey(name: 'assigned_officer')
  final String? assignedOfficer;
  final List<InvestigationNote> _investigationNotes;
  @override
  @JsonKey(name: 'investigation_notes')
  List<InvestigationNote> get investigationNotes {
    if (_investigationNotes is EqualUnmodifiableListView)
      return _investigationNotes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_investigationNotes);
  }

  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @override
  @JsonKey(name: 'resolved_at')
  final DateTime? resolvedAt;
// Additional reporter information
  @override
  @JsonKey(name: 'reporter_name')
  final String? reporterName;
  @override
  @JsonKey(name: 'reporter_phone')
  final String? reporterPhone;
  @override
  @JsonKey(name: 'reporter_country')
  final String? reporterCountry;

  @override
  String toString() {
    return 'IncidentModel(id: $id, caseNumber: $caseNumber, userId: $userId, incidentType: $incidentType, title: $title, description: $description, dateOccurred: $dateOccurred, locationOccurred: $locationOccurred, locationLatitude: $locationLatitude, locationLongitude: $locationLongitude, financialLoss: $financialLoss, financialLossCurrency: $financialLossCurrency, suspectInformation: $suspectInformation, evidenceFiles: $evidenceFiles, contactPreference: $contactPreference, contactDetails: $contactDetails, priorityLevel: $priorityLevel, status: $status, assignedOfficer: $assignedOfficer, investigationNotes: $investigationNotes, createdAt: $createdAt, updatedAt: $updatedAt, resolvedAt: $resolvedAt, reporterName: $reporterName, reporterPhone: $reporterPhone, reporterCountry: $reporterCountry)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IncidentModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.caseNumber, caseNumber) ||
                other.caseNumber == caseNumber) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.incidentType, incidentType) ||
                other.incidentType == incidentType) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.dateOccurred, dateOccurred) ||
                other.dateOccurred == dateOccurred) &&
            (identical(other.locationOccurred, locationOccurred) ||
                other.locationOccurred == locationOccurred) &&
            (identical(other.locationLatitude, locationLatitude) ||
                other.locationLatitude == locationLatitude) &&
            (identical(other.locationLongitude, locationLongitude) ||
                other.locationLongitude == locationLongitude) &&
            (identical(other.financialLoss, financialLoss) ||
                other.financialLoss == financialLoss) &&
            (identical(other.financialLossCurrency, financialLossCurrency) ||
                other.financialLossCurrency == financialLossCurrency) &&
            (identical(other.suspectInformation, suspectInformation) ||
                other.suspectInformation == suspectInformation) &&
            const DeepCollectionEquality()
                .equals(other._evidenceFiles, _evidenceFiles) &&
            (identical(other.contactPreference, contactPreference) ||
                other.contactPreference == contactPreference) &&
            (identical(other.contactDetails, contactDetails) ||
                other.contactDetails == contactDetails) &&
            (identical(other.priorityLevel, priorityLevel) ||
                other.priorityLevel == priorityLevel) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.assignedOfficer, assignedOfficer) ||
                other.assignedOfficer == assignedOfficer) &&
            const DeepCollectionEquality()
                .equals(other._investigationNotes, _investigationNotes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.resolvedAt, resolvedAt) ||
                other.resolvedAt == resolvedAt) &&
            (identical(other.reporterName, reporterName) ||
                other.reporterName == reporterName) &&
            (identical(other.reporterPhone, reporterPhone) ||
                other.reporterPhone == reporterPhone) &&
            (identical(other.reporterCountry, reporterCountry) ||
                other.reporterCountry == reporterCountry));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        caseNumber,
        userId,
        incidentType,
        title,
        description,
        dateOccurred,
        locationOccurred,
        locationLatitude,
        locationLongitude,
        financialLoss,
        financialLossCurrency,
        suspectInformation,
        const DeepCollectionEquality().hash(_evidenceFiles),
        contactPreference,
        contactDetails,
        priorityLevel,
        status,
        assignedOfficer,
        const DeepCollectionEquality().hash(_investigationNotes),
        createdAt,
        updatedAt,
        resolvedAt,
        reporterName,
        reporterPhone,
        reporterCountry
      ]);

  /// Create a copy of IncidentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IncidentModelImplCopyWith<_$IncidentModelImpl> get copyWith =>
      __$$IncidentModelImplCopyWithImpl<_$IncidentModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IncidentModelImplToJson(
      this,
    );
  }
}

abstract class _IncidentModel extends IncidentModel {
  const factory _IncidentModel(
      {required final String id,
      @JsonKey(name: 'case_number') required final String caseNumber,
      @JsonKey(name: 'user_id') required final String userId,
      @JsonKey(name: 'incident_type') required final String incidentType,
      required final String title,
      required final String description,
      @JsonKey(name: 'date_occurred') required final DateTime dateOccurred,
      @JsonKey(name: 'location_occurred') final String? locationOccurred,
      @JsonKey(name: 'location_latitude') final double? locationLatitude,
      @JsonKey(name: 'location_longitude') final double? locationLongitude,
      @JsonKey(name: 'financial_loss') final double? financialLoss,
      @JsonKey(name: 'financial_loss_currency')
      final String? financialLossCurrency,
      @JsonKey(name: 'suspect_information') final String? suspectInformation,
      @JsonKey(name: 'evidence_files') final List<EvidenceFile> evidenceFiles,
      @JsonKey(name: 'contact_preference')
      required final String contactPreference,
      @JsonKey(name: 'contact_details') required final String contactDetails,
      @JsonKey(name: 'priority_level') required final String priorityLevel,
      required final String status,
      @JsonKey(name: 'assigned_officer') final String? assignedOfficer,
      @JsonKey(name: 'investigation_notes')
      final List<InvestigationNote> investigationNotes,
      @JsonKey(name: 'created_at') required final DateTime createdAt,
      @JsonKey(name: 'updated_at') required final DateTime updatedAt,
      @JsonKey(name: 'resolved_at') final DateTime? resolvedAt,
      @JsonKey(name: 'reporter_name') final String? reporterName,
      @JsonKey(name: 'reporter_phone') final String? reporterPhone,
      @JsonKey(name: 'reporter_country')
      final String? reporterCountry}) = _$IncidentModelImpl;
  const _IncidentModel._() : super._();

  factory _IncidentModel.fromJson(Map<String, dynamic> json) =
      _$IncidentModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'case_number')
  String get caseNumber;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'incident_type')
  String get incidentType;
  @override
  String get title;
  @override
  String get description;
  @override
  @JsonKey(name: 'date_occurred')
  DateTime get dateOccurred;
  @override
  @JsonKey(name: 'location_occurred')
  String? get locationOccurred;
  @override
  @JsonKey(name: 'location_latitude')
  double? get locationLatitude;
  @override
  @JsonKey(name: 'location_longitude')
  double? get locationLongitude;
  @override
  @JsonKey(name: 'financial_loss')
  double? get financialLoss;
  @override
  @JsonKey(name: 'financial_loss_currency')
  String? get financialLossCurrency;
  @override
  @JsonKey(name: 'suspect_information')
  String? get suspectInformation;
  @override
  @JsonKey(name: 'evidence_files')
  List<EvidenceFile> get evidenceFiles;
  @override
  @JsonKey(name: 'contact_preference')
  String get contactPreference;
  @override
  @JsonKey(name: 'contact_details')
  String get contactDetails;
  @override
  @JsonKey(name: 'priority_level')
  String get priorityLevel;
  @override
  String get status;
  @override
  @JsonKey(name: 'assigned_officer')
  String? get assignedOfficer;
  @override
  @JsonKey(name: 'investigation_notes')
  List<InvestigationNote> get investigationNotes;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;
  @override
  @JsonKey(name: 'resolved_at')
  DateTime? get resolvedAt; // Additional reporter information
  @override
  @JsonKey(name: 'reporter_name')
  String? get reporterName;
  @override
  @JsonKey(name: 'reporter_phone')
  String? get reporterPhone;
  @override
  @JsonKey(name: 'reporter_country')
  String? get reporterCountry;

  /// Create a copy of IncidentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IncidentModelImplCopyWith<_$IncidentModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

InvestigationNote _$InvestigationNoteFromJson(Map<String, dynamic> json) {
  return _InvestigationNote.fromJson(json);
}

/// @nodoc
mixin _$InvestigationNote {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'officer_id')
  String get officerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'officer_name')
  String get officerName => throw _privateConstructorUsedError;
  String get note => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this InvestigationNote to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InvestigationNote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InvestigationNoteCopyWith<InvestigationNote> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InvestigationNoteCopyWith<$Res> {
  factory $InvestigationNoteCopyWith(
          InvestigationNote value, $Res Function(InvestigationNote) then) =
      _$InvestigationNoteCopyWithImpl<$Res, InvestigationNote>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'officer_id') String officerId,
      @JsonKey(name: 'officer_name') String officerName,
      String note,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$InvestigationNoteCopyWithImpl<$Res, $Val extends InvestigationNote>
    implements $InvestigationNoteCopyWith<$Res> {
  _$InvestigationNoteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InvestigationNote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? officerId = null,
    Object? officerName = null,
    Object? note = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      officerId: null == officerId
          ? _value.officerId
          : officerId // ignore: cast_nullable_to_non_nullable
              as String,
      officerName: null == officerName
          ? _value.officerName
          : officerName // ignore: cast_nullable_to_non_nullable
              as String,
      note: null == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InvestigationNoteImplCopyWith<$Res>
    implements $InvestigationNoteCopyWith<$Res> {
  factory _$$InvestigationNoteImplCopyWith(_$InvestigationNoteImpl value,
          $Res Function(_$InvestigationNoteImpl) then) =
      __$$InvestigationNoteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'officer_id') String officerId,
      @JsonKey(name: 'officer_name') String officerName,
      String note,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$$InvestigationNoteImplCopyWithImpl<$Res>
    extends _$InvestigationNoteCopyWithImpl<$Res, _$InvestigationNoteImpl>
    implements _$$InvestigationNoteImplCopyWith<$Res> {
  __$$InvestigationNoteImplCopyWithImpl(_$InvestigationNoteImpl _value,
      $Res Function(_$InvestigationNoteImpl) _then)
      : super(_value, _then);

  /// Create a copy of InvestigationNote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? officerId = null,
    Object? officerName = null,
    Object? note = null,
    Object? createdAt = null,
  }) {
    return _then(_$InvestigationNoteImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      officerId: null == officerId
          ? _value.officerId
          : officerId // ignore: cast_nullable_to_non_nullable
              as String,
      officerName: null == officerName
          ? _value.officerName
          : officerName // ignore: cast_nullable_to_non_nullable
              as String,
      note: null == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InvestigationNoteImpl implements _InvestigationNote {
  const _$InvestigationNoteImpl(
      {required this.id,
      @JsonKey(name: 'officer_id') required this.officerId,
      @JsonKey(name: 'officer_name') required this.officerName,
      required this.note,
      @JsonKey(name: 'created_at') required this.createdAt});

  factory _$InvestigationNoteImpl.fromJson(Map<String, dynamic> json) =>
      _$$InvestigationNoteImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'officer_id')
  final String officerId;
  @override
  @JsonKey(name: 'officer_name')
  final String officerName;
  @override
  final String note;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'InvestigationNote(id: $id, officerId: $officerId, officerName: $officerName, note: $note, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvestigationNoteImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.officerId, officerId) ||
                other.officerId == officerId) &&
            (identical(other.officerName, officerName) ||
                other.officerName == officerName) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, officerId, officerName, note, createdAt);

  /// Create a copy of InvestigationNote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvestigationNoteImplCopyWith<_$InvestigationNoteImpl> get copyWith =>
      __$$InvestigationNoteImplCopyWithImpl<_$InvestigationNoteImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InvestigationNoteImplToJson(
      this,
    );
  }
}

abstract class _InvestigationNote implements InvestigationNote {
  const factory _InvestigationNote(
          {required final String id,
          @JsonKey(name: 'officer_id') required final String officerId,
          @JsonKey(name: 'officer_name') required final String officerName,
          required final String note,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$InvestigationNoteImpl;

  factory _InvestigationNote.fromJson(Map<String, dynamic> json) =
      _$InvestigationNoteImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'officer_id')
  String get officerId;
  @override
  @JsonKey(name: 'officer_name')
  String get officerName;
  @override
  String get note;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of InvestigationNote
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvestigationNoteImplCopyWith<_$InvestigationNoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EvidenceFile _$EvidenceFileFromJson(Map<String, dynamic> json) {
  return _EvidenceFile.fromJson(json);
}

/// @nodoc
mixin _$EvidenceFile {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_name')
  String get fileName => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_type')
  String get fileType => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_size')
  int get fileSize => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_data')
  String? get fileData =>
      throw _privateConstructorUsedError; // Base64 encoded data or download URL
  @JsonKey(name: 'file_path')
  String? get filePath => throw _privateConstructorUsedError; // File path
  @JsonKey(name: 'description')
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'uploaded_at')
  DateTime get uploadedAt => throw _privateConstructorUsedError;

  /// Serializes this EvidenceFile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EvidenceFile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EvidenceFileCopyWith<EvidenceFile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EvidenceFileCopyWith<$Res> {
  factory $EvidenceFileCopyWith(
          EvidenceFile value, $Res Function(EvidenceFile) then) =
      _$EvidenceFileCopyWithImpl<$Res, EvidenceFile>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'file_name') String fileName,
      @JsonKey(name: 'file_type') String fileType,
      @JsonKey(name: 'file_size') int fileSize,
      @JsonKey(name: 'file_data') String? fileData,
      @JsonKey(name: 'file_path') String? filePath,
      @JsonKey(name: 'description') String? description,
      @JsonKey(name: 'uploaded_at') DateTime uploadedAt});
}

/// @nodoc
class _$EvidenceFileCopyWithImpl<$Res, $Val extends EvidenceFile>
    implements $EvidenceFileCopyWith<$Res> {
  _$EvidenceFileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EvidenceFile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fileName = null,
    Object? fileType = null,
    Object? fileSize = null,
    Object? fileData = freezed,
    Object? filePath = freezed,
    Object? description = freezed,
    Object? uploadedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: null == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String,
      fileSize: null == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      fileData: freezed == fileData
          ? _value.fileData
          : fileData // ignore: cast_nullable_to_non_nullable
              as String?,
      filePath: freezed == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      uploadedAt: null == uploadedAt
          ? _value.uploadedAt
          : uploadedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EvidenceFileImplCopyWith<$Res>
    implements $EvidenceFileCopyWith<$Res> {
  factory _$$EvidenceFileImplCopyWith(
          _$EvidenceFileImpl value, $Res Function(_$EvidenceFileImpl) then) =
      __$$EvidenceFileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'file_name') String fileName,
      @JsonKey(name: 'file_type') String fileType,
      @JsonKey(name: 'file_size') int fileSize,
      @JsonKey(name: 'file_data') String? fileData,
      @JsonKey(name: 'file_path') String? filePath,
      @JsonKey(name: 'description') String? description,
      @JsonKey(name: 'uploaded_at') DateTime uploadedAt});
}

/// @nodoc
class __$$EvidenceFileImplCopyWithImpl<$Res>
    extends _$EvidenceFileCopyWithImpl<$Res, _$EvidenceFileImpl>
    implements _$$EvidenceFileImplCopyWith<$Res> {
  __$$EvidenceFileImplCopyWithImpl(
      _$EvidenceFileImpl _value, $Res Function(_$EvidenceFileImpl) _then)
      : super(_value, _then);

  /// Create a copy of EvidenceFile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fileName = null,
    Object? fileType = null,
    Object? fileSize = null,
    Object? fileData = freezed,
    Object? filePath = freezed,
    Object? description = freezed,
    Object? uploadedAt = null,
  }) {
    return _then(_$EvidenceFileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: null == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String,
      fileSize: null == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      fileData: freezed == fileData
          ? _value.fileData
          : fileData // ignore: cast_nullable_to_non_nullable
              as String?,
      filePath: freezed == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      uploadedAt: null == uploadedAt
          ? _value.uploadedAt
          : uploadedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EvidenceFileImpl extends _EvidenceFile {
  const _$EvidenceFileImpl(
      {required this.id,
      @JsonKey(name: 'file_name') required this.fileName,
      @JsonKey(name: 'file_type') required this.fileType,
      @JsonKey(name: 'file_size') required this.fileSize,
      @JsonKey(name: 'file_data') this.fileData,
      @JsonKey(name: 'file_path') this.filePath,
      @JsonKey(name: 'description') this.description,
      @JsonKey(name: 'uploaded_at') required this.uploadedAt})
      : super._();

  factory _$EvidenceFileImpl.fromJson(Map<String, dynamic> json) =>
      _$$EvidenceFileImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'file_name')
  final String fileName;
  @override
  @JsonKey(name: 'file_type')
  final String fileType;
  @override
  @JsonKey(name: 'file_size')
  final int fileSize;
  @override
  @JsonKey(name: 'file_data')
  final String? fileData;
// Base64 encoded data or download URL
  @override
  @JsonKey(name: 'file_path')
  final String? filePath;
// File path
  @override
  @JsonKey(name: 'description')
  final String? description;
  @override
  @JsonKey(name: 'uploaded_at')
  final DateTime uploadedAt;

  @override
  String toString() {
    return 'EvidenceFile(id: $id, fileName: $fileName, fileType: $fileType, fileSize: $fileSize, fileData: $fileData, filePath: $filePath, description: $description, uploadedAt: $uploadedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EvidenceFileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.fileType, fileType) ||
                other.fileType == fileType) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.fileData, fileData) ||
                other.fileData == fileData) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.uploadedAt, uploadedAt) ||
                other.uploadedAt == uploadedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, fileName, fileType, fileSize,
      fileData, filePath, description, uploadedAt);

  /// Create a copy of EvidenceFile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EvidenceFileImplCopyWith<_$EvidenceFileImpl> get copyWith =>
      __$$EvidenceFileImplCopyWithImpl<_$EvidenceFileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EvidenceFileImplToJson(
      this,
    );
  }
}

abstract class _EvidenceFile extends EvidenceFile {
  const factory _EvidenceFile(
          {required final String id,
          @JsonKey(name: 'file_name') required final String fileName,
          @JsonKey(name: 'file_type') required final String fileType,
          @JsonKey(name: 'file_size') required final int fileSize,
          @JsonKey(name: 'file_data') final String? fileData,
          @JsonKey(name: 'file_path') final String? filePath,
          @JsonKey(name: 'description') final String? description,
          @JsonKey(name: 'uploaded_at') required final DateTime uploadedAt}) =
      _$EvidenceFileImpl;
  const _EvidenceFile._() : super._();

  factory _EvidenceFile.fromJson(Map<String, dynamic> json) =
      _$EvidenceFileImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'file_name')
  String get fileName;
  @override
  @JsonKey(name: 'file_type')
  String get fileType;
  @override
  @JsonKey(name: 'file_size')
  int get fileSize;
  @override
  @JsonKey(name: 'file_data')
  String? get fileData; // Base64 encoded data or download URL
  @override
  @JsonKey(name: 'file_path')
  String? get filePath; // File path
  @override
  @JsonKey(name: 'description')
  String? get description;
  @override
  @JsonKey(name: 'uploaded_at')
  DateTime get uploadedAt;

  /// Create a copy of EvidenceFile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EvidenceFileImplCopyWith<_$EvidenceFileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

import '../../../../shared/models/incident_model.dart';

abstract class IncidentRepository {
  /// Create a new incident report with evidence files
  Future<String> createIncident({
    required Map<String, dynamic> incidentData,
    List<EvidenceFile>? evidenceFiles,
  });

  /// Get incident by ID
  Future<IncidentModel?> getIncident(String incidentId);

  /// Get all incidents for a user
  Stream<List<IncidentModel>> getUserIncidents(String userId);

  /// Update incident status
  Future<void> updateIncidentStatus({
    required String incidentId,
    required String status,
    String? notes,
    String? assignedOfficer,
  });

  /// Add investigation note
  Future<void> addInvestigationNote({
    required String incidentId,
    required String note,
    required String officerId,
    required String officerName,
  });

  /// Search incidents with filters
  Future<List<IncidentModel>> searchIncidents({
    String? query,
    String? status,
    String? incidentType,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get incident statistics for a user
  Future<Map<String, int>> getIncidentStatistics(String userId);

  /// Delete incident (soft delete)
  Future<void> deleteIncident(String incidentId);
}
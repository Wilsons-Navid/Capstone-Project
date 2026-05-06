import 'dart:typed_data';
import '../../../../shared/models/incident_model.dart';
import '../../../../core/services/demo_incident_service.dart';
import '../../domain/repositories/incident_repository.dart';

class IncidentRepositoryImpl implements IncidentRepository {
  @override
  Future<String> createIncident({
    required Map<String, dynamic> incidentData,
    List<EvidenceFile>? evidenceFiles,
  }) async {
    try {
      return await DemoIncidentService.createIncident(
        incidentData: incidentData,
        evidenceFiles: evidenceFiles,
      );
    } catch (e) {
      throw Exception('Failed to create incident: $e');
    }
  }

  @override
  Future<IncidentModel?> getIncident(String incidentId) async {
    try {
      return await DemoIncidentService.getIncidentById(incidentId);
    } catch (e) {
      throw Exception('Failed to get incident: $e');
    }
  }

  @override
  Stream<List<IncidentModel>> getUserIncidents(String userId) {
    try {
      return Stream.fromFuture(DemoIncidentService.getUserIncidents(userId));
    } catch (e) {
      throw Exception('Failed to get user incidents: $e');
    }
  }

  @override
  Future<void> updateIncidentStatus({
    required String incidentId,
    required String status,
    String? notes,
    String? assignedOfficer,
  }) async {
    // Demo implementation - just print for now
    print('Demo: Updated incident $incidentId to status: $status');
  }

  @override
  Future<void> addInvestigationNote({
    required String incidentId,
    required String note,
    required String officerId,
    required String officerName,
  }) async {
    // Demo implementation - just print for now
    print('Demo: Added note to incident $incidentId: $note');
  }

  @override
  Future<List<IncidentModel>> searchIncidents({
    String? query,
    String? status,
    String? incidentType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // For demo, just return all user incidents
      return await DemoIncidentService.getUserIncidents('demo_user');
    } catch (e) {
      throw Exception('Failed to search incidents: $e');
    }
  }

  @override
  Future<Map<String, int>> getIncidentStatistics(String userId) async {
    try {
      final incidents = await DemoIncidentService.getUserIncidents(userId);
      return {
        'total': incidents.length,
        'submitted': incidents.where((i) => i.status == 'submitted').length,
        'under_review': incidents.where((i) => i.status == 'under_review').length,
        'in_progress': incidents.where((i) => i.status == 'in_progress').length,
        'investigating': incidents.where((i) => i.status == 'investigating').length,
        'resolved': incidents.where((i) => i.status == 'resolved').length,
        'closed': incidents.where((i) => i.status == 'closed').length,
      };
    } catch (e) {
      throw Exception('Failed to get incident statistics: $e');
    }
  }

  @override
  Future<void> deleteIncident(String incidentId) async {
    // Demo implementation - just print for now
    print('Demo: Deleted incident $incidentId');
  }
}
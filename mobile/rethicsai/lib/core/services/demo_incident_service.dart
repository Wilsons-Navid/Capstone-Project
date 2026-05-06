import '../../shared/models/incident_model.dart';

class DemoIncidentService {
  static final List<IncidentModel> _incidents = [];
  
  static Future<String> createIncident({
    required Map<String, dynamic> incidentData,
    List<EvidenceFile>? evidenceFiles,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    final caseNumber = _generateCaseNumber();
    final now = DateTime.now();
    
    final incident = IncidentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      caseNumber: caseNumber,
      userId: incidentData['user_id'] ?? 'demo_user',
      incidentType: incidentData['incident_type'],
      title: incidentData['title'],
      description: incidentData['description'],
      dateOccurred: DateTime.parse(incidentData['date_occurred']),
      locationOccurred: incidentData['location_occurred'],
      financialLoss: incidentData['financial_loss'],
      suspectInformation: incidentData['suspect_information'],
      evidenceFiles: evidenceFiles ?? [],
      contactPreference: incidentData['contact_preference'],
      contactDetails: incidentData['contact_details'],
      priorityLevel: incidentData['priority_level'],
      status: 'submitted',
      investigationNotes: [],
      createdAt: now,
      updatedAt: now,
    );
    
    _incidents.add(incident);
    return incident.id;
  }
  
  static String _generateCaseNumber() {
    final now = DateTime.now();
    final year = now.year;
    final randomPart = now.millisecondsSinceEpoch % 10000;
    return 'RET$year$randomPart';
  }
  
  static Future<List<IncidentModel>> getUserIncidents(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _incidents.where((incident) => incident.userId == userId).toList();
  }
  
  static Future<IncidentModel?> getIncidentById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _incidents.firstWhere((incident) => incident.id == id);
    } catch (e) {
      return null;
    }
  }
}

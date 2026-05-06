import '../../../../shared/models/incident_model.dart';

abstract class CaseTrackingState {}

class CaseTrackingInitial extends CaseTrackingState {}

class CaseTrackingLoading extends CaseTrackingState {}

class CaseTrackingLoaded extends CaseTrackingState {
  final List<IncidentModel> cases;
  
  CaseTrackingLoaded(this.cases);
}

class CaseTrackingError extends CaseTrackingState {
  final String message;
  
  CaseTrackingError(this.message);
}
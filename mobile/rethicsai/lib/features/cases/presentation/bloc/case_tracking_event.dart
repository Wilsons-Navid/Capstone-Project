abstract class CaseTrackingEvent {}

class LoadUserCases extends CaseTrackingEvent {
  final String userId;
  
  LoadUserCases(this.userId);
}

class FilterCases extends CaseTrackingEvent {
  final String filter;
  
  FilterCases(this.filter);
}

class RefreshCases extends CaseTrackingEvent {}
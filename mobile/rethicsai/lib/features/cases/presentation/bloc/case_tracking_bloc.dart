import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../shared/models/incident_model.dart';
import '../../../../core/services/incident_service.dart';
import 'case_tracking_event.dart';
import 'case_tracking_state.dart';

class CaseTrackingBloc extends Bloc<CaseTrackingEvent, CaseTrackingState> {
  List<IncidentModel> _allCases = [];

  CaseTrackingBloc() : super(CaseTrackingInitial()) {
    on<LoadUserCases>(_onLoadUserCases);
    on<FilterCases>(_onFilterCases);
    on<RefreshCases>(_onRefreshCases);
  }

  Future<void> _onLoadUserCases(
    LoadUserCases event,
    Emitter<CaseTrackingState> emit,
  ) async {
    emit(CaseTrackingLoading());
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      final cases = await IncidentService.getUserIncidents(event.userId);
      _allCases = cases;
      
      emit(CaseTrackingLoaded(cases));
    } catch (e) {
      emit(CaseTrackingError('Failed to load cases: $e'));
    }
  }

  void _onFilterCases(FilterCases event, Emitter<CaseTrackingState> emit) {
    if (_allCases.isEmpty) return;

    List<IncidentModel> filteredCases;

    switch (event.filter) {
      case 'submitted':
        filteredCases = _allCases.where((case_) => case_.status == 'submitted').toList();
        break;
      case 'in_progress':
        filteredCases = _allCases.where((case_) => case_.status == 'in_progress').toList();
        break;
      case 'resolved':
        filteredCases = _allCases.where((case_) => case_.status == 'resolved').toList();
        break;
      case 'closed':
        filteredCases = _allCases.where((case_) => case_.status == 'closed').toList();
        break;
      default:
        filteredCases = _allCases;
    }

    emit(CaseTrackingLoaded(filteredCases));
  }

  Future<void> _onRefreshCases(
    RefreshCases event,
    Emitter<CaseTrackingState> emit,
  ) async {
    // Don't show loading state on refresh
    try {
      final user = FirebaseAuth.instance.currentUser;
      final cases = await IncidentService.getUserIncidents(user?.uid);
      _allCases = cases;
      
      emit(CaseTrackingLoaded(cases));
    } catch (e) {
      emit(CaseTrackingError('Failed to refresh cases: $e'));
    }
  }
}
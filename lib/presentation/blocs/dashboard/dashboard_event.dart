// lib/presentation/blocs/dashboard/dashboard_event.dart
part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class FetchDashboardData extends DashboardEvent {
  final String schoolId;
  const FetchDashboardData(this.schoolId);

  @override
  List<Object?> get props => [schoolId];
}

// ⭐ NOUVEAU : Event pour rafraîchir les stats
class RefreshDashboardData extends DashboardEvent {
  final String schoolId;
  const RefreshDashboardData(this.schoolId);

  @override
  List<Object?> get props => [schoolId];
}

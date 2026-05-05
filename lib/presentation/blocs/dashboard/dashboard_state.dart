// lib/presentation/blocs/dashboard/dashboard_state.dart
part of 'dashboard_bloc.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

// ⭐ AMÉLIORÉ : Avec timestamp pour savoir quand les données ont été chargées
class DashboardLoaded extends DashboardState {
  final DashboardStats stats;
  final DateTime loadedAt;

  const DashboardLoaded({
    required this.stats,
    required this.loadedAt,
  });

  // ⭐ Helper : Les données sont-elles fraîches (moins de 5 min) ?
  bool get isFresh => DateTime.now().difference(loadedAt).inMinutes < 5;

  @override
  List<Object?> get props => [stats, loadedAt];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
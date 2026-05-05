// lib/presentation/blocs/dashboard/dashboard_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../../data/models/dashboard_stats.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _repository;

  DashboardBloc(this._repository) : super(DashboardInitial()) {
    on<FetchDashboardData>(_onFetchDashboardData);
    on<RefreshDashboardData>(_onRefreshDashboardData);
  }

  Future<void> _onFetchDashboardData(
    FetchDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    // ⭐ Si on a déjà des données fraîches, ne pas recharger
    if (state is DashboardLoaded) {
      final current = state as DashboardLoaded;
      if (current.isFresh && event.schoolId == current.stats.schoolId) {
        return; // Données encore fraîches, on garde
      }
    }

    emit(DashboardLoading());
    
    try {
      final stats = await _repository.getGlobalStats(event.schoolId);
      emit(DashboardLoaded(
        stats: stats,
        loadedAt: DateTime.now(),
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  // ⭐ NOUVEAU : Rafraîchissement forcé (pull-to-refresh)
  Future<void> _onRefreshDashboardData(
    RefreshDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    
    try {
      final stats = await _repository.getGlobalStats(event.schoolId);
      emit(DashboardLoaded(
        stats: stats,
        loadedAt: DateTime.now(),
      ));
    } catch (e) {
      // ⭐ En cas d'erreur, garder les anciennes données si possible
      if (state is DashboardLoaded) {
        final old = state as DashboardLoaded;
        emit(DashboardLoaded(
          stats: old.stats, // Garder anciennes données
          loadedAt: old.loadedAt,
        ));
        // Afficher erreur en snackbar via listener
      } else {
        emit(DashboardError(e.toString()));
      }
    }
  }
}
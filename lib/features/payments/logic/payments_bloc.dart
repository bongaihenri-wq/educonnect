// lib/features/payments/logic/payments_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/payment_repository.dart';
import '../models/import_report.dart';
import '../models/payment_status_dto.dart';

// ── Events ────────────────────────────────────────────────────

abstract class PaymentsEvent {}

class ImportCsvRequested extends PaymentsEvent {
  final String schoolId;
  final String csvContent;
  ImportCsvRequested(this.schoolId, this.csvContent);
}

class ImportFileRequested extends PaymentsEvent {
  final String schoolId;
  final List<int> bytes;
  ImportFileRequested(this.schoolId, this.bytes);
}

class SimulateCsvRequested extends PaymentsEvent {
  final String schoolId;
  final String csvContent;
  SimulateCsvRequested(this.schoolId, this.csvContent);
}

class SimulateFileRequested extends PaymentsEvent {
  final String schoolId;
  final List<int> bytes;
  SimulateFileRequested(this.schoolId, this.bytes);
}

class PaymentsStatusRequested extends PaymentsEvent {
  final String schoolId;
  PaymentsStatusRequested(this.schoolId);
}

class GradeGatingRequested extends PaymentsEvent {
  final String schoolId;
  GradeGatingRequested(this.schoolId);
}

class GradeGatingToggled extends PaymentsEvent {
  final String schoolId;
  final bool enabled;
  GradeGatingToggled(this.schoolId, this.enabled);
}

class ManualStatusSet extends PaymentsEvent {
  final String schoolId;
  final String studentId;
  final bool upToDate;
  ManualStatusSet(this.schoolId, this.studentId, this.upToDate);
}

// ── States ────────────────────────────────────────────────────

abstract class PaymentsState {}

class PaymentsLoading extends PaymentsState {}

class PaymentsLoaded extends PaymentsState {
  final List<PaymentStatusDto> statuses;
  PaymentsLoaded(this.statuses);
}

class PaymentsImportDone extends PaymentsState {
  final ImportReport report;
  PaymentsImportDone(this.report);
}

class PaymentsSimulated extends PaymentsState {
  final ImportReport report;
  final bool isExcel;
  PaymentsSimulated(this.report, this.isExcel);
}

class GradeGatingLoaded extends PaymentsState {
  final bool enabled;
  GradeGatingLoaded(this.enabled);
}

class PaymentsError extends PaymentsState {
  final String message;
  PaymentsError(this.message);
}

// ── Bloc ──────────────────────────────────────────────────────

class PaymentsBloc extends Bloc<PaymentsEvent, PaymentsState> {
  final PaymentRepository _repo;

  PaymentsBloc(this._repo) : super(PaymentsLoading()) {
    on<ImportCsvRequested>(_onImportCsv);
    on<ImportFileRequested>(_onImportFile);
    on<SimulateCsvRequested>(_onSimulateCsv);
    on<SimulateFileRequested>(_onSimulateFile);
    on<PaymentsStatusRequested>(_onLoad);
    on<GradeGatingRequested>(_onLoadGating);
    on<GradeGatingToggled>(_onToggleGating);
    on<ManualStatusSet>(_onManualStatus);
  }

  Future<void> _onImportCsv(
      ImportCsvRequested event, Emitter<PaymentsState> emit) async {
    emit(PaymentsLoading());
    try {
      final report = await _repo.importCsv(
        schoolId: event.schoolId,
        csvContent: event.csvContent,
      );
      emit(PaymentsImportDone(report));
      add(PaymentsStatusRequested(event.schoolId));
    } catch (e) {
      emit(PaymentsError('Échec de l\'import : $e'));
    }
  }

  Future<void> _onImportFile(
      ImportFileRequested event, Emitter<PaymentsState> emit) async {
    emit(PaymentsLoading());
    try {
      final report = await _repo.importExcel(
        schoolId: event.schoolId,
        bytes: event.bytes,
      );
      emit(PaymentsImportDone(report));
      add(PaymentsStatusRequested(event.schoolId));
    } catch (e) {
      emit(PaymentsError('Échec de l\'import : $e'));
    }
  }

  Future<void> _onSimulateCsv(
      SimulateCsvRequested event, Emitter<PaymentsState> emit) async {
    try {
      final report = await _repo.importCsv(
        schoolId: event.schoolId,
        csvContent: event.csvContent,
        simulate: true,
      );
      emit(PaymentsSimulated(report, false));
    } catch (e) {
      emit(PaymentsError('Simulation impossible : $e'));
    }
  }

  Future<void> _onSimulateFile(
      SimulateFileRequested event, Emitter<PaymentsState> emit) async {
    try {
      final report = await _repo.importExcel(
        schoolId: event.schoolId,
        bytes: event.bytes,
        simulate: true,
      );
      emit(PaymentsSimulated(report, true));
    } catch (e) {
      emit(PaymentsError('Simulation impossible : $e'));
    }
  }

  Future<void> _onLoad(
      PaymentsStatusRequested event, Emitter<PaymentsState> emit) async {
    emit(PaymentsLoading());
    try {
      final statuses = await _repo.getStatusByClass(event.schoolId);
      emit(PaymentsLoaded(statuses));
    } catch (e) {
      emit(PaymentsError('Chargement impossible : $e'));
    }
  }

  Future<void> _onLoadGating(
      GradeGatingRequested event, Emitter<PaymentsState> emit) async {
    try {
      final enabled = await _repo.getGradeGatingEnabled(event.schoolId);
      emit(GradeGatingLoaded(enabled));
    } catch (_) {/* silencieux */}
  }

  Future<void> _onToggleGating(
      GradeGatingToggled event, Emitter<PaymentsState> emit) async {
    try {
      await _repo.setGradeGatingEnabled(event.schoolId, event.enabled);
    } catch (e) {
      emit(PaymentsError('Modification impossible : $e'));
    }
  }

  Future<void> _onManualStatus(
      ManualStatusSet event, Emitter<PaymentsState> emit) async {
    try {
      await _repo.setStudentUpToDate(
          event.schoolId, event.studentId, event.upToDate);
      add(PaymentsStatusRequested(event.schoolId));
    } catch (e) {
      emit(PaymentsError('Modification impossible : $e'));
    }
  }
}
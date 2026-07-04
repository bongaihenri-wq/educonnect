// lib/core/logging/app_bloc_observer.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_logger.dart';

class AppBlocObserver extends BlocObserver {
  final AppLogger _logger = AppLogger();

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    _logger.logDebug(
      category: LogCategory.bloc,
      message: 'BLoC created: ${bloc.runtimeType}',
      blocName: bloc.runtimeType.toString(),
    );
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    _logger.logDebug(
      category: LogCategory.bloc,
      message: 'Event: ${event.runtimeType}',
      blocName: bloc.runtimeType.toString(),
      metadata: {'event': event.runtimeType.toString()},
    );
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    
    // Ne pas logger les states avec des données sensibles
    final currentState = change.currentState.runtimeType.toString();
    final nextState = change.nextState.runtimeType.toString();
    
    _logger.logDebug(
      category: LogCategory.bloc,
      message: 'State: $currentState → $nextState',
      blocName: bloc.runtimeType.toString(),
      metadata: {
        'from_state': currentState,
        'to_state': nextState,
      },
    );
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    _logger.logDebug(
      category: LogCategory.bloc,
      message: 'Transition: ${transition.event.runtimeType}',
      blocName: bloc.runtimeType.toString(),
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    _logger.logError(
      category: LogCategory.bloc,
      message: 'BLoC error in ${bloc.runtimeType}',
      error: error,
      stackTrace: stackTrace,
      blocName: bloc.runtimeType.toString(),
    );
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    _logger.logDebug(
      category: LogCategory.bloc,
      message: 'BLoC closed: ${bloc.runtimeType}',
      blocName: bloc.runtimeType.toString(),
    );
  }
}
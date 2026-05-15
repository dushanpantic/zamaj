import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Global [BlocObserver] that streams Bloc/Cubit lifecycle to `dart:developer`
/// (visible in the DevTools "Logging" view, filterable by the `Bloc` channel).
///
/// Only emits in debug builds — in profile/release it is a no-op so logs are
/// stripped by the compiler.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    if (!kDebugMode) return;
    developer.log('CREATE ${bloc.runtimeType}', name: 'Bloc');
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    if (!kDebugMode) return;
    developer.log('EVENT  ${bloc.runtimeType} <- $event', name: 'Bloc');
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (!kDebugMode) return;
    // Skip Bloc here — onTransition already reports the full event→state pair.
    // Only Cubits (which have no events) need onChange logging.
    if (bloc is Bloc) return;
    developer.log(
      'CHANGE ${bloc.runtimeType} ${change.currentState} -> ${change.nextState}',
      name: 'Bloc',
    );
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    if (!kDebugMode) return;
    developer.log(
      'TRANS  ${bloc.runtimeType} ${transition.event} : '
      '${transition.currentState} -> ${transition.nextState}',
      name: 'Bloc',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    if (!kDebugMode) return;
    developer.log(
      'ERROR  ${bloc.runtimeType}',
      name: 'Bloc',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    if (!kDebugMode) return;
    developer.log('CLOSE  ${bloc.runtimeType}', name: 'Bloc');
  }
}

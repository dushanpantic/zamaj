import 'package:clock/clock.dart';

/// Thin abstraction over [package:clock] that always returns UTC.
///
/// Inject this into repositories and services instead of calling
/// [DateTime.now] directly, so tests can substitute a fake clock.
class AppClock {
  const AppClock();

  DateTime nowUtc() => clock.now().toUtc();
}

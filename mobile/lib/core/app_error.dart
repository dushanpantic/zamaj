/// Marker interface for all application-level errors.
///
/// BLoCs, services, and domain layers extend or implement this interface
/// so that error-handling code can catch the full error hierarchy with a
/// single type check.
abstract interface class AppError implements Exception {}

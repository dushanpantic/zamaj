/// Single source of truth for schema version integers.
///
/// [drift] is the Drift `schemaVersion` passed to [GeneratedDatabase].
/// [domain] is stamped onto every written domain entity row.
abstract final class SchemaVersions {
  static const int drift = 3;
  static const int domain = 2;
}

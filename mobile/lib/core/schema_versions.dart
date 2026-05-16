/// Single source of truth for schema version integers.
///
/// [drift] is the Drift `schemaVersion` passed to [GeneratedDatabase].
/// [domain] is stamped onto every written domain entity row.
abstract final class SchemaVersions {
  static const int drift = 6;
  static const int domain = 3;
}

import 'package:zamaj/modules/domain/repositories/exercise_library_repository.dart';
import 'package:zamaj/modules/domain/services/canonical_seed_catalog.dart';

/// Seeds the embedded canonical catalog into the library on launch.
///
/// Pure domain glue: it takes the catalog as a JSON string (the caller owns
/// asset/file IO — see `bootstrap.dart`) so it carries no Flutter or platform
/// dependency and stays usable from tests. Parsing surfaces typed
/// [DeserializationError]/[ValidationError]s; the seeder never swallows them —
/// the launch site decides whether to log-and-continue.
class CanonicalLibrarySeeder {
  const CanonicalLibrarySeeder(this._repository);

  final ExerciseLibraryRepository _repository;

  /// Parses [catalogJson] and idempotently seeds the library. Returns the
  /// number of rows actually inserted (0 on a re-seed). Re-throws any parse
  /// error rather than hiding a malformed catalog.
  Future<int> seed(String catalogJson) {
    final entries = CanonicalSeedCatalog.parse(catalogJson);
    return _repository.seedCanonical(entries);
  }
}

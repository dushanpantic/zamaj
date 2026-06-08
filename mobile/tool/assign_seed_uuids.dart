import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

/// Result of one id-assignment pass over the catalog and its lock file.
class SeedUuidAssignment {
  const SeedUuidAssignment({
    required this.catalogJson,
    required this.lockJson,
    required this.assignedNames,
  });

  /// The catalog re-encoded with every `"id": null` filled in.
  final String catalogJson;

  /// The lock re-encoded: existing ids preserved, freshly-assigned ids
  /// appended. Append-only — never shrinks.
  final String lockJson;

  /// Names of the entries that received a fresh id this pass.
  final List<String> assignedNames;
}

const _encoder = JsonEncoder.withIndent('  ');

/// Assigns a v4 UUID to every catalog entry whose `id` is null or absent,
/// leaving existing ids untouched, and records each freshly-assigned id in the
/// lock. The lock is append-only: ids already present are kept verbatim so a
/// shipped id can never be silently dropped (the frozen-id test enforces the
/// matching catalog-side invariant).
///
/// Pure over its string inputs; [generateId] is injectable so tests can make
/// the output deterministic. The real run uses [Uuid.v4].
SeedUuidAssignment assignSeedUuids({
  required String catalogJson,
  String? lockJson,
  String Function()? generateId,
}) {
  final newId = generateId ?? const Uuid().v4;

  final catalog = (jsonDecode(catalogJson) as List)
      .cast<Map<String, dynamic>>();
  final lockedIds = lockJson == null
      ? <String>[]
      : (jsonDecode(lockJson) as List).cast<String>().toList();
  final lockedSet = lockedIds.toSet();
  final assignedNames = <String>[];

  for (final entry in catalog) {
    if (entry['id'] != null) continue;
    final fresh = newId();
    entry['id'] = fresh;
    assignedNames.add((entry['name'] as String?) ?? '<unnamed>');
    if (lockedSet.add(fresh)) lockedIds.add(fresh);
  }

  return SeedUuidAssignment(
    catalogJson: _encoder.convert(catalog),
    lockJson: _encoder.convert(lockedIds),
    assignedNames: assignedNames,
  );
}

void main() {
  final catalogFile = File('assets/exercise_library_seed.json');
  final lockFile = File('assets/exercise_library_seed.lock.json');

  if (!catalogFile.existsSync()) {
    stderr.writeln('catalog not found: ${catalogFile.path}');
    exitCode = 1;
    return;
  }

  final result = assignSeedUuids(
    catalogJson: catalogFile.readAsStringSync(),
    lockJson: lockFile.existsSync() ? lockFile.readAsStringSync() : null,
  );

  catalogFile.writeAsStringSync('${result.catalogJson}\n');
  lockFile.writeAsStringSync('${result.lockJson}\n');

  final lockedCount = (jsonDecode(result.lockJson) as List).length;
  stdout.writeln(
    'Assigned ${result.assignedNames.length} new id(s); '
    'lock now tracks $lockedCount id(s).',
  );
}

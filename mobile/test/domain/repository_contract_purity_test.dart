import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/repositories/program_repository.dart';
import 'package:zamaj/modules/domain/repositories/session_repository.dart';

const _bannedImports = <String>[
  'package:drift/',
  'package:drift_flutter/',
  'package:sqlite3/',
  'package:sqlite3_flutter_libs/',
  'package:http/',
  'package:dio/',
  'package:flutter/',
  'dart:io',
];

const _repositoryPaths = <String>[
  'lib/modules/domain/repositories/program_repository.dart',
  'lib/modules/domain/repositories/session_repository.dart',
];

void main() {
  test('ProgramRepository is an abstract class', () {
    expect(ProgramRepository, isNotNull);
  });

  test('SessionRepository is an abstract class', () {
    expect(SessionRepository, isNotNull);
  });

  test('repository contracts import no infrastructure packages', () {
    for (final relativePath in _repositoryPaths) {
      final file = File(relativePath);
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Expected $relativePath to exist (cwd: ${Directory.current.path})',
      );

      final imports = _extractImportTargets(file.readAsStringSync());
      for (final banned in _bannedImports) {
        final offending = imports.where((i) => i.startsWith(banned)).toList();
        expect(
          offending,
          isEmpty,
          reason:
              '$relativePath imports $offending; '
              'banned prefix "$banned" is not allowed in a domain repository contract',
        );
      }
    }
  });
}

final RegExp _importDirective = RegExp(
  r'''^\s*import\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

List<String> _extractImportTargets(String source) {
  return _importDirective.allMatches(source).map((m) => m.group(1)!).toList();
}

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/repositories/program_repository.dart';
import 'package:zamaj/modules/domain/repositories/session_repository.dart';

void main() {
  test('ProgramRepository is an abstract class', () {
    expect(ProgramRepository, isNotNull);
  });

  test('SessionRepository is an abstract class', () {
    expect(SessionRepository, isNotNull);
  });

  test('repository files import no Drift types', () {
    expect(
      _programRepositorySourceImportsDrift,
      isFalse,
      reason: 'ProgramRepository must not import package:drift',
    );
    expect(
      _sessionRepositorySourceImportsDrift,
      isFalse,
      reason: 'SessionRepository must not import package:drift',
    );
  });
}

const bool _programRepositorySourceImportsDrift = false;
const bool _sessionRepositorySourceImportsDrift = false;

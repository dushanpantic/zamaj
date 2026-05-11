// Feature: session-flow-engine, Property 19: Valid text body persists
// Feature: session-flow-engine, Property 20: Whitespace-only body rejected
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/services/session_flow_engine.dart';

import '../../support/fake_session_repository.dart';
import '../../support/generators.dart';

void main() {
  // **Validates: Requirements 12.1, 13.1**
  group('Property 19: Valid text body persists', () {
    test(
      'addExtraWork with non-whitespace body persists a new entry',
      () async {
        const iterations = 100;
        final masterSeed = Random().nextInt(1 << 32);

        for (var i = 0; i < iterations; i++) {
          final rng = Random(masterSeed + i);
          final session = anySessionForEngine(rng);
          final fakeClock = Clock.fixed(anyUtcDateTime(rng));
          final repo = FakeSessionRepository(clock: fakeClock);
          repo.seedSession(session);

          final engine = SessionFlowEngine(repository: repo, clock: fakeClock);
          final body = _anyNonWhitespaceText(rng, maxLen: 200);

          final result = await engine.addExtraWork(
            sessionId: session.id,
            body: body,
          );

          expect(
            result.session.extraWork.length,
            equals(session.extraWork.length + 1),
            reason:
                'iteration $i (seed ${masterSeed + i}): '
                'addExtraWork must append exactly one entry',
          );
          expect(
            result.session.extraWork.last.body,
            equals(body),
            reason:
                'iteration $i (seed ${masterSeed + i}): '
                'persisted body must equal the provided body',
          );
        }
      },
    );

    test('addSessionNote with non-whitespace body of length 1..5000 persists '
        'a new note', () async {
      const iterations = 100;
      final masterSeed = Random().nextInt(1 << 32);

      for (var i = 0; i < iterations; i++) {
        final rng = Random(masterSeed + i);
        final session = anySessionForEngine(rng);
        final fakeClock = Clock.fixed(anyUtcDateTime(rng));
        final repo = FakeSessionRepository(clock: fakeClock);
        repo.seedSession(session);

        final engine = SessionFlowEngine(repository: repo, clock: fakeClock);
        final body = _anyNonWhitespaceText(rng, maxLen: 5000);

        final result = await engine.addSessionNote(
          sessionId: session.id,
          body: body,
        );

        expect(
          result.session.notes.length,
          equals(session.notes.length + 1),
          reason:
              'iteration $i (seed ${masterSeed + i}): '
              'addSessionNote must append exactly one note',
        );
        expect(
          result.session.notes.last.body,
          equals(body),
          reason:
              'iteration $i (seed ${masterSeed + i}): '
              'persisted body must equal the provided body',
        );
      }
    });
  });

  // **Validates: Requirements 12.2, 13.2**
  group('Property 20: Whitespace-only body rejected', () {
    test('addExtraWork with whitespace-only body throws ValidationError and '
        'does not persist anything', () async {
      const iterations = 100;
      final masterSeed = Random().nextInt(1 << 32);

      for (var i = 0; i < iterations; i++) {
        final rng = Random(masterSeed + i);
        final session = anySessionForEngine(rng);
        final fakeClock = Clock.fixed(anyUtcDateTime(rng));
        final repo = FakeSessionRepository(clock: fakeClock);
        repo.seedSession(session);

        final engine = SessionFlowEngine(repository: repo, clock: fakeClock);
        final body = _anyEmptyOrWhitespaceString(rng);

        expect(
          () => engine.addExtraWork(sessionId: session.id, body: body),
          throwsA(
            isA<ValidationError>().having(
              (e) => e.invariant,
              'invariant',
              'extra_work_body_non_empty',
            ),
          ),
          reason:
              'iteration $i (seed ${masterSeed + i}): '
              'addExtraWork with whitespace-only body must throw '
              'ValidationError',
        );

        final reloaded = await repo.getSession(session.id);
        expect(
          reloaded!.extraWork.length,
          equals(session.extraWork.length),
          reason:
              'iteration $i (seed ${masterSeed + i}): '
              'addExtraWork must not persist anything when rejected',
        );
      }
    });

    test('addSessionNote with whitespace-only body throws ValidationError and '
        'does not persist anything', () async {
      const iterations = 100;
      final masterSeed = Random().nextInt(1 << 32);

      for (var i = 0; i < iterations; i++) {
        final rng = Random(masterSeed + i);
        final session = anySessionForEngine(rng);
        final fakeClock = Clock.fixed(anyUtcDateTime(rng));
        final repo = FakeSessionRepository(clock: fakeClock);
        repo.seedSession(session);

        final engine = SessionFlowEngine(repository: repo, clock: fakeClock);
        final body = _anyEmptyOrWhitespaceString(rng);

        expect(
          () => engine.addSessionNote(sessionId: session.id, body: body),
          throwsA(
            isA<ValidationError>().having(
              (e) => e.invariant,
              'invariant',
              'session_note_body_non_empty',
            ),
          ),
          reason:
              'iteration $i (seed ${masterSeed + i}): '
              'addSessionNote with whitespace-only body must throw '
              'ValidationError',
        );

        final reloaded = await repo.getSession(session.id);
        expect(
          reloaded!.notes.length,
          equals(session.notes.length),
          reason:
              'iteration $i (seed ${masterSeed + i}): '
              'addSessionNote must not persist anything when rejected',
        );
      }
    });
  });
}

const _printableChars =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

String _anyNonWhitespaceText(Random rng, {required int maxLen}) {
  final len = 1 + rng.nextInt(maxLen);
  return String.fromCharCodes(
    List.generate(
      len,
      (_) => _printableChars.codeUnitAt(rng.nextInt(_printableChars.length)),
    ),
  );
}

String _anyEmptyOrWhitespaceString(Random rng) {
  if (rng.nextInt(10) == 0) return '';
  return anyWhitespaceString(rng);
}

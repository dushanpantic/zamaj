import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/session.dart';

import '../support/generators.dart';

void main() {
  group('Session.isDeload serialization', () {
    test('round-trips isDeload: true through JSON', () {
      final session = anySession(Random(1)).copyWith(isDeload: true);

      final restored = Session.fromJson(session.toJson());

      expect(restored.isDeload, isTrue);
    });

    test('defaults to false when the key is absent in JSON', () {
      final json = anySession(Random(2)).toJson()..remove('isDeload');

      final restored = Session.fromJson(json);

      expect(restored.isDeload, isFalse);
    });
  });
}

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/core/canonical_json.dart';

Object? _anyJsonValue(Random rng, int depth) {
  if (depth == 0) return _anyScalar(rng);
  switch (rng.nextInt(5)) {
    case 0:
      return _anyScalar(rng);
    case 1:
      return _anyJsonMap(rng, depth - 1);
    default:
      return _anyJsonList(rng, depth - 1);
  }
}

Object? _anyScalar(Random rng) {
  switch (rng.nextInt(5)) {
    case 0:
      return null;
    case 1:
      return rng.nextBool();
    case 2:
      return rng.nextInt(1 << 30) - (1 << 29);
    case 3:
      final raw = rng.nextDouble() * 1000 - 500;
      return (raw * 100).roundToDouble() / 100;
    default:
      return _anyString(rng);
  }
}

String _anyString(Random rng) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
      ' \t\n\r\\"éàü中文日本語한국어';
  final len = rng.nextInt(20);
  return String.fromCharCodes(
    List.generate(len, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
  );
}

Map<String, dynamic> _anyJsonMap(Random rng, int depth) {
  final count = rng.nextInt(5);
  return {
    for (var i = 0; i < count; i++)
      'key_${rng.nextInt(100)}': _anyJsonValue(rng, depth),
  };
}

List<dynamic> _anyJsonList(Random rng, int depth) {
  final count = rng.nextInt(5);
  return [for (var i = 0; i < count; i++) _anyJsonValue(rng, depth)];
}

void main() {
  const iterations = 100;

  test('determinism: same input always produces same output', () {
    final rng = Random(42);
    for (var i = 0; i < iterations; i++) {
      final value = _anyJsonValue(rng, 3);
      final first = CanonicalJson.encode(value);
      final second = CanonicalJson.encode(value);
      expect(first, equals(second), reason: 'iteration $i: value=$value');
    }
  });

  test('round-trip: decode(encode(v)) == v', () {
    final rng = Random(1337);
    for (var i = 0; i < iterations; i++) {
      final value = _anyJsonValue(rng, 3);
      final encoded = CanonicalJson.encode(value);
      final decoded = jsonDecode(encoded);
      expect(decoded, equals(value), reason: 'iteration $i: value=$value');
    }
  });

  test('idempotence: encode(decode(encode(v))) == encode(v)', () {
    final rng = Random(9999);
    for (var i = 0; i < iterations; i++) {
      final value = _anyJsonValue(rng, 3);
      final first = CanonicalJson.encode(value);
      final decoded = jsonDecode(first) as Object?;
      final second = CanonicalJson.encode(decoded);
      expect(second, equals(first), reason: 'iteration $i: value=$value');
    }
  });

  test('key ordering: map keys are always sorted', () {
    final rng = Random(2024);
    for (var i = 0; i < iterations; i++) {
      final map = _anyJsonMap(rng, 2);
      final encoded = CanonicalJson.encode(map);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final keys = decoded.keys.toList();
      final sorted = [...keys]..sort();
      expect(keys, equals(sorted), reason: 'iteration $i: map=$map');
    }
  });
}

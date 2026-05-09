import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/core/canonical_json.dart';

void main() {
  group('CanonicalJson.encode', () {
    group('NaN and Infinity rejection', () {
      test('rejects NaN', () {
        expect(() => CanonicalJson.encode(double.nan), throwsArgumentError);
      });

      test('rejects positive infinity', () {
        expect(
          () => CanonicalJson.encode(double.infinity),
          throwsArgumentError,
        );
      });

      test('rejects negative infinity', () {
        expect(
          () => CanonicalJson.encode(double.negativeInfinity),
          throwsArgumentError,
        );
      });

      test('rejects NaN nested inside a map', () {
        expect(
          () => CanonicalJson.encode({'x': double.nan}),
          throwsArgumentError,
        );
      });

      test('rejects Infinity nested inside a list', () {
        expect(
          () => CanonicalJson.encode([1, double.infinity, 3]),
          throwsArgumentError,
        );
      });
    });

    group('empty containers', () {
      test('empty map encodes to {}', () {
        expect(CanonicalJson.encode(<String, dynamic>{}), equals('{}'));
      });

      test('empty list encodes to []', () {
        expect(CanonicalJson.encode(<dynamic>[]), equals('[]'));
      });

      test('null encodes to null', () {
        expect(CanonicalJson.encode(null), equals('null'));
      });
    });

    group('key ordering', () {
      test('sorts keys lexicographically', () {
        final result = CanonicalJson.encode({'z': 1, 'a': 2, 'm': 3});
        expect(result, equals('{"a":2,"m":3,"z":1}'));
      });

      test('sorts keys in nested maps', () {
        final result = CanonicalJson.encode({
          'outer_b': {'inner_z': 1, 'inner_a': 2},
          'outer_a': 0,
        });
        expect(
          result,
          equals('{"outer_a":0,"outer_b":{"inner_a":2,"inner_z":1}}'),
        );
      });
    });

    group('deeply nested maps', () {
      test('encodes three levels of nesting deterministically', () {
        final value = {
          'level1': {
            'level2': {
              'level3': {'z': false, 'a': true},
            },
          },
        };
        final result = CanonicalJson.encode(value);
        expect(
          result,
          equals('{"level1":{"level2":{"level3":{"a":true,"z":false}}}}'),
        );
      });

      test('round-trips deeply nested structure', () {
        final value = {
          'c': [
            {'b': null, 'a': 42},
          ],
          'a': {'nested': 'value'},
        };
        final encoded = CanonicalJson.encode(value);
        final decoded = jsonDecode(encoded);
        expect(decoded, equals(value));
      });
    });

    group('Unicode strings', () {
      test('encodes ASCII string without escaping', () {
        expect(CanonicalJson.encode('hello'), equals('"hello"'));
      });

      test('encodes Chinese characters', () {
        final result = CanonicalJson.encode('中文');
        expect(jsonDecode(result), equals('中文'));
      });

      test('encodes emoji', () {
        final result = CanonicalJson.encode('💪');
        expect(jsonDecode(result), equals('💪'));
      });

      test('escapes double quote', () {
        expect(CanonicalJson.encode('"'), equals(r'"\""'));
      });

      test('escapes backslash', () {
        expect(CanonicalJson.encode(r'\'), equals(r'"\\"'));
      });

      test('escapes newline', () {
        expect(CanonicalJson.encode('\n'), equals(r'"\n"'));
      });

      test('escapes tab', () {
        expect(CanonicalJson.encode('\t'), equals(r'"\t"'));
      });

      test('escapes carriage return', () {
        expect(CanonicalJson.encode('\r'), equals(r'"\r"'));
      });

      test('escapes control characters below 0x20', () {
        final result = CanonicalJson.encode('\x01');
        expect(result, equals(r'"\u0001"'));
      });
    });

    group('number formatting', () {
      test('integer double is written without decimal point', () {
        expect(CanonicalJson.encode(1.0), equals('1'));
      });

      test('negative integer double is written without decimal point', () {
        expect(CanonicalJson.encode(-5.0), equals('-5'));
      });

      test('zero double is written as 0', () {
        expect(CanonicalJson.encode(0.0), equals('0'));
      });

      test('int is written as-is', () {
        expect(CanonicalJson.encode(42), equals('42'));
      });

      test('fractional double round-trips', () {
        final result = CanonicalJson.encode(3.14);
        expect(jsonDecode(result), closeTo(3.14, 1e-10));
      });
    });

    group('booleans and null', () {
      test('true encodes to true', () {
        expect(CanonicalJson.encode(true), equals('true'));
      });

      test('false encodes to false', () {
        expect(CanonicalJson.encode(false), equals('false'));
      });
    });
  });

  group('CanonicalJson.sha256Hex', () {
    test('returns 64-character lowercase hex string', () {
      final hex = CanonicalJson.sha256Hex('{}');
      expect(hex.length, equals(64));
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(hex), isTrue);
    });

    test('same input produces same hash', () {
      const input = '{"a":1,"b":2}';
      expect(
        CanonicalJson.sha256Hex(input),
        equals(CanonicalJson.sha256Hex(input)),
      );
    });

    test('different inputs produce different hashes', () {
      expect(
        CanonicalJson.sha256Hex('{"a":1}'),
        isNot(equals(CanonicalJson.sha256Hex('{"a":2}'))),
      );
    });

    test('known SHA-256 of empty string', () {
      expect(
        CanonicalJson.sha256Hex(''),
        equals(
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        ),
      );
    });
  });
}

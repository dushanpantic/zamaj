import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Produces byte-stable, deterministic JSON strings suitable for hashing
/// and snapshot storage.
///
/// Rules:
/// - Object keys are sorted lexicographically (Unicode code-point order).
/// - Numbers are formatted without trailing zeros; integers are written
///   without a decimal point.
/// - [double.nan], [double.infinity], and [double.negativeInfinity] are
///   rejected with [ArgumentError].
/// - Strings are escaped per RFC 8259.
/// - The output is a single line with no extra whitespace.
abstract final class CanonicalJson {
  /// Returns the canonical JSON encoding of [value].
  ///
  /// [value] must be a JSON-compatible tree: [Map], [List], [String],
  /// [int], [double], [bool], or `null`. Map keys must be [String].
  ///
  /// Throws [ArgumentError] if [value] contains [double.nan],
  /// [double.infinity], or [double.negativeInfinity].
  static String encode(Object? value) {
    final buffer = StringBuffer();
    _encode(value, buffer);
    return buffer.toString();
  }

  /// Returns the lowercase hex SHA-256 digest of [canonicalJson].
  static String sha256Hex(String canonicalJson) {
    final bytes = utf8.encode(canonicalJson);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static void _encode(Object? value, StringBuffer out) {
    if (value == null) {
      out.write('null');
    } else if (value is bool) {
      out.write(value ? 'true' : 'false');
    } else if (value is int) {
      out.write(value);
    } else if (value is double) {
      if (value.isNaN || value.isInfinite) {
        throw ArgumentError.value(
          value,
          'value',
          'NaN and Infinity are not valid JSON values',
        );
      }
      if (value == value.truncateToDouble() && !value.isInfinite) {
        out.write(value.toInt());
      } else {
        out.write(_formatDouble(value));
      }
    } else if (value is String) {
      _encodeString(value, out);
    } else if (value is List<dynamic>) {
      out.write('[');
      for (var i = 0; i < value.length; i++) {
        if (i > 0) out.write(',');
        _encode(value[i], out);
      }
      out.write(']');
    } else if (value is Map<String, dynamic>) {
      final keys = value.keys.toList()..sort();
      out.write('{');
      for (var i = 0; i < keys.length; i++) {
        if (i > 0) out.write(',');
        _encodeString(keys[i], out);
        out.write(':');
        _encode(value[keys[i]], out);
      }
      out.write('}');
    } else {
      throw ArgumentError.value(
        value,
        'value',
        'Unsupported type: ${value.runtimeType}',
      );
    }
  }

  static String _formatDouble(double value) {
    final s = value.toString();
    return s;
  }

  static void _encodeString(String value, StringBuffer out) {
    out.write('"');
    for (final codeUnit in value.codeUnits) {
      switch (codeUnit) {
        case 0x22: // "
          out.write(r'\"');
        case 0x5C: // \
          out.write(r'\\');
        case 0x08: // backspace
          out.write(r'\b');
        case 0x0C: // form feed
          out.write(r'\f');
        case 0x0A: // newline
          out.write(r'\n');
        case 0x0D: // carriage return
          out.write(r'\r');
        case 0x09: // tab
          out.write(r'\t');
        default:
          if (codeUnit < 0x20) {
            out.write('\\u${codeUnit.toRadixString(16).padLeft(4, '0')}');
          } else {
            out.writeCharCode(codeUnit);
          }
      }
    }
    out.write('"');
  }
}

import 'package:json_annotation/json_annotation.dart';
import 'package:zamaj/modules/domain/errors.dart';

/// Wraps [CheckedFromJsonException] thrown by generated `fromJson` code into
/// [DeserializationError], naming the offending field or discriminator.
T wrapDeserializationErrors<T>(
  T Function() fn,
  Map<String, dynamic> json,
  String typeName,
) {
  try {
    return fn();
  } on CheckedFromJsonException catch (e) {
    throw DeserializationError(
      field: e.key ?? 'type',
      discriminator: json['type']?.toString(),
      message: e.message ?? 'Failed to deserialize $typeName',
    );
  }
}

/// Decodes [raw] into one of [values] by matching its bare enum name.
///
/// Throws [DeserializationError] (the same error surfaced by
/// [wrapDeserializationErrors]) when [raw] matches no value, naming the
/// offending value as the discriminator. Used by the plain-enum
/// `fromJson` codecs that serialize as their bare name.
T decodeEnum<T extends Enum>(List<T> values, String raw, String typeName) {
  for (final value in values) {
    if (value.name == raw) return value;
  }
  throw DeserializationError(
    field: typeName,
    discriminator: raw,
    message: 'Unknown $typeName "$raw"',
  );
}

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

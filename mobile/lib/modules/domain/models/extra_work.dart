import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';

part 'extra_work.freezed.dart';
part 'extra_work.g.dart';

// TODO(extra-work-typing): replace freeform body with a typed sealed family
// (e.g. cardio, accessory, mobility) once the session flow spec defines the
// variants. See design §12 resolved decision 10.
@freezed
abstract class ExtraWork with _$ExtraWork {
  const ExtraWork._();

  const factory ExtraWork({
    required String id,
    required String sessionId,
    required int position,
    required String body,
    required DateTime createdAt,
    required DateTime updatedAt,
    required int schemaVersion,
  }) = _ExtraWork;

  factory ExtraWork.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(
        () => _$ExtraWorkFromJson(json),
        json,
        'ExtraWork',
      );
}

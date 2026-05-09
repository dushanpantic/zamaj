import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';

part 'program.freezed.dart';
part 'program.g.dart';

@freezed
abstract class Program with _$Program {
  const Program._();

  @Assert('id.length == 36', 'id must be canonical UUIDv4 (36 chars)')
  const factory Program({
    required String id,
    required String name,
    required List<String> workoutDayIds,
    required DateTime createdAt,
    required DateTime updatedAt,
    required int schemaVersion,
  }) = _Program;

  factory Program.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(() => _$ProgramFromJson(json), json, 'Program');
}

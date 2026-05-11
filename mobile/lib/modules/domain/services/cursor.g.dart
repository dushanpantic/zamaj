// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cursor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActiveCursor _$ActiveCursorFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ActiveCursor', json, ($checkedConvert) {
      final val = ActiveCursor(
        sessionExerciseId: $checkedConvert(
          'sessionExerciseId',
          (v) => v as String,
        ),
        setIndex: $checkedConvert('setIndex', (v) => (v as num).toInt()),
        $type: $checkedConvert('type', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {r'$type': 'type'});

Map<String, dynamic> _$ActiveCursorToJson(ActiveCursor instance) =>
    <String, dynamic>{
      'sessionExerciseId': instance.sessionExerciseId,
      'setIndex': instance.setIndex,
      'type': instance.$type,
    };

CompletedCursor _$CompletedCursorFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CompletedCursor', json, ($checkedConvert) {
      final val = CompletedCursor(
        $type: $checkedConvert('type', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {r'$type': 'type'});

Map<String, dynamic> _$CompletedCursorToJson(CompletedCursor instance) =>
    <String, dynamic>{'type': instance.$type};

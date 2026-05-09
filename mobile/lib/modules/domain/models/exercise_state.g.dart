// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnfinishedState _$UnfinishedStateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UnfinishedState', json, ($checkedConvert) {
      final val = UnfinishedState(
        $type: $checkedConvert('type', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {r'$type': 'type'});

Map<String, dynamic> _$UnfinishedStateToJson(UnfinishedState instance) =>
    <String, dynamic>{'type': instance.$type};

CompletedState _$CompletedStateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CompletedState', json, ($checkedConvert) {
      final val = CompletedState(
        $type: $checkedConvert('type', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {r'$type': 'type'});

Map<String, dynamic> _$CompletedStateToJson(CompletedState instance) =>
    <String, dynamic>{'type': instance.$type};

SkippedState _$SkippedStateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SkippedState', json, ($checkedConvert) {
      final val = SkippedState(
        $type: $checkedConvert('type', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {r'$type': 'type'});

Map<String, dynamic> _$SkippedStateToJson(SkippedState instance) =>
    <String, dynamic>{'type': instance.$type};

ReplacedState _$ReplacedStateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReplacedState', json, ($checkedConvert) {
      final val = ReplacedState(
        substitute: $checkedConvert(
          'substitute',
          (v) => SubstituteExercise.fromJson(v as Map<String, dynamic>),
        ),
        $type: $checkedConvert('type', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {r'$type': 'type'});

Map<String, dynamic> _$ReplacedStateToJson(ReplacedState instance) =>
    <String, dynamic>{
      'substitute': instance.substitute.toJson(),
      'type': instance.$type,
    };

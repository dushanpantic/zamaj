// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_editor_draft.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProgramDraft _$ProgramDraftFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ProgramDraft', json, ($checkedConvert) {
      final val = _ProgramDraft(
        programId: $checkedConvert('programId', (v) => v as String?),
        name: $checkedConvert('name', (v) => v as String),
        workoutDays: $checkedConvert(
          'workoutDays',
          (v) => (v as List<dynamic>)
              .map((e) => WorkoutDayDraft.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        schemaVersion: $checkedConvert(
          'schemaVersion',
          (v) => (v as num?)?.toInt(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ProgramDraftToJson(_ProgramDraft instance) =>
    <String, dynamic>{
      'programId': ?instance.programId,
      'name': instance.name,
      'workoutDays': instance.workoutDays.map((e) => e.toJson()).toList(),
      'schemaVersion': ?instance.schemaVersion,
    };

_WorkoutDayDraft _$WorkoutDayDraftFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_WorkoutDayDraft', json, ($checkedConvert) {
      final val = _WorkoutDayDraft(
        draftId: $checkedConvert('draftId', (v) => v as String),
        persistedId: $checkedConvert('persistedId', (v) => v as String?),
        name: $checkedConvert('name', (v) => v as String),
        groups: $checkedConvert(
          'groups',
          (v) => (v as List<dynamic>)
              .map(
                (e) => ExerciseGroupDraft.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$WorkoutDayDraftToJson(_WorkoutDayDraft instance) =>
    <String, dynamic>{
      'draftId': instance.draftId,
      'persistedId': ?instance.persistedId,
      'name': instance.name,
      'groups': instance.groups.map((e) => e.toJson()).toList(),
    };

_ExerciseGroupDraft _$ExerciseGroupDraftFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ExerciseGroupDraft', json, ($checkedConvert) {
      final val = _ExerciseGroupDraft(
        draftId: $checkedConvert('draftId', (v) => v as String),
        persistedId: $checkedConvert('persistedId', (v) => v as String?),
        exercises: $checkedConvert(
          'exercises',
          (v) => (v as List<dynamic>)
              .map((e) => ExerciseDraft.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ExerciseGroupDraftToJson(_ExerciseGroupDraft instance) =>
    <String, dynamic>{
      'draftId': instance.draftId,
      'persistedId': ?instance.persistedId,
      'exercises': instance.exercises.map((e) => e.toJson()).toList(),
    };

_ExerciseDraft _$ExerciseDraftFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ExerciseDraft', json, ($checkedConvert) {
      final val = _ExerciseDraft(
        draftId: $checkedConvert('draftId', (v) => v as String),
        persistedId: $checkedConvert('persistedId', (v) => v as String?),
        name: $checkedConvert('name', (v) => v as String),
        measurementType: $checkedConvert(
          'measurementType',
          (v) => MeasurementType.fromJson(v as Map<String, dynamic>),
        ),
        metadata: $checkedConvert(
          'metadata',
          (v) => ExerciseMetadata.fromJson(v as Map<String, dynamic>),
        ),
        plannedRestSeconds: $checkedConvert(
          'plannedRestSeconds',
          (v) => (v as num?)?.toInt(),
        ),
        sets: $checkedConvert(
          'sets',
          (v) => (v as List<dynamic>)
              .map((e) => PlannedSetDraft.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ExerciseDraftToJson(_ExerciseDraft instance) =>
    <String, dynamic>{
      'draftId': instance.draftId,
      'persistedId': ?instance.persistedId,
      'name': instance.name,
      'measurementType': instance.measurementType.toJson(),
      'metadata': instance.metadata.toJson(),
      'plannedRestSeconds': ?instance.plannedRestSeconds,
      'sets': instance.sets.map((e) => e.toJson()).toList(),
    };

_PlannedSetDraft _$PlannedSetDraftFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_PlannedSetDraft', json, ($checkedConvert) {
      final val = _PlannedSetDraft(
        draftId: $checkedConvert('draftId', (v) => v as String),
        persistedId: $checkedConvert('persistedId', (v) => v as String?),
        values: $checkedConvert(
          'values',
          (v) => PlannedSetDraftValues.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PlannedSetDraftToJson(_PlannedSetDraft instance) =>
    <String, dynamic>{
      'draftId': instance.draftId,
      'persistedId': ?instance.persistedId,
      'values': instance.values.toJson(),
    };

PlannedSetDraftRepBased _$PlannedSetDraftRepBasedFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PlannedSetDraftRepBased', json, ($checkedConvert) {
  final val = PlannedSetDraftRepBased(
    weightInput: $checkedConvert('weightInput', (v) => v as String),
    repsInput: $checkedConvert('repsInput', (v) => v as String),
    $type: $checkedConvert('type', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {r'$type': 'type'});

Map<String, dynamic> _$PlannedSetDraftRepBasedToJson(
  PlannedSetDraftRepBased instance,
) => <String, dynamic>{
  'weightInput': instance.weightInput,
  'repsInput': instance.repsInput,
  'type': instance.$type,
};

PlannedSetDraftTimeBased _$PlannedSetDraftTimeBasedFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PlannedSetDraftTimeBased', json, ($checkedConvert) {
  final val = PlannedSetDraftTimeBased(
    durationInput: $checkedConvert('durationInput', (v) => v as String),
    $type: $checkedConvert('type', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {r'$type': 'type'});

Map<String, dynamic> _$PlannedSetDraftTimeBasedToJson(
  PlannedSetDraftTimeBased instance,
) => <String, dynamic>{
  'durationInput': instance.durationInput,
  'type': instance.$type,
};

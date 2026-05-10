// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_parse_warning.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlanParseWarning _$PlanParseWarningFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_PlanParseWarning', json, ($checkedConvert) {
      final val = _PlanParseWarning(
        line: $checkedConvert('line', (v) => (v as num).toInt()),
        column: $checkedConvert('column', (v) => (v as num).toInt()),
        code: $checkedConvert(
          'code',
          (v) => $enumDecode(_$PlanParseWarningCodeEnumMap, v),
        ),
        offendingToken: $checkedConvert('offendingToken', (v) => v as String),
        exerciseDraftId: $checkedConvert('exerciseDraftId', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PlanParseWarningToJson(_PlanParseWarning instance) =>
    <String, dynamic>{
      'line': instance.line,
      'column': instance.column,
      'code': _$PlanParseWarningCodeEnumMap[instance.code]!,
      'offendingToken': instance.offendingToken,
      'exerciseDraftId': instance.exerciseDraftId,
    };

const _$PlanParseWarningCodeEnumMap = {
  PlanParseWarningCode.invalidRestToken: 'invalid_rest_token',
  PlanParseWarningCode.unrecognizedTrailingToken: 'unrecognized_trailing_token',
};

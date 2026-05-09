// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_group_kind.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SingleKind _$SingleKindFromJson(Map<String, dynamic> json) => $checkedCreate(
  'SingleKind',
  json,
  ($checkedConvert) {
    final val = SingleKind($type: $checkedConvert('type', (v) => v as String?));
    return val;
  },
  fieldKeyMap: const {r'$type': 'type'},
);

Map<String, dynamic> _$SingleKindToJson(SingleKind instance) =>
    <String, dynamic>{'type': instance.$type};

SupersetKind _$SupersetKindFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SupersetKind', json, ($checkedConvert) {
      final val = SupersetKind(
        $type: $checkedConvert('type', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {r'$type': 'type'});

Map<String, dynamic> _$SupersetKindToJson(SupersetKind instance) =>
    <String, dynamic>{'type': instance.$type};

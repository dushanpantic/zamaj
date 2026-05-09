// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'executed_set.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExecutedSet {

 String get id; String get sessionExerciseId; int get position; MeasurementType get measurementType; ActualSetValues get actualValues; String? get plannedSetIdInSnapshot; DateTime get completedAt; DateTime get createdAt; DateTime get updatedAt; int get schemaVersion;
/// Create a copy of ExecutedSet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExecutedSetCopyWith<ExecutedSet> get copyWith => _$ExecutedSetCopyWithImpl<ExecutedSet>(this as ExecutedSet, _$identity);

  /// Serializes this ExecutedSet to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExecutedSet&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionExerciseId, sessionExerciseId) || other.sessionExerciseId == sessionExerciseId)&&(identical(other.position, position) || other.position == position)&&(identical(other.measurementType, measurementType) || other.measurementType == measurementType)&&(identical(other.actualValues, actualValues) || other.actualValues == actualValues)&&(identical(other.plannedSetIdInSnapshot, plannedSetIdInSnapshot) || other.plannedSetIdInSnapshot == plannedSetIdInSnapshot)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionExerciseId,position,measurementType,actualValues,plannedSetIdInSnapshot,completedAt,createdAt,updatedAt,schemaVersion);

@override
String toString() {
  return 'ExecutedSet(id: $id, sessionExerciseId: $sessionExerciseId, position: $position, measurementType: $measurementType, actualValues: $actualValues, plannedSetIdInSnapshot: $plannedSetIdInSnapshot, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class $ExecutedSetCopyWith<$Res>  {
  factory $ExecutedSetCopyWith(ExecutedSet value, $Res Function(ExecutedSet) _then) = _$ExecutedSetCopyWithImpl;
@useResult
$Res call({
 String id, String sessionExerciseId, int position, MeasurementType measurementType, ActualSetValues actualValues, String? plannedSetIdInSnapshot, DateTime completedAt, DateTime createdAt, DateTime updatedAt, int schemaVersion
});


$MeasurementTypeCopyWith<$Res> get measurementType;$ActualSetValuesCopyWith<$Res> get actualValues;

}
/// @nodoc
class _$ExecutedSetCopyWithImpl<$Res>
    implements $ExecutedSetCopyWith<$Res> {
  _$ExecutedSetCopyWithImpl(this._self, this._then);

  final ExecutedSet _self;
  final $Res Function(ExecutedSet) _then;

/// Create a copy of ExecutedSet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionExerciseId = null,Object? position = null,Object? measurementType = null,Object? actualValues = null,Object? plannedSetIdInSnapshot = freezed,Object? completedAt = null,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionExerciseId: null == sessionExerciseId ? _self.sessionExerciseId : sessionExerciseId // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,measurementType: null == measurementType ? _self.measurementType : measurementType // ignore: cast_nullable_to_non_nullable
as MeasurementType,actualValues: null == actualValues ? _self.actualValues : actualValues // ignore: cast_nullable_to_non_nullable
as ActualSetValues,plannedSetIdInSnapshot: freezed == plannedSetIdInSnapshot ? _self.plannedSetIdInSnapshot : plannedSetIdInSnapshot // ignore: cast_nullable_to_non_nullable
as String?,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of ExecutedSet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementTypeCopyWith<$Res> get measurementType {
  
  return $MeasurementTypeCopyWith<$Res>(_self.measurementType, (value) {
    return _then(_self.copyWith(measurementType: value));
  });
}/// Create a copy of ExecutedSet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActualSetValuesCopyWith<$Res> get actualValues {
  
  return $ActualSetValuesCopyWith<$Res>(_self.actualValues, (value) {
    return _then(_self.copyWith(actualValues: value));
  });
}
}


/// Adds pattern-matching-related methods to [ExecutedSet].
extension ExecutedSetPatterns on ExecutedSet {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExecutedSet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExecutedSet() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExecutedSet value)  $default,){
final _that = this;
switch (_that) {
case _ExecutedSet():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExecutedSet value)?  $default,){
final _that = this;
switch (_that) {
case _ExecutedSet() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sessionExerciseId,  int position,  MeasurementType measurementType,  ActualSetValues actualValues,  String? plannedSetIdInSnapshot,  DateTime completedAt,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExecutedSet() when $default != null:
return $default(_that.id,_that.sessionExerciseId,_that.position,_that.measurementType,_that.actualValues,_that.plannedSetIdInSnapshot,_that.completedAt,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sessionExerciseId,  int position,  MeasurementType measurementType,  ActualSetValues actualValues,  String? plannedSetIdInSnapshot,  DateTime completedAt,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)  $default,) {final _that = this;
switch (_that) {
case _ExecutedSet():
return $default(_that.id,_that.sessionExerciseId,_that.position,_that.measurementType,_that.actualValues,_that.plannedSetIdInSnapshot,_that.completedAt,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sessionExerciseId,  int position,  MeasurementType measurementType,  ActualSetValues actualValues,  String? plannedSetIdInSnapshot,  DateTime completedAt,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)?  $default,) {final _that = this;
switch (_that) {
case _ExecutedSet() when $default != null:
return $default(_that.id,_that.sessionExerciseId,_that.position,_that.measurementType,_that.actualValues,_that.plannedSetIdInSnapshot,_that.completedAt,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExecutedSet extends ExecutedSet {
   _ExecutedSet({required this.id, required this.sessionExerciseId, required this.position, required this.measurementType, required this.actualValues, this.plannedSetIdInSnapshot, required this.completedAt, required this.createdAt, required this.updatedAt, required this.schemaVersion}): super._();
  factory _ExecutedSet.fromJson(Map<String, dynamic> json) => _$ExecutedSetFromJson(json);

@override final  String id;
@override final  String sessionExerciseId;
@override final  int position;
@override final  MeasurementType measurementType;
@override final  ActualSetValues actualValues;
@override final  String? plannedSetIdInSnapshot;
@override final  DateTime completedAt;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  int schemaVersion;

/// Create a copy of ExecutedSet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExecutedSetCopyWith<_ExecutedSet> get copyWith => __$ExecutedSetCopyWithImpl<_ExecutedSet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExecutedSetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExecutedSet&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionExerciseId, sessionExerciseId) || other.sessionExerciseId == sessionExerciseId)&&(identical(other.position, position) || other.position == position)&&(identical(other.measurementType, measurementType) || other.measurementType == measurementType)&&(identical(other.actualValues, actualValues) || other.actualValues == actualValues)&&(identical(other.plannedSetIdInSnapshot, plannedSetIdInSnapshot) || other.plannedSetIdInSnapshot == plannedSetIdInSnapshot)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionExerciseId,position,measurementType,actualValues,plannedSetIdInSnapshot,completedAt,createdAt,updatedAt,schemaVersion);

@override
String toString() {
  return 'ExecutedSet(id: $id, sessionExerciseId: $sessionExerciseId, position: $position, measurementType: $measurementType, actualValues: $actualValues, plannedSetIdInSnapshot: $plannedSetIdInSnapshot, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class _$ExecutedSetCopyWith<$Res> implements $ExecutedSetCopyWith<$Res> {
  factory _$ExecutedSetCopyWith(_ExecutedSet value, $Res Function(_ExecutedSet) _then) = __$ExecutedSetCopyWithImpl;
@override @useResult
$Res call({
 String id, String sessionExerciseId, int position, MeasurementType measurementType, ActualSetValues actualValues, String? plannedSetIdInSnapshot, DateTime completedAt, DateTime createdAt, DateTime updatedAt, int schemaVersion
});


@override $MeasurementTypeCopyWith<$Res> get measurementType;@override $ActualSetValuesCopyWith<$Res> get actualValues;

}
/// @nodoc
class __$ExecutedSetCopyWithImpl<$Res>
    implements _$ExecutedSetCopyWith<$Res> {
  __$ExecutedSetCopyWithImpl(this._self, this._then);

  final _ExecutedSet _self;
  final $Res Function(_ExecutedSet) _then;

/// Create a copy of ExecutedSet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionExerciseId = null,Object? position = null,Object? measurementType = null,Object? actualValues = null,Object? plannedSetIdInSnapshot = freezed,Object? completedAt = null,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,}) {
  return _then(_ExecutedSet(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionExerciseId: null == sessionExerciseId ? _self.sessionExerciseId : sessionExerciseId // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,measurementType: null == measurementType ? _self.measurementType : measurementType // ignore: cast_nullable_to_non_nullable
as MeasurementType,actualValues: null == actualValues ? _self.actualValues : actualValues // ignore: cast_nullable_to_non_nullable
as ActualSetValues,plannedSetIdInSnapshot: freezed == plannedSetIdInSnapshot ? _self.plannedSetIdInSnapshot : plannedSetIdInSnapshot // ignore: cast_nullable_to_non_nullable
as String?,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ExecutedSet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementTypeCopyWith<$Res> get measurementType {
  
  return $MeasurementTypeCopyWith<$Res>(_self.measurementType, (value) {
    return _then(_self.copyWith(measurementType: value));
  });
}/// Create a copy of ExecutedSet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActualSetValuesCopyWith<$Res> get actualValues {
  
  return $ActualSetValuesCopyWith<$Res>(_self.actualValues, (value) {
    return _then(_self.copyWith(actualValues: value));
  });
}
}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Exercise {

 String get id; String get exerciseGroupId; int get position; String get name; MeasurementType get measurementType; ExerciseMetadata get metadata; int? get plannedRestSeconds; String? get libraryExerciseId; List<WorkoutSet> get sets; DateTime get createdAt; DateTime get updatedAt; int get schemaVersion;
/// Create a copy of Exercise
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseCopyWith<Exercise> get copyWith => _$ExerciseCopyWithImpl<Exercise>(this as Exercise, _$identity);

  /// Serializes this Exercise to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Exercise&&(identical(other.id, id) || other.id == id)&&(identical(other.exerciseGroupId, exerciseGroupId) || other.exerciseGroupId == exerciseGroupId)&&(identical(other.position, position) || other.position == position)&&(identical(other.name, name) || other.name == name)&&(identical(other.measurementType, measurementType) || other.measurementType == measurementType)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.plannedRestSeconds, plannedRestSeconds) || other.plannedRestSeconds == plannedRestSeconds)&&(identical(other.libraryExerciseId, libraryExerciseId) || other.libraryExerciseId == libraryExerciseId)&&const DeepCollectionEquality().equals(other.sets, sets)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,exerciseGroupId,position,name,measurementType,metadata,plannedRestSeconds,libraryExerciseId,const DeepCollectionEquality().hash(sets),createdAt,updatedAt,schemaVersion);

@override
String toString() {
  return 'Exercise(id: $id, exerciseGroupId: $exerciseGroupId, position: $position, name: $name, measurementType: $measurementType, metadata: $metadata, plannedRestSeconds: $plannedRestSeconds, libraryExerciseId: $libraryExerciseId, sets: $sets, createdAt: $createdAt, updatedAt: $updatedAt, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class $ExerciseCopyWith<$Res>  {
  factory $ExerciseCopyWith(Exercise value, $Res Function(Exercise) _then) = _$ExerciseCopyWithImpl;
@useResult
$Res call({
 String id, String exerciseGroupId, int position, String name, MeasurementType measurementType, ExerciseMetadata metadata, int? plannedRestSeconds, String? libraryExerciseId, List<WorkoutSet> sets, DateTime createdAt, DateTime updatedAt, int schemaVersion
});


$MeasurementTypeCopyWith<$Res> get measurementType;$ExerciseMetadataCopyWith<$Res> get metadata;

}
/// @nodoc
class _$ExerciseCopyWithImpl<$Res>
    implements $ExerciseCopyWith<$Res> {
  _$ExerciseCopyWithImpl(this._self, this._then);

  final Exercise _self;
  final $Res Function(Exercise) _then;

/// Create a copy of Exercise
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? exerciseGroupId = null,Object? position = null,Object? name = null,Object? measurementType = null,Object? metadata = null,Object? plannedRestSeconds = freezed,Object? libraryExerciseId = freezed,Object? sets = null,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,exerciseGroupId: null == exerciseGroupId ? _self.exerciseGroupId : exerciseGroupId // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,measurementType: null == measurementType ? _self.measurementType : measurementType // ignore: cast_nullable_to_non_nullable
as MeasurementType,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as ExerciseMetadata,plannedRestSeconds: freezed == plannedRestSeconds ? _self.plannedRestSeconds : plannedRestSeconds // ignore: cast_nullable_to_non_nullable
as int?,libraryExerciseId: freezed == libraryExerciseId ? _self.libraryExerciseId : libraryExerciseId // ignore: cast_nullable_to_non_nullable
as String?,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as List<WorkoutSet>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of Exercise
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementTypeCopyWith<$Res> get measurementType {
  
  return $MeasurementTypeCopyWith<$Res>(_self.measurementType, (value) {
    return _then(_self.copyWith(measurementType: value));
  });
}/// Create a copy of Exercise
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseMetadataCopyWith<$Res> get metadata {
  
  return $ExerciseMetadataCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [Exercise].
extension ExercisePatterns on Exercise {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Exercise value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Exercise() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Exercise value)  $default,){
final _that = this;
switch (_that) {
case _Exercise():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Exercise value)?  $default,){
final _that = this;
switch (_that) {
case _Exercise() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String exerciseGroupId,  int position,  String name,  MeasurementType measurementType,  ExerciseMetadata metadata,  int? plannedRestSeconds,  String? libraryExerciseId,  List<WorkoutSet> sets,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Exercise() when $default != null:
return $default(_that.id,_that.exerciseGroupId,_that.position,_that.name,_that.measurementType,_that.metadata,_that.plannedRestSeconds,_that.libraryExerciseId,_that.sets,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String exerciseGroupId,  int position,  String name,  MeasurementType measurementType,  ExerciseMetadata metadata,  int? plannedRestSeconds,  String? libraryExerciseId,  List<WorkoutSet> sets,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)  $default,) {final _that = this;
switch (_that) {
case _Exercise():
return $default(_that.id,_that.exerciseGroupId,_that.position,_that.name,_that.measurementType,_that.metadata,_that.plannedRestSeconds,_that.libraryExerciseId,_that.sets,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String exerciseGroupId,  int position,  String name,  MeasurementType measurementType,  ExerciseMetadata metadata,  int? plannedRestSeconds,  String? libraryExerciseId,  List<WorkoutSet> sets,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)?  $default,) {final _that = this;
switch (_that) {
case _Exercise() when $default != null:
return $default(_that.id,_that.exerciseGroupId,_that.position,_that.name,_that.measurementType,_that.metadata,_that.plannedRestSeconds,_that.libraryExerciseId,_that.sets,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Exercise extends Exercise {
   _Exercise({required this.id, required this.exerciseGroupId, required this.position, required this.name, required this.measurementType, required this.metadata, this.plannedRestSeconds, this.libraryExerciseId, required final  List<WorkoutSet> sets, required this.createdAt, required this.updatedAt, required this.schemaVersion}): _sets = sets,super._();
  factory _Exercise.fromJson(Map<String, dynamic> json) => _$ExerciseFromJson(json);

@override final  String id;
@override final  String exerciseGroupId;
@override final  int position;
@override final  String name;
@override final  MeasurementType measurementType;
@override final  ExerciseMetadata metadata;
@override final  int? plannedRestSeconds;
@override final  String? libraryExerciseId;
 final  List<WorkoutSet> _sets;
@override List<WorkoutSet> get sets {
  if (_sets is EqualUnmodifiableListView) return _sets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sets);
}

@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  int schemaVersion;

/// Create a copy of Exercise
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseCopyWith<_Exercise> get copyWith => __$ExerciseCopyWithImpl<_Exercise>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExerciseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Exercise&&(identical(other.id, id) || other.id == id)&&(identical(other.exerciseGroupId, exerciseGroupId) || other.exerciseGroupId == exerciseGroupId)&&(identical(other.position, position) || other.position == position)&&(identical(other.name, name) || other.name == name)&&(identical(other.measurementType, measurementType) || other.measurementType == measurementType)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.plannedRestSeconds, plannedRestSeconds) || other.plannedRestSeconds == plannedRestSeconds)&&(identical(other.libraryExerciseId, libraryExerciseId) || other.libraryExerciseId == libraryExerciseId)&&const DeepCollectionEquality().equals(other._sets, _sets)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,exerciseGroupId,position,name,measurementType,metadata,plannedRestSeconds,libraryExerciseId,const DeepCollectionEquality().hash(_sets),createdAt,updatedAt,schemaVersion);

@override
String toString() {
  return 'Exercise(id: $id, exerciseGroupId: $exerciseGroupId, position: $position, name: $name, measurementType: $measurementType, metadata: $metadata, plannedRestSeconds: $plannedRestSeconds, libraryExerciseId: $libraryExerciseId, sets: $sets, createdAt: $createdAt, updatedAt: $updatedAt, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class _$ExerciseCopyWith<$Res> implements $ExerciseCopyWith<$Res> {
  factory _$ExerciseCopyWith(_Exercise value, $Res Function(_Exercise) _then) = __$ExerciseCopyWithImpl;
@override @useResult
$Res call({
 String id, String exerciseGroupId, int position, String name, MeasurementType measurementType, ExerciseMetadata metadata, int? plannedRestSeconds, String? libraryExerciseId, List<WorkoutSet> sets, DateTime createdAt, DateTime updatedAt, int schemaVersion
});


@override $MeasurementTypeCopyWith<$Res> get measurementType;@override $ExerciseMetadataCopyWith<$Res> get metadata;

}
/// @nodoc
class __$ExerciseCopyWithImpl<$Res>
    implements _$ExerciseCopyWith<$Res> {
  __$ExerciseCopyWithImpl(this._self, this._then);

  final _Exercise _self;
  final $Res Function(_Exercise) _then;

/// Create a copy of Exercise
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? exerciseGroupId = null,Object? position = null,Object? name = null,Object? measurementType = null,Object? metadata = null,Object? plannedRestSeconds = freezed,Object? libraryExerciseId = freezed,Object? sets = null,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,}) {
  return _then(_Exercise(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,exerciseGroupId: null == exerciseGroupId ? _self.exerciseGroupId : exerciseGroupId // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,measurementType: null == measurementType ? _self.measurementType : measurementType // ignore: cast_nullable_to_non_nullable
as MeasurementType,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as ExerciseMetadata,plannedRestSeconds: freezed == plannedRestSeconds ? _self.plannedRestSeconds : plannedRestSeconds // ignore: cast_nullable_to_non_nullable
as int?,libraryExerciseId: freezed == libraryExerciseId ? _self.libraryExerciseId : libraryExerciseId // ignore: cast_nullable_to_non_nullable
as String?,sets: null == sets ? _self._sets : sets // ignore: cast_nullable_to_non_nullable
as List<WorkoutSet>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of Exercise
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementTypeCopyWith<$Res> get measurementType {
  
  return $MeasurementTypeCopyWith<$Res>(_self.measurementType, (value) {
    return _then(_self.copyWith(measurementType: value));
  });
}/// Create a copy of Exercise
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseMetadataCopyWith<$Res> get metadata {
  
  return $ExerciseMetadataCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}

// dart format on

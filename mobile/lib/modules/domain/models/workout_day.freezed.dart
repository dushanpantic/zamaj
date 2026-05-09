// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_day.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkoutDay {

 String get id; String get programId; String get name; List<ExerciseGroup> get exerciseGroups; DateTime get createdAt; DateTime get updatedAt; int get schemaVersion;
/// Create a copy of WorkoutDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutDayCopyWith<WorkoutDay> get copyWith => _$WorkoutDayCopyWithImpl<WorkoutDay>(this as WorkoutDay, _$identity);

  /// Serializes this WorkoutDay to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutDay&&(identical(other.id, id) || other.id == id)&&(identical(other.programId, programId) || other.programId == programId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.exerciseGroups, exerciseGroups)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,programId,name,const DeepCollectionEquality().hash(exerciseGroups),createdAt,updatedAt,schemaVersion);

@override
String toString() {
  return 'WorkoutDay(id: $id, programId: $programId, name: $name, exerciseGroups: $exerciseGroups, createdAt: $createdAt, updatedAt: $updatedAt, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class $WorkoutDayCopyWith<$Res>  {
  factory $WorkoutDayCopyWith(WorkoutDay value, $Res Function(WorkoutDay) _then) = _$WorkoutDayCopyWithImpl;
@useResult
$Res call({
 String id, String programId, String name, List<ExerciseGroup> exerciseGroups, DateTime createdAt, DateTime updatedAt, int schemaVersion
});




}
/// @nodoc
class _$WorkoutDayCopyWithImpl<$Res>
    implements $WorkoutDayCopyWith<$Res> {
  _$WorkoutDayCopyWithImpl(this._self, this._then);

  final WorkoutDay _self;
  final $Res Function(WorkoutDay) _then;

/// Create a copy of WorkoutDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? programId = null,Object? name = null,Object? exerciseGroups = null,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,exerciseGroups: null == exerciseGroups ? _self.exerciseGroups : exerciseGroups // ignore: cast_nullable_to_non_nullable
as List<ExerciseGroup>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutDay].
extension WorkoutDayPatterns on WorkoutDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutDay value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutDay value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String programId,  String name,  List<ExerciseGroup> exerciseGroups,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutDay() when $default != null:
return $default(_that.id,_that.programId,_that.name,_that.exerciseGroups,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String programId,  String name,  List<ExerciseGroup> exerciseGroups,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)  $default,) {final _that = this;
switch (_that) {
case _WorkoutDay():
return $default(_that.id,_that.programId,_that.name,_that.exerciseGroups,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String programId,  String name,  List<ExerciseGroup> exerciseGroups,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutDay() when $default != null:
return $default(_that.id,_that.programId,_that.name,_that.exerciseGroups,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkoutDay extends WorkoutDay {
  const _WorkoutDay({required this.id, required this.programId, required this.name, required final  List<ExerciseGroup> exerciseGroups, required this.createdAt, required this.updatedAt, required this.schemaVersion}): _exerciseGroups = exerciseGroups,super._();
  factory _WorkoutDay.fromJson(Map<String, dynamic> json) => _$WorkoutDayFromJson(json);

@override final  String id;
@override final  String programId;
@override final  String name;
 final  List<ExerciseGroup> _exerciseGroups;
@override List<ExerciseGroup> get exerciseGroups {
  if (_exerciseGroups is EqualUnmodifiableListView) return _exerciseGroups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exerciseGroups);
}

@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  int schemaVersion;

/// Create a copy of WorkoutDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutDayCopyWith<_WorkoutDay> get copyWith => __$WorkoutDayCopyWithImpl<_WorkoutDay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkoutDayToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutDay&&(identical(other.id, id) || other.id == id)&&(identical(other.programId, programId) || other.programId == programId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._exerciseGroups, _exerciseGroups)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,programId,name,const DeepCollectionEquality().hash(_exerciseGroups),createdAt,updatedAt,schemaVersion);

@override
String toString() {
  return 'WorkoutDay(id: $id, programId: $programId, name: $name, exerciseGroups: $exerciseGroups, createdAt: $createdAt, updatedAt: $updatedAt, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class _$WorkoutDayCopyWith<$Res> implements $WorkoutDayCopyWith<$Res> {
  factory _$WorkoutDayCopyWith(_WorkoutDay value, $Res Function(_WorkoutDay) _then) = __$WorkoutDayCopyWithImpl;
@override @useResult
$Res call({
 String id, String programId, String name, List<ExerciseGroup> exerciseGroups, DateTime createdAt, DateTime updatedAt, int schemaVersion
});




}
/// @nodoc
class __$WorkoutDayCopyWithImpl<$Res>
    implements _$WorkoutDayCopyWith<$Res> {
  __$WorkoutDayCopyWithImpl(this._self, this._then);

  final _WorkoutDay _self;
  final $Res Function(_WorkoutDay) _then;

/// Create a copy of WorkoutDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? programId = null,Object? name = null,Object? exerciseGroups = null,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,}) {
  return _then(_WorkoutDay(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,exerciseGroups: null == exerciseGroups ? _self._exerciseGroups : exerciseGroups // ignore: cast_nullable_to_non_nullable
as List<ExerciseGroup>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExerciseGroup {

 String get id; String get workoutDayId; int get position; ExerciseGroupKind get kind; List<Exercise> get exercises; DateTime get createdAt; DateTime get updatedAt; int get schemaVersion;
/// Create a copy of ExerciseGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseGroupCopyWith<ExerciseGroup> get copyWith => _$ExerciseGroupCopyWithImpl<ExerciseGroup>(this as ExerciseGroup, _$identity);

  /// Serializes this ExerciseGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.workoutDayId, workoutDayId) || other.workoutDayId == workoutDayId)&&(identical(other.position, position) || other.position == position)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.exercises, exercises)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workoutDayId,position,kind,const DeepCollectionEquality().hash(exercises),createdAt,updatedAt,schemaVersion);

@override
String toString() {
  return 'ExerciseGroup(id: $id, workoutDayId: $workoutDayId, position: $position, kind: $kind, exercises: $exercises, createdAt: $createdAt, updatedAt: $updatedAt, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class $ExerciseGroupCopyWith<$Res>  {
  factory $ExerciseGroupCopyWith(ExerciseGroup value, $Res Function(ExerciseGroup) _then) = _$ExerciseGroupCopyWithImpl;
@useResult
$Res call({
 String id, String workoutDayId, int position, ExerciseGroupKind kind, List<Exercise> exercises, DateTime createdAt, DateTime updatedAt, int schemaVersion
});


$ExerciseGroupKindCopyWith<$Res> get kind;

}
/// @nodoc
class _$ExerciseGroupCopyWithImpl<$Res>
    implements $ExerciseGroupCopyWith<$Res> {
  _$ExerciseGroupCopyWithImpl(this._self, this._then);

  final ExerciseGroup _self;
  final $Res Function(ExerciseGroup) _then;

/// Create a copy of ExerciseGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workoutDayId = null,Object? position = null,Object? kind = null,Object? exercises = null,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workoutDayId: null == workoutDayId ? _self.workoutDayId : workoutDayId // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ExerciseGroupKind,exercises: null == exercises ? _self.exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<Exercise>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of ExerciseGroup
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseGroupKindCopyWith<$Res> get kind {
  
  return $ExerciseGroupKindCopyWith<$Res>(_self.kind, (value) {
    return _then(_self.copyWith(kind: value));
  });
}
}


/// Adds pattern-matching-related methods to [ExerciseGroup].
extension ExerciseGroupPatterns on ExerciseGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExerciseGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExerciseGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExerciseGroup value)  $default,){
final _that = this;
switch (_that) {
case _ExerciseGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExerciseGroup value)?  $default,){
final _that = this;
switch (_that) {
case _ExerciseGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workoutDayId,  int position,  ExerciseGroupKind kind,  List<Exercise> exercises,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExerciseGroup() when $default != null:
return $default(_that.id,_that.workoutDayId,_that.position,_that.kind,_that.exercises,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workoutDayId,  int position,  ExerciseGroupKind kind,  List<Exercise> exercises,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)  $default,) {final _that = this;
switch (_that) {
case _ExerciseGroup():
return $default(_that.id,_that.workoutDayId,_that.position,_that.kind,_that.exercises,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workoutDayId,  int position,  ExerciseGroupKind kind,  List<Exercise> exercises,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)?  $default,) {final _that = this;
switch (_that) {
case _ExerciseGroup() when $default != null:
return $default(_that.id,_that.workoutDayId,_that.position,_that.kind,_that.exercises,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExerciseGroup extends ExerciseGroup {
   _ExerciseGroup({required this.id, required this.workoutDayId, required this.position, required this.kind, required final  List<Exercise> exercises, required this.createdAt, required this.updatedAt, required this.schemaVersion}): _exercises = exercises,super._();
  factory _ExerciseGroup.fromJson(Map<String, dynamic> json) => _$ExerciseGroupFromJson(json);

@override final  String id;
@override final  String workoutDayId;
@override final  int position;
@override final  ExerciseGroupKind kind;
 final  List<Exercise> _exercises;
@override List<Exercise> get exercises {
  if (_exercises is EqualUnmodifiableListView) return _exercises;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exercises);
}

@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  int schemaVersion;

/// Create a copy of ExerciseGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseGroupCopyWith<_ExerciseGroup> get copyWith => __$ExerciseGroupCopyWithImpl<_ExerciseGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExerciseGroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExerciseGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.workoutDayId, workoutDayId) || other.workoutDayId == workoutDayId)&&(identical(other.position, position) || other.position == position)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other._exercises, _exercises)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workoutDayId,position,kind,const DeepCollectionEquality().hash(_exercises),createdAt,updatedAt,schemaVersion);

@override
String toString() {
  return 'ExerciseGroup(id: $id, workoutDayId: $workoutDayId, position: $position, kind: $kind, exercises: $exercises, createdAt: $createdAt, updatedAt: $updatedAt, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class _$ExerciseGroupCopyWith<$Res> implements $ExerciseGroupCopyWith<$Res> {
  factory _$ExerciseGroupCopyWith(_ExerciseGroup value, $Res Function(_ExerciseGroup) _then) = __$ExerciseGroupCopyWithImpl;
@override @useResult
$Res call({
 String id, String workoutDayId, int position, ExerciseGroupKind kind, List<Exercise> exercises, DateTime createdAt, DateTime updatedAt, int schemaVersion
});


@override $ExerciseGroupKindCopyWith<$Res> get kind;

}
/// @nodoc
class __$ExerciseGroupCopyWithImpl<$Res>
    implements _$ExerciseGroupCopyWith<$Res> {
  __$ExerciseGroupCopyWithImpl(this._self, this._then);

  final _ExerciseGroup _self;
  final $Res Function(_ExerciseGroup) _then;

/// Create a copy of ExerciseGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workoutDayId = null,Object? position = null,Object? kind = null,Object? exercises = null,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,}) {
  return _then(_ExerciseGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workoutDayId: null == workoutDayId ? _self.workoutDayId : workoutDayId // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ExerciseGroupKind,exercises: null == exercises ? _self._exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<Exercise>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ExerciseGroup
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseGroupKindCopyWith<$Res> get kind {
  
  return $ExerciseGroupKindCopyWith<$Res>(_self.kind, (value) {
    return _then(_self.copyWith(kind: value));
  });
}
}

// dart format on

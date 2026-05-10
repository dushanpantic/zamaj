// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'program_aggregate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProgramAggregate {

 String get id; String get name; DateTime get createdAt; DateTime get updatedAt; int get schemaVersion; List<WorkoutDayAggregate> get workoutDays;
/// Create a copy of ProgramAggregate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgramAggregateCopyWith<ProgramAggregate> get copyWith => _$ProgramAggregateCopyWithImpl<ProgramAggregate>(this as ProgramAggregate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProgramAggregate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&const DeepCollectionEquality().equals(other.workoutDays, workoutDays));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,createdAt,updatedAt,schemaVersion,const DeepCollectionEquality().hash(workoutDays));

@override
String toString() {
  return 'ProgramAggregate(id: $id, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, schemaVersion: $schemaVersion, workoutDays: $workoutDays)';
}


}

/// @nodoc
abstract mixin class $ProgramAggregateCopyWith<$Res>  {
  factory $ProgramAggregateCopyWith(ProgramAggregate value, $Res Function(ProgramAggregate) _then) = _$ProgramAggregateCopyWithImpl;
@useResult
$Res call({
 String id, String name, DateTime createdAt, DateTime updatedAt, int schemaVersion, List<WorkoutDayAggregate> workoutDays
});




}
/// @nodoc
class _$ProgramAggregateCopyWithImpl<$Res>
    implements $ProgramAggregateCopyWith<$Res> {
  _$ProgramAggregateCopyWithImpl(this._self, this._then);

  final ProgramAggregate _self;
  final $Res Function(ProgramAggregate) _then;

/// Create a copy of ProgramAggregate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,Object? workoutDays = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,workoutDays: null == workoutDays ? _self.workoutDays : workoutDays // ignore: cast_nullable_to_non_nullable
as List<WorkoutDayAggregate>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProgramAggregate].
extension ProgramAggregatePatterns on ProgramAggregate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProgramAggregate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProgramAggregate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProgramAggregate value)  $default,){
final _that = this;
switch (_that) {
case _ProgramAggregate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProgramAggregate value)?  $default,){
final _that = this;
switch (_that) {
case _ProgramAggregate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion,  List<WorkoutDayAggregate> workoutDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProgramAggregate() when $default != null:
return $default(_that.id,_that.name,_that.createdAt,_that.updatedAt,_that.schemaVersion,_that.workoutDays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion,  List<WorkoutDayAggregate> workoutDays)  $default,) {final _that = this;
switch (_that) {
case _ProgramAggregate():
return $default(_that.id,_that.name,_that.createdAt,_that.updatedAt,_that.schemaVersion,_that.workoutDays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion,  List<WorkoutDayAggregate> workoutDays)?  $default,) {final _that = this;
switch (_that) {
case _ProgramAggregate() when $default != null:
return $default(_that.id,_that.name,_that.createdAt,_that.updatedAt,_that.schemaVersion,_that.workoutDays);case _:
  return null;

}
}

}

/// @nodoc


class _ProgramAggregate implements ProgramAggregate {
  const _ProgramAggregate({required this.id, required this.name, required this.createdAt, required this.updatedAt, required this.schemaVersion, required final  List<WorkoutDayAggregate> workoutDays}): _workoutDays = workoutDays;
  

@override final  String id;
@override final  String name;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  int schemaVersion;
 final  List<WorkoutDayAggregate> _workoutDays;
@override List<WorkoutDayAggregate> get workoutDays {
  if (_workoutDays is EqualUnmodifiableListView) return _workoutDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_workoutDays);
}


/// Create a copy of ProgramAggregate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgramAggregateCopyWith<_ProgramAggregate> get copyWith => __$ProgramAggregateCopyWithImpl<_ProgramAggregate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProgramAggregate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&const DeepCollectionEquality().equals(other._workoutDays, _workoutDays));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,createdAt,updatedAt,schemaVersion,const DeepCollectionEquality().hash(_workoutDays));

@override
String toString() {
  return 'ProgramAggregate(id: $id, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, schemaVersion: $schemaVersion, workoutDays: $workoutDays)';
}


}

/// @nodoc
abstract mixin class _$ProgramAggregateCopyWith<$Res> implements $ProgramAggregateCopyWith<$Res> {
  factory _$ProgramAggregateCopyWith(_ProgramAggregate value, $Res Function(_ProgramAggregate) _then) = __$ProgramAggregateCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, DateTime createdAt, DateTime updatedAt, int schemaVersion, List<WorkoutDayAggregate> workoutDays
});




}
/// @nodoc
class __$ProgramAggregateCopyWithImpl<$Res>
    implements _$ProgramAggregateCopyWith<$Res> {
  __$ProgramAggregateCopyWithImpl(this._self, this._then);

  final _ProgramAggregate _self;
  final $Res Function(_ProgramAggregate) _then;

/// Create a copy of ProgramAggregate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,Object? workoutDays = null,}) {
  return _then(_ProgramAggregate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,workoutDays: null == workoutDays ? _self._workoutDays : workoutDays // ignore: cast_nullable_to_non_nullable
as List<WorkoutDayAggregate>,
  ));
}


}

/// @nodoc
mixin _$WorkoutDayAggregate {

 String get id; String get programId; String get name; int get position; List<ExerciseGroupAggregate> get groups;
/// Create a copy of WorkoutDayAggregate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutDayAggregateCopyWith<WorkoutDayAggregate> get copyWith => _$WorkoutDayAggregateCopyWithImpl<WorkoutDayAggregate>(this as WorkoutDayAggregate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutDayAggregate&&(identical(other.id, id) || other.id == id)&&(identical(other.programId, programId) || other.programId == programId)&&(identical(other.name, name) || other.name == name)&&(identical(other.position, position) || other.position == position)&&const DeepCollectionEquality().equals(other.groups, groups));
}


@override
int get hashCode => Object.hash(runtimeType,id,programId,name,position,const DeepCollectionEquality().hash(groups));

@override
String toString() {
  return 'WorkoutDayAggregate(id: $id, programId: $programId, name: $name, position: $position, groups: $groups)';
}


}

/// @nodoc
abstract mixin class $WorkoutDayAggregateCopyWith<$Res>  {
  factory $WorkoutDayAggregateCopyWith(WorkoutDayAggregate value, $Res Function(WorkoutDayAggregate) _then) = _$WorkoutDayAggregateCopyWithImpl;
@useResult
$Res call({
 String id, String programId, String name, int position, List<ExerciseGroupAggregate> groups
});




}
/// @nodoc
class _$WorkoutDayAggregateCopyWithImpl<$Res>
    implements $WorkoutDayAggregateCopyWith<$Res> {
  _$WorkoutDayAggregateCopyWithImpl(this._self, this._then);

  final WorkoutDayAggregate _self;
  final $Res Function(WorkoutDayAggregate) _then;

/// Create a copy of WorkoutDayAggregate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? programId = null,Object? name = null,Object? position = null,Object? groups = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,groups: null == groups ? _self.groups : groups // ignore: cast_nullable_to_non_nullable
as List<ExerciseGroupAggregate>,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutDayAggregate].
extension WorkoutDayAggregatePatterns on WorkoutDayAggregate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutDayAggregate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutDayAggregate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutDayAggregate value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutDayAggregate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutDayAggregate value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutDayAggregate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String programId,  String name,  int position,  List<ExerciseGroupAggregate> groups)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutDayAggregate() when $default != null:
return $default(_that.id,_that.programId,_that.name,_that.position,_that.groups);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String programId,  String name,  int position,  List<ExerciseGroupAggregate> groups)  $default,) {final _that = this;
switch (_that) {
case _WorkoutDayAggregate():
return $default(_that.id,_that.programId,_that.name,_that.position,_that.groups);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String programId,  String name,  int position,  List<ExerciseGroupAggregate> groups)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutDayAggregate() when $default != null:
return $default(_that.id,_that.programId,_that.name,_that.position,_that.groups);case _:
  return null;

}
}

}

/// @nodoc


class _WorkoutDayAggregate implements WorkoutDayAggregate {
  const _WorkoutDayAggregate({required this.id, required this.programId, required this.name, required this.position, required final  List<ExerciseGroupAggregate> groups}): _groups = groups;
  

@override final  String id;
@override final  String programId;
@override final  String name;
@override final  int position;
 final  List<ExerciseGroupAggregate> _groups;
@override List<ExerciseGroupAggregate> get groups {
  if (_groups is EqualUnmodifiableListView) return _groups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_groups);
}


/// Create a copy of WorkoutDayAggregate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutDayAggregateCopyWith<_WorkoutDayAggregate> get copyWith => __$WorkoutDayAggregateCopyWithImpl<_WorkoutDayAggregate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutDayAggregate&&(identical(other.id, id) || other.id == id)&&(identical(other.programId, programId) || other.programId == programId)&&(identical(other.name, name) || other.name == name)&&(identical(other.position, position) || other.position == position)&&const DeepCollectionEquality().equals(other._groups, _groups));
}


@override
int get hashCode => Object.hash(runtimeType,id,programId,name,position,const DeepCollectionEquality().hash(_groups));

@override
String toString() {
  return 'WorkoutDayAggregate(id: $id, programId: $programId, name: $name, position: $position, groups: $groups)';
}


}

/// @nodoc
abstract mixin class _$WorkoutDayAggregateCopyWith<$Res> implements $WorkoutDayAggregateCopyWith<$Res> {
  factory _$WorkoutDayAggregateCopyWith(_WorkoutDayAggregate value, $Res Function(_WorkoutDayAggregate) _then) = __$WorkoutDayAggregateCopyWithImpl;
@override @useResult
$Res call({
 String id, String programId, String name, int position, List<ExerciseGroupAggregate> groups
});




}
/// @nodoc
class __$WorkoutDayAggregateCopyWithImpl<$Res>
    implements _$WorkoutDayAggregateCopyWith<$Res> {
  __$WorkoutDayAggregateCopyWithImpl(this._self, this._then);

  final _WorkoutDayAggregate _self;
  final $Res Function(_WorkoutDayAggregate) _then;

/// Create a copy of WorkoutDayAggregate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? programId = null,Object? name = null,Object? position = null,Object? groups = null,}) {
  return _then(_WorkoutDayAggregate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,groups: null == groups ? _self._groups : groups // ignore: cast_nullable_to_non_nullable
as List<ExerciseGroupAggregate>,
  ));
}


}

/// @nodoc
mixin _$ExerciseGroupAggregate {

 String get id; String get workoutDayId; ExerciseGroupKind get kind; int get position; List<ExerciseAggregate> get exercises;
/// Create a copy of ExerciseGroupAggregate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseGroupAggregateCopyWith<ExerciseGroupAggregate> get copyWith => _$ExerciseGroupAggregateCopyWithImpl<ExerciseGroupAggregate>(this as ExerciseGroupAggregate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseGroupAggregate&&(identical(other.id, id) || other.id == id)&&(identical(other.workoutDayId, workoutDayId) || other.workoutDayId == workoutDayId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.position, position) || other.position == position)&&const DeepCollectionEquality().equals(other.exercises, exercises));
}


@override
int get hashCode => Object.hash(runtimeType,id,workoutDayId,kind,position,const DeepCollectionEquality().hash(exercises));

@override
String toString() {
  return 'ExerciseGroupAggregate(id: $id, workoutDayId: $workoutDayId, kind: $kind, position: $position, exercises: $exercises)';
}


}

/// @nodoc
abstract mixin class $ExerciseGroupAggregateCopyWith<$Res>  {
  factory $ExerciseGroupAggregateCopyWith(ExerciseGroupAggregate value, $Res Function(ExerciseGroupAggregate) _then) = _$ExerciseGroupAggregateCopyWithImpl;
@useResult
$Res call({
 String id, String workoutDayId, ExerciseGroupKind kind, int position, List<ExerciseAggregate> exercises
});


$ExerciseGroupKindCopyWith<$Res> get kind;

}
/// @nodoc
class _$ExerciseGroupAggregateCopyWithImpl<$Res>
    implements $ExerciseGroupAggregateCopyWith<$Res> {
  _$ExerciseGroupAggregateCopyWithImpl(this._self, this._then);

  final ExerciseGroupAggregate _self;
  final $Res Function(ExerciseGroupAggregate) _then;

/// Create a copy of ExerciseGroupAggregate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workoutDayId = null,Object? kind = null,Object? position = null,Object? exercises = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workoutDayId: null == workoutDayId ? _self.workoutDayId : workoutDayId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ExerciseGroupKind,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,exercises: null == exercises ? _self.exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<ExerciseAggregate>,
  ));
}
/// Create a copy of ExerciseGroupAggregate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseGroupKindCopyWith<$Res> get kind {
  
  return $ExerciseGroupKindCopyWith<$Res>(_self.kind, (value) {
    return _then(_self.copyWith(kind: value));
  });
}
}


/// Adds pattern-matching-related methods to [ExerciseGroupAggregate].
extension ExerciseGroupAggregatePatterns on ExerciseGroupAggregate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExerciseGroupAggregate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExerciseGroupAggregate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExerciseGroupAggregate value)  $default,){
final _that = this;
switch (_that) {
case _ExerciseGroupAggregate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExerciseGroupAggregate value)?  $default,){
final _that = this;
switch (_that) {
case _ExerciseGroupAggregate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workoutDayId,  ExerciseGroupKind kind,  int position,  List<ExerciseAggregate> exercises)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExerciseGroupAggregate() when $default != null:
return $default(_that.id,_that.workoutDayId,_that.kind,_that.position,_that.exercises);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workoutDayId,  ExerciseGroupKind kind,  int position,  List<ExerciseAggregate> exercises)  $default,) {final _that = this;
switch (_that) {
case _ExerciseGroupAggregate():
return $default(_that.id,_that.workoutDayId,_that.kind,_that.position,_that.exercises);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workoutDayId,  ExerciseGroupKind kind,  int position,  List<ExerciseAggregate> exercises)?  $default,) {final _that = this;
switch (_that) {
case _ExerciseGroupAggregate() when $default != null:
return $default(_that.id,_that.workoutDayId,_that.kind,_that.position,_that.exercises);case _:
  return null;

}
}

}

/// @nodoc


class _ExerciseGroupAggregate implements ExerciseGroupAggregate {
  const _ExerciseGroupAggregate({required this.id, required this.workoutDayId, required this.kind, required this.position, required final  List<ExerciseAggregate> exercises}): _exercises = exercises;
  

@override final  String id;
@override final  String workoutDayId;
@override final  ExerciseGroupKind kind;
@override final  int position;
 final  List<ExerciseAggregate> _exercises;
@override List<ExerciseAggregate> get exercises {
  if (_exercises is EqualUnmodifiableListView) return _exercises;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exercises);
}


/// Create a copy of ExerciseGroupAggregate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseGroupAggregateCopyWith<_ExerciseGroupAggregate> get copyWith => __$ExerciseGroupAggregateCopyWithImpl<_ExerciseGroupAggregate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExerciseGroupAggregate&&(identical(other.id, id) || other.id == id)&&(identical(other.workoutDayId, workoutDayId) || other.workoutDayId == workoutDayId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.position, position) || other.position == position)&&const DeepCollectionEquality().equals(other._exercises, _exercises));
}


@override
int get hashCode => Object.hash(runtimeType,id,workoutDayId,kind,position,const DeepCollectionEquality().hash(_exercises));

@override
String toString() {
  return 'ExerciseGroupAggregate(id: $id, workoutDayId: $workoutDayId, kind: $kind, position: $position, exercises: $exercises)';
}


}

/// @nodoc
abstract mixin class _$ExerciseGroupAggregateCopyWith<$Res> implements $ExerciseGroupAggregateCopyWith<$Res> {
  factory _$ExerciseGroupAggregateCopyWith(_ExerciseGroupAggregate value, $Res Function(_ExerciseGroupAggregate) _then) = __$ExerciseGroupAggregateCopyWithImpl;
@override @useResult
$Res call({
 String id, String workoutDayId, ExerciseGroupKind kind, int position, List<ExerciseAggregate> exercises
});


@override $ExerciseGroupKindCopyWith<$Res> get kind;

}
/// @nodoc
class __$ExerciseGroupAggregateCopyWithImpl<$Res>
    implements _$ExerciseGroupAggregateCopyWith<$Res> {
  __$ExerciseGroupAggregateCopyWithImpl(this._self, this._then);

  final _ExerciseGroupAggregate _self;
  final $Res Function(_ExerciseGroupAggregate) _then;

/// Create a copy of ExerciseGroupAggregate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workoutDayId = null,Object? kind = null,Object? position = null,Object? exercises = null,}) {
  return _then(_ExerciseGroupAggregate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workoutDayId: null == workoutDayId ? _self.workoutDayId : workoutDayId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ExerciseGroupKind,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,exercises: null == exercises ? _self._exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<ExerciseAggregate>,
  ));
}

/// Create a copy of ExerciseGroupAggregate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseGroupKindCopyWith<$Res> get kind {
  
  return $ExerciseGroupKindCopyWith<$Res>(_self.kind, (value) {
    return _then(_self.copyWith(kind: value));
  });
}
}

/// @nodoc
mixin _$ExerciseAggregate {

 String get id; String get groupId; String get name; MeasurementType get measurementType; ExerciseMetadata get metadata; int? get plannedRestSeconds; int get position; List<WorkoutSetAggregate> get sets;
/// Create a copy of ExerciseAggregate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseAggregateCopyWith<ExerciseAggregate> get copyWith => _$ExerciseAggregateCopyWithImpl<ExerciseAggregate>(this as ExerciseAggregate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseAggregate&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.name, name) || other.name == name)&&(identical(other.measurementType, measurementType) || other.measurementType == measurementType)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.plannedRestSeconds, plannedRestSeconds) || other.plannedRestSeconds == plannedRestSeconds)&&(identical(other.position, position) || other.position == position)&&const DeepCollectionEquality().equals(other.sets, sets));
}


@override
int get hashCode => Object.hash(runtimeType,id,groupId,name,measurementType,metadata,plannedRestSeconds,position,const DeepCollectionEquality().hash(sets));

@override
String toString() {
  return 'ExerciseAggregate(id: $id, groupId: $groupId, name: $name, measurementType: $measurementType, metadata: $metadata, plannedRestSeconds: $plannedRestSeconds, position: $position, sets: $sets)';
}


}

/// @nodoc
abstract mixin class $ExerciseAggregateCopyWith<$Res>  {
  factory $ExerciseAggregateCopyWith(ExerciseAggregate value, $Res Function(ExerciseAggregate) _then) = _$ExerciseAggregateCopyWithImpl;
@useResult
$Res call({
 String id, String groupId, String name, MeasurementType measurementType, ExerciseMetadata metadata, int? plannedRestSeconds, int position, List<WorkoutSetAggregate> sets
});


$MeasurementTypeCopyWith<$Res> get measurementType;$ExerciseMetadataCopyWith<$Res> get metadata;

}
/// @nodoc
class _$ExerciseAggregateCopyWithImpl<$Res>
    implements $ExerciseAggregateCopyWith<$Res> {
  _$ExerciseAggregateCopyWithImpl(this._self, this._then);

  final ExerciseAggregate _self;
  final $Res Function(ExerciseAggregate) _then;

/// Create a copy of ExerciseAggregate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? name = null,Object? measurementType = null,Object? metadata = null,Object? plannedRestSeconds = freezed,Object? position = null,Object? sets = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,measurementType: null == measurementType ? _self.measurementType : measurementType // ignore: cast_nullable_to_non_nullable
as MeasurementType,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as ExerciseMetadata,plannedRestSeconds: freezed == plannedRestSeconds ? _self.plannedRestSeconds : plannedRestSeconds // ignore: cast_nullable_to_non_nullable
as int?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as List<WorkoutSetAggregate>,
  ));
}
/// Create a copy of ExerciseAggregate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementTypeCopyWith<$Res> get measurementType {
  
  return $MeasurementTypeCopyWith<$Res>(_self.measurementType, (value) {
    return _then(_self.copyWith(measurementType: value));
  });
}/// Create a copy of ExerciseAggregate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseMetadataCopyWith<$Res> get metadata {
  
  return $ExerciseMetadataCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [ExerciseAggregate].
extension ExerciseAggregatePatterns on ExerciseAggregate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExerciseAggregate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExerciseAggregate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExerciseAggregate value)  $default,){
final _that = this;
switch (_that) {
case _ExerciseAggregate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExerciseAggregate value)?  $default,){
final _that = this;
switch (_that) {
case _ExerciseAggregate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String groupId,  String name,  MeasurementType measurementType,  ExerciseMetadata metadata,  int? plannedRestSeconds,  int position,  List<WorkoutSetAggregate> sets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExerciseAggregate() when $default != null:
return $default(_that.id,_that.groupId,_that.name,_that.measurementType,_that.metadata,_that.plannedRestSeconds,_that.position,_that.sets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String groupId,  String name,  MeasurementType measurementType,  ExerciseMetadata metadata,  int? plannedRestSeconds,  int position,  List<WorkoutSetAggregate> sets)  $default,) {final _that = this;
switch (_that) {
case _ExerciseAggregate():
return $default(_that.id,_that.groupId,_that.name,_that.measurementType,_that.metadata,_that.plannedRestSeconds,_that.position,_that.sets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String groupId,  String name,  MeasurementType measurementType,  ExerciseMetadata metadata,  int? plannedRestSeconds,  int position,  List<WorkoutSetAggregate> sets)?  $default,) {final _that = this;
switch (_that) {
case _ExerciseAggregate() when $default != null:
return $default(_that.id,_that.groupId,_that.name,_that.measurementType,_that.metadata,_that.plannedRestSeconds,_that.position,_that.sets);case _:
  return null;

}
}

}

/// @nodoc


class _ExerciseAggregate implements ExerciseAggregate {
  const _ExerciseAggregate({required this.id, required this.groupId, required this.name, required this.measurementType, required this.metadata, required this.plannedRestSeconds, required this.position, required final  List<WorkoutSetAggregate> sets}): _sets = sets;
  

@override final  String id;
@override final  String groupId;
@override final  String name;
@override final  MeasurementType measurementType;
@override final  ExerciseMetadata metadata;
@override final  int? plannedRestSeconds;
@override final  int position;
 final  List<WorkoutSetAggregate> _sets;
@override List<WorkoutSetAggregate> get sets {
  if (_sets is EqualUnmodifiableListView) return _sets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sets);
}


/// Create a copy of ExerciseAggregate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseAggregateCopyWith<_ExerciseAggregate> get copyWith => __$ExerciseAggregateCopyWithImpl<_ExerciseAggregate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExerciseAggregate&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.name, name) || other.name == name)&&(identical(other.measurementType, measurementType) || other.measurementType == measurementType)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.plannedRestSeconds, plannedRestSeconds) || other.plannedRestSeconds == plannedRestSeconds)&&(identical(other.position, position) || other.position == position)&&const DeepCollectionEquality().equals(other._sets, _sets));
}


@override
int get hashCode => Object.hash(runtimeType,id,groupId,name,measurementType,metadata,plannedRestSeconds,position,const DeepCollectionEquality().hash(_sets));

@override
String toString() {
  return 'ExerciseAggregate(id: $id, groupId: $groupId, name: $name, measurementType: $measurementType, metadata: $metadata, plannedRestSeconds: $plannedRestSeconds, position: $position, sets: $sets)';
}


}

/// @nodoc
abstract mixin class _$ExerciseAggregateCopyWith<$Res> implements $ExerciseAggregateCopyWith<$Res> {
  factory _$ExerciseAggregateCopyWith(_ExerciseAggregate value, $Res Function(_ExerciseAggregate) _then) = __$ExerciseAggregateCopyWithImpl;
@override @useResult
$Res call({
 String id, String groupId, String name, MeasurementType measurementType, ExerciseMetadata metadata, int? plannedRestSeconds, int position, List<WorkoutSetAggregate> sets
});


@override $MeasurementTypeCopyWith<$Res> get measurementType;@override $ExerciseMetadataCopyWith<$Res> get metadata;

}
/// @nodoc
class __$ExerciseAggregateCopyWithImpl<$Res>
    implements _$ExerciseAggregateCopyWith<$Res> {
  __$ExerciseAggregateCopyWithImpl(this._self, this._then);

  final _ExerciseAggregate _self;
  final $Res Function(_ExerciseAggregate) _then;

/// Create a copy of ExerciseAggregate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? name = null,Object? measurementType = null,Object? metadata = null,Object? plannedRestSeconds = freezed,Object? position = null,Object? sets = null,}) {
  return _then(_ExerciseAggregate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,measurementType: null == measurementType ? _self.measurementType : measurementType // ignore: cast_nullable_to_non_nullable
as MeasurementType,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as ExerciseMetadata,plannedRestSeconds: freezed == plannedRestSeconds ? _self.plannedRestSeconds : plannedRestSeconds // ignore: cast_nullable_to_non_nullable
as int?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,sets: null == sets ? _self._sets : sets // ignore: cast_nullable_to_non_nullable
as List<WorkoutSetAggregate>,
  ));
}

/// Create a copy of ExerciseAggregate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementTypeCopyWith<$Res> get measurementType {
  
  return $MeasurementTypeCopyWith<$Res>(_self.measurementType, (value) {
    return _then(_self.copyWith(measurementType: value));
  });
}/// Create a copy of ExerciseAggregate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseMetadataCopyWith<$Res> get metadata {
  
  return $ExerciseMetadataCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}

/// @nodoc
mixin _$WorkoutSetAggregate {

 String get id; String get exerciseId; PlannedSetValues get values; int get position;
/// Create a copy of WorkoutSetAggregate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutSetAggregateCopyWith<WorkoutSetAggregate> get copyWith => _$WorkoutSetAggregateCopyWithImpl<WorkoutSetAggregate>(this as WorkoutSetAggregate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutSetAggregate&&(identical(other.id, id) || other.id == id)&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.values, values) || other.values == values)&&(identical(other.position, position) || other.position == position));
}


@override
int get hashCode => Object.hash(runtimeType,id,exerciseId,values,position);

@override
String toString() {
  return 'WorkoutSetAggregate(id: $id, exerciseId: $exerciseId, values: $values, position: $position)';
}


}

/// @nodoc
abstract mixin class $WorkoutSetAggregateCopyWith<$Res>  {
  factory $WorkoutSetAggregateCopyWith(WorkoutSetAggregate value, $Res Function(WorkoutSetAggregate) _then) = _$WorkoutSetAggregateCopyWithImpl;
@useResult
$Res call({
 String id, String exerciseId, PlannedSetValues values, int position
});


$PlannedSetValuesCopyWith<$Res> get values;

}
/// @nodoc
class _$WorkoutSetAggregateCopyWithImpl<$Res>
    implements $WorkoutSetAggregateCopyWith<$Res> {
  _$WorkoutSetAggregateCopyWithImpl(this._self, this._then);

  final WorkoutSetAggregate _self;
  final $Res Function(WorkoutSetAggregate) _then;

/// Create a copy of WorkoutSetAggregate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? exerciseId = null,Object? values = null,Object? position = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,values: null == values ? _self.values : values // ignore: cast_nullable_to_non_nullable
as PlannedSetValues,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of WorkoutSetAggregate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlannedSetValuesCopyWith<$Res> get values {
  
  return $PlannedSetValuesCopyWith<$Res>(_self.values, (value) {
    return _then(_self.copyWith(values: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorkoutSetAggregate].
extension WorkoutSetAggregatePatterns on WorkoutSetAggregate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutSetAggregate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutSetAggregate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutSetAggregate value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutSetAggregate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutSetAggregate value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutSetAggregate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String exerciseId,  PlannedSetValues values,  int position)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutSetAggregate() when $default != null:
return $default(_that.id,_that.exerciseId,_that.values,_that.position);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String exerciseId,  PlannedSetValues values,  int position)  $default,) {final _that = this;
switch (_that) {
case _WorkoutSetAggregate():
return $default(_that.id,_that.exerciseId,_that.values,_that.position);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String exerciseId,  PlannedSetValues values,  int position)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutSetAggregate() when $default != null:
return $default(_that.id,_that.exerciseId,_that.values,_that.position);case _:
  return null;

}
}

}

/// @nodoc


class _WorkoutSetAggregate implements WorkoutSetAggregate {
  const _WorkoutSetAggregate({required this.id, required this.exerciseId, required this.values, required this.position});
  

@override final  String id;
@override final  String exerciseId;
@override final  PlannedSetValues values;
@override final  int position;

/// Create a copy of WorkoutSetAggregate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutSetAggregateCopyWith<_WorkoutSetAggregate> get copyWith => __$WorkoutSetAggregateCopyWithImpl<_WorkoutSetAggregate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutSetAggregate&&(identical(other.id, id) || other.id == id)&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.values, values) || other.values == values)&&(identical(other.position, position) || other.position == position));
}


@override
int get hashCode => Object.hash(runtimeType,id,exerciseId,values,position);

@override
String toString() {
  return 'WorkoutSetAggregate(id: $id, exerciseId: $exerciseId, values: $values, position: $position)';
}


}

/// @nodoc
abstract mixin class _$WorkoutSetAggregateCopyWith<$Res> implements $WorkoutSetAggregateCopyWith<$Res> {
  factory _$WorkoutSetAggregateCopyWith(_WorkoutSetAggregate value, $Res Function(_WorkoutSetAggregate) _then) = __$WorkoutSetAggregateCopyWithImpl;
@override @useResult
$Res call({
 String id, String exerciseId, PlannedSetValues values, int position
});


@override $PlannedSetValuesCopyWith<$Res> get values;

}
/// @nodoc
class __$WorkoutSetAggregateCopyWithImpl<$Res>
    implements _$WorkoutSetAggregateCopyWith<$Res> {
  __$WorkoutSetAggregateCopyWithImpl(this._self, this._then);

  final _WorkoutSetAggregate _self;
  final $Res Function(_WorkoutSetAggregate) _then;

/// Create a copy of WorkoutSetAggregate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? exerciseId = null,Object? values = null,Object? position = null,}) {
  return _then(_WorkoutSetAggregate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,values: null == values ? _self.values : values // ignore: cast_nullable_to_non_nullable
as PlannedSetValues,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of WorkoutSetAggregate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlannedSetValuesCopyWith<$Res> get values {
  
  return $PlannedSetValuesCopyWith<$Res>(_self.values, (value) {
    return _then(_self.copyWith(values: value));
  });
}
}

// dart format on

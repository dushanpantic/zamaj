// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'program_editor_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProgramDraft {

 String? get programId; String get name; List<WorkoutDayDraft> get workoutDays; int? get schemaVersion;
/// Create a copy of ProgramDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgramDraftCopyWith<ProgramDraft> get copyWith => _$ProgramDraftCopyWithImpl<ProgramDraft>(this as ProgramDraft, _$identity);

  /// Serializes this ProgramDraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProgramDraft&&(identical(other.programId, programId) || other.programId == programId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.workoutDays, workoutDays)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,programId,name,const DeepCollectionEquality().hash(workoutDays),schemaVersion);

@override
String toString() {
  return 'ProgramDraft(programId: $programId, name: $name, workoutDays: $workoutDays, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class $ProgramDraftCopyWith<$Res>  {
  factory $ProgramDraftCopyWith(ProgramDraft value, $Res Function(ProgramDraft) _then) = _$ProgramDraftCopyWithImpl;
@useResult
$Res call({
 String? programId, String name, List<WorkoutDayDraft> workoutDays, int? schemaVersion
});




}
/// @nodoc
class _$ProgramDraftCopyWithImpl<$Res>
    implements $ProgramDraftCopyWith<$Res> {
  _$ProgramDraftCopyWithImpl(this._self, this._then);

  final ProgramDraft _self;
  final $Res Function(ProgramDraft) _then;

/// Create a copy of ProgramDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? programId = freezed,Object? name = null,Object? workoutDays = null,Object? schemaVersion = freezed,}) {
  return _then(_self.copyWith(
programId: freezed == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,workoutDays: null == workoutDays ? _self.workoutDays : workoutDays // ignore: cast_nullable_to_non_nullable
as List<WorkoutDayDraft>,schemaVersion: freezed == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProgramDraft].
extension ProgramDraftPatterns on ProgramDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProgramDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProgramDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProgramDraft value)  $default,){
final _that = this;
switch (_that) {
case _ProgramDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProgramDraft value)?  $default,){
final _that = this;
switch (_that) {
case _ProgramDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? programId,  String name,  List<WorkoutDayDraft> workoutDays,  int? schemaVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProgramDraft() when $default != null:
return $default(_that.programId,_that.name,_that.workoutDays,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? programId,  String name,  List<WorkoutDayDraft> workoutDays,  int? schemaVersion)  $default,) {final _that = this;
switch (_that) {
case _ProgramDraft():
return $default(_that.programId,_that.name,_that.workoutDays,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? programId,  String name,  List<WorkoutDayDraft> workoutDays,  int? schemaVersion)?  $default,) {final _that = this;
switch (_that) {
case _ProgramDraft() when $default != null:
return $default(_that.programId,_that.name,_that.workoutDays,_that.schemaVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProgramDraft extends ProgramDraft {
  const _ProgramDraft({required this.programId, required this.name, required final  List<WorkoutDayDraft> workoutDays, required this.schemaVersion}): _workoutDays = workoutDays,super._();
  factory _ProgramDraft.fromJson(Map<String, dynamic> json) => _$ProgramDraftFromJson(json);

@override final  String? programId;
@override final  String name;
 final  List<WorkoutDayDraft> _workoutDays;
@override List<WorkoutDayDraft> get workoutDays {
  if (_workoutDays is EqualUnmodifiableListView) return _workoutDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_workoutDays);
}

@override final  int? schemaVersion;

/// Create a copy of ProgramDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgramDraftCopyWith<_ProgramDraft> get copyWith => __$ProgramDraftCopyWithImpl<_ProgramDraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProgramDraftToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProgramDraft&&(identical(other.programId, programId) || other.programId == programId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._workoutDays, _workoutDays)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,programId,name,const DeepCollectionEquality().hash(_workoutDays),schemaVersion);

@override
String toString() {
  return 'ProgramDraft(programId: $programId, name: $name, workoutDays: $workoutDays, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class _$ProgramDraftCopyWith<$Res> implements $ProgramDraftCopyWith<$Res> {
  factory _$ProgramDraftCopyWith(_ProgramDraft value, $Res Function(_ProgramDraft) _then) = __$ProgramDraftCopyWithImpl;
@override @useResult
$Res call({
 String? programId, String name, List<WorkoutDayDraft> workoutDays, int? schemaVersion
});




}
/// @nodoc
class __$ProgramDraftCopyWithImpl<$Res>
    implements _$ProgramDraftCopyWith<$Res> {
  __$ProgramDraftCopyWithImpl(this._self, this._then);

  final _ProgramDraft _self;
  final $Res Function(_ProgramDraft) _then;

/// Create a copy of ProgramDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? programId = freezed,Object? name = null,Object? workoutDays = null,Object? schemaVersion = freezed,}) {
  return _then(_ProgramDraft(
programId: freezed == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,workoutDays: null == workoutDays ? _self._workoutDays : workoutDays // ignore: cast_nullable_to_non_nullable
as List<WorkoutDayDraft>,schemaVersion: freezed == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$WorkoutDayDraft {

 String get draftId; String? get persistedId; String get name; List<ExerciseGroupDraft> get groups;
/// Create a copy of WorkoutDayDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutDayDraftCopyWith<WorkoutDayDraft> get copyWith => _$WorkoutDayDraftCopyWithImpl<WorkoutDayDraft>(this as WorkoutDayDraft, _$identity);

  /// Serializes this WorkoutDayDraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutDayDraft&&(identical(other.draftId, draftId) || other.draftId == draftId)&&(identical(other.persistedId, persistedId) || other.persistedId == persistedId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.groups, groups));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,draftId,persistedId,name,const DeepCollectionEquality().hash(groups));

@override
String toString() {
  return 'WorkoutDayDraft(draftId: $draftId, persistedId: $persistedId, name: $name, groups: $groups)';
}


}

/// @nodoc
abstract mixin class $WorkoutDayDraftCopyWith<$Res>  {
  factory $WorkoutDayDraftCopyWith(WorkoutDayDraft value, $Res Function(WorkoutDayDraft) _then) = _$WorkoutDayDraftCopyWithImpl;
@useResult
$Res call({
 String draftId, String? persistedId, String name, List<ExerciseGroupDraft> groups
});




}
/// @nodoc
class _$WorkoutDayDraftCopyWithImpl<$Res>
    implements $WorkoutDayDraftCopyWith<$Res> {
  _$WorkoutDayDraftCopyWithImpl(this._self, this._then);

  final WorkoutDayDraft _self;
  final $Res Function(WorkoutDayDraft) _then;

/// Create a copy of WorkoutDayDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? draftId = null,Object? persistedId = freezed,Object? name = null,Object? groups = null,}) {
  return _then(_self.copyWith(
draftId: null == draftId ? _self.draftId : draftId // ignore: cast_nullable_to_non_nullable
as String,persistedId: freezed == persistedId ? _self.persistedId : persistedId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,groups: null == groups ? _self.groups : groups // ignore: cast_nullable_to_non_nullable
as List<ExerciseGroupDraft>,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutDayDraft].
extension WorkoutDayDraftPatterns on WorkoutDayDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutDayDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutDayDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutDayDraft value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutDayDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutDayDraft value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutDayDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String draftId,  String? persistedId,  String name,  List<ExerciseGroupDraft> groups)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutDayDraft() when $default != null:
return $default(_that.draftId,_that.persistedId,_that.name,_that.groups);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String draftId,  String? persistedId,  String name,  List<ExerciseGroupDraft> groups)  $default,) {final _that = this;
switch (_that) {
case _WorkoutDayDraft():
return $default(_that.draftId,_that.persistedId,_that.name,_that.groups);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String draftId,  String? persistedId,  String name,  List<ExerciseGroupDraft> groups)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutDayDraft() when $default != null:
return $default(_that.draftId,_that.persistedId,_that.name,_that.groups);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkoutDayDraft implements WorkoutDayDraft {
  const _WorkoutDayDraft({required this.draftId, required this.persistedId, required this.name, required final  List<ExerciseGroupDraft> groups}): _groups = groups;
  factory _WorkoutDayDraft.fromJson(Map<String, dynamic> json) => _$WorkoutDayDraftFromJson(json);

@override final  String draftId;
@override final  String? persistedId;
@override final  String name;
 final  List<ExerciseGroupDraft> _groups;
@override List<ExerciseGroupDraft> get groups {
  if (_groups is EqualUnmodifiableListView) return _groups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_groups);
}


/// Create a copy of WorkoutDayDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutDayDraftCopyWith<_WorkoutDayDraft> get copyWith => __$WorkoutDayDraftCopyWithImpl<_WorkoutDayDraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkoutDayDraftToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutDayDraft&&(identical(other.draftId, draftId) || other.draftId == draftId)&&(identical(other.persistedId, persistedId) || other.persistedId == persistedId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._groups, _groups));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,draftId,persistedId,name,const DeepCollectionEquality().hash(_groups));

@override
String toString() {
  return 'WorkoutDayDraft(draftId: $draftId, persistedId: $persistedId, name: $name, groups: $groups)';
}


}

/// @nodoc
abstract mixin class _$WorkoutDayDraftCopyWith<$Res> implements $WorkoutDayDraftCopyWith<$Res> {
  factory _$WorkoutDayDraftCopyWith(_WorkoutDayDraft value, $Res Function(_WorkoutDayDraft) _then) = __$WorkoutDayDraftCopyWithImpl;
@override @useResult
$Res call({
 String draftId, String? persistedId, String name, List<ExerciseGroupDraft> groups
});




}
/// @nodoc
class __$WorkoutDayDraftCopyWithImpl<$Res>
    implements _$WorkoutDayDraftCopyWith<$Res> {
  __$WorkoutDayDraftCopyWithImpl(this._self, this._then);

  final _WorkoutDayDraft _self;
  final $Res Function(_WorkoutDayDraft) _then;

/// Create a copy of WorkoutDayDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draftId = null,Object? persistedId = freezed,Object? name = null,Object? groups = null,}) {
  return _then(_WorkoutDayDraft(
draftId: null == draftId ? _self.draftId : draftId // ignore: cast_nullable_to_non_nullable
as String,persistedId: freezed == persistedId ? _self.persistedId : persistedId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,groups: null == groups ? _self._groups : groups // ignore: cast_nullable_to_non_nullable
as List<ExerciseGroupDraft>,
  ));
}


}


/// @nodoc
mixin _$ExerciseGroupDraft {

 String get draftId; String? get persistedId; List<ExerciseDraft> get exercises; ExerciseGroupRole get role;
/// Create a copy of ExerciseGroupDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseGroupDraftCopyWith<ExerciseGroupDraft> get copyWith => _$ExerciseGroupDraftCopyWithImpl<ExerciseGroupDraft>(this as ExerciseGroupDraft, _$identity);

  /// Serializes this ExerciseGroupDraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseGroupDraft&&(identical(other.draftId, draftId) || other.draftId == draftId)&&(identical(other.persistedId, persistedId) || other.persistedId == persistedId)&&const DeepCollectionEquality().equals(other.exercises, exercises)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,draftId,persistedId,const DeepCollectionEquality().hash(exercises),role);

@override
String toString() {
  return 'ExerciseGroupDraft(draftId: $draftId, persistedId: $persistedId, exercises: $exercises, role: $role)';
}


}

/// @nodoc
abstract mixin class $ExerciseGroupDraftCopyWith<$Res>  {
  factory $ExerciseGroupDraftCopyWith(ExerciseGroupDraft value, $Res Function(ExerciseGroupDraft) _then) = _$ExerciseGroupDraftCopyWithImpl;
@useResult
$Res call({
 String draftId, String? persistedId, List<ExerciseDraft> exercises, ExerciseGroupRole role
});




}
/// @nodoc
class _$ExerciseGroupDraftCopyWithImpl<$Res>
    implements $ExerciseGroupDraftCopyWith<$Res> {
  _$ExerciseGroupDraftCopyWithImpl(this._self, this._then);

  final ExerciseGroupDraft _self;
  final $Res Function(ExerciseGroupDraft) _then;

/// Create a copy of ExerciseGroupDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? draftId = null,Object? persistedId = freezed,Object? exercises = null,Object? role = null,}) {
  return _then(_self.copyWith(
draftId: null == draftId ? _self.draftId : draftId // ignore: cast_nullable_to_non_nullable
as String,persistedId: freezed == persistedId ? _self.persistedId : persistedId // ignore: cast_nullable_to_non_nullable
as String?,exercises: null == exercises ? _self.exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<ExerciseDraft>,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as ExerciseGroupRole,
  ));
}

}


/// Adds pattern-matching-related methods to [ExerciseGroupDraft].
extension ExerciseGroupDraftPatterns on ExerciseGroupDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExerciseGroupDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExerciseGroupDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExerciseGroupDraft value)  $default,){
final _that = this;
switch (_that) {
case _ExerciseGroupDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExerciseGroupDraft value)?  $default,){
final _that = this;
switch (_that) {
case _ExerciseGroupDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String draftId,  String? persistedId,  List<ExerciseDraft> exercises,  ExerciseGroupRole role)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExerciseGroupDraft() when $default != null:
return $default(_that.draftId,_that.persistedId,_that.exercises,_that.role);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String draftId,  String? persistedId,  List<ExerciseDraft> exercises,  ExerciseGroupRole role)  $default,) {final _that = this;
switch (_that) {
case _ExerciseGroupDraft():
return $default(_that.draftId,_that.persistedId,_that.exercises,_that.role);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String draftId,  String? persistedId,  List<ExerciseDraft> exercises,  ExerciseGroupRole role)?  $default,) {final _that = this;
switch (_that) {
case _ExerciseGroupDraft() when $default != null:
return $default(_that.draftId,_that.persistedId,_that.exercises,_that.role);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExerciseGroupDraft extends ExerciseGroupDraft {
  const _ExerciseGroupDraft({required this.draftId, required this.persistedId, required final  List<ExerciseDraft> exercises, this.role = ExerciseGroupRole.main}): _exercises = exercises,super._();
  factory _ExerciseGroupDraft.fromJson(Map<String, dynamic> json) => _$ExerciseGroupDraftFromJson(json);

@override final  String draftId;
@override final  String? persistedId;
 final  List<ExerciseDraft> _exercises;
@override List<ExerciseDraft> get exercises {
  if (_exercises is EqualUnmodifiableListView) return _exercises;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exercises);
}

@override@JsonKey() final  ExerciseGroupRole role;

/// Create a copy of ExerciseGroupDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseGroupDraftCopyWith<_ExerciseGroupDraft> get copyWith => __$ExerciseGroupDraftCopyWithImpl<_ExerciseGroupDraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExerciseGroupDraftToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExerciseGroupDraft&&(identical(other.draftId, draftId) || other.draftId == draftId)&&(identical(other.persistedId, persistedId) || other.persistedId == persistedId)&&const DeepCollectionEquality().equals(other._exercises, _exercises)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,draftId,persistedId,const DeepCollectionEquality().hash(_exercises),role);

@override
String toString() {
  return 'ExerciseGroupDraft(draftId: $draftId, persistedId: $persistedId, exercises: $exercises, role: $role)';
}


}

/// @nodoc
abstract mixin class _$ExerciseGroupDraftCopyWith<$Res> implements $ExerciseGroupDraftCopyWith<$Res> {
  factory _$ExerciseGroupDraftCopyWith(_ExerciseGroupDraft value, $Res Function(_ExerciseGroupDraft) _then) = __$ExerciseGroupDraftCopyWithImpl;
@override @useResult
$Res call({
 String draftId, String? persistedId, List<ExerciseDraft> exercises, ExerciseGroupRole role
});




}
/// @nodoc
class __$ExerciseGroupDraftCopyWithImpl<$Res>
    implements _$ExerciseGroupDraftCopyWith<$Res> {
  __$ExerciseGroupDraftCopyWithImpl(this._self, this._then);

  final _ExerciseGroupDraft _self;
  final $Res Function(_ExerciseGroupDraft) _then;

/// Create a copy of ExerciseGroupDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draftId = null,Object? persistedId = freezed,Object? exercises = null,Object? role = null,}) {
  return _then(_ExerciseGroupDraft(
draftId: null == draftId ? _self.draftId : draftId // ignore: cast_nullable_to_non_nullable
as String,persistedId: freezed == persistedId ? _self.persistedId : persistedId // ignore: cast_nullable_to_non_nullable
as String?,exercises: null == exercises ? _self._exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<ExerciseDraft>,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as ExerciseGroupRole,
  ));
}


}


/// @nodoc
mixin _$ExerciseDraft {

 String get draftId; String? get persistedId; String get name; MeasurementType get measurementType; ExerciseMetadata get metadata; int? get plannedRestSeconds; List<PlannedSetDraft> get sets; String? get libraryExerciseId;
/// Create a copy of ExerciseDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseDraftCopyWith<ExerciseDraft> get copyWith => _$ExerciseDraftCopyWithImpl<ExerciseDraft>(this as ExerciseDraft, _$identity);

  /// Serializes this ExerciseDraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseDraft&&(identical(other.draftId, draftId) || other.draftId == draftId)&&(identical(other.persistedId, persistedId) || other.persistedId == persistedId)&&(identical(other.name, name) || other.name == name)&&(identical(other.measurementType, measurementType) || other.measurementType == measurementType)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.plannedRestSeconds, plannedRestSeconds) || other.plannedRestSeconds == plannedRestSeconds)&&const DeepCollectionEquality().equals(other.sets, sets)&&(identical(other.libraryExerciseId, libraryExerciseId) || other.libraryExerciseId == libraryExerciseId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,draftId,persistedId,name,measurementType,metadata,plannedRestSeconds,const DeepCollectionEquality().hash(sets),libraryExerciseId);

@override
String toString() {
  return 'ExerciseDraft(draftId: $draftId, persistedId: $persistedId, name: $name, measurementType: $measurementType, metadata: $metadata, plannedRestSeconds: $plannedRestSeconds, sets: $sets, libraryExerciseId: $libraryExerciseId)';
}


}

/// @nodoc
abstract mixin class $ExerciseDraftCopyWith<$Res>  {
  factory $ExerciseDraftCopyWith(ExerciseDraft value, $Res Function(ExerciseDraft) _then) = _$ExerciseDraftCopyWithImpl;
@useResult
$Res call({
 String draftId, String? persistedId, String name, MeasurementType measurementType, ExerciseMetadata metadata, int? plannedRestSeconds, List<PlannedSetDraft> sets, String? libraryExerciseId
});


$MeasurementTypeCopyWith<$Res> get measurementType;$ExerciseMetadataCopyWith<$Res> get metadata;

}
/// @nodoc
class _$ExerciseDraftCopyWithImpl<$Res>
    implements $ExerciseDraftCopyWith<$Res> {
  _$ExerciseDraftCopyWithImpl(this._self, this._then);

  final ExerciseDraft _self;
  final $Res Function(ExerciseDraft) _then;

/// Create a copy of ExerciseDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? draftId = null,Object? persistedId = freezed,Object? name = null,Object? measurementType = null,Object? metadata = null,Object? plannedRestSeconds = freezed,Object? sets = null,Object? libraryExerciseId = freezed,}) {
  return _then(_self.copyWith(
draftId: null == draftId ? _self.draftId : draftId // ignore: cast_nullable_to_non_nullable
as String,persistedId: freezed == persistedId ? _self.persistedId : persistedId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,measurementType: null == measurementType ? _self.measurementType : measurementType // ignore: cast_nullable_to_non_nullable
as MeasurementType,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as ExerciseMetadata,plannedRestSeconds: freezed == plannedRestSeconds ? _self.plannedRestSeconds : plannedRestSeconds // ignore: cast_nullable_to_non_nullable
as int?,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as List<PlannedSetDraft>,libraryExerciseId: freezed == libraryExerciseId ? _self.libraryExerciseId : libraryExerciseId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ExerciseDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementTypeCopyWith<$Res> get measurementType {
  
  return $MeasurementTypeCopyWith<$Res>(_self.measurementType, (value) {
    return _then(_self.copyWith(measurementType: value));
  });
}/// Create a copy of ExerciseDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseMetadataCopyWith<$Res> get metadata {
  
  return $ExerciseMetadataCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [ExerciseDraft].
extension ExerciseDraftPatterns on ExerciseDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExerciseDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExerciseDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExerciseDraft value)  $default,){
final _that = this;
switch (_that) {
case _ExerciseDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExerciseDraft value)?  $default,){
final _that = this;
switch (_that) {
case _ExerciseDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String draftId,  String? persistedId,  String name,  MeasurementType measurementType,  ExerciseMetadata metadata,  int? plannedRestSeconds,  List<PlannedSetDraft> sets,  String? libraryExerciseId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExerciseDraft() when $default != null:
return $default(_that.draftId,_that.persistedId,_that.name,_that.measurementType,_that.metadata,_that.plannedRestSeconds,_that.sets,_that.libraryExerciseId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String draftId,  String? persistedId,  String name,  MeasurementType measurementType,  ExerciseMetadata metadata,  int? plannedRestSeconds,  List<PlannedSetDraft> sets,  String? libraryExerciseId)  $default,) {final _that = this;
switch (_that) {
case _ExerciseDraft():
return $default(_that.draftId,_that.persistedId,_that.name,_that.measurementType,_that.metadata,_that.plannedRestSeconds,_that.sets,_that.libraryExerciseId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String draftId,  String? persistedId,  String name,  MeasurementType measurementType,  ExerciseMetadata metadata,  int? plannedRestSeconds,  List<PlannedSetDraft> sets,  String? libraryExerciseId)?  $default,) {final _that = this;
switch (_that) {
case _ExerciseDraft() when $default != null:
return $default(_that.draftId,_that.persistedId,_that.name,_that.measurementType,_that.metadata,_that.plannedRestSeconds,_that.sets,_that.libraryExerciseId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExerciseDraft implements ExerciseDraft {
  const _ExerciseDraft({required this.draftId, required this.persistedId, required this.name, required this.measurementType, required this.metadata, required this.plannedRestSeconds, required final  List<PlannedSetDraft> sets, this.libraryExerciseId}): _sets = sets;
  factory _ExerciseDraft.fromJson(Map<String, dynamic> json) => _$ExerciseDraftFromJson(json);

@override final  String draftId;
@override final  String? persistedId;
@override final  String name;
@override final  MeasurementType measurementType;
@override final  ExerciseMetadata metadata;
@override final  int? plannedRestSeconds;
 final  List<PlannedSetDraft> _sets;
@override List<PlannedSetDraft> get sets {
  if (_sets is EqualUnmodifiableListView) return _sets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sets);
}

@override final  String? libraryExerciseId;

/// Create a copy of ExerciseDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseDraftCopyWith<_ExerciseDraft> get copyWith => __$ExerciseDraftCopyWithImpl<_ExerciseDraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExerciseDraftToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExerciseDraft&&(identical(other.draftId, draftId) || other.draftId == draftId)&&(identical(other.persistedId, persistedId) || other.persistedId == persistedId)&&(identical(other.name, name) || other.name == name)&&(identical(other.measurementType, measurementType) || other.measurementType == measurementType)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.plannedRestSeconds, plannedRestSeconds) || other.plannedRestSeconds == plannedRestSeconds)&&const DeepCollectionEquality().equals(other._sets, _sets)&&(identical(other.libraryExerciseId, libraryExerciseId) || other.libraryExerciseId == libraryExerciseId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,draftId,persistedId,name,measurementType,metadata,plannedRestSeconds,const DeepCollectionEquality().hash(_sets),libraryExerciseId);

@override
String toString() {
  return 'ExerciseDraft(draftId: $draftId, persistedId: $persistedId, name: $name, measurementType: $measurementType, metadata: $metadata, plannedRestSeconds: $plannedRestSeconds, sets: $sets, libraryExerciseId: $libraryExerciseId)';
}


}

/// @nodoc
abstract mixin class _$ExerciseDraftCopyWith<$Res> implements $ExerciseDraftCopyWith<$Res> {
  factory _$ExerciseDraftCopyWith(_ExerciseDraft value, $Res Function(_ExerciseDraft) _then) = __$ExerciseDraftCopyWithImpl;
@override @useResult
$Res call({
 String draftId, String? persistedId, String name, MeasurementType measurementType, ExerciseMetadata metadata, int? plannedRestSeconds, List<PlannedSetDraft> sets, String? libraryExerciseId
});


@override $MeasurementTypeCopyWith<$Res> get measurementType;@override $ExerciseMetadataCopyWith<$Res> get metadata;

}
/// @nodoc
class __$ExerciseDraftCopyWithImpl<$Res>
    implements _$ExerciseDraftCopyWith<$Res> {
  __$ExerciseDraftCopyWithImpl(this._self, this._then);

  final _ExerciseDraft _self;
  final $Res Function(_ExerciseDraft) _then;

/// Create a copy of ExerciseDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draftId = null,Object? persistedId = freezed,Object? name = null,Object? measurementType = null,Object? metadata = null,Object? plannedRestSeconds = freezed,Object? sets = null,Object? libraryExerciseId = freezed,}) {
  return _then(_ExerciseDraft(
draftId: null == draftId ? _self.draftId : draftId // ignore: cast_nullable_to_non_nullable
as String,persistedId: freezed == persistedId ? _self.persistedId : persistedId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,measurementType: null == measurementType ? _self.measurementType : measurementType // ignore: cast_nullable_to_non_nullable
as MeasurementType,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as ExerciseMetadata,plannedRestSeconds: freezed == plannedRestSeconds ? _self.plannedRestSeconds : plannedRestSeconds // ignore: cast_nullable_to_non_nullable
as int?,sets: null == sets ? _self._sets : sets // ignore: cast_nullable_to_non_nullable
as List<PlannedSetDraft>,libraryExerciseId: freezed == libraryExerciseId ? _self.libraryExerciseId : libraryExerciseId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ExerciseDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementTypeCopyWith<$Res> get measurementType {
  
  return $MeasurementTypeCopyWith<$Res>(_self.measurementType, (value) {
    return _then(_self.copyWith(measurementType: value));
  });
}/// Create a copy of ExerciseDraft
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
mixin _$PlannedSetDraft {

 String get draftId; String? get persistedId; PlannedSetDraftValues get values;
/// Create a copy of PlannedSetDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlannedSetDraftCopyWith<PlannedSetDraft> get copyWith => _$PlannedSetDraftCopyWithImpl<PlannedSetDraft>(this as PlannedSetDraft, _$identity);

  /// Serializes this PlannedSetDraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlannedSetDraft&&(identical(other.draftId, draftId) || other.draftId == draftId)&&(identical(other.persistedId, persistedId) || other.persistedId == persistedId)&&(identical(other.values, values) || other.values == values));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,draftId,persistedId,values);

@override
String toString() {
  return 'PlannedSetDraft(draftId: $draftId, persistedId: $persistedId, values: $values)';
}


}

/// @nodoc
abstract mixin class $PlannedSetDraftCopyWith<$Res>  {
  factory $PlannedSetDraftCopyWith(PlannedSetDraft value, $Res Function(PlannedSetDraft) _then) = _$PlannedSetDraftCopyWithImpl;
@useResult
$Res call({
 String draftId, String? persistedId, PlannedSetDraftValues values
});


$PlannedSetDraftValuesCopyWith<$Res> get values;

}
/// @nodoc
class _$PlannedSetDraftCopyWithImpl<$Res>
    implements $PlannedSetDraftCopyWith<$Res> {
  _$PlannedSetDraftCopyWithImpl(this._self, this._then);

  final PlannedSetDraft _self;
  final $Res Function(PlannedSetDraft) _then;

/// Create a copy of PlannedSetDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? draftId = null,Object? persistedId = freezed,Object? values = null,}) {
  return _then(_self.copyWith(
draftId: null == draftId ? _self.draftId : draftId // ignore: cast_nullable_to_non_nullable
as String,persistedId: freezed == persistedId ? _self.persistedId : persistedId // ignore: cast_nullable_to_non_nullable
as String?,values: null == values ? _self.values : values // ignore: cast_nullable_to_non_nullable
as PlannedSetDraftValues,
  ));
}
/// Create a copy of PlannedSetDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlannedSetDraftValuesCopyWith<$Res> get values {
  
  return $PlannedSetDraftValuesCopyWith<$Res>(_self.values, (value) {
    return _then(_self.copyWith(values: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlannedSetDraft].
extension PlannedSetDraftPatterns on PlannedSetDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlannedSetDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlannedSetDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlannedSetDraft value)  $default,){
final _that = this;
switch (_that) {
case _PlannedSetDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlannedSetDraft value)?  $default,){
final _that = this;
switch (_that) {
case _PlannedSetDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String draftId,  String? persistedId,  PlannedSetDraftValues values)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlannedSetDraft() when $default != null:
return $default(_that.draftId,_that.persistedId,_that.values);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String draftId,  String? persistedId,  PlannedSetDraftValues values)  $default,) {final _that = this;
switch (_that) {
case _PlannedSetDraft():
return $default(_that.draftId,_that.persistedId,_that.values);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String draftId,  String? persistedId,  PlannedSetDraftValues values)?  $default,) {final _that = this;
switch (_that) {
case _PlannedSetDraft() when $default != null:
return $default(_that.draftId,_that.persistedId,_that.values);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlannedSetDraft implements PlannedSetDraft {
  const _PlannedSetDraft({required this.draftId, required this.persistedId, required this.values});
  factory _PlannedSetDraft.fromJson(Map<String, dynamic> json) => _$PlannedSetDraftFromJson(json);

@override final  String draftId;
@override final  String? persistedId;
@override final  PlannedSetDraftValues values;

/// Create a copy of PlannedSetDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlannedSetDraftCopyWith<_PlannedSetDraft> get copyWith => __$PlannedSetDraftCopyWithImpl<_PlannedSetDraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlannedSetDraftToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlannedSetDraft&&(identical(other.draftId, draftId) || other.draftId == draftId)&&(identical(other.persistedId, persistedId) || other.persistedId == persistedId)&&(identical(other.values, values) || other.values == values));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,draftId,persistedId,values);

@override
String toString() {
  return 'PlannedSetDraft(draftId: $draftId, persistedId: $persistedId, values: $values)';
}


}

/// @nodoc
abstract mixin class _$PlannedSetDraftCopyWith<$Res> implements $PlannedSetDraftCopyWith<$Res> {
  factory _$PlannedSetDraftCopyWith(_PlannedSetDraft value, $Res Function(_PlannedSetDraft) _then) = __$PlannedSetDraftCopyWithImpl;
@override @useResult
$Res call({
 String draftId, String? persistedId, PlannedSetDraftValues values
});


@override $PlannedSetDraftValuesCopyWith<$Res> get values;

}
/// @nodoc
class __$PlannedSetDraftCopyWithImpl<$Res>
    implements _$PlannedSetDraftCopyWith<$Res> {
  __$PlannedSetDraftCopyWithImpl(this._self, this._then);

  final _PlannedSetDraft _self;
  final $Res Function(_PlannedSetDraft) _then;

/// Create a copy of PlannedSetDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draftId = null,Object? persistedId = freezed,Object? values = null,}) {
  return _then(_PlannedSetDraft(
draftId: null == draftId ? _self.draftId : draftId // ignore: cast_nullable_to_non_nullable
as String,persistedId: freezed == persistedId ? _self.persistedId : persistedId // ignore: cast_nullable_to_non_nullable
as String?,values: null == values ? _self.values : values // ignore: cast_nullable_to_non_nullable
as PlannedSetDraftValues,
  ));
}

/// Create a copy of PlannedSetDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlannedSetDraftValuesCopyWith<$Res> get values {
  
  return $PlannedSetDraftValuesCopyWith<$Res>(_self.values, (value) {
    return _then(_self.copyWith(values: value));
  });
}
}

PlannedSetDraftValues _$PlannedSetDraftValuesFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'repBased':
          return PlannedSetDraftRepBased.fromJson(
            json
          );
                case 'timeBased':
          return PlannedSetDraftTimeBased.fromJson(
            json
          );
                case 'bodyweight':
          return PlannedSetDraftBodyweight.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'PlannedSetDraftValues',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$PlannedSetDraftValues {



  /// Serializes this PlannedSetDraftValues to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlannedSetDraftValues);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlannedSetDraftValues()';
}


}

/// @nodoc
class $PlannedSetDraftValuesCopyWith<$Res>  {
$PlannedSetDraftValuesCopyWith(PlannedSetDraftValues _, $Res Function(PlannedSetDraftValues) __);
}


/// Adds pattern-matching-related methods to [PlannedSetDraftValues].
extension PlannedSetDraftValuesPatterns on PlannedSetDraftValues {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlannedSetDraftRepBased value)?  repBased,TResult Function( PlannedSetDraftTimeBased value)?  timeBased,TResult Function( PlannedSetDraftBodyweight value)?  bodyweight,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlannedSetDraftRepBased() when repBased != null:
return repBased(_that);case PlannedSetDraftTimeBased() when timeBased != null:
return timeBased(_that);case PlannedSetDraftBodyweight() when bodyweight != null:
return bodyweight(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlannedSetDraftRepBased value)  repBased,required TResult Function( PlannedSetDraftTimeBased value)  timeBased,required TResult Function( PlannedSetDraftBodyweight value)  bodyweight,}){
final _that = this;
switch (_that) {
case PlannedSetDraftRepBased():
return repBased(_that);case PlannedSetDraftTimeBased():
return timeBased(_that);case PlannedSetDraftBodyweight():
return bodyweight(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlannedSetDraftRepBased value)?  repBased,TResult? Function( PlannedSetDraftTimeBased value)?  timeBased,TResult? Function( PlannedSetDraftBodyweight value)?  bodyweight,}){
final _that = this;
switch (_that) {
case PlannedSetDraftRepBased() when repBased != null:
return repBased(_that);case PlannedSetDraftTimeBased() when timeBased != null:
return timeBased(_that);case PlannedSetDraftBodyweight() when bodyweight != null:
return bodyweight(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String weightInput,  String repsInput)?  repBased,TResult Function( String durationInput,  String weightInput)?  timeBased,TResult Function( String repsInput)?  bodyweight,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PlannedSetDraftRepBased() when repBased != null:
return repBased(_that.weightInput,_that.repsInput);case PlannedSetDraftTimeBased() when timeBased != null:
return timeBased(_that.durationInput,_that.weightInput);case PlannedSetDraftBodyweight() when bodyweight != null:
return bodyweight(_that.repsInput);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String weightInput,  String repsInput)  repBased,required TResult Function( String durationInput,  String weightInput)  timeBased,required TResult Function( String repsInput)  bodyweight,}) {final _that = this;
switch (_that) {
case PlannedSetDraftRepBased():
return repBased(_that.weightInput,_that.repsInput);case PlannedSetDraftTimeBased():
return timeBased(_that.durationInput,_that.weightInput);case PlannedSetDraftBodyweight():
return bodyweight(_that.repsInput);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String weightInput,  String repsInput)?  repBased,TResult? Function( String durationInput,  String weightInput)?  timeBased,TResult? Function( String repsInput)?  bodyweight,}) {final _that = this;
switch (_that) {
case PlannedSetDraftRepBased() when repBased != null:
return repBased(_that.weightInput,_that.repsInput);case PlannedSetDraftTimeBased() when timeBased != null:
return timeBased(_that.durationInput,_that.weightInput);case PlannedSetDraftBodyweight() when bodyweight != null:
return bodyweight(_that.repsInput);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class PlannedSetDraftRepBased implements PlannedSetDraftValues {
  const PlannedSetDraftRepBased({required this.weightInput, required this.repsInput, final  String? $type}): $type = $type ?? 'repBased';
  factory PlannedSetDraftRepBased.fromJson(Map<String, dynamic> json) => _$PlannedSetDraftRepBasedFromJson(json);

 final  String weightInput;
 final  String repsInput;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of PlannedSetDraftValues
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlannedSetDraftRepBasedCopyWith<PlannedSetDraftRepBased> get copyWith => _$PlannedSetDraftRepBasedCopyWithImpl<PlannedSetDraftRepBased>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlannedSetDraftRepBasedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlannedSetDraftRepBased&&(identical(other.weightInput, weightInput) || other.weightInput == weightInput)&&(identical(other.repsInput, repsInput) || other.repsInput == repsInput));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weightInput,repsInput);

@override
String toString() {
  return 'PlannedSetDraftValues.repBased(weightInput: $weightInput, repsInput: $repsInput)';
}


}

/// @nodoc
abstract mixin class $PlannedSetDraftRepBasedCopyWith<$Res> implements $PlannedSetDraftValuesCopyWith<$Res> {
  factory $PlannedSetDraftRepBasedCopyWith(PlannedSetDraftRepBased value, $Res Function(PlannedSetDraftRepBased) _then) = _$PlannedSetDraftRepBasedCopyWithImpl;
@useResult
$Res call({
 String weightInput, String repsInput
});




}
/// @nodoc
class _$PlannedSetDraftRepBasedCopyWithImpl<$Res>
    implements $PlannedSetDraftRepBasedCopyWith<$Res> {
  _$PlannedSetDraftRepBasedCopyWithImpl(this._self, this._then);

  final PlannedSetDraftRepBased _self;
  final $Res Function(PlannedSetDraftRepBased) _then;

/// Create a copy of PlannedSetDraftValues
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? weightInput = null,Object? repsInput = null,}) {
  return _then(PlannedSetDraftRepBased(
weightInput: null == weightInput ? _self.weightInput : weightInput // ignore: cast_nullable_to_non_nullable
as String,repsInput: null == repsInput ? _self.repsInput : repsInput // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class PlannedSetDraftTimeBased implements PlannedSetDraftValues {
  const PlannedSetDraftTimeBased({required this.durationInput, this.weightInput = '', final  String? $type}): $type = $type ?? 'timeBased';
  factory PlannedSetDraftTimeBased.fromJson(Map<String, dynamic> json) => _$PlannedSetDraftTimeBasedFromJson(json);

 final  String durationInput;
@JsonKey() final  String weightInput;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of PlannedSetDraftValues
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlannedSetDraftTimeBasedCopyWith<PlannedSetDraftTimeBased> get copyWith => _$PlannedSetDraftTimeBasedCopyWithImpl<PlannedSetDraftTimeBased>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlannedSetDraftTimeBasedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlannedSetDraftTimeBased&&(identical(other.durationInput, durationInput) || other.durationInput == durationInput)&&(identical(other.weightInput, weightInput) || other.weightInput == weightInput));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,durationInput,weightInput);

@override
String toString() {
  return 'PlannedSetDraftValues.timeBased(durationInput: $durationInput, weightInput: $weightInput)';
}


}

/// @nodoc
abstract mixin class $PlannedSetDraftTimeBasedCopyWith<$Res> implements $PlannedSetDraftValuesCopyWith<$Res> {
  factory $PlannedSetDraftTimeBasedCopyWith(PlannedSetDraftTimeBased value, $Res Function(PlannedSetDraftTimeBased) _then) = _$PlannedSetDraftTimeBasedCopyWithImpl;
@useResult
$Res call({
 String durationInput, String weightInput
});




}
/// @nodoc
class _$PlannedSetDraftTimeBasedCopyWithImpl<$Res>
    implements $PlannedSetDraftTimeBasedCopyWith<$Res> {
  _$PlannedSetDraftTimeBasedCopyWithImpl(this._self, this._then);

  final PlannedSetDraftTimeBased _self;
  final $Res Function(PlannedSetDraftTimeBased) _then;

/// Create a copy of PlannedSetDraftValues
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? durationInput = null,Object? weightInput = null,}) {
  return _then(PlannedSetDraftTimeBased(
durationInput: null == durationInput ? _self.durationInput : durationInput // ignore: cast_nullable_to_non_nullable
as String,weightInput: null == weightInput ? _self.weightInput : weightInput // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class PlannedSetDraftBodyweight implements PlannedSetDraftValues {
  const PlannedSetDraftBodyweight({required this.repsInput, final  String? $type}): $type = $type ?? 'bodyweight';
  factory PlannedSetDraftBodyweight.fromJson(Map<String, dynamic> json) => _$PlannedSetDraftBodyweightFromJson(json);

 final  String repsInput;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of PlannedSetDraftValues
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlannedSetDraftBodyweightCopyWith<PlannedSetDraftBodyweight> get copyWith => _$PlannedSetDraftBodyweightCopyWithImpl<PlannedSetDraftBodyweight>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlannedSetDraftBodyweightToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlannedSetDraftBodyweight&&(identical(other.repsInput, repsInput) || other.repsInput == repsInput));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,repsInput);

@override
String toString() {
  return 'PlannedSetDraftValues.bodyweight(repsInput: $repsInput)';
}


}

/// @nodoc
abstract mixin class $PlannedSetDraftBodyweightCopyWith<$Res> implements $PlannedSetDraftValuesCopyWith<$Res> {
  factory $PlannedSetDraftBodyweightCopyWith(PlannedSetDraftBodyweight value, $Res Function(PlannedSetDraftBodyweight) _then) = _$PlannedSetDraftBodyweightCopyWithImpl;
@useResult
$Res call({
 String repsInput
});




}
/// @nodoc
class _$PlannedSetDraftBodyweightCopyWithImpl<$Res>
    implements $PlannedSetDraftBodyweightCopyWith<$Res> {
  _$PlannedSetDraftBodyweightCopyWithImpl(this._self, this._then);

  final PlannedSetDraftBodyweight _self;
  final $Res Function(PlannedSetDraftBodyweight) _then;

/// Create a copy of PlannedSetDraftValues
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? repsInput = null,}) {
  return _then(PlannedSetDraftBodyweight(
repsInput: null == repsInput ? _self.repsInput : repsInput // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

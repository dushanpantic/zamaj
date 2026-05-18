// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlanDraft {

 String get programName; List<PlanDraftWorkoutDay> get workoutDays;
/// Create a copy of PlanDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanDraftCopyWith<PlanDraft> get copyWith => _$PlanDraftCopyWithImpl<PlanDraft>(this as PlanDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanDraft&&(identical(other.programName, programName) || other.programName == programName)&&const DeepCollectionEquality().equals(other.workoutDays, workoutDays));
}


@override
int get hashCode => Object.hash(runtimeType,programName,const DeepCollectionEquality().hash(workoutDays));

@override
String toString() {
  return 'PlanDraft(programName: $programName, workoutDays: $workoutDays)';
}


}

/// @nodoc
abstract mixin class $PlanDraftCopyWith<$Res>  {
  factory $PlanDraftCopyWith(PlanDraft value, $Res Function(PlanDraft) _then) = _$PlanDraftCopyWithImpl;
@useResult
$Res call({
 String programName, List<PlanDraftWorkoutDay> workoutDays
});




}
/// @nodoc
class _$PlanDraftCopyWithImpl<$Res>
    implements $PlanDraftCopyWith<$Res> {
  _$PlanDraftCopyWithImpl(this._self, this._then);

  final PlanDraft _self;
  final $Res Function(PlanDraft) _then;

/// Create a copy of PlanDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? programName = null,Object? workoutDays = null,}) {
  return _then(_self.copyWith(
programName: null == programName ? _self.programName : programName // ignore: cast_nullable_to_non_nullable
as String,workoutDays: null == workoutDays ? _self.workoutDays : workoutDays // ignore: cast_nullable_to_non_nullable
as List<PlanDraftWorkoutDay>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanDraft].
extension PlanDraftPatterns on PlanDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanDraft value)  $default,){
final _that = this;
switch (_that) {
case _PlanDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanDraft value)?  $default,){
final _that = this;
switch (_that) {
case _PlanDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String programName,  List<PlanDraftWorkoutDay> workoutDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanDraft() when $default != null:
return $default(_that.programName,_that.workoutDays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String programName,  List<PlanDraftWorkoutDay> workoutDays)  $default,) {final _that = this;
switch (_that) {
case _PlanDraft():
return $default(_that.programName,_that.workoutDays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String programName,  List<PlanDraftWorkoutDay> workoutDays)?  $default,) {final _that = this;
switch (_that) {
case _PlanDraft() when $default != null:
return $default(_that.programName,_that.workoutDays);case _:
  return null;

}
}

}

/// @nodoc


class _PlanDraft implements PlanDraft {
  const _PlanDraft({required this.programName, required final  List<PlanDraftWorkoutDay> workoutDays}): _workoutDays = workoutDays;
  

@override final  String programName;
 final  List<PlanDraftWorkoutDay> _workoutDays;
@override List<PlanDraftWorkoutDay> get workoutDays {
  if (_workoutDays is EqualUnmodifiableListView) return _workoutDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_workoutDays);
}


/// Create a copy of PlanDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanDraftCopyWith<_PlanDraft> get copyWith => __$PlanDraftCopyWithImpl<_PlanDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanDraft&&(identical(other.programName, programName) || other.programName == programName)&&const DeepCollectionEquality().equals(other._workoutDays, _workoutDays));
}


@override
int get hashCode => Object.hash(runtimeType,programName,const DeepCollectionEquality().hash(_workoutDays));

@override
String toString() {
  return 'PlanDraft(programName: $programName, workoutDays: $workoutDays)';
}


}

/// @nodoc
abstract mixin class _$PlanDraftCopyWith<$Res> implements $PlanDraftCopyWith<$Res> {
  factory _$PlanDraftCopyWith(_PlanDraft value, $Res Function(_PlanDraft) _then) = __$PlanDraftCopyWithImpl;
@override @useResult
$Res call({
 String programName, List<PlanDraftWorkoutDay> workoutDays
});




}
/// @nodoc
class __$PlanDraftCopyWithImpl<$Res>
    implements _$PlanDraftCopyWith<$Res> {
  __$PlanDraftCopyWithImpl(this._self, this._then);

  final _PlanDraft _self;
  final $Res Function(_PlanDraft) _then;

/// Create a copy of PlanDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? programName = null,Object? workoutDays = null,}) {
  return _then(_PlanDraft(
programName: null == programName ? _self.programName : programName // ignore: cast_nullable_to_non_nullable
as String,workoutDays: null == workoutDays ? _self._workoutDays : workoutDays // ignore: cast_nullable_to_non_nullable
as List<PlanDraftWorkoutDay>,
  ));
}


}

/// @nodoc
mixin _$PlanDraftWorkoutDay {

 String get name; List<PlanDraftGroup> get groups;
/// Create a copy of PlanDraftWorkoutDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanDraftWorkoutDayCopyWith<PlanDraftWorkoutDay> get copyWith => _$PlanDraftWorkoutDayCopyWithImpl<PlanDraftWorkoutDay>(this as PlanDraftWorkoutDay, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanDraftWorkoutDay&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.groups, groups));
}


@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(groups));

@override
String toString() {
  return 'PlanDraftWorkoutDay(name: $name, groups: $groups)';
}


}

/// @nodoc
abstract mixin class $PlanDraftWorkoutDayCopyWith<$Res>  {
  factory $PlanDraftWorkoutDayCopyWith(PlanDraftWorkoutDay value, $Res Function(PlanDraftWorkoutDay) _then) = _$PlanDraftWorkoutDayCopyWithImpl;
@useResult
$Res call({
 String name, List<PlanDraftGroup> groups
});




}
/// @nodoc
class _$PlanDraftWorkoutDayCopyWithImpl<$Res>
    implements $PlanDraftWorkoutDayCopyWith<$Res> {
  _$PlanDraftWorkoutDayCopyWithImpl(this._self, this._then);

  final PlanDraftWorkoutDay _self;
  final $Res Function(PlanDraftWorkoutDay) _then;

/// Create a copy of PlanDraftWorkoutDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? groups = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,groups: null == groups ? _self.groups : groups // ignore: cast_nullable_to_non_nullable
as List<PlanDraftGroup>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanDraftWorkoutDay].
extension PlanDraftWorkoutDayPatterns on PlanDraftWorkoutDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanDraftWorkoutDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanDraftWorkoutDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanDraftWorkoutDay value)  $default,){
final _that = this;
switch (_that) {
case _PlanDraftWorkoutDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanDraftWorkoutDay value)?  $default,){
final _that = this;
switch (_that) {
case _PlanDraftWorkoutDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  List<PlanDraftGroup> groups)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanDraftWorkoutDay() when $default != null:
return $default(_that.name,_that.groups);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  List<PlanDraftGroup> groups)  $default,) {final _that = this;
switch (_that) {
case _PlanDraftWorkoutDay():
return $default(_that.name,_that.groups);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  List<PlanDraftGroup> groups)?  $default,) {final _that = this;
switch (_that) {
case _PlanDraftWorkoutDay() when $default != null:
return $default(_that.name,_that.groups);case _:
  return null;

}
}

}

/// @nodoc


class _PlanDraftWorkoutDay implements PlanDraftWorkoutDay {
  const _PlanDraftWorkoutDay({required this.name, required final  List<PlanDraftGroup> groups}): _groups = groups;
  

@override final  String name;
 final  List<PlanDraftGroup> _groups;
@override List<PlanDraftGroup> get groups {
  if (_groups is EqualUnmodifiableListView) return _groups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_groups);
}


/// Create a copy of PlanDraftWorkoutDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanDraftWorkoutDayCopyWith<_PlanDraftWorkoutDay> get copyWith => __$PlanDraftWorkoutDayCopyWithImpl<_PlanDraftWorkoutDay>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanDraftWorkoutDay&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._groups, _groups));
}


@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(_groups));

@override
String toString() {
  return 'PlanDraftWorkoutDay(name: $name, groups: $groups)';
}


}

/// @nodoc
abstract mixin class _$PlanDraftWorkoutDayCopyWith<$Res> implements $PlanDraftWorkoutDayCopyWith<$Res> {
  factory _$PlanDraftWorkoutDayCopyWith(_PlanDraftWorkoutDay value, $Res Function(_PlanDraftWorkoutDay) _then) = __$PlanDraftWorkoutDayCopyWithImpl;
@override @useResult
$Res call({
 String name, List<PlanDraftGroup> groups
});




}
/// @nodoc
class __$PlanDraftWorkoutDayCopyWithImpl<$Res>
    implements _$PlanDraftWorkoutDayCopyWith<$Res> {
  __$PlanDraftWorkoutDayCopyWithImpl(this._self, this._then);

  final _PlanDraftWorkoutDay _self;
  final $Res Function(_PlanDraftWorkoutDay) _then;

/// Create a copy of PlanDraftWorkoutDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? groups = null,}) {
  return _then(_PlanDraftWorkoutDay(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,groups: null == groups ? _self._groups : groups // ignore: cast_nullable_to_non_nullable
as List<PlanDraftGroup>,
  ));
}


}

/// @nodoc
mixin _$PlanDraftGroup {

 List<PlanDraftExercise> get exercises;
/// Create a copy of PlanDraftGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanDraftGroupCopyWith<PlanDraftGroup> get copyWith => _$PlanDraftGroupCopyWithImpl<PlanDraftGroup>(this as PlanDraftGroup, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanDraftGroup&&const DeepCollectionEquality().equals(other.exercises, exercises));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(exercises));

@override
String toString() {
  return 'PlanDraftGroup(exercises: $exercises)';
}


}

/// @nodoc
abstract mixin class $PlanDraftGroupCopyWith<$Res>  {
  factory $PlanDraftGroupCopyWith(PlanDraftGroup value, $Res Function(PlanDraftGroup) _then) = _$PlanDraftGroupCopyWithImpl;
@useResult
$Res call({
 List<PlanDraftExercise> exercises
});




}
/// @nodoc
class _$PlanDraftGroupCopyWithImpl<$Res>
    implements $PlanDraftGroupCopyWith<$Res> {
  _$PlanDraftGroupCopyWithImpl(this._self, this._then);

  final PlanDraftGroup _self;
  final $Res Function(PlanDraftGroup) _then;

/// Create a copy of PlanDraftGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? exercises = null,}) {
  return _then(_self.copyWith(
exercises: null == exercises ? _self.exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<PlanDraftExercise>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanDraftGroup].
extension PlanDraftGroupPatterns on PlanDraftGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanDraftGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanDraftGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanDraftGroup value)  $default,){
final _that = this;
switch (_that) {
case _PlanDraftGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanDraftGroup value)?  $default,){
final _that = this;
switch (_that) {
case _PlanDraftGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PlanDraftExercise> exercises)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanDraftGroup() when $default != null:
return $default(_that.exercises);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PlanDraftExercise> exercises)  $default,) {final _that = this;
switch (_that) {
case _PlanDraftGroup():
return $default(_that.exercises);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PlanDraftExercise> exercises)?  $default,) {final _that = this;
switch (_that) {
case _PlanDraftGroup() when $default != null:
return $default(_that.exercises);case _:
  return null;

}
}

}

/// @nodoc


class _PlanDraftGroup implements PlanDraftGroup {
  const _PlanDraftGroup({required final  List<PlanDraftExercise> exercises}): _exercises = exercises;
  

 final  List<PlanDraftExercise> _exercises;
@override List<PlanDraftExercise> get exercises {
  if (_exercises is EqualUnmodifiableListView) return _exercises;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exercises);
}


/// Create a copy of PlanDraftGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanDraftGroupCopyWith<_PlanDraftGroup> get copyWith => __$PlanDraftGroupCopyWithImpl<_PlanDraftGroup>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanDraftGroup&&const DeepCollectionEquality().equals(other._exercises, _exercises));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_exercises));

@override
String toString() {
  return 'PlanDraftGroup(exercises: $exercises)';
}


}

/// @nodoc
abstract mixin class _$PlanDraftGroupCopyWith<$Res> implements $PlanDraftGroupCopyWith<$Res> {
  factory _$PlanDraftGroupCopyWith(_PlanDraftGroup value, $Res Function(_PlanDraftGroup) _then) = __$PlanDraftGroupCopyWithImpl;
@override @useResult
$Res call({
 List<PlanDraftExercise> exercises
});




}
/// @nodoc
class __$PlanDraftGroupCopyWithImpl<$Res>
    implements _$PlanDraftGroupCopyWith<$Res> {
  __$PlanDraftGroupCopyWithImpl(this._self, this._then);

  final _PlanDraftGroup _self;
  final $Res Function(_PlanDraftGroup) _then;

/// Create a copy of PlanDraftGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? exercises = null,}) {
  return _then(_PlanDraftGroup(
exercises: null == exercises ? _self._exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<PlanDraftExercise>,
  ));
}


}

/// @nodoc
mixin _$PlanDraftExercise {

 String get draftId; String get name; int? get plannedRestSeconds; String? get notes; String? get videoUrl; List<PlanDraftSet> get sets; List<PlanParseWarning> get warnings;
/// Create a copy of PlanDraftExercise
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanDraftExerciseCopyWith<PlanDraftExercise> get copyWith => _$PlanDraftExerciseCopyWithImpl<PlanDraftExercise>(this as PlanDraftExercise, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanDraftExercise&&(identical(other.draftId, draftId) || other.draftId == draftId)&&(identical(other.name, name) || other.name == name)&&(identical(other.plannedRestSeconds, plannedRestSeconds) || other.plannedRestSeconds == plannedRestSeconds)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&const DeepCollectionEquality().equals(other.sets, sets)&&const DeepCollectionEquality().equals(other.warnings, warnings));
}


@override
int get hashCode => Object.hash(runtimeType,draftId,name,plannedRestSeconds,notes,videoUrl,const DeepCollectionEquality().hash(sets),const DeepCollectionEquality().hash(warnings));

@override
String toString() {
  return 'PlanDraftExercise(draftId: $draftId, name: $name, plannedRestSeconds: $plannedRestSeconds, notes: $notes, videoUrl: $videoUrl, sets: $sets, warnings: $warnings)';
}


}

/// @nodoc
abstract mixin class $PlanDraftExerciseCopyWith<$Res>  {
  factory $PlanDraftExerciseCopyWith(PlanDraftExercise value, $Res Function(PlanDraftExercise) _then) = _$PlanDraftExerciseCopyWithImpl;
@useResult
$Res call({
 String draftId, String name, int? plannedRestSeconds, String? notes, String? videoUrl, List<PlanDraftSet> sets, List<PlanParseWarning> warnings
});




}
/// @nodoc
class _$PlanDraftExerciseCopyWithImpl<$Res>
    implements $PlanDraftExerciseCopyWith<$Res> {
  _$PlanDraftExerciseCopyWithImpl(this._self, this._then);

  final PlanDraftExercise _self;
  final $Res Function(PlanDraftExercise) _then;

/// Create a copy of PlanDraftExercise
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? draftId = null,Object? name = null,Object? plannedRestSeconds = freezed,Object? notes = freezed,Object? videoUrl = freezed,Object? sets = null,Object? warnings = null,}) {
  return _then(_self.copyWith(
draftId: null == draftId ? _self.draftId : draftId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,plannedRestSeconds: freezed == plannedRestSeconds ? _self.plannedRestSeconds : plannedRestSeconds // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as List<PlanDraftSet>,warnings: null == warnings ? _self.warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<PlanParseWarning>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanDraftExercise].
extension PlanDraftExercisePatterns on PlanDraftExercise {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanDraftExercise value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanDraftExercise() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanDraftExercise value)  $default,){
final _that = this;
switch (_that) {
case _PlanDraftExercise():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanDraftExercise value)?  $default,){
final _that = this;
switch (_that) {
case _PlanDraftExercise() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String draftId,  String name,  int? plannedRestSeconds,  String? notes,  String? videoUrl,  List<PlanDraftSet> sets,  List<PlanParseWarning> warnings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanDraftExercise() when $default != null:
return $default(_that.draftId,_that.name,_that.plannedRestSeconds,_that.notes,_that.videoUrl,_that.sets,_that.warnings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String draftId,  String name,  int? plannedRestSeconds,  String? notes,  String? videoUrl,  List<PlanDraftSet> sets,  List<PlanParseWarning> warnings)  $default,) {final _that = this;
switch (_that) {
case _PlanDraftExercise():
return $default(_that.draftId,_that.name,_that.plannedRestSeconds,_that.notes,_that.videoUrl,_that.sets,_that.warnings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String draftId,  String name,  int? plannedRestSeconds,  String? notes,  String? videoUrl,  List<PlanDraftSet> sets,  List<PlanParseWarning> warnings)?  $default,) {final _that = this;
switch (_that) {
case _PlanDraftExercise() when $default != null:
return $default(_that.draftId,_that.name,_that.plannedRestSeconds,_that.notes,_that.videoUrl,_that.sets,_that.warnings);case _:
  return null;

}
}

}

/// @nodoc


class _PlanDraftExercise implements PlanDraftExercise {
  const _PlanDraftExercise({required this.draftId, required this.name, required this.plannedRestSeconds, required this.notes, required this.videoUrl, required final  List<PlanDraftSet> sets, required final  List<PlanParseWarning> warnings}): _sets = sets,_warnings = warnings;
  

@override final  String draftId;
@override final  String name;
@override final  int? plannedRestSeconds;
@override final  String? notes;
@override final  String? videoUrl;
 final  List<PlanDraftSet> _sets;
@override List<PlanDraftSet> get sets {
  if (_sets is EqualUnmodifiableListView) return _sets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sets);
}

 final  List<PlanParseWarning> _warnings;
@override List<PlanParseWarning> get warnings {
  if (_warnings is EqualUnmodifiableListView) return _warnings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_warnings);
}


/// Create a copy of PlanDraftExercise
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanDraftExerciseCopyWith<_PlanDraftExercise> get copyWith => __$PlanDraftExerciseCopyWithImpl<_PlanDraftExercise>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanDraftExercise&&(identical(other.draftId, draftId) || other.draftId == draftId)&&(identical(other.name, name) || other.name == name)&&(identical(other.plannedRestSeconds, plannedRestSeconds) || other.plannedRestSeconds == plannedRestSeconds)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&const DeepCollectionEquality().equals(other._sets, _sets)&&const DeepCollectionEquality().equals(other._warnings, _warnings));
}


@override
int get hashCode => Object.hash(runtimeType,draftId,name,plannedRestSeconds,notes,videoUrl,const DeepCollectionEquality().hash(_sets),const DeepCollectionEquality().hash(_warnings));

@override
String toString() {
  return 'PlanDraftExercise(draftId: $draftId, name: $name, plannedRestSeconds: $plannedRestSeconds, notes: $notes, videoUrl: $videoUrl, sets: $sets, warnings: $warnings)';
}


}

/// @nodoc
abstract mixin class _$PlanDraftExerciseCopyWith<$Res> implements $PlanDraftExerciseCopyWith<$Res> {
  factory _$PlanDraftExerciseCopyWith(_PlanDraftExercise value, $Res Function(_PlanDraftExercise) _then) = __$PlanDraftExerciseCopyWithImpl;
@override @useResult
$Res call({
 String draftId, String name, int? plannedRestSeconds, String? notes, String? videoUrl, List<PlanDraftSet> sets, List<PlanParseWarning> warnings
});




}
/// @nodoc
class __$PlanDraftExerciseCopyWithImpl<$Res>
    implements _$PlanDraftExerciseCopyWith<$Res> {
  __$PlanDraftExerciseCopyWithImpl(this._self, this._then);

  final _PlanDraftExercise _self;
  final $Res Function(_PlanDraftExercise) _then;

/// Create a copy of PlanDraftExercise
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draftId = null,Object? name = null,Object? plannedRestSeconds = freezed,Object? notes = freezed,Object? videoUrl = freezed,Object? sets = null,Object? warnings = null,}) {
  return _then(_PlanDraftExercise(
draftId: null == draftId ? _self.draftId : draftId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,plannedRestSeconds: freezed == plannedRestSeconds ? _self.plannedRestSeconds : plannedRestSeconds // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,sets: null == sets ? _self._sets : sets // ignore: cast_nullable_to_non_nullable
as List<PlanDraftSet>,warnings: null == warnings ? _self._warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<PlanParseWarning>,
  ));
}


}

/// @nodoc
mixin _$PlanDraftSet {

 int get count;
/// Create a copy of PlanDraftSet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanDraftSetCopyWith<PlanDraftSet> get copyWith => _$PlanDraftSetCopyWithImpl<PlanDraftSet>(this as PlanDraftSet, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanDraftSet&&(identical(other.count, count) || other.count == count));
}


@override
int get hashCode => Object.hash(runtimeType,count);

@override
String toString() {
  return 'PlanDraftSet(count: $count)';
}


}

/// @nodoc
abstract mixin class $PlanDraftSetCopyWith<$Res>  {
  factory $PlanDraftSetCopyWith(PlanDraftSet value, $Res Function(PlanDraftSet) _then) = _$PlanDraftSetCopyWithImpl;
@useResult
$Res call({
 int count
});




}
/// @nodoc
class _$PlanDraftSetCopyWithImpl<$Res>
    implements $PlanDraftSetCopyWith<$Res> {
  _$PlanDraftSetCopyWithImpl(this._self, this._then);

  final PlanDraftSet _self;
  final $Res Function(PlanDraftSet) _then;

/// Create a copy of PlanDraftSet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? count = null,}) {
  return _then(_self.copyWith(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanDraftSet].
extension PlanDraftSetPatterns on PlanDraftSet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlanDraftSetRepBased value)?  repBased,TResult Function( PlanDraftSetTimeBased value)?  timeBased,TResult Function( PlanDraftSetBodyweight value)?  bodyweight,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlanDraftSetRepBased() when repBased != null:
return repBased(_that);case PlanDraftSetTimeBased() when timeBased != null:
return timeBased(_that);case PlanDraftSetBodyweight() when bodyweight != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlanDraftSetRepBased value)  repBased,required TResult Function( PlanDraftSetTimeBased value)  timeBased,required TResult Function( PlanDraftSetBodyweight value)  bodyweight,}){
final _that = this;
switch (_that) {
case PlanDraftSetRepBased():
return repBased(_that);case PlanDraftSetTimeBased():
return timeBased(_that);case PlanDraftSetBodyweight():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlanDraftSetRepBased value)?  repBased,TResult? Function( PlanDraftSetTimeBased value)?  timeBased,TResult? Function( PlanDraftSetBodyweight value)?  bodyweight,}){
final _that = this;
switch (_that) {
case PlanDraftSetRepBased() when repBased != null:
return repBased(_that);case PlanDraftSetTimeBased() when timeBased != null:
return timeBased(_that);case PlanDraftSetBodyweight() when bodyweight != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int count,  RepTarget repTarget,  double weightKg)?  repBased,TResult Function( int count,  int durationSeconds,  double? weightKg)?  timeBased,TResult Function( int count,  RepTarget repTarget)?  bodyweight,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PlanDraftSetRepBased() when repBased != null:
return repBased(_that.count,_that.repTarget,_that.weightKg);case PlanDraftSetTimeBased() when timeBased != null:
return timeBased(_that.count,_that.durationSeconds,_that.weightKg);case PlanDraftSetBodyweight() when bodyweight != null:
return bodyweight(_that.count,_that.repTarget);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int count,  RepTarget repTarget,  double weightKg)  repBased,required TResult Function( int count,  int durationSeconds,  double? weightKg)  timeBased,required TResult Function( int count,  RepTarget repTarget)  bodyweight,}) {final _that = this;
switch (_that) {
case PlanDraftSetRepBased():
return repBased(_that.count,_that.repTarget,_that.weightKg);case PlanDraftSetTimeBased():
return timeBased(_that.count,_that.durationSeconds,_that.weightKg);case PlanDraftSetBodyweight():
return bodyweight(_that.count,_that.repTarget);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int count,  RepTarget repTarget,  double weightKg)?  repBased,TResult? Function( int count,  int durationSeconds,  double? weightKg)?  timeBased,TResult? Function( int count,  RepTarget repTarget)?  bodyweight,}) {final _that = this;
switch (_that) {
case PlanDraftSetRepBased() when repBased != null:
return repBased(_that.count,_that.repTarget,_that.weightKg);case PlanDraftSetTimeBased() when timeBased != null:
return timeBased(_that.count,_that.durationSeconds,_that.weightKg);case PlanDraftSetBodyweight() when bodyweight != null:
return bodyweight(_that.count,_that.repTarget);case _:
  return null;

}
}

}

/// @nodoc


class PlanDraftSetRepBased implements PlanDraftSet {
  const PlanDraftSetRepBased({required this.count, required this.repTarget, required this.weightKg});
  

@override final  int count;
 final  RepTarget repTarget;
 final  double weightKg;

/// Create a copy of PlanDraftSet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanDraftSetRepBasedCopyWith<PlanDraftSetRepBased> get copyWith => _$PlanDraftSetRepBasedCopyWithImpl<PlanDraftSetRepBased>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanDraftSetRepBased&&(identical(other.count, count) || other.count == count)&&(identical(other.repTarget, repTarget) || other.repTarget == repTarget)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg));
}


@override
int get hashCode => Object.hash(runtimeType,count,repTarget,weightKg);

@override
String toString() {
  return 'PlanDraftSet.repBased(count: $count, repTarget: $repTarget, weightKg: $weightKg)';
}


}

/// @nodoc
abstract mixin class $PlanDraftSetRepBasedCopyWith<$Res> implements $PlanDraftSetCopyWith<$Res> {
  factory $PlanDraftSetRepBasedCopyWith(PlanDraftSetRepBased value, $Res Function(PlanDraftSetRepBased) _then) = _$PlanDraftSetRepBasedCopyWithImpl;
@override @useResult
$Res call({
 int count, RepTarget repTarget, double weightKg
});


$RepTargetCopyWith<$Res> get repTarget;

}
/// @nodoc
class _$PlanDraftSetRepBasedCopyWithImpl<$Res>
    implements $PlanDraftSetRepBasedCopyWith<$Res> {
  _$PlanDraftSetRepBasedCopyWithImpl(this._self, this._then);

  final PlanDraftSetRepBased _self;
  final $Res Function(PlanDraftSetRepBased) _then;

/// Create a copy of PlanDraftSet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? count = null,Object? repTarget = null,Object? weightKg = null,}) {
  return _then(PlanDraftSetRepBased(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,repTarget: null == repTarget ? _self.repTarget : repTarget // ignore: cast_nullable_to_non_nullable
as RepTarget,weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

/// Create a copy of PlanDraftSet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RepTargetCopyWith<$Res> get repTarget {
  
  return $RepTargetCopyWith<$Res>(_self.repTarget, (value) {
    return _then(_self.copyWith(repTarget: value));
  });
}
}

/// @nodoc


class PlanDraftSetTimeBased implements PlanDraftSet {
  const PlanDraftSetTimeBased({required this.count, required this.durationSeconds, this.weightKg});
  

@override final  int count;
 final  int durationSeconds;
 final  double? weightKg;

/// Create a copy of PlanDraftSet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanDraftSetTimeBasedCopyWith<PlanDraftSetTimeBased> get copyWith => _$PlanDraftSetTimeBasedCopyWithImpl<PlanDraftSetTimeBased>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanDraftSetTimeBased&&(identical(other.count, count) || other.count == count)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg));
}


@override
int get hashCode => Object.hash(runtimeType,count,durationSeconds,weightKg);

@override
String toString() {
  return 'PlanDraftSet.timeBased(count: $count, durationSeconds: $durationSeconds, weightKg: $weightKg)';
}


}

/// @nodoc
abstract mixin class $PlanDraftSetTimeBasedCopyWith<$Res> implements $PlanDraftSetCopyWith<$Res> {
  factory $PlanDraftSetTimeBasedCopyWith(PlanDraftSetTimeBased value, $Res Function(PlanDraftSetTimeBased) _then) = _$PlanDraftSetTimeBasedCopyWithImpl;
@override @useResult
$Res call({
 int count, int durationSeconds, double? weightKg
});




}
/// @nodoc
class _$PlanDraftSetTimeBasedCopyWithImpl<$Res>
    implements $PlanDraftSetTimeBasedCopyWith<$Res> {
  _$PlanDraftSetTimeBasedCopyWithImpl(this._self, this._then);

  final PlanDraftSetTimeBased _self;
  final $Res Function(PlanDraftSetTimeBased) _then;

/// Create a copy of PlanDraftSet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? count = null,Object? durationSeconds = null,Object? weightKg = freezed,}) {
  return _then(PlanDraftSetTimeBased(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

/// @nodoc


class PlanDraftSetBodyweight implements PlanDraftSet {
  const PlanDraftSetBodyweight({required this.count, required this.repTarget});
  

@override final  int count;
 final  RepTarget repTarget;

/// Create a copy of PlanDraftSet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanDraftSetBodyweightCopyWith<PlanDraftSetBodyweight> get copyWith => _$PlanDraftSetBodyweightCopyWithImpl<PlanDraftSetBodyweight>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanDraftSetBodyweight&&(identical(other.count, count) || other.count == count)&&(identical(other.repTarget, repTarget) || other.repTarget == repTarget));
}


@override
int get hashCode => Object.hash(runtimeType,count,repTarget);

@override
String toString() {
  return 'PlanDraftSet.bodyweight(count: $count, repTarget: $repTarget)';
}


}

/// @nodoc
abstract mixin class $PlanDraftSetBodyweightCopyWith<$Res> implements $PlanDraftSetCopyWith<$Res> {
  factory $PlanDraftSetBodyweightCopyWith(PlanDraftSetBodyweight value, $Res Function(PlanDraftSetBodyweight) _then) = _$PlanDraftSetBodyweightCopyWithImpl;
@override @useResult
$Res call({
 int count, RepTarget repTarget
});


$RepTargetCopyWith<$Res> get repTarget;

}
/// @nodoc
class _$PlanDraftSetBodyweightCopyWithImpl<$Res>
    implements $PlanDraftSetBodyweightCopyWith<$Res> {
  _$PlanDraftSetBodyweightCopyWithImpl(this._self, this._then);

  final PlanDraftSetBodyweight _self;
  final $Res Function(PlanDraftSetBodyweight) _then;

/// Create a copy of PlanDraftSet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? count = null,Object? repTarget = null,}) {
  return _then(PlanDraftSetBodyweight(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,repTarget: null == repTarget ? _self.repTarget : repTarget // ignore: cast_nullable_to_non_nullable
as RepTarget,
  ));
}

/// Create a copy of PlanDraftSet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RepTargetCopyWith<$Res> get repTarget {
  
  return $RepTargetCopyWith<$Res>(_self.repTarget, (value) {
    return _then(_self.copyWith(repTarget: value));
  });
}
}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_exercise.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionExercise {

 String get id; String get sessionId; int get position; String get plannedExerciseIdInSnapshot; ExerciseState get state; List<ExecutedSet> get executedSets; String? get supersetTag;/// Inline plan for an exercise added to the session after start — work not
/// present in the frozen day snapshot. When non-null, the session-exercise
/// resolves its planned data from here via [EffectiveExercises] rather than
/// the snapshot (its [plannedExerciseIdInSnapshot] is a synthetic id that is
/// never looked up). Null for every snapshot-backed exercise.
 AddedExercisePlan? get addedPlan; DateTime get createdAt; DateTime get updatedAt; int get schemaVersion;
/// Create a copy of SessionExercise
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionExerciseCopyWith<SessionExercise> get copyWith => _$SessionExerciseCopyWithImpl<SessionExercise>(this as SessionExercise, _$identity);

  /// Serializes this SessionExercise to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionExercise&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.position, position) || other.position == position)&&(identical(other.plannedExerciseIdInSnapshot, plannedExerciseIdInSnapshot) || other.plannedExerciseIdInSnapshot == plannedExerciseIdInSnapshot)&&(identical(other.state, state) || other.state == state)&&const DeepCollectionEquality().equals(other.executedSets, executedSets)&&(identical(other.supersetTag, supersetTag) || other.supersetTag == supersetTag)&&(identical(other.addedPlan, addedPlan) || other.addedPlan == addedPlan)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,position,plannedExerciseIdInSnapshot,state,const DeepCollectionEquality().hash(executedSets),supersetTag,addedPlan,createdAt,updatedAt,schemaVersion);

@override
String toString() {
  return 'SessionExercise(id: $id, sessionId: $sessionId, position: $position, plannedExerciseIdInSnapshot: $plannedExerciseIdInSnapshot, state: $state, executedSets: $executedSets, supersetTag: $supersetTag, addedPlan: $addedPlan, createdAt: $createdAt, updatedAt: $updatedAt, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class $SessionExerciseCopyWith<$Res>  {
  factory $SessionExerciseCopyWith(SessionExercise value, $Res Function(SessionExercise) _then) = _$SessionExerciseCopyWithImpl;
@useResult
$Res call({
 String id, String sessionId, int position, String plannedExerciseIdInSnapshot, ExerciseState state, List<ExecutedSet> executedSets, String? supersetTag, AddedExercisePlan? addedPlan, DateTime createdAt, DateTime updatedAt, int schemaVersion
});


$ExerciseStateCopyWith<$Res> get state;$AddedExercisePlanCopyWith<$Res>? get addedPlan;

}
/// @nodoc
class _$SessionExerciseCopyWithImpl<$Res>
    implements $SessionExerciseCopyWith<$Res> {
  _$SessionExerciseCopyWithImpl(this._self, this._then);

  final SessionExercise _self;
  final $Res Function(SessionExercise) _then;

/// Create a copy of SessionExercise
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionId = null,Object? position = null,Object? plannedExerciseIdInSnapshot = null,Object? state = null,Object? executedSets = null,Object? supersetTag = freezed,Object? addedPlan = freezed,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,plannedExerciseIdInSnapshot: null == plannedExerciseIdInSnapshot ? _self.plannedExerciseIdInSnapshot : plannedExerciseIdInSnapshot // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ExerciseState,executedSets: null == executedSets ? _self.executedSets : executedSets // ignore: cast_nullable_to_non_nullable
as List<ExecutedSet>,supersetTag: freezed == supersetTag ? _self.supersetTag : supersetTag // ignore: cast_nullable_to_non_nullable
as String?,addedPlan: freezed == addedPlan ? _self.addedPlan : addedPlan // ignore: cast_nullable_to_non_nullable
as AddedExercisePlan?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of SessionExercise
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseStateCopyWith<$Res> get state {
  
  return $ExerciseStateCopyWith<$Res>(_self.state, (value) {
    return _then(_self.copyWith(state: value));
  });
}/// Create a copy of SessionExercise
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AddedExercisePlanCopyWith<$Res>? get addedPlan {
    if (_self.addedPlan == null) {
    return null;
  }

  return $AddedExercisePlanCopyWith<$Res>(_self.addedPlan!, (value) {
    return _then(_self.copyWith(addedPlan: value));
  });
}
}


/// Adds pattern-matching-related methods to [SessionExercise].
extension SessionExercisePatterns on SessionExercise {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionExercise value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionExercise() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionExercise value)  $default,){
final _that = this;
switch (_that) {
case _SessionExercise():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionExercise value)?  $default,){
final _that = this;
switch (_that) {
case _SessionExercise() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sessionId,  int position,  String plannedExerciseIdInSnapshot,  ExerciseState state,  List<ExecutedSet> executedSets,  String? supersetTag,  AddedExercisePlan? addedPlan,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionExercise() when $default != null:
return $default(_that.id,_that.sessionId,_that.position,_that.plannedExerciseIdInSnapshot,_that.state,_that.executedSets,_that.supersetTag,_that.addedPlan,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sessionId,  int position,  String plannedExerciseIdInSnapshot,  ExerciseState state,  List<ExecutedSet> executedSets,  String? supersetTag,  AddedExercisePlan? addedPlan,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)  $default,) {final _that = this;
switch (_that) {
case _SessionExercise():
return $default(_that.id,_that.sessionId,_that.position,_that.plannedExerciseIdInSnapshot,_that.state,_that.executedSets,_that.supersetTag,_that.addedPlan,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sessionId,  int position,  String plannedExerciseIdInSnapshot,  ExerciseState state,  List<ExecutedSet> executedSets,  String? supersetTag,  AddedExercisePlan? addedPlan,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)?  $default,) {final _that = this;
switch (_that) {
case _SessionExercise() when $default != null:
return $default(_that.id,_that.sessionId,_that.position,_that.plannedExerciseIdInSnapshot,_that.state,_that.executedSets,_that.supersetTag,_that.addedPlan,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionExercise extends SessionExercise {
  const _SessionExercise({required this.id, required this.sessionId, required this.position, required this.plannedExerciseIdInSnapshot, required this.state, required final  List<ExecutedSet> executedSets, this.supersetTag, this.addedPlan, required this.createdAt, required this.updatedAt, required this.schemaVersion}): _executedSets = executedSets,super._();
  factory _SessionExercise.fromJson(Map<String, dynamic> json) => _$SessionExerciseFromJson(json);

@override final  String id;
@override final  String sessionId;
@override final  int position;
@override final  String plannedExerciseIdInSnapshot;
@override final  ExerciseState state;
 final  List<ExecutedSet> _executedSets;
@override List<ExecutedSet> get executedSets {
  if (_executedSets is EqualUnmodifiableListView) return _executedSets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_executedSets);
}

@override final  String? supersetTag;
/// Inline plan for an exercise added to the session after start — work not
/// present in the frozen day snapshot. When non-null, the session-exercise
/// resolves its planned data from here via [EffectiveExercises] rather than
/// the snapshot (its [plannedExerciseIdInSnapshot] is a synthetic id that is
/// never looked up). Null for every snapshot-backed exercise.
@override final  AddedExercisePlan? addedPlan;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  int schemaVersion;

/// Create a copy of SessionExercise
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionExerciseCopyWith<_SessionExercise> get copyWith => __$SessionExerciseCopyWithImpl<_SessionExercise>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionExerciseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionExercise&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.position, position) || other.position == position)&&(identical(other.plannedExerciseIdInSnapshot, plannedExerciseIdInSnapshot) || other.plannedExerciseIdInSnapshot == plannedExerciseIdInSnapshot)&&(identical(other.state, state) || other.state == state)&&const DeepCollectionEquality().equals(other._executedSets, _executedSets)&&(identical(other.supersetTag, supersetTag) || other.supersetTag == supersetTag)&&(identical(other.addedPlan, addedPlan) || other.addedPlan == addedPlan)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,position,plannedExerciseIdInSnapshot,state,const DeepCollectionEquality().hash(_executedSets),supersetTag,addedPlan,createdAt,updatedAt,schemaVersion);

@override
String toString() {
  return 'SessionExercise(id: $id, sessionId: $sessionId, position: $position, plannedExerciseIdInSnapshot: $plannedExerciseIdInSnapshot, state: $state, executedSets: $executedSets, supersetTag: $supersetTag, addedPlan: $addedPlan, createdAt: $createdAt, updatedAt: $updatedAt, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class _$SessionExerciseCopyWith<$Res> implements $SessionExerciseCopyWith<$Res> {
  factory _$SessionExerciseCopyWith(_SessionExercise value, $Res Function(_SessionExercise) _then) = __$SessionExerciseCopyWithImpl;
@override @useResult
$Res call({
 String id, String sessionId, int position, String plannedExerciseIdInSnapshot, ExerciseState state, List<ExecutedSet> executedSets, String? supersetTag, AddedExercisePlan? addedPlan, DateTime createdAt, DateTime updatedAt, int schemaVersion
});


@override $ExerciseStateCopyWith<$Res> get state;@override $AddedExercisePlanCopyWith<$Res>? get addedPlan;

}
/// @nodoc
class __$SessionExerciseCopyWithImpl<$Res>
    implements _$SessionExerciseCopyWith<$Res> {
  __$SessionExerciseCopyWithImpl(this._self, this._then);

  final _SessionExercise _self;
  final $Res Function(_SessionExercise) _then;

/// Create a copy of SessionExercise
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionId = null,Object? position = null,Object? plannedExerciseIdInSnapshot = null,Object? state = null,Object? executedSets = null,Object? supersetTag = freezed,Object? addedPlan = freezed,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,}) {
  return _then(_SessionExercise(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,plannedExerciseIdInSnapshot: null == plannedExerciseIdInSnapshot ? _self.plannedExerciseIdInSnapshot : plannedExerciseIdInSnapshot // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ExerciseState,executedSets: null == executedSets ? _self._executedSets : executedSets // ignore: cast_nullable_to_non_nullable
as List<ExecutedSet>,supersetTag: freezed == supersetTag ? _self.supersetTag : supersetTag // ignore: cast_nullable_to_non_nullable
as String?,addedPlan: freezed == addedPlan ? _self.addedPlan : addedPlan // ignore: cast_nullable_to_non_nullable
as AddedExercisePlan?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of SessionExercise
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseStateCopyWith<$Res> get state {
  
  return $ExerciseStateCopyWith<$Res>(_self.state, (value) {
    return _then(_self.copyWith(state: value));
  });
}/// Create a copy of SessionExercise
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AddedExercisePlanCopyWith<$Res>? get addedPlan {
    if (_self.addedPlan == null) {
    return null;
  }

  return $AddedExercisePlanCopyWith<$Res>(_self.addedPlan!, (value) {
    return _then(_self.copyWith(addedPlan: value));
  });
}
}

// dart format on

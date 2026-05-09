// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Session {

 String get id; String get workoutDayId; SessionSnapshot get snapshot; List<SessionExercise> get sessionExercises; List<SessionNote> get notes; List<ExtraWork> get extraWork; DateTime get startedAt; DateTime? get endedAt; DateTime get createdAt; DateTime get updatedAt; int get schemaVersion;
/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionCopyWith<Session> get copyWith => _$SessionCopyWithImpl<Session>(this as Session, _$identity);

  /// Serializes this Session to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Session&&(identical(other.id, id) || other.id == id)&&(identical(other.workoutDayId, workoutDayId) || other.workoutDayId == workoutDayId)&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&const DeepCollectionEquality().equals(other.sessionExercises, sessionExercises)&&const DeepCollectionEquality().equals(other.notes, notes)&&const DeepCollectionEquality().equals(other.extraWork, extraWork)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workoutDayId,snapshot,const DeepCollectionEquality().hash(sessionExercises),const DeepCollectionEquality().hash(notes),const DeepCollectionEquality().hash(extraWork),startedAt,endedAt,createdAt,updatedAt,schemaVersion);

@override
String toString() {
  return 'Session(id: $id, workoutDayId: $workoutDayId, snapshot: $snapshot, sessionExercises: $sessionExercises, notes: $notes, extraWork: $extraWork, startedAt: $startedAt, endedAt: $endedAt, createdAt: $createdAt, updatedAt: $updatedAt, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class $SessionCopyWith<$Res>  {
  factory $SessionCopyWith(Session value, $Res Function(Session) _then) = _$SessionCopyWithImpl;
@useResult
$Res call({
 String id, String workoutDayId, SessionSnapshot snapshot, List<SessionExercise> sessionExercises, List<SessionNote> notes, List<ExtraWork> extraWork, DateTime startedAt, DateTime? endedAt, DateTime createdAt, DateTime updatedAt, int schemaVersion
});


$SessionSnapshotCopyWith<$Res> get snapshot;

}
/// @nodoc
class _$SessionCopyWithImpl<$Res>
    implements $SessionCopyWith<$Res> {
  _$SessionCopyWithImpl(this._self, this._then);

  final Session _self;
  final $Res Function(Session) _then;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workoutDayId = null,Object? snapshot = null,Object? sessionExercises = null,Object? notes = null,Object? extraWork = null,Object? startedAt = null,Object? endedAt = freezed,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workoutDayId: null == workoutDayId ? _self.workoutDayId : workoutDayId // ignore: cast_nullable_to_non_nullable
as String,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as SessionSnapshot,sessionExercises: null == sessionExercises ? _self.sessionExercises : sessionExercises // ignore: cast_nullable_to_non_nullable
as List<SessionExercise>,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as List<SessionNote>,extraWork: null == extraWork ? _self.extraWork : extraWork // ignore: cast_nullable_to_non_nullable
as List<ExtraWork>,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionSnapshotCopyWith<$Res> get snapshot {
  
  return $SessionSnapshotCopyWith<$Res>(_self.snapshot, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}
}


/// Adds pattern-matching-related methods to [Session].
extension SessionPatterns on Session {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Session value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Session() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Session value)  $default,){
final _that = this;
switch (_that) {
case _Session():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Session value)?  $default,){
final _that = this;
switch (_that) {
case _Session() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workoutDayId,  SessionSnapshot snapshot,  List<SessionExercise> sessionExercises,  List<SessionNote> notes,  List<ExtraWork> extraWork,  DateTime startedAt,  DateTime? endedAt,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Session() when $default != null:
return $default(_that.id,_that.workoutDayId,_that.snapshot,_that.sessionExercises,_that.notes,_that.extraWork,_that.startedAt,_that.endedAt,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workoutDayId,  SessionSnapshot snapshot,  List<SessionExercise> sessionExercises,  List<SessionNote> notes,  List<ExtraWork> extraWork,  DateTime startedAt,  DateTime? endedAt,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)  $default,) {final _that = this;
switch (_that) {
case _Session():
return $default(_that.id,_that.workoutDayId,_that.snapshot,_that.sessionExercises,_that.notes,_that.extraWork,_that.startedAt,_that.endedAt,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workoutDayId,  SessionSnapshot snapshot,  List<SessionExercise> sessionExercises,  List<SessionNote> notes,  List<ExtraWork> extraWork,  DateTime startedAt,  DateTime? endedAt,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)?  $default,) {final _that = this;
switch (_that) {
case _Session() when $default != null:
return $default(_that.id,_that.workoutDayId,_that.snapshot,_that.sessionExercises,_that.notes,_that.extraWork,_that.startedAt,_that.endedAt,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Session extends Session {
  const _Session({required this.id, required this.workoutDayId, required this.snapshot, required final  List<SessionExercise> sessionExercises, required final  List<SessionNote> notes, required final  List<ExtraWork> extraWork, required this.startedAt, this.endedAt, required this.createdAt, required this.updatedAt, required this.schemaVersion}): _sessionExercises = sessionExercises,_notes = notes,_extraWork = extraWork,super._();
  factory _Session.fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);

@override final  String id;
@override final  String workoutDayId;
@override final  SessionSnapshot snapshot;
 final  List<SessionExercise> _sessionExercises;
@override List<SessionExercise> get sessionExercises {
  if (_sessionExercises is EqualUnmodifiableListView) return _sessionExercises;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sessionExercises);
}

 final  List<SessionNote> _notes;
@override List<SessionNote> get notes {
  if (_notes is EqualUnmodifiableListView) return _notes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notes);
}

 final  List<ExtraWork> _extraWork;
@override List<ExtraWork> get extraWork {
  if (_extraWork is EqualUnmodifiableListView) return _extraWork;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_extraWork);
}

@override final  DateTime startedAt;
@override final  DateTime? endedAt;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  int schemaVersion;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionCopyWith<_Session> get copyWith => __$SessionCopyWithImpl<_Session>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Session&&(identical(other.id, id) || other.id == id)&&(identical(other.workoutDayId, workoutDayId) || other.workoutDayId == workoutDayId)&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&const DeepCollectionEquality().equals(other._sessionExercises, _sessionExercises)&&const DeepCollectionEquality().equals(other._notes, _notes)&&const DeepCollectionEquality().equals(other._extraWork, _extraWork)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workoutDayId,snapshot,const DeepCollectionEquality().hash(_sessionExercises),const DeepCollectionEquality().hash(_notes),const DeepCollectionEquality().hash(_extraWork),startedAt,endedAt,createdAt,updatedAt,schemaVersion);

@override
String toString() {
  return 'Session(id: $id, workoutDayId: $workoutDayId, snapshot: $snapshot, sessionExercises: $sessionExercises, notes: $notes, extraWork: $extraWork, startedAt: $startedAt, endedAt: $endedAt, createdAt: $createdAt, updatedAt: $updatedAt, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class _$SessionCopyWith<$Res> implements $SessionCopyWith<$Res> {
  factory _$SessionCopyWith(_Session value, $Res Function(_Session) _then) = __$SessionCopyWithImpl;
@override @useResult
$Res call({
 String id, String workoutDayId, SessionSnapshot snapshot, List<SessionExercise> sessionExercises, List<SessionNote> notes, List<ExtraWork> extraWork, DateTime startedAt, DateTime? endedAt, DateTime createdAt, DateTime updatedAt, int schemaVersion
});


@override $SessionSnapshotCopyWith<$Res> get snapshot;

}
/// @nodoc
class __$SessionCopyWithImpl<$Res>
    implements _$SessionCopyWith<$Res> {
  __$SessionCopyWithImpl(this._self, this._then);

  final _Session _self;
  final $Res Function(_Session) _then;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workoutDayId = null,Object? snapshot = null,Object? sessionExercises = null,Object? notes = null,Object? extraWork = null,Object? startedAt = null,Object? endedAt = freezed,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,}) {
  return _then(_Session(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workoutDayId: null == workoutDayId ? _self.workoutDayId : workoutDayId // ignore: cast_nullable_to_non_nullable
as String,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as SessionSnapshot,sessionExercises: null == sessionExercises ? _self._sessionExercises : sessionExercises // ignore: cast_nullable_to_non_nullable
as List<SessionExercise>,notes: null == notes ? _self._notes : notes // ignore: cast_nullable_to_non_nullable
as List<SessionNote>,extraWork: null == extraWork ? _self._extraWork : extraWork // ignore: cast_nullable_to_non_nullable
as List<ExtraWork>,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionSnapshotCopyWith<$Res> get snapshot {
  
  return $SessionSnapshotCopyWith<$Res>(_self.snapshot, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}
}

// dart format on

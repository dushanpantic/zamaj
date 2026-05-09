// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionSnapshot {

 WorkoutDay get workoutDay; String get canonicalJson; String get sha256Hash; DateTime get capturedAt; int get schemaVersion;
/// Create a copy of SessionSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionSnapshotCopyWith<SessionSnapshot> get copyWith => _$SessionSnapshotCopyWithImpl<SessionSnapshot>(this as SessionSnapshot, _$identity);

  /// Serializes this SessionSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionSnapshot&&(identical(other.workoutDay, workoutDay) || other.workoutDay == workoutDay)&&(identical(other.canonicalJson, canonicalJson) || other.canonicalJson == canonicalJson)&&(identical(other.sha256Hash, sha256Hash) || other.sha256Hash == sha256Hash)&&(identical(other.capturedAt, capturedAt) || other.capturedAt == capturedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workoutDay,canonicalJson,sha256Hash,capturedAt,schemaVersion);

@override
String toString() {
  return 'SessionSnapshot(workoutDay: $workoutDay, canonicalJson: $canonicalJson, sha256Hash: $sha256Hash, capturedAt: $capturedAt, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class $SessionSnapshotCopyWith<$Res>  {
  factory $SessionSnapshotCopyWith(SessionSnapshot value, $Res Function(SessionSnapshot) _then) = _$SessionSnapshotCopyWithImpl;
@useResult
$Res call({
 WorkoutDay workoutDay, String canonicalJson, String sha256Hash, DateTime capturedAt, int schemaVersion
});


$WorkoutDayCopyWith<$Res> get workoutDay;

}
/// @nodoc
class _$SessionSnapshotCopyWithImpl<$Res>
    implements $SessionSnapshotCopyWith<$Res> {
  _$SessionSnapshotCopyWithImpl(this._self, this._then);

  final SessionSnapshot _self;
  final $Res Function(SessionSnapshot) _then;

/// Create a copy of SessionSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workoutDay = null,Object? canonicalJson = null,Object? sha256Hash = null,Object? capturedAt = null,Object? schemaVersion = null,}) {
  return _then(_self.copyWith(
workoutDay: null == workoutDay ? _self.workoutDay : workoutDay // ignore: cast_nullable_to_non_nullable
as WorkoutDay,canonicalJson: null == canonicalJson ? _self.canonicalJson : canonicalJson // ignore: cast_nullable_to_non_nullable
as String,sha256Hash: null == sha256Hash ? _self.sha256Hash : sha256Hash // ignore: cast_nullable_to_non_nullable
as String,capturedAt: null == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of SessionSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkoutDayCopyWith<$Res> get workoutDay {
  
  return $WorkoutDayCopyWith<$Res>(_self.workoutDay, (value) {
    return _then(_self.copyWith(workoutDay: value));
  });
}
}


/// Adds pattern-matching-related methods to [SessionSnapshot].
extension SessionSnapshotPatterns on SessionSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _SessionSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _SessionSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorkoutDay workoutDay,  String canonicalJson,  String sha256Hash,  DateTime capturedAt,  int schemaVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionSnapshot() when $default != null:
return $default(_that.workoutDay,_that.canonicalJson,_that.sha256Hash,_that.capturedAt,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorkoutDay workoutDay,  String canonicalJson,  String sha256Hash,  DateTime capturedAt,  int schemaVersion)  $default,) {final _that = this;
switch (_that) {
case _SessionSnapshot():
return $default(_that.workoutDay,_that.canonicalJson,_that.sha256Hash,_that.capturedAt,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorkoutDay workoutDay,  String canonicalJson,  String sha256Hash,  DateTime capturedAt,  int schemaVersion)?  $default,) {final _that = this;
switch (_that) {
case _SessionSnapshot() when $default != null:
return $default(_that.workoutDay,_that.canonicalJson,_that.sha256Hash,_that.capturedAt,_that.schemaVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionSnapshot extends SessionSnapshot {
   _SessionSnapshot({required this.workoutDay, required this.canonicalJson, required this.sha256Hash, required this.capturedAt, required this.schemaVersion}): super._();
  factory _SessionSnapshot.fromJson(Map<String, dynamic> json) => _$SessionSnapshotFromJson(json);

@override final  WorkoutDay workoutDay;
@override final  String canonicalJson;
@override final  String sha256Hash;
@override final  DateTime capturedAt;
@override final  int schemaVersion;

/// Create a copy of SessionSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionSnapshotCopyWith<_SessionSnapshot> get copyWith => __$SessionSnapshotCopyWithImpl<_SessionSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionSnapshot&&(identical(other.workoutDay, workoutDay) || other.workoutDay == workoutDay)&&(identical(other.canonicalJson, canonicalJson) || other.canonicalJson == canonicalJson)&&(identical(other.sha256Hash, sha256Hash) || other.sha256Hash == sha256Hash)&&(identical(other.capturedAt, capturedAt) || other.capturedAt == capturedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workoutDay,canonicalJson,sha256Hash,capturedAt,schemaVersion);

@override
String toString() {
  return 'SessionSnapshot(workoutDay: $workoutDay, canonicalJson: $canonicalJson, sha256Hash: $sha256Hash, capturedAt: $capturedAt, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class _$SessionSnapshotCopyWith<$Res> implements $SessionSnapshotCopyWith<$Res> {
  factory _$SessionSnapshotCopyWith(_SessionSnapshot value, $Res Function(_SessionSnapshot) _then) = __$SessionSnapshotCopyWithImpl;
@override @useResult
$Res call({
 WorkoutDay workoutDay, String canonicalJson, String sha256Hash, DateTime capturedAt, int schemaVersion
});


@override $WorkoutDayCopyWith<$Res> get workoutDay;

}
/// @nodoc
class __$SessionSnapshotCopyWithImpl<$Res>
    implements _$SessionSnapshotCopyWith<$Res> {
  __$SessionSnapshotCopyWithImpl(this._self, this._then);

  final _SessionSnapshot _self;
  final $Res Function(_SessionSnapshot) _then;

/// Create a copy of SessionSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workoutDay = null,Object? canonicalJson = null,Object? sha256Hash = null,Object? capturedAt = null,Object? schemaVersion = null,}) {
  return _then(_SessionSnapshot(
workoutDay: null == workoutDay ? _self.workoutDay : workoutDay // ignore: cast_nullable_to_non_nullable
as WorkoutDay,canonicalJson: null == canonicalJson ? _self.canonicalJson : canonicalJson // ignore: cast_nullable_to_non_nullable
as String,sha256Hash: null == sha256Hash ? _self.sha256Hash : sha256Hash // ignore: cast_nullable_to_non_nullable
as String,capturedAt: null == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of SessionSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkoutDayCopyWith<$Res> get workoutDay {
  
  return $WorkoutDayCopyWith<$Res>(_self.workoutDay, (value) {
    return _then(_self.copyWith(workoutDay: value));
  });
}
}

// dart format on

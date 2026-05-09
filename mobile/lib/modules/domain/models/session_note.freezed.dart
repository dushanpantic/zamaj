// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_note.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionNote {

 String get id; String get sessionId; String get body; DateTime get createdAt; DateTime get updatedAt; int get schemaVersion;
/// Create a copy of SessionNote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionNoteCopyWith<SessionNote> get copyWith => _$SessionNoteCopyWithImpl<SessionNote>(this as SessionNote, _$identity);

  /// Serializes this SessionNote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionNote&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,body,createdAt,updatedAt,schemaVersion);

@override
String toString() {
  return 'SessionNote(id: $id, sessionId: $sessionId, body: $body, createdAt: $createdAt, updatedAt: $updatedAt, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class $SessionNoteCopyWith<$Res>  {
  factory $SessionNoteCopyWith(SessionNote value, $Res Function(SessionNote) _then) = _$SessionNoteCopyWithImpl;
@useResult
$Res call({
 String id, String sessionId, String body, DateTime createdAt, DateTime updatedAt, int schemaVersion
});




}
/// @nodoc
class _$SessionNoteCopyWithImpl<$Res>
    implements $SessionNoteCopyWith<$Res> {
  _$SessionNoteCopyWithImpl(this._self, this._then);

  final SessionNote _self;
  final $Res Function(SessionNote) _then;

/// Create a copy of SessionNote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionId = null,Object? body = null,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionNote].
extension SessionNotePatterns on SessionNote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionNote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionNote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionNote value)  $default,){
final _that = this;
switch (_that) {
case _SessionNote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionNote value)?  $default,){
final _that = this;
switch (_that) {
case _SessionNote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sessionId,  String body,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionNote() when $default != null:
return $default(_that.id,_that.sessionId,_that.body,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sessionId,  String body,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)  $default,) {final _that = this;
switch (_that) {
case _SessionNote():
return $default(_that.id,_that.sessionId,_that.body,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sessionId,  String body,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)?  $default,) {final _that = this;
switch (_that) {
case _SessionNote() when $default != null:
return $default(_that.id,_that.sessionId,_that.body,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionNote extends SessionNote {
  const _SessionNote({required this.id, required this.sessionId, required this.body, required this.createdAt, required this.updatedAt, required this.schemaVersion}): super._();
  factory _SessionNote.fromJson(Map<String, dynamic> json) => _$SessionNoteFromJson(json);

@override final  String id;
@override final  String sessionId;
@override final  String body;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  int schemaVersion;

/// Create a copy of SessionNote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionNoteCopyWith<_SessionNote> get copyWith => __$SessionNoteCopyWithImpl<_SessionNote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionNoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionNote&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,body,createdAt,updatedAt,schemaVersion);

@override
String toString() {
  return 'SessionNote(id: $id, sessionId: $sessionId, body: $body, createdAt: $createdAt, updatedAt: $updatedAt, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class _$SessionNoteCopyWith<$Res> implements $SessionNoteCopyWith<$Res> {
  factory _$SessionNoteCopyWith(_SessionNote value, $Res Function(_SessionNote) _then) = __$SessionNoteCopyWithImpl;
@override @useResult
$Res call({
 String id, String sessionId, String body, DateTime createdAt, DateTime updatedAt, int schemaVersion
});




}
/// @nodoc
class __$SessionNoteCopyWithImpl<$Res>
    implements _$SessionNoteCopyWith<$Res> {
  __$SessionNoteCopyWithImpl(this._self, this._then);

  final _SessionNote _self;
  final $Res Function(_SessionNote) _then;

/// Create a copy of SessionNote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionId = null,Object? body = null,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,}) {
  return _then(_SessionNote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

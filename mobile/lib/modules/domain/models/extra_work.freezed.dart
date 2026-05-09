// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'extra_work.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExtraWork {

 String get id; String get sessionId; int get position; String get body; DateTime get createdAt; DateTime get updatedAt; int get schemaVersion;
/// Create a copy of ExtraWork
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExtraWorkCopyWith<ExtraWork> get copyWith => _$ExtraWorkCopyWithImpl<ExtraWork>(this as ExtraWork, _$identity);

  /// Serializes this ExtraWork to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExtraWork&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.position, position) || other.position == position)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,position,body,createdAt,updatedAt,schemaVersion);

@override
String toString() {
  return 'ExtraWork(id: $id, sessionId: $sessionId, position: $position, body: $body, createdAt: $createdAt, updatedAt: $updatedAt, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class $ExtraWorkCopyWith<$Res>  {
  factory $ExtraWorkCopyWith(ExtraWork value, $Res Function(ExtraWork) _then) = _$ExtraWorkCopyWithImpl;
@useResult
$Res call({
 String id, String sessionId, int position, String body, DateTime createdAt, DateTime updatedAt, int schemaVersion
});




}
/// @nodoc
class _$ExtraWorkCopyWithImpl<$Res>
    implements $ExtraWorkCopyWith<$Res> {
  _$ExtraWorkCopyWithImpl(this._self, this._then);

  final ExtraWork _self;
  final $Res Function(ExtraWork) _then;

/// Create a copy of ExtraWork
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionId = null,Object? position = null,Object? body = null,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ExtraWork].
extension ExtraWorkPatterns on ExtraWork {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExtraWork value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExtraWork() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExtraWork value)  $default,){
final _that = this;
switch (_that) {
case _ExtraWork():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExtraWork value)?  $default,){
final _that = this;
switch (_that) {
case _ExtraWork() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sessionId,  int position,  String body,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExtraWork() when $default != null:
return $default(_that.id,_that.sessionId,_that.position,_that.body,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sessionId,  int position,  String body,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)  $default,) {final _that = this;
switch (_that) {
case _ExtraWork():
return $default(_that.id,_that.sessionId,_that.position,_that.body,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sessionId,  int position,  String body,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)?  $default,) {final _that = this;
switch (_that) {
case _ExtraWork() when $default != null:
return $default(_that.id,_that.sessionId,_that.position,_that.body,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExtraWork extends ExtraWork {
  const _ExtraWork({required this.id, required this.sessionId, required this.position, required this.body, required this.createdAt, required this.updatedAt, required this.schemaVersion}): super._();
  factory _ExtraWork.fromJson(Map<String, dynamic> json) => _$ExtraWorkFromJson(json);

@override final  String id;
@override final  String sessionId;
@override final  int position;
@override final  String body;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  int schemaVersion;

/// Create a copy of ExtraWork
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExtraWorkCopyWith<_ExtraWork> get copyWith => __$ExtraWorkCopyWithImpl<_ExtraWork>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExtraWorkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExtraWork&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.position, position) || other.position == position)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,position,body,createdAt,updatedAt,schemaVersion);

@override
String toString() {
  return 'ExtraWork(id: $id, sessionId: $sessionId, position: $position, body: $body, createdAt: $createdAt, updatedAt: $updatedAt, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class _$ExtraWorkCopyWith<$Res> implements $ExtraWorkCopyWith<$Res> {
  factory _$ExtraWorkCopyWith(_ExtraWork value, $Res Function(_ExtraWork) _then) = __$ExtraWorkCopyWithImpl;
@override @useResult
$Res call({
 String id, String sessionId, int position, String body, DateTime createdAt, DateTime updatedAt, int schemaVersion
});




}
/// @nodoc
class __$ExtraWorkCopyWithImpl<$Res>
    implements _$ExtraWorkCopyWith<$Res> {
  __$ExtraWorkCopyWithImpl(this._self, this._then);

  final _ExtraWork _self;
  final $Res Function(_ExtraWork) _then;

/// Create a copy of ExtraWork
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionId = null,Object? position = null,Object? body = null,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,}) {
  return _then(_ExtraWork(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

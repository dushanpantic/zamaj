// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recent_sessions_args.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecentSessionsArgs {

 String get programId;
/// Create a copy of RecentSessionsArgs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecentSessionsArgsCopyWith<RecentSessionsArgs> get copyWith => _$RecentSessionsArgsCopyWithImpl<RecentSessionsArgs>(this as RecentSessionsArgs, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecentSessionsArgs&&(identical(other.programId, programId) || other.programId == programId));
}


@override
int get hashCode => Object.hash(runtimeType,programId);

@override
String toString() {
  return 'RecentSessionsArgs(programId: $programId)';
}


}

/// @nodoc
abstract mixin class $RecentSessionsArgsCopyWith<$Res>  {
  factory $RecentSessionsArgsCopyWith(RecentSessionsArgs value, $Res Function(RecentSessionsArgs) _then) = _$RecentSessionsArgsCopyWithImpl;
@useResult
$Res call({
 String programId
});




}
/// @nodoc
class _$RecentSessionsArgsCopyWithImpl<$Res>
    implements $RecentSessionsArgsCopyWith<$Res> {
  _$RecentSessionsArgsCopyWithImpl(this._self, this._then);

  final RecentSessionsArgs _self;
  final $Res Function(RecentSessionsArgs) _then;

/// Create a copy of RecentSessionsArgs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? programId = null,}) {
  return _then(_self.copyWith(
programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RecentSessionsArgs].
extension RecentSessionsArgsPatterns on RecentSessionsArgs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecentSessionsArgs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecentSessionsArgs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecentSessionsArgs value)  $default,){
final _that = this;
switch (_that) {
case _RecentSessionsArgs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecentSessionsArgs value)?  $default,){
final _that = this;
switch (_that) {
case _RecentSessionsArgs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String programId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecentSessionsArgs() when $default != null:
return $default(_that.programId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String programId)  $default,) {final _that = this;
switch (_that) {
case _RecentSessionsArgs():
return $default(_that.programId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String programId)?  $default,) {final _that = this;
switch (_that) {
case _RecentSessionsArgs() when $default != null:
return $default(_that.programId);case _:
  return null;

}
}

}

/// @nodoc


class _RecentSessionsArgs implements RecentSessionsArgs {
  const _RecentSessionsArgs({required this.programId});
  

@override final  String programId;

/// Create a copy of RecentSessionsArgs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecentSessionsArgsCopyWith<_RecentSessionsArgs> get copyWith => __$RecentSessionsArgsCopyWithImpl<_RecentSessionsArgs>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecentSessionsArgs&&(identical(other.programId, programId) || other.programId == programId));
}


@override
int get hashCode => Object.hash(runtimeType,programId);

@override
String toString() {
  return 'RecentSessionsArgs(programId: $programId)';
}


}

/// @nodoc
abstract mixin class _$RecentSessionsArgsCopyWith<$Res> implements $RecentSessionsArgsCopyWith<$Res> {
  factory _$RecentSessionsArgsCopyWith(_RecentSessionsArgs value, $Res Function(_RecentSessionsArgs) _then) = __$RecentSessionsArgsCopyWithImpl;
@override @useResult
$Res call({
 String programId
});




}
/// @nodoc
class __$RecentSessionsArgsCopyWithImpl<$Res>
    implements _$RecentSessionsArgsCopyWith<$Res> {
  __$RecentSessionsArgsCopyWithImpl(this._self, this._then);

  final _RecentSessionsArgs _self;
  final $Res Function(_RecentSessionsArgs) _then;

/// Create a copy of RecentSessionsArgs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? programId = null,}) {
  return _then(_RecentSessionsArgs(
programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

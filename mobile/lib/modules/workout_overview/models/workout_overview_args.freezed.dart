// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_overview_args.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkoutOverviewArgs {

 String get sessionId;
/// Create a copy of WorkoutOverviewArgs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutOverviewArgsCopyWith<WorkoutOverviewArgs> get copyWith => _$WorkoutOverviewArgsCopyWithImpl<WorkoutOverviewArgs>(this as WorkoutOverviewArgs, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutOverviewArgs&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId);

@override
String toString() {
  return 'WorkoutOverviewArgs(sessionId: $sessionId)';
}


}

/// @nodoc
abstract mixin class $WorkoutOverviewArgsCopyWith<$Res>  {
  factory $WorkoutOverviewArgsCopyWith(WorkoutOverviewArgs value, $Res Function(WorkoutOverviewArgs) _then) = _$WorkoutOverviewArgsCopyWithImpl;
@useResult
$Res call({
 String sessionId
});




}
/// @nodoc
class _$WorkoutOverviewArgsCopyWithImpl<$Res>
    implements $WorkoutOverviewArgsCopyWith<$Res> {
  _$WorkoutOverviewArgsCopyWithImpl(this._self, this._then);

  final WorkoutOverviewArgs _self;
  final $Res Function(WorkoutOverviewArgs) _then;

/// Create a copy of WorkoutOverviewArgs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutOverviewArgs].
extension WorkoutOverviewArgsPatterns on WorkoutOverviewArgs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutOverviewArgs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutOverviewArgs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutOverviewArgs value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutOverviewArgs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutOverviewArgs value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutOverviewArgs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutOverviewArgs() when $default != null:
return $default(_that.sessionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId)  $default,) {final _that = this;
switch (_that) {
case _WorkoutOverviewArgs():
return $default(_that.sessionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutOverviewArgs() when $default != null:
return $default(_that.sessionId);case _:
  return null;

}
}

}

/// @nodoc


class _WorkoutOverviewArgs implements WorkoutOverviewArgs {
  const _WorkoutOverviewArgs({required this.sessionId});
  

@override final  String sessionId;

/// Create a copy of WorkoutOverviewArgs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutOverviewArgsCopyWith<_WorkoutOverviewArgs> get copyWith => __$WorkoutOverviewArgsCopyWithImpl<_WorkoutOverviewArgs>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutOverviewArgs&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId);

@override
String toString() {
  return 'WorkoutOverviewArgs(sessionId: $sessionId)';
}


}

/// @nodoc
abstract mixin class _$WorkoutOverviewArgsCopyWith<$Res> implements $WorkoutOverviewArgsCopyWith<$Res> {
  factory _$WorkoutOverviewArgsCopyWith(_WorkoutOverviewArgs value, $Res Function(_WorkoutOverviewArgs) _then) = __$WorkoutOverviewArgsCopyWithImpl;
@override @useResult
$Res call({
 String sessionId
});




}
/// @nodoc
class __$WorkoutOverviewArgsCopyWithImpl<$Res>
    implements _$WorkoutOverviewArgsCopyWith<$Res> {
  __$WorkoutOverviewArgsCopyWithImpl(this._self, this._then);

  final _WorkoutOverviewArgs _self;
  final $Res Function(_WorkoutOverviewArgs) _then;

/// Create a copy of WorkoutOverviewArgs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,}) {
  return _then(_WorkoutOverviewArgs(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'log_target.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LogTarget {

 String get sessionExerciseId; int get plannedSetIndex;
/// Create a copy of LogTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LogTargetCopyWith<LogTarget> get copyWith => _$LogTargetCopyWithImpl<LogTarget>(this as LogTarget, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogTarget&&(identical(other.sessionExerciseId, sessionExerciseId) || other.sessionExerciseId == sessionExerciseId)&&(identical(other.plannedSetIndex, plannedSetIndex) || other.plannedSetIndex == plannedSetIndex));
}


@override
int get hashCode => Object.hash(runtimeType,sessionExerciseId,plannedSetIndex);

@override
String toString() {
  return 'LogTarget(sessionExerciseId: $sessionExerciseId, plannedSetIndex: $plannedSetIndex)';
}


}

/// @nodoc
abstract mixin class $LogTargetCopyWith<$Res>  {
  factory $LogTargetCopyWith(LogTarget value, $Res Function(LogTarget) _then) = _$LogTargetCopyWithImpl;
@useResult
$Res call({
 String sessionExerciseId, int plannedSetIndex
});




}
/// @nodoc
class _$LogTargetCopyWithImpl<$Res>
    implements $LogTargetCopyWith<$Res> {
  _$LogTargetCopyWithImpl(this._self, this._then);

  final LogTarget _self;
  final $Res Function(LogTarget) _then;

/// Create a copy of LogTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionExerciseId = null,Object? plannedSetIndex = null,}) {
  return _then(_self.copyWith(
sessionExerciseId: null == sessionExerciseId ? _self.sessionExerciseId : sessionExerciseId // ignore: cast_nullable_to_non_nullable
as String,plannedSetIndex: null == plannedSetIndex ? _self.plannedSetIndex : plannedSetIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LogTarget].
extension LogTargetPatterns on LogTarget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LogTarget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LogTarget() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LogTarget value)  $default,){
final _that = this;
switch (_that) {
case _LogTarget():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LogTarget value)?  $default,){
final _that = this;
switch (_that) {
case _LogTarget() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionExerciseId,  int plannedSetIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LogTarget() when $default != null:
return $default(_that.sessionExerciseId,_that.plannedSetIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionExerciseId,  int plannedSetIndex)  $default,) {final _that = this;
switch (_that) {
case _LogTarget():
return $default(_that.sessionExerciseId,_that.plannedSetIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionExerciseId,  int plannedSetIndex)?  $default,) {final _that = this;
switch (_that) {
case _LogTarget() when $default != null:
return $default(_that.sessionExerciseId,_that.plannedSetIndex);case _:
  return null;

}
}

}

/// @nodoc


class _LogTarget implements LogTarget {
  const _LogTarget({required this.sessionExerciseId, required this.plannedSetIndex});
  

@override final  String sessionExerciseId;
@override final  int plannedSetIndex;

/// Create a copy of LogTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LogTargetCopyWith<_LogTarget> get copyWith => __$LogTargetCopyWithImpl<_LogTarget>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LogTarget&&(identical(other.sessionExerciseId, sessionExerciseId) || other.sessionExerciseId == sessionExerciseId)&&(identical(other.plannedSetIndex, plannedSetIndex) || other.plannedSetIndex == plannedSetIndex));
}


@override
int get hashCode => Object.hash(runtimeType,sessionExerciseId,plannedSetIndex);

@override
String toString() {
  return 'LogTarget(sessionExerciseId: $sessionExerciseId, plannedSetIndex: $plannedSetIndex)';
}


}

/// @nodoc
abstract mixin class _$LogTargetCopyWith<$Res> implements $LogTargetCopyWith<$Res> {
  factory _$LogTargetCopyWith(_LogTarget value, $Res Function(_LogTarget) _then) = __$LogTargetCopyWithImpl;
@override @useResult
$Res call({
 String sessionExerciseId, int plannedSetIndex
});




}
/// @nodoc
class __$LogTargetCopyWithImpl<$Res>
    implements _$LogTargetCopyWith<$Res> {
  __$LogTargetCopyWithImpl(this._self, this._then);

  final _LogTarget _self;
  final $Res Function(_LogTarget) _then;

/// Create a copy of LogTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionExerciseId = null,Object? plannedSetIndex = null,}) {
  return _then(_LogTarget(
sessionExerciseId: null == sessionExerciseId ? _self.sessionExerciseId : sessionExerciseId // ignore: cast_nullable_to_non_nullable
as String,plannedSetIndex: null == plannedSetIndex ? _self.plannedSetIndex : plannedSetIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

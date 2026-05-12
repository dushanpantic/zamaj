// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_day_picker_args.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkoutDayPickerArgs {

 String get programId;
/// Create a copy of WorkoutDayPickerArgs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutDayPickerArgsCopyWith<WorkoutDayPickerArgs> get copyWith => _$WorkoutDayPickerArgsCopyWithImpl<WorkoutDayPickerArgs>(this as WorkoutDayPickerArgs, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutDayPickerArgs&&(identical(other.programId, programId) || other.programId == programId));
}


@override
int get hashCode => Object.hash(runtimeType,programId);

@override
String toString() {
  return 'WorkoutDayPickerArgs(programId: $programId)';
}


}

/// @nodoc
abstract mixin class $WorkoutDayPickerArgsCopyWith<$Res>  {
  factory $WorkoutDayPickerArgsCopyWith(WorkoutDayPickerArgs value, $Res Function(WorkoutDayPickerArgs) _then) = _$WorkoutDayPickerArgsCopyWithImpl;
@useResult
$Res call({
 String programId
});




}
/// @nodoc
class _$WorkoutDayPickerArgsCopyWithImpl<$Res>
    implements $WorkoutDayPickerArgsCopyWith<$Res> {
  _$WorkoutDayPickerArgsCopyWithImpl(this._self, this._then);

  final WorkoutDayPickerArgs _self;
  final $Res Function(WorkoutDayPickerArgs) _then;

/// Create a copy of WorkoutDayPickerArgs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? programId = null,}) {
  return _then(_self.copyWith(
programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutDayPickerArgs].
extension WorkoutDayPickerArgsPatterns on WorkoutDayPickerArgs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutDayPickerArgs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutDayPickerArgs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutDayPickerArgs value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutDayPickerArgs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutDayPickerArgs value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutDayPickerArgs() when $default != null:
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
case _WorkoutDayPickerArgs() when $default != null:
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
case _WorkoutDayPickerArgs():
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
case _WorkoutDayPickerArgs() when $default != null:
return $default(_that.programId);case _:
  return null;

}
}

}

/// @nodoc


class _WorkoutDayPickerArgs implements WorkoutDayPickerArgs {
  const _WorkoutDayPickerArgs({required this.programId});
  

@override final  String programId;

/// Create a copy of WorkoutDayPickerArgs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutDayPickerArgsCopyWith<_WorkoutDayPickerArgs> get copyWith => __$WorkoutDayPickerArgsCopyWithImpl<_WorkoutDayPickerArgs>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutDayPickerArgs&&(identical(other.programId, programId) || other.programId == programId));
}


@override
int get hashCode => Object.hash(runtimeType,programId);

@override
String toString() {
  return 'WorkoutDayPickerArgs(programId: $programId)';
}


}

/// @nodoc
abstract mixin class _$WorkoutDayPickerArgsCopyWith<$Res> implements $WorkoutDayPickerArgsCopyWith<$Res> {
  factory _$WorkoutDayPickerArgsCopyWith(_WorkoutDayPickerArgs value, $Res Function(_WorkoutDayPickerArgs) _then) = __$WorkoutDayPickerArgsCopyWithImpl;
@override @useResult
$Res call({
 String programId
});




}
/// @nodoc
class __$WorkoutDayPickerArgsCopyWithImpl<$Res>
    implements _$WorkoutDayPickerArgsCopyWith<$Res> {
  __$WorkoutDayPickerArgsCopyWithImpl(this._self, this._then);

  final _WorkoutDayPickerArgs _self;
  final $Res Function(_WorkoutDayPickerArgs) _then;

/// Create a copy of WorkoutDayPickerArgs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? programId = null,}) {
  return _then(_WorkoutDayPickerArgs(
programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

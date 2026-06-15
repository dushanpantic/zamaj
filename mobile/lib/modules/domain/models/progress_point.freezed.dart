// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'progress_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProgressPoint {

 DateTime get date; double get topSetWeightKg; int get reps; String get programId; String get sourceWorkoutDayName;
/// Create a copy of ProgressPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgressPointCopyWith<ProgressPoint> get copyWith => _$ProgressPointCopyWithImpl<ProgressPoint>(this as ProgressPoint, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProgressPoint&&(identical(other.date, date) || other.date == date)&&(identical(other.topSetWeightKg, topSetWeightKg) || other.topSetWeightKg == topSetWeightKg)&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.programId, programId) || other.programId == programId)&&(identical(other.sourceWorkoutDayName, sourceWorkoutDayName) || other.sourceWorkoutDayName == sourceWorkoutDayName));
}


@override
int get hashCode => Object.hash(runtimeType,date,topSetWeightKg,reps,programId,sourceWorkoutDayName);

@override
String toString() {
  return 'ProgressPoint(date: $date, topSetWeightKg: $topSetWeightKg, reps: $reps, programId: $programId, sourceWorkoutDayName: $sourceWorkoutDayName)';
}


}

/// @nodoc
abstract mixin class $ProgressPointCopyWith<$Res>  {
  factory $ProgressPointCopyWith(ProgressPoint value, $Res Function(ProgressPoint) _then) = _$ProgressPointCopyWithImpl;
@useResult
$Res call({
 DateTime date, double topSetWeightKg, int reps, String programId, String sourceWorkoutDayName
});




}
/// @nodoc
class _$ProgressPointCopyWithImpl<$Res>
    implements $ProgressPointCopyWith<$Res> {
  _$ProgressPointCopyWithImpl(this._self, this._then);

  final ProgressPoint _self;
  final $Res Function(ProgressPoint) _then;

/// Create a copy of ProgressPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? topSetWeightKg = null,Object? reps = null,Object? programId = null,Object? sourceWorkoutDayName = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,topSetWeightKg: null == topSetWeightKg ? _self.topSetWeightKg : topSetWeightKg // ignore: cast_nullable_to_non_nullable
as double,reps: null == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int,programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,sourceWorkoutDayName: null == sourceWorkoutDayName ? _self.sourceWorkoutDayName : sourceWorkoutDayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProgressPoint].
extension ProgressPointPatterns on ProgressPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProgressPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProgressPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProgressPoint value)  $default,){
final _that = this;
switch (_that) {
case _ProgressPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProgressPoint value)?  $default,){
final _that = this;
switch (_that) {
case _ProgressPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  double topSetWeightKg,  int reps,  String programId,  String sourceWorkoutDayName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProgressPoint() when $default != null:
return $default(_that.date,_that.topSetWeightKg,_that.reps,_that.programId,_that.sourceWorkoutDayName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  double topSetWeightKg,  int reps,  String programId,  String sourceWorkoutDayName)  $default,) {final _that = this;
switch (_that) {
case _ProgressPoint():
return $default(_that.date,_that.topSetWeightKg,_that.reps,_that.programId,_that.sourceWorkoutDayName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  double topSetWeightKg,  int reps,  String programId,  String sourceWorkoutDayName)?  $default,) {final _that = this;
switch (_that) {
case _ProgressPoint() when $default != null:
return $default(_that.date,_that.topSetWeightKg,_that.reps,_that.programId,_that.sourceWorkoutDayName);case _:
  return null;

}
}

}

/// @nodoc


class _ProgressPoint extends ProgressPoint {
   _ProgressPoint({required this.date, required this.topSetWeightKg, required this.reps, required this.programId, required this.sourceWorkoutDayName}): super._();
  

@override final  DateTime date;
@override final  double topSetWeightKg;
@override final  int reps;
@override final  String programId;
@override final  String sourceWorkoutDayName;

/// Create a copy of ProgressPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgressPointCopyWith<_ProgressPoint> get copyWith => __$ProgressPointCopyWithImpl<_ProgressPoint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProgressPoint&&(identical(other.date, date) || other.date == date)&&(identical(other.topSetWeightKg, topSetWeightKg) || other.topSetWeightKg == topSetWeightKg)&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.programId, programId) || other.programId == programId)&&(identical(other.sourceWorkoutDayName, sourceWorkoutDayName) || other.sourceWorkoutDayName == sourceWorkoutDayName));
}


@override
int get hashCode => Object.hash(runtimeType,date,topSetWeightKg,reps,programId,sourceWorkoutDayName);

@override
String toString() {
  return 'ProgressPoint(date: $date, topSetWeightKg: $topSetWeightKg, reps: $reps, programId: $programId, sourceWorkoutDayName: $sourceWorkoutDayName)';
}


}

/// @nodoc
abstract mixin class _$ProgressPointCopyWith<$Res> implements $ProgressPointCopyWith<$Res> {
  factory _$ProgressPointCopyWith(_ProgressPoint value, $Res Function(_ProgressPoint) _then) = __$ProgressPointCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, double topSetWeightKg, int reps, String programId, String sourceWorkoutDayName
});




}
/// @nodoc
class __$ProgressPointCopyWithImpl<$Res>
    implements _$ProgressPointCopyWith<$Res> {
  __$ProgressPointCopyWithImpl(this._self, this._then);

  final _ProgressPoint _self;
  final $Res Function(_ProgressPoint) _then;

/// Create a copy of ProgressPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? topSetWeightKg = null,Object? reps = null,Object? programId = null,Object? sourceWorkoutDayName = null,}) {
  return _then(_ProgressPoint(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,topSetWeightKg: null == topSetWeightKg ? _self.topSetWeightKg : topSetWeightKg // ignore: cast_nullable_to_non_nullable
as double,reps: null == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int,programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,sourceWorkoutDayName: null == sourceWorkoutDayName ? _self.sourceWorkoutDayName : sourceWorkoutDayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

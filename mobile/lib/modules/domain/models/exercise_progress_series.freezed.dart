// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_progress_series.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExerciseProgressSeries {

 List<ProgressPoint> get points;
/// Create a copy of ExerciseProgressSeries
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseProgressSeriesCopyWith<ExerciseProgressSeries> get copyWith => _$ExerciseProgressSeriesCopyWithImpl<ExerciseProgressSeries>(this as ExerciseProgressSeries, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseProgressSeries&&const DeepCollectionEquality().equals(other.points, points));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(points));

@override
String toString() {
  return 'ExerciseProgressSeries(points: $points)';
}


}

/// @nodoc
abstract mixin class $ExerciseProgressSeriesCopyWith<$Res>  {
  factory $ExerciseProgressSeriesCopyWith(ExerciseProgressSeries value, $Res Function(ExerciseProgressSeries) _then) = _$ExerciseProgressSeriesCopyWithImpl;
@useResult
$Res call({
 List<ProgressPoint> points
});




}
/// @nodoc
class _$ExerciseProgressSeriesCopyWithImpl<$Res>
    implements $ExerciseProgressSeriesCopyWith<$Res> {
  _$ExerciseProgressSeriesCopyWithImpl(this._self, this._then);

  final ExerciseProgressSeries _self;
  final $Res Function(ExerciseProgressSeries) _then;

/// Create a copy of ExerciseProgressSeries
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? points = null,}) {
  return _then(_self.copyWith(
points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as List<ProgressPoint>,
  ));
}

}


/// Adds pattern-matching-related methods to [ExerciseProgressSeries].
extension ExerciseProgressSeriesPatterns on ExerciseProgressSeries {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExerciseProgressSeries value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExerciseProgressSeries() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExerciseProgressSeries value)  $default,){
final _that = this;
switch (_that) {
case _ExerciseProgressSeries():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExerciseProgressSeries value)?  $default,){
final _that = this;
switch (_that) {
case _ExerciseProgressSeries() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ProgressPoint> points)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExerciseProgressSeries() when $default != null:
return $default(_that.points);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ProgressPoint> points)  $default,) {final _that = this;
switch (_that) {
case _ExerciseProgressSeries():
return $default(_that.points);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ProgressPoint> points)?  $default,) {final _that = this;
switch (_that) {
case _ExerciseProgressSeries() when $default != null:
return $default(_that.points);case _:
  return null;

}
}

}

/// @nodoc


class _ExerciseProgressSeries extends ExerciseProgressSeries {
  const _ExerciseProgressSeries({required final  List<ProgressPoint> points}): _points = points,super._();
  

 final  List<ProgressPoint> _points;
@override List<ProgressPoint> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}


/// Create a copy of ExerciseProgressSeries
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseProgressSeriesCopyWith<_ExerciseProgressSeries> get copyWith => __$ExerciseProgressSeriesCopyWithImpl<_ExerciseProgressSeries>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExerciseProgressSeries&&const DeepCollectionEquality().equals(other._points, _points));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_points));

@override
String toString() {
  return 'ExerciseProgressSeries(points: $points)';
}


}

/// @nodoc
abstract mixin class _$ExerciseProgressSeriesCopyWith<$Res> implements $ExerciseProgressSeriesCopyWith<$Res> {
  factory _$ExerciseProgressSeriesCopyWith(_ExerciseProgressSeries value, $Res Function(_ExerciseProgressSeries) _then) = __$ExerciseProgressSeriesCopyWithImpl;
@override @useResult
$Res call({
 List<ProgressPoint> points
});




}
/// @nodoc
class __$ExerciseProgressSeriesCopyWithImpl<$Res>
    implements _$ExerciseProgressSeriesCopyWith<$Res> {
  __$ExerciseProgressSeriesCopyWithImpl(this._self, this._then);

  final _ExerciseProgressSeries _self;
  final $Res Function(_ExerciseProgressSeries) _then;

/// Create a copy of ExerciseProgressSeries
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? points = null,}) {
  return _then(_ExerciseProgressSeries(
points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<ProgressPoint>,
  ));
}


}

// dart format on

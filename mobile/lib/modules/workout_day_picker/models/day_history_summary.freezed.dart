// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'day_history_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DayHistorySummary {

 DateTime? get lastCompleted; int get totalCompletedCount; int get thisWeekCount; String? get activeSessionId;
/// Create a copy of DayHistorySummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayHistorySummaryCopyWith<DayHistorySummary> get copyWith => _$DayHistorySummaryCopyWithImpl<DayHistorySummary>(this as DayHistorySummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayHistorySummary&&(identical(other.lastCompleted, lastCompleted) || other.lastCompleted == lastCompleted)&&(identical(other.totalCompletedCount, totalCompletedCount) || other.totalCompletedCount == totalCompletedCount)&&(identical(other.thisWeekCount, thisWeekCount) || other.thisWeekCount == thisWeekCount)&&(identical(other.activeSessionId, activeSessionId) || other.activeSessionId == activeSessionId));
}


@override
int get hashCode => Object.hash(runtimeType,lastCompleted,totalCompletedCount,thisWeekCount,activeSessionId);

@override
String toString() {
  return 'DayHistorySummary(lastCompleted: $lastCompleted, totalCompletedCount: $totalCompletedCount, thisWeekCount: $thisWeekCount, activeSessionId: $activeSessionId)';
}


}

/// @nodoc
abstract mixin class $DayHistorySummaryCopyWith<$Res>  {
  factory $DayHistorySummaryCopyWith(DayHistorySummary value, $Res Function(DayHistorySummary) _then) = _$DayHistorySummaryCopyWithImpl;
@useResult
$Res call({
 DateTime? lastCompleted, int totalCompletedCount, int thisWeekCount, String? activeSessionId
});




}
/// @nodoc
class _$DayHistorySummaryCopyWithImpl<$Res>
    implements $DayHistorySummaryCopyWith<$Res> {
  _$DayHistorySummaryCopyWithImpl(this._self, this._then);

  final DayHistorySummary _self;
  final $Res Function(DayHistorySummary) _then;

/// Create a copy of DayHistorySummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lastCompleted = freezed,Object? totalCompletedCount = null,Object? thisWeekCount = null,Object? activeSessionId = freezed,}) {
  return _then(_self.copyWith(
lastCompleted: freezed == lastCompleted ? _self.lastCompleted : lastCompleted // ignore: cast_nullable_to_non_nullable
as DateTime?,totalCompletedCount: null == totalCompletedCount ? _self.totalCompletedCount : totalCompletedCount // ignore: cast_nullable_to_non_nullable
as int,thisWeekCount: null == thisWeekCount ? _self.thisWeekCount : thisWeekCount // ignore: cast_nullable_to_non_nullable
as int,activeSessionId: freezed == activeSessionId ? _self.activeSessionId : activeSessionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DayHistorySummary].
extension DayHistorySummaryPatterns on DayHistorySummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayHistorySummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayHistorySummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayHistorySummary value)  $default,){
final _that = this;
switch (_that) {
case _DayHistorySummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayHistorySummary value)?  $default,){
final _that = this;
switch (_that) {
case _DayHistorySummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime? lastCompleted,  int totalCompletedCount,  int thisWeekCount,  String? activeSessionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayHistorySummary() when $default != null:
return $default(_that.lastCompleted,_that.totalCompletedCount,_that.thisWeekCount,_that.activeSessionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime? lastCompleted,  int totalCompletedCount,  int thisWeekCount,  String? activeSessionId)  $default,) {final _that = this;
switch (_that) {
case _DayHistorySummary():
return $default(_that.lastCompleted,_that.totalCompletedCount,_that.thisWeekCount,_that.activeSessionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime? lastCompleted,  int totalCompletedCount,  int thisWeekCount,  String? activeSessionId)?  $default,) {final _that = this;
switch (_that) {
case _DayHistorySummary() when $default != null:
return $default(_that.lastCompleted,_that.totalCompletedCount,_that.thisWeekCount,_that.activeSessionId);case _:
  return null;

}
}

}

/// @nodoc


class _DayHistorySummary implements DayHistorySummary {
  const _DayHistorySummary({required this.lastCompleted, required this.totalCompletedCount, required this.thisWeekCount, required this.activeSessionId});
  

@override final  DateTime? lastCompleted;
@override final  int totalCompletedCount;
@override final  int thisWeekCount;
@override final  String? activeSessionId;

/// Create a copy of DayHistorySummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayHistorySummaryCopyWith<_DayHistorySummary> get copyWith => __$DayHistorySummaryCopyWithImpl<_DayHistorySummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayHistorySummary&&(identical(other.lastCompleted, lastCompleted) || other.lastCompleted == lastCompleted)&&(identical(other.totalCompletedCount, totalCompletedCount) || other.totalCompletedCount == totalCompletedCount)&&(identical(other.thisWeekCount, thisWeekCount) || other.thisWeekCount == thisWeekCount)&&(identical(other.activeSessionId, activeSessionId) || other.activeSessionId == activeSessionId));
}


@override
int get hashCode => Object.hash(runtimeType,lastCompleted,totalCompletedCount,thisWeekCount,activeSessionId);

@override
String toString() {
  return 'DayHistorySummary(lastCompleted: $lastCompleted, totalCompletedCount: $totalCompletedCount, thisWeekCount: $thisWeekCount, activeSessionId: $activeSessionId)';
}


}

/// @nodoc
abstract mixin class _$DayHistorySummaryCopyWith<$Res> implements $DayHistorySummaryCopyWith<$Res> {
  factory _$DayHistorySummaryCopyWith(_DayHistorySummary value, $Res Function(_DayHistorySummary) _then) = __$DayHistorySummaryCopyWithImpl;
@override @useResult
$Res call({
 DateTime? lastCompleted, int totalCompletedCount, int thisWeekCount, String? activeSessionId
});




}
/// @nodoc
class __$DayHistorySummaryCopyWithImpl<$Res>
    implements _$DayHistorySummaryCopyWith<$Res> {
  __$DayHistorySummaryCopyWithImpl(this._self, this._then);

  final _DayHistorySummary _self;
  final $Res Function(_DayHistorySummary) _then;

/// Create a copy of DayHistorySummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lastCompleted = freezed,Object? totalCompletedCount = null,Object? thisWeekCount = null,Object? activeSessionId = freezed,}) {
  return _then(_DayHistorySummary(
lastCompleted: freezed == lastCompleted ? _self.lastCompleted : lastCompleted // ignore: cast_nullable_to_non_nullable
as DateTime?,totalCompletedCount: null == totalCompletedCount ? _self.totalCompletedCount : totalCompletedCount // ignore: cast_nullable_to_non_nullable
as int,thisWeekCount: null == thisWeekCount ? _self.thisWeekCount : thisWeekCount // ignore: cast_nullable_to_non_nullable
as int,activeSessionId: freezed == activeSessionId ? _self.activeSessionId : activeSessionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

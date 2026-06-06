// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stopwatch_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StopwatchViewModel {

 bool get isRunning; int get elapsedSeconds; bool get isFinished;
/// Create a copy of StopwatchViewModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StopwatchViewModelCopyWith<StopwatchViewModel> get copyWith => _$StopwatchViewModelCopyWithImpl<StopwatchViewModel>(this as StopwatchViewModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StopwatchViewModel&&(identical(other.isRunning, isRunning) || other.isRunning == isRunning)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds)&&(identical(other.isFinished, isFinished) || other.isFinished == isFinished));
}


@override
int get hashCode => Object.hash(runtimeType,isRunning,elapsedSeconds,isFinished);

@override
String toString() {
  return 'StopwatchViewModel(isRunning: $isRunning, elapsedSeconds: $elapsedSeconds, isFinished: $isFinished)';
}


}

/// @nodoc
abstract mixin class $StopwatchViewModelCopyWith<$Res>  {
  factory $StopwatchViewModelCopyWith(StopwatchViewModel value, $Res Function(StopwatchViewModel) _then) = _$StopwatchViewModelCopyWithImpl;
@useResult
$Res call({
 bool isRunning, int elapsedSeconds, bool isFinished
});




}
/// @nodoc
class _$StopwatchViewModelCopyWithImpl<$Res>
    implements $StopwatchViewModelCopyWith<$Res> {
  _$StopwatchViewModelCopyWithImpl(this._self, this._then);

  final StopwatchViewModel _self;
  final $Res Function(StopwatchViewModel) _then;

/// Create a copy of StopwatchViewModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isRunning = null,Object? elapsedSeconds = null,Object? isFinished = null,}) {
  return _then(_self.copyWith(
isRunning: null == isRunning ? _self.isRunning : isRunning // ignore: cast_nullable_to_non_nullable
as bool,elapsedSeconds: null == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int,isFinished: null == isFinished ? _self.isFinished : isFinished // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [StopwatchViewModel].
extension StopwatchViewModelPatterns on StopwatchViewModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StopwatchViewModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StopwatchViewModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StopwatchViewModel value)  $default,){
final _that = this;
switch (_that) {
case _StopwatchViewModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StopwatchViewModel value)?  $default,){
final _that = this;
switch (_that) {
case _StopwatchViewModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isRunning,  int elapsedSeconds,  bool isFinished)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StopwatchViewModel() when $default != null:
return $default(_that.isRunning,_that.elapsedSeconds,_that.isFinished);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isRunning,  int elapsedSeconds,  bool isFinished)  $default,) {final _that = this;
switch (_that) {
case _StopwatchViewModel():
return $default(_that.isRunning,_that.elapsedSeconds,_that.isFinished);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isRunning,  int elapsedSeconds,  bool isFinished)?  $default,) {final _that = this;
switch (_that) {
case _StopwatchViewModel() when $default != null:
return $default(_that.isRunning,_that.elapsedSeconds,_that.isFinished);case _:
  return null;

}
}

}

/// @nodoc


class _StopwatchViewModel implements StopwatchViewModel {
  const _StopwatchViewModel({required this.isRunning, required this.elapsedSeconds, this.isFinished = false});
  

@override final  bool isRunning;
@override final  int elapsedSeconds;
@override@JsonKey() final  bool isFinished;

/// Create a copy of StopwatchViewModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StopwatchViewModelCopyWith<_StopwatchViewModel> get copyWith => __$StopwatchViewModelCopyWithImpl<_StopwatchViewModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StopwatchViewModel&&(identical(other.isRunning, isRunning) || other.isRunning == isRunning)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds)&&(identical(other.isFinished, isFinished) || other.isFinished == isFinished));
}


@override
int get hashCode => Object.hash(runtimeType,isRunning,elapsedSeconds,isFinished);

@override
String toString() {
  return 'StopwatchViewModel(isRunning: $isRunning, elapsedSeconds: $elapsedSeconds, isFinished: $isFinished)';
}


}

/// @nodoc
abstract mixin class _$StopwatchViewModelCopyWith<$Res> implements $StopwatchViewModelCopyWith<$Res> {
  factory _$StopwatchViewModelCopyWith(_StopwatchViewModel value, $Res Function(_StopwatchViewModel) _then) = __$StopwatchViewModelCopyWithImpl;
@override @useResult
$Res call({
 bool isRunning, int elapsedSeconds, bool isFinished
});




}
/// @nodoc
class __$StopwatchViewModelCopyWithImpl<$Res>
    implements _$StopwatchViewModelCopyWith<$Res> {
  __$StopwatchViewModelCopyWithImpl(this._self, this._then);

  final _StopwatchViewModel _self;
  final $Res Function(_StopwatchViewModel) _then;

/// Create a copy of StopwatchViewModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isRunning = null,Object? elapsedSeconds = null,Object? isFinished = null,}) {
  return _then(_StopwatchViewModel(
isRunning: null == isRunning ? _self.isRunning : isRunning // ignore: cast_nullable_to_non_nullable
as bool,elapsedSeconds: null == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int,isFinished: null == isFinished ? _self.isFinished : isFinished // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

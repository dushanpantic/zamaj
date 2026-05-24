// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rest_timer_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RestTimerViewModel {

 int get plannedSeconds; int get elapsedSeconds;
/// Create a copy of RestTimerViewModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RestTimerViewModelCopyWith<RestTimerViewModel> get copyWith => _$RestTimerViewModelCopyWithImpl<RestTimerViewModel>(this as RestTimerViewModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RestTimerViewModel&&(identical(other.plannedSeconds, plannedSeconds) || other.plannedSeconds == plannedSeconds)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds));
}


@override
int get hashCode => Object.hash(runtimeType,plannedSeconds,elapsedSeconds);

@override
String toString() {
  return 'RestTimerViewModel(plannedSeconds: $plannedSeconds, elapsedSeconds: $elapsedSeconds)';
}


}

/// @nodoc
abstract mixin class $RestTimerViewModelCopyWith<$Res>  {
  factory $RestTimerViewModelCopyWith(RestTimerViewModel value, $Res Function(RestTimerViewModel) _then) = _$RestTimerViewModelCopyWithImpl;
@useResult
$Res call({
 int plannedSeconds, int elapsedSeconds
});




}
/// @nodoc
class _$RestTimerViewModelCopyWithImpl<$Res>
    implements $RestTimerViewModelCopyWith<$Res> {
  _$RestTimerViewModelCopyWithImpl(this._self, this._then);

  final RestTimerViewModel _self;
  final $Res Function(RestTimerViewModel) _then;

/// Create a copy of RestTimerViewModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plannedSeconds = null,Object? elapsedSeconds = null,}) {
  return _then(_self.copyWith(
plannedSeconds: null == plannedSeconds ? _self.plannedSeconds : plannedSeconds // ignore: cast_nullable_to_non_nullable
as int,elapsedSeconds: null == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RestTimerViewModel].
extension RestTimerViewModelPatterns on RestTimerViewModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RestTimerViewModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RestTimerViewModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RestTimerViewModel value)  $default,){
final _that = this;
switch (_that) {
case _RestTimerViewModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RestTimerViewModel value)?  $default,){
final _that = this;
switch (_that) {
case _RestTimerViewModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int plannedSeconds,  int elapsedSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RestTimerViewModel() when $default != null:
return $default(_that.plannedSeconds,_that.elapsedSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int plannedSeconds,  int elapsedSeconds)  $default,) {final _that = this;
switch (_that) {
case _RestTimerViewModel():
return $default(_that.plannedSeconds,_that.elapsedSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int plannedSeconds,  int elapsedSeconds)?  $default,) {final _that = this;
switch (_that) {
case _RestTimerViewModel() when $default != null:
return $default(_that.plannedSeconds,_that.elapsedSeconds);case _:
  return null;

}
}

}

/// @nodoc


class _RestTimerViewModel extends RestTimerViewModel {
  const _RestTimerViewModel({required this.plannedSeconds, required this.elapsedSeconds}): super._();
  

@override final  int plannedSeconds;
@override final  int elapsedSeconds;

/// Create a copy of RestTimerViewModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RestTimerViewModelCopyWith<_RestTimerViewModel> get copyWith => __$RestTimerViewModelCopyWithImpl<_RestTimerViewModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RestTimerViewModel&&(identical(other.plannedSeconds, plannedSeconds) || other.plannedSeconds == plannedSeconds)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds));
}


@override
int get hashCode => Object.hash(runtimeType,plannedSeconds,elapsedSeconds);

@override
String toString() {
  return 'RestTimerViewModel(plannedSeconds: $plannedSeconds, elapsedSeconds: $elapsedSeconds)';
}


}

/// @nodoc
abstract mixin class _$RestTimerViewModelCopyWith<$Res> implements $RestTimerViewModelCopyWith<$Res> {
  factory _$RestTimerViewModelCopyWith(_RestTimerViewModel value, $Res Function(_RestTimerViewModel) _then) = __$RestTimerViewModelCopyWithImpl;
@override @useResult
$Res call({
 int plannedSeconds, int elapsedSeconds
});




}
/// @nodoc
class __$RestTimerViewModelCopyWithImpl<$Res>
    implements _$RestTimerViewModelCopyWith<$Res> {
  __$RestTimerViewModelCopyWithImpl(this._self, this._then);

  final _RestTimerViewModel _self;
  final $Res Function(_RestTimerViewModel) _then;

/// Create a copy of RestTimerViewModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plannedSeconds = null,Object? elapsedSeconds = null,}) {
  return _then(_RestTimerViewModel(
plannedSeconds: null == plannedSeconds ? _self.plannedSeconds : plannedSeconds // ignore: cast_nullable_to_non_nullable
as int,elapsedSeconds: null == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

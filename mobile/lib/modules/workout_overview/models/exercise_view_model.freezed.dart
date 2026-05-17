// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExerciseViewModel {

 SessionExercise get sessionExercise; String get plannedExerciseName; String get plannedSummary; MeasurementType get plannedMeasurementType; ExerciseMetadata get plannedMetadata; int? get plannedRestSeconds; List<SetRowViewModel> get setRows;/// True when this exercise has at least one row in [setRows] flagged as
/// `isLoggable` — i.e. the user can log a new set on it right now.
/// Derived from the engine's [SessionState.openTargets] projection.
 bool get isLoggable; MeasurementType get effectiveMeasurementType;
/// Create a copy of ExerciseViewModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseViewModelCopyWith<ExerciseViewModel> get copyWith => _$ExerciseViewModelCopyWithImpl<ExerciseViewModel>(this as ExerciseViewModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseViewModel&&(identical(other.sessionExercise, sessionExercise) || other.sessionExercise == sessionExercise)&&(identical(other.plannedExerciseName, plannedExerciseName) || other.plannedExerciseName == plannedExerciseName)&&(identical(other.plannedSummary, plannedSummary) || other.plannedSummary == plannedSummary)&&(identical(other.plannedMeasurementType, plannedMeasurementType) || other.plannedMeasurementType == plannedMeasurementType)&&(identical(other.plannedMetadata, plannedMetadata) || other.plannedMetadata == plannedMetadata)&&(identical(other.plannedRestSeconds, plannedRestSeconds) || other.plannedRestSeconds == plannedRestSeconds)&&const DeepCollectionEquality().equals(other.setRows, setRows)&&(identical(other.isLoggable, isLoggable) || other.isLoggable == isLoggable)&&(identical(other.effectiveMeasurementType, effectiveMeasurementType) || other.effectiveMeasurementType == effectiveMeasurementType));
}


@override
int get hashCode => Object.hash(runtimeType,sessionExercise,plannedExerciseName,plannedSummary,plannedMeasurementType,plannedMetadata,plannedRestSeconds,const DeepCollectionEquality().hash(setRows),isLoggable,effectiveMeasurementType);

@override
String toString() {
  return 'ExerciseViewModel(sessionExercise: $sessionExercise, plannedExerciseName: $plannedExerciseName, plannedSummary: $plannedSummary, plannedMeasurementType: $plannedMeasurementType, plannedMetadata: $plannedMetadata, plannedRestSeconds: $plannedRestSeconds, setRows: $setRows, isLoggable: $isLoggable, effectiveMeasurementType: $effectiveMeasurementType)';
}


}

/// @nodoc
abstract mixin class $ExerciseViewModelCopyWith<$Res>  {
  factory $ExerciseViewModelCopyWith(ExerciseViewModel value, $Res Function(ExerciseViewModel) _then) = _$ExerciseViewModelCopyWithImpl;
@useResult
$Res call({
 SessionExercise sessionExercise, String plannedExerciseName, String plannedSummary, MeasurementType plannedMeasurementType, ExerciseMetadata plannedMetadata, int? plannedRestSeconds, List<SetRowViewModel> setRows, bool isLoggable, MeasurementType effectiveMeasurementType
});


$SessionExerciseCopyWith<$Res> get sessionExercise;$MeasurementTypeCopyWith<$Res> get plannedMeasurementType;$ExerciseMetadataCopyWith<$Res> get plannedMetadata;$MeasurementTypeCopyWith<$Res> get effectiveMeasurementType;

}
/// @nodoc
class _$ExerciseViewModelCopyWithImpl<$Res>
    implements $ExerciseViewModelCopyWith<$Res> {
  _$ExerciseViewModelCopyWithImpl(this._self, this._then);

  final ExerciseViewModel _self;
  final $Res Function(ExerciseViewModel) _then;

/// Create a copy of ExerciseViewModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionExercise = null,Object? plannedExerciseName = null,Object? plannedSummary = null,Object? plannedMeasurementType = null,Object? plannedMetadata = null,Object? plannedRestSeconds = freezed,Object? setRows = null,Object? isLoggable = null,Object? effectiveMeasurementType = null,}) {
  return _then(_self.copyWith(
sessionExercise: null == sessionExercise ? _self.sessionExercise : sessionExercise // ignore: cast_nullable_to_non_nullable
as SessionExercise,plannedExerciseName: null == plannedExerciseName ? _self.plannedExerciseName : plannedExerciseName // ignore: cast_nullable_to_non_nullable
as String,plannedSummary: null == plannedSummary ? _self.plannedSummary : plannedSummary // ignore: cast_nullable_to_non_nullable
as String,plannedMeasurementType: null == plannedMeasurementType ? _self.plannedMeasurementType : plannedMeasurementType // ignore: cast_nullable_to_non_nullable
as MeasurementType,plannedMetadata: null == plannedMetadata ? _self.plannedMetadata : plannedMetadata // ignore: cast_nullable_to_non_nullable
as ExerciseMetadata,plannedRestSeconds: freezed == plannedRestSeconds ? _self.plannedRestSeconds : plannedRestSeconds // ignore: cast_nullable_to_non_nullable
as int?,setRows: null == setRows ? _self.setRows : setRows // ignore: cast_nullable_to_non_nullable
as List<SetRowViewModel>,isLoggable: null == isLoggable ? _self.isLoggable : isLoggable // ignore: cast_nullable_to_non_nullable
as bool,effectiveMeasurementType: null == effectiveMeasurementType ? _self.effectiveMeasurementType : effectiveMeasurementType // ignore: cast_nullable_to_non_nullable
as MeasurementType,
  ));
}
/// Create a copy of ExerciseViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionExerciseCopyWith<$Res> get sessionExercise {
  
  return $SessionExerciseCopyWith<$Res>(_self.sessionExercise, (value) {
    return _then(_self.copyWith(sessionExercise: value));
  });
}/// Create a copy of ExerciseViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementTypeCopyWith<$Res> get plannedMeasurementType {
  
  return $MeasurementTypeCopyWith<$Res>(_self.plannedMeasurementType, (value) {
    return _then(_self.copyWith(plannedMeasurementType: value));
  });
}/// Create a copy of ExerciseViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseMetadataCopyWith<$Res> get plannedMetadata {
  
  return $ExerciseMetadataCopyWith<$Res>(_self.plannedMetadata, (value) {
    return _then(_self.copyWith(plannedMetadata: value));
  });
}/// Create a copy of ExerciseViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementTypeCopyWith<$Res> get effectiveMeasurementType {
  
  return $MeasurementTypeCopyWith<$Res>(_self.effectiveMeasurementType, (value) {
    return _then(_self.copyWith(effectiveMeasurementType: value));
  });
}
}


/// Adds pattern-matching-related methods to [ExerciseViewModel].
extension ExerciseViewModelPatterns on ExerciseViewModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExerciseViewModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExerciseViewModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExerciseViewModel value)  $default,){
final _that = this;
switch (_that) {
case _ExerciseViewModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExerciseViewModel value)?  $default,){
final _that = this;
switch (_that) {
case _ExerciseViewModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SessionExercise sessionExercise,  String plannedExerciseName,  String plannedSummary,  MeasurementType plannedMeasurementType,  ExerciseMetadata plannedMetadata,  int? plannedRestSeconds,  List<SetRowViewModel> setRows,  bool isLoggable,  MeasurementType effectiveMeasurementType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExerciseViewModel() when $default != null:
return $default(_that.sessionExercise,_that.plannedExerciseName,_that.plannedSummary,_that.plannedMeasurementType,_that.plannedMetadata,_that.plannedRestSeconds,_that.setRows,_that.isLoggable,_that.effectiveMeasurementType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SessionExercise sessionExercise,  String plannedExerciseName,  String plannedSummary,  MeasurementType plannedMeasurementType,  ExerciseMetadata plannedMetadata,  int? plannedRestSeconds,  List<SetRowViewModel> setRows,  bool isLoggable,  MeasurementType effectiveMeasurementType)  $default,) {final _that = this;
switch (_that) {
case _ExerciseViewModel():
return $default(_that.sessionExercise,_that.plannedExerciseName,_that.plannedSummary,_that.plannedMeasurementType,_that.plannedMetadata,_that.plannedRestSeconds,_that.setRows,_that.isLoggable,_that.effectiveMeasurementType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SessionExercise sessionExercise,  String plannedExerciseName,  String plannedSummary,  MeasurementType plannedMeasurementType,  ExerciseMetadata plannedMetadata,  int? plannedRestSeconds,  List<SetRowViewModel> setRows,  bool isLoggable,  MeasurementType effectiveMeasurementType)?  $default,) {final _that = this;
switch (_that) {
case _ExerciseViewModel() when $default != null:
return $default(_that.sessionExercise,_that.plannedExerciseName,_that.plannedSummary,_that.plannedMeasurementType,_that.plannedMetadata,_that.plannedRestSeconds,_that.setRows,_that.isLoggable,_that.effectiveMeasurementType);case _:
  return null;

}
}

}

/// @nodoc


class _ExerciseViewModel implements ExerciseViewModel {
  const _ExerciseViewModel({required this.sessionExercise, required this.plannedExerciseName, required this.plannedSummary, required this.plannedMeasurementType, required this.plannedMetadata, required this.plannedRestSeconds, required final  List<SetRowViewModel> setRows, required this.isLoggable, required this.effectiveMeasurementType}): _setRows = setRows;
  

@override final  SessionExercise sessionExercise;
@override final  String plannedExerciseName;
@override final  String plannedSummary;
@override final  MeasurementType plannedMeasurementType;
@override final  ExerciseMetadata plannedMetadata;
@override final  int? plannedRestSeconds;
 final  List<SetRowViewModel> _setRows;
@override List<SetRowViewModel> get setRows {
  if (_setRows is EqualUnmodifiableListView) return _setRows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_setRows);
}

/// True when this exercise has at least one row in [setRows] flagged as
/// `isLoggable` — i.e. the user can log a new set on it right now.
/// Derived from the engine's [SessionState.openTargets] projection.
@override final  bool isLoggable;
@override final  MeasurementType effectiveMeasurementType;

/// Create a copy of ExerciseViewModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseViewModelCopyWith<_ExerciseViewModel> get copyWith => __$ExerciseViewModelCopyWithImpl<_ExerciseViewModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExerciseViewModel&&(identical(other.sessionExercise, sessionExercise) || other.sessionExercise == sessionExercise)&&(identical(other.plannedExerciseName, plannedExerciseName) || other.plannedExerciseName == plannedExerciseName)&&(identical(other.plannedSummary, plannedSummary) || other.plannedSummary == plannedSummary)&&(identical(other.plannedMeasurementType, plannedMeasurementType) || other.plannedMeasurementType == plannedMeasurementType)&&(identical(other.plannedMetadata, plannedMetadata) || other.plannedMetadata == plannedMetadata)&&(identical(other.plannedRestSeconds, plannedRestSeconds) || other.plannedRestSeconds == plannedRestSeconds)&&const DeepCollectionEquality().equals(other._setRows, _setRows)&&(identical(other.isLoggable, isLoggable) || other.isLoggable == isLoggable)&&(identical(other.effectiveMeasurementType, effectiveMeasurementType) || other.effectiveMeasurementType == effectiveMeasurementType));
}


@override
int get hashCode => Object.hash(runtimeType,sessionExercise,plannedExerciseName,plannedSummary,plannedMeasurementType,plannedMetadata,plannedRestSeconds,const DeepCollectionEquality().hash(_setRows),isLoggable,effectiveMeasurementType);

@override
String toString() {
  return 'ExerciseViewModel(sessionExercise: $sessionExercise, plannedExerciseName: $plannedExerciseName, plannedSummary: $plannedSummary, plannedMeasurementType: $plannedMeasurementType, plannedMetadata: $plannedMetadata, plannedRestSeconds: $plannedRestSeconds, setRows: $setRows, isLoggable: $isLoggable, effectiveMeasurementType: $effectiveMeasurementType)';
}


}

/// @nodoc
abstract mixin class _$ExerciseViewModelCopyWith<$Res> implements $ExerciseViewModelCopyWith<$Res> {
  factory _$ExerciseViewModelCopyWith(_ExerciseViewModel value, $Res Function(_ExerciseViewModel) _then) = __$ExerciseViewModelCopyWithImpl;
@override @useResult
$Res call({
 SessionExercise sessionExercise, String plannedExerciseName, String plannedSummary, MeasurementType plannedMeasurementType, ExerciseMetadata plannedMetadata, int? plannedRestSeconds, List<SetRowViewModel> setRows, bool isLoggable, MeasurementType effectiveMeasurementType
});


@override $SessionExerciseCopyWith<$Res> get sessionExercise;@override $MeasurementTypeCopyWith<$Res> get plannedMeasurementType;@override $ExerciseMetadataCopyWith<$Res> get plannedMetadata;@override $MeasurementTypeCopyWith<$Res> get effectiveMeasurementType;

}
/// @nodoc
class __$ExerciseViewModelCopyWithImpl<$Res>
    implements _$ExerciseViewModelCopyWith<$Res> {
  __$ExerciseViewModelCopyWithImpl(this._self, this._then);

  final _ExerciseViewModel _self;
  final $Res Function(_ExerciseViewModel) _then;

/// Create a copy of ExerciseViewModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionExercise = null,Object? plannedExerciseName = null,Object? plannedSummary = null,Object? plannedMeasurementType = null,Object? plannedMetadata = null,Object? plannedRestSeconds = freezed,Object? setRows = null,Object? isLoggable = null,Object? effectiveMeasurementType = null,}) {
  return _then(_ExerciseViewModel(
sessionExercise: null == sessionExercise ? _self.sessionExercise : sessionExercise // ignore: cast_nullable_to_non_nullable
as SessionExercise,plannedExerciseName: null == plannedExerciseName ? _self.plannedExerciseName : plannedExerciseName // ignore: cast_nullable_to_non_nullable
as String,plannedSummary: null == plannedSummary ? _self.plannedSummary : plannedSummary // ignore: cast_nullable_to_non_nullable
as String,plannedMeasurementType: null == plannedMeasurementType ? _self.plannedMeasurementType : plannedMeasurementType // ignore: cast_nullable_to_non_nullable
as MeasurementType,plannedMetadata: null == plannedMetadata ? _self.plannedMetadata : plannedMetadata // ignore: cast_nullable_to_non_nullable
as ExerciseMetadata,plannedRestSeconds: freezed == plannedRestSeconds ? _self.plannedRestSeconds : plannedRestSeconds // ignore: cast_nullable_to_non_nullable
as int?,setRows: null == setRows ? _self._setRows : setRows // ignore: cast_nullable_to_non_nullable
as List<SetRowViewModel>,isLoggable: null == isLoggable ? _self.isLoggable : isLoggable // ignore: cast_nullable_to_non_nullable
as bool,effectiveMeasurementType: null == effectiveMeasurementType ? _self.effectiveMeasurementType : effectiveMeasurementType // ignore: cast_nullable_to_non_nullable
as MeasurementType,
  ));
}

/// Create a copy of ExerciseViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionExerciseCopyWith<$Res> get sessionExercise {
  
  return $SessionExerciseCopyWith<$Res>(_self.sessionExercise, (value) {
    return _then(_self.copyWith(sessionExercise: value));
  });
}/// Create a copy of ExerciseViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementTypeCopyWith<$Res> get plannedMeasurementType {
  
  return $MeasurementTypeCopyWith<$Res>(_self.plannedMeasurementType, (value) {
    return _then(_self.copyWith(plannedMeasurementType: value));
  });
}/// Create a copy of ExerciseViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseMetadataCopyWith<$Res> get plannedMetadata {
  
  return $ExerciseMetadataCopyWith<$Res>(_self.plannedMetadata, (value) {
    return _then(_self.copyWith(plannedMetadata: value));
  });
}/// Create a copy of ExerciseViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementTypeCopyWith<$Res> get effectiveMeasurementType {
  
  return $MeasurementTypeCopyWith<$Res>(_self.effectiveMeasurementType, (value) {
    return _then(_self.copyWith(effectiveMeasurementType: value));
  });
}
}

// dart format on

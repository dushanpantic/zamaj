// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'focus_mode_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FocusModeViewModel {

 String get sessionExerciseId; String get displayExerciseName; ExerciseMetadata? get displayMetadata; MeasurementType get effectiveMeasurementType;/// 0-based index of the set the user is about to log on this exercise.
/// Equals `executedSets.length` for loggable panels; equals
/// `plannedSetCount` for completed panels (past the last planned slot).
 int get currentSetIndex;/// Number of planned sets for this exercise. May be 0 for snapshot-only
/// planned exercises that were stripped of sets.
 int get totalPlannedSets;/// Always equals `executedSets.length` for the panel exercise.
 int get completedSetsCount;/// Planned values for the current set index, or null when the panel is
/// past the planned set list (e.g. completed, or extra sets on a
/// replaced exercise).
 PlannedSetValues? get currentPlannedValues;/// Pre-formatted "100kg 4 × 8" summary of all planned sets.
 String get plannedSummary;/// Identity of the planned set being targeted; copied onto the logged
/// [ExecutedSet] when known.
 String? get currentPlannedSetIdInSnapshot;/// Actual values from the last completed set on this exercise.
 ActualSetValues? get lastExecutedValues;/// Coach-defined rest, propagated from the planned exercise. Drives the
/// shared rest-timer's planned/remaining display.
 int? get plannedRestSeconds;/// The planned exercise's name (for a snapshot-backed exercise the snapshot
/// entry; for an added exercise the inline plan's name).
 String get plannedExerciseName;/// True when the user can still log a working set on this exercise —
/// i.e. state is `unfinished` and `executedSets.length < plannedSetCount`.
/// False for completed/skipped panels.
 bool get isLoggable; ExerciseGroupRole get plannedGroupRole;
/// Create a copy of FocusModeViewModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FocusModeViewModelCopyWith<FocusModeViewModel> get copyWith => _$FocusModeViewModelCopyWithImpl<FocusModeViewModel>(this as FocusModeViewModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FocusModeViewModel&&(identical(other.sessionExerciseId, sessionExerciseId) || other.sessionExerciseId == sessionExerciseId)&&(identical(other.displayExerciseName, displayExerciseName) || other.displayExerciseName == displayExerciseName)&&(identical(other.displayMetadata, displayMetadata) || other.displayMetadata == displayMetadata)&&(identical(other.effectiveMeasurementType, effectiveMeasurementType) || other.effectiveMeasurementType == effectiveMeasurementType)&&(identical(other.currentSetIndex, currentSetIndex) || other.currentSetIndex == currentSetIndex)&&(identical(other.totalPlannedSets, totalPlannedSets) || other.totalPlannedSets == totalPlannedSets)&&(identical(other.completedSetsCount, completedSetsCount) || other.completedSetsCount == completedSetsCount)&&(identical(other.currentPlannedValues, currentPlannedValues) || other.currentPlannedValues == currentPlannedValues)&&(identical(other.plannedSummary, plannedSummary) || other.plannedSummary == plannedSummary)&&(identical(other.currentPlannedSetIdInSnapshot, currentPlannedSetIdInSnapshot) || other.currentPlannedSetIdInSnapshot == currentPlannedSetIdInSnapshot)&&(identical(other.lastExecutedValues, lastExecutedValues) || other.lastExecutedValues == lastExecutedValues)&&(identical(other.plannedRestSeconds, plannedRestSeconds) || other.plannedRestSeconds == plannedRestSeconds)&&(identical(other.plannedExerciseName, plannedExerciseName) || other.plannedExerciseName == plannedExerciseName)&&(identical(other.isLoggable, isLoggable) || other.isLoggable == isLoggable)&&(identical(other.plannedGroupRole, plannedGroupRole) || other.plannedGroupRole == plannedGroupRole));
}


@override
int get hashCode => Object.hash(runtimeType,sessionExerciseId,displayExerciseName,displayMetadata,effectiveMeasurementType,currentSetIndex,totalPlannedSets,completedSetsCount,currentPlannedValues,plannedSummary,currentPlannedSetIdInSnapshot,lastExecutedValues,plannedRestSeconds,plannedExerciseName,isLoggable,plannedGroupRole);

@override
String toString() {
  return 'FocusModeViewModel(sessionExerciseId: $sessionExerciseId, displayExerciseName: $displayExerciseName, displayMetadata: $displayMetadata, effectiveMeasurementType: $effectiveMeasurementType, currentSetIndex: $currentSetIndex, totalPlannedSets: $totalPlannedSets, completedSetsCount: $completedSetsCount, currentPlannedValues: $currentPlannedValues, plannedSummary: $plannedSummary, currentPlannedSetIdInSnapshot: $currentPlannedSetIdInSnapshot, lastExecutedValues: $lastExecutedValues, plannedRestSeconds: $plannedRestSeconds, plannedExerciseName: $plannedExerciseName, isLoggable: $isLoggable, plannedGroupRole: $plannedGroupRole)';
}


}

/// @nodoc
abstract mixin class $FocusModeViewModelCopyWith<$Res>  {
  factory $FocusModeViewModelCopyWith(FocusModeViewModel value, $Res Function(FocusModeViewModel) _then) = _$FocusModeViewModelCopyWithImpl;
@useResult
$Res call({
 String sessionExerciseId, String displayExerciseName, ExerciseMetadata? displayMetadata, MeasurementType effectiveMeasurementType, int currentSetIndex, int totalPlannedSets, int completedSetsCount, PlannedSetValues? currentPlannedValues, String plannedSummary, String? currentPlannedSetIdInSnapshot, ActualSetValues? lastExecutedValues, int? plannedRestSeconds, String plannedExerciseName, bool isLoggable, ExerciseGroupRole plannedGroupRole
});


$ExerciseMetadataCopyWith<$Res>? get displayMetadata;$MeasurementTypeCopyWith<$Res> get effectiveMeasurementType;$PlannedSetValuesCopyWith<$Res>? get currentPlannedValues;$ActualSetValuesCopyWith<$Res>? get lastExecutedValues;

}
/// @nodoc
class _$FocusModeViewModelCopyWithImpl<$Res>
    implements $FocusModeViewModelCopyWith<$Res> {
  _$FocusModeViewModelCopyWithImpl(this._self, this._then);

  final FocusModeViewModel _self;
  final $Res Function(FocusModeViewModel) _then;

/// Create a copy of FocusModeViewModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionExerciseId = null,Object? displayExerciseName = null,Object? displayMetadata = freezed,Object? effectiveMeasurementType = null,Object? currentSetIndex = null,Object? totalPlannedSets = null,Object? completedSetsCount = null,Object? currentPlannedValues = freezed,Object? plannedSummary = null,Object? currentPlannedSetIdInSnapshot = freezed,Object? lastExecutedValues = freezed,Object? plannedRestSeconds = freezed,Object? plannedExerciseName = null,Object? isLoggable = null,Object? plannedGroupRole = null,}) {
  return _then(_self.copyWith(
sessionExerciseId: null == sessionExerciseId ? _self.sessionExerciseId : sessionExerciseId // ignore: cast_nullable_to_non_nullable
as String,displayExerciseName: null == displayExerciseName ? _self.displayExerciseName : displayExerciseName // ignore: cast_nullable_to_non_nullable
as String,displayMetadata: freezed == displayMetadata ? _self.displayMetadata : displayMetadata // ignore: cast_nullable_to_non_nullable
as ExerciseMetadata?,effectiveMeasurementType: null == effectiveMeasurementType ? _self.effectiveMeasurementType : effectiveMeasurementType // ignore: cast_nullable_to_non_nullable
as MeasurementType,currentSetIndex: null == currentSetIndex ? _self.currentSetIndex : currentSetIndex // ignore: cast_nullable_to_non_nullable
as int,totalPlannedSets: null == totalPlannedSets ? _self.totalPlannedSets : totalPlannedSets // ignore: cast_nullable_to_non_nullable
as int,completedSetsCount: null == completedSetsCount ? _self.completedSetsCount : completedSetsCount // ignore: cast_nullable_to_non_nullable
as int,currentPlannedValues: freezed == currentPlannedValues ? _self.currentPlannedValues : currentPlannedValues // ignore: cast_nullable_to_non_nullable
as PlannedSetValues?,plannedSummary: null == plannedSummary ? _self.plannedSummary : plannedSummary // ignore: cast_nullable_to_non_nullable
as String,currentPlannedSetIdInSnapshot: freezed == currentPlannedSetIdInSnapshot ? _self.currentPlannedSetIdInSnapshot : currentPlannedSetIdInSnapshot // ignore: cast_nullable_to_non_nullable
as String?,lastExecutedValues: freezed == lastExecutedValues ? _self.lastExecutedValues : lastExecutedValues // ignore: cast_nullable_to_non_nullable
as ActualSetValues?,plannedRestSeconds: freezed == plannedRestSeconds ? _self.plannedRestSeconds : plannedRestSeconds // ignore: cast_nullable_to_non_nullable
as int?,plannedExerciseName: null == plannedExerciseName ? _self.plannedExerciseName : plannedExerciseName // ignore: cast_nullable_to_non_nullable
as String,isLoggable: null == isLoggable ? _self.isLoggable : isLoggable // ignore: cast_nullable_to_non_nullable
as bool,plannedGroupRole: null == plannedGroupRole ? _self.plannedGroupRole : plannedGroupRole // ignore: cast_nullable_to_non_nullable
as ExerciseGroupRole,
  ));
}
/// Create a copy of FocusModeViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseMetadataCopyWith<$Res>? get displayMetadata {
    if (_self.displayMetadata == null) {
    return null;
  }

  return $ExerciseMetadataCopyWith<$Res>(_self.displayMetadata!, (value) {
    return _then(_self.copyWith(displayMetadata: value));
  });
}/// Create a copy of FocusModeViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementTypeCopyWith<$Res> get effectiveMeasurementType {
  
  return $MeasurementTypeCopyWith<$Res>(_self.effectiveMeasurementType, (value) {
    return _then(_self.copyWith(effectiveMeasurementType: value));
  });
}/// Create a copy of FocusModeViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlannedSetValuesCopyWith<$Res>? get currentPlannedValues {
    if (_self.currentPlannedValues == null) {
    return null;
  }

  return $PlannedSetValuesCopyWith<$Res>(_self.currentPlannedValues!, (value) {
    return _then(_self.copyWith(currentPlannedValues: value));
  });
}/// Create a copy of FocusModeViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActualSetValuesCopyWith<$Res>? get lastExecutedValues {
    if (_self.lastExecutedValues == null) {
    return null;
  }

  return $ActualSetValuesCopyWith<$Res>(_self.lastExecutedValues!, (value) {
    return _then(_self.copyWith(lastExecutedValues: value));
  });
}
}


/// Adds pattern-matching-related methods to [FocusModeViewModel].
extension FocusModeViewModelPatterns on FocusModeViewModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FocusModeViewModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FocusModeViewModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FocusModeViewModel value)  $default,){
final _that = this;
switch (_that) {
case _FocusModeViewModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FocusModeViewModel value)?  $default,){
final _that = this;
switch (_that) {
case _FocusModeViewModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionExerciseId,  String displayExerciseName,  ExerciseMetadata? displayMetadata,  MeasurementType effectiveMeasurementType,  int currentSetIndex,  int totalPlannedSets,  int completedSetsCount,  PlannedSetValues? currentPlannedValues,  String plannedSummary,  String? currentPlannedSetIdInSnapshot,  ActualSetValues? lastExecutedValues,  int? plannedRestSeconds,  String plannedExerciseName,  bool isLoggable,  ExerciseGroupRole plannedGroupRole)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FocusModeViewModel() when $default != null:
return $default(_that.sessionExerciseId,_that.displayExerciseName,_that.displayMetadata,_that.effectiveMeasurementType,_that.currentSetIndex,_that.totalPlannedSets,_that.completedSetsCount,_that.currentPlannedValues,_that.plannedSummary,_that.currentPlannedSetIdInSnapshot,_that.lastExecutedValues,_that.plannedRestSeconds,_that.plannedExerciseName,_that.isLoggable,_that.plannedGroupRole);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionExerciseId,  String displayExerciseName,  ExerciseMetadata? displayMetadata,  MeasurementType effectiveMeasurementType,  int currentSetIndex,  int totalPlannedSets,  int completedSetsCount,  PlannedSetValues? currentPlannedValues,  String plannedSummary,  String? currentPlannedSetIdInSnapshot,  ActualSetValues? lastExecutedValues,  int? plannedRestSeconds,  String plannedExerciseName,  bool isLoggable,  ExerciseGroupRole plannedGroupRole)  $default,) {final _that = this;
switch (_that) {
case _FocusModeViewModel():
return $default(_that.sessionExerciseId,_that.displayExerciseName,_that.displayMetadata,_that.effectiveMeasurementType,_that.currentSetIndex,_that.totalPlannedSets,_that.completedSetsCount,_that.currentPlannedValues,_that.plannedSummary,_that.currentPlannedSetIdInSnapshot,_that.lastExecutedValues,_that.plannedRestSeconds,_that.plannedExerciseName,_that.isLoggable,_that.plannedGroupRole);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionExerciseId,  String displayExerciseName,  ExerciseMetadata? displayMetadata,  MeasurementType effectiveMeasurementType,  int currentSetIndex,  int totalPlannedSets,  int completedSetsCount,  PlannedSetValues? currentPlannedValues,  String plannedSummary,  String? currentPlannedSetIdInSnapshot,  ActualSetValues? lastExecutedValues,  int? plannedRestSeconds,  String plannedExerciseName,  bool isLoggable,  ExerciseGroupRole plannedGroupRole)?  $default,) {final _that = this;
switch (_that) {
case _FocusModeViewModel() when $default != null:
return $default(_that.sessionExerciseId,_that.displayExerciseName,_that.displayMetadata,_that.effectiveMeasurementType,_that.currentSetIndex,_that.totalPlannedSets,_that.completedSetsCount,_that.currentPlannedValues,_that.plannedSummary,_that.currentPlannedSetIdInSnapshot,_that.lastExecutedValues,_that.plannedRestSeconds,_that.plannedExerciseName,_that.isLoggable,_that.plannedGroupRole);case _:
  return null;

}
}

}

/// @nodoc


class _FocusModeViewModel implements FocusModeViewModel {
  const _FocusModeViewModel({required this.sessionExerciseId, required this.displayExerciseName, required this.displayMetadata, required this.effectiveMeasurementType, required this.currentSetIndex, required this.totalPlannedSets, required this.completedSetsCount, required this.currentPlannedValues, required this.plannedSummary, required this.currentPlannedSetIdInSnapshot, required this.lastExecutedValues, required this.plannedRestSeconds, required this.plannedExerciseName, required this.isLoggable, this.plannedGroupRole = ExerciseGroupRole.main});
  

@override final  String sessionExerciseId;
@override final  String displayExerciseName;
@override final  ExerciseMetadata? displayMetadata;
@override final  MeasurementType effectiveMeasurementType;
/// 0-based index of the set the user is about to log on this exercise.
/// Equals `executedSets.length` for loggable panels; equals
/// `plannedSetCount` for completed panels (past the last planned slot).
@override final  int currentSetIndex;
/// Number of planned sets for this exercise. May be 0 for snapshot-only
/// planned exercises that were stripped of sets.
@override final  int totalPlannedSets;
/// Always equals `executedSets.length` for the panel exercise.
@override final  int completedSetsCount;
/// Planned values for the current set index, or null when the panel is
/// past the planned set list (e.g. completed, or extra sets on a
/// replaced exercise).
@override final  PlannedSetValues? currentPlannedValues;
/// Pre-formatted "100kg 4 × 8" summary of all planned sets.
@override final  String plannedSummary;
/// Identity of the planned set being targeted; copied onto the logged
/// [ExecutedSet] when known.
@override final  String? currentPlannedSetIdInSnapshot;
/// Actual values from the last completed set on this exercise.
@override final  ActualSetValues? lastExecutedValues;
/// Coach-defined rest, propagated from the planned exercise. Drives the
/// shared rest-timer's planned/remaining display.
@override final  int? plannedRestSeconds;
/// The planned exercise's name (for a snapshot-backed exercise the snapshot
/// entry; for an added exercise the inline plan's name).
@override final  String plannedExerciseName;
/// True when the user can still log a working set on this exercise —
/// i.e. state is `unfinished` and `executedSets.length < plannedSetCount`.
/// False for completed/skipped panels.
@override final  bool isLoggable;
@override@JsonKey() final  ExerciseGroupRole plannedGroupRole;

/// Create a copy of FocusModeViewModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FocusModeViewModelCopyWith<_FocusModeViewModel> get copyWith => __$FocusModeViewModelCopyWithImpl<_FocusModeViewModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FocusModeViewModel&&(identical(other.sessionExerciseId, sessionExerciseId) || other.sessionExerciseId == sessionExerciseId)&&(identical(other.displayExerciseName, displayExerciseName) || other.displayExerciseName == displayExerciseName)&&(identical(other.displayMetadata, displayMetadata) || other.displayMetadata == displayMetadata)&&(identical(other.effectiveMeasurementType, effectiveMeasurementType) || other.effectiveMeasurementType == effectiveMeasurementType)&&(identical(other.currentSetIndex, currentSetIndex) || other.currentSetIndex == currentSetIndex)&&(identical(other.totalPlannedSets, totalPlannedSets) || other.totalPlannedSets == totalPlannedSets)&&(identical(other.completedSetsCount, completedSetsCount) || other.completedSetsCount == completedSetsCount)&&(identical(other.currentPlannedValues, currentPlannedValues) || other.currentPlannedValues == currentPlannedValues)&&(identical(other.plannedSummary, plannedSummary) || other.plannedSummary == plannedSummary)&&(identical(other.currentPlannedSetIdInSnapshot, currentPlannedSetIdInSnapshot) || other.currentPlannedSetIdInSnapshot == currentPlannedSetIdInSnapshot)&&(identical(other.lastExecutedValues, lastExecutedValues) || other.lastExecutedValues == lastExecutedValues)&&(identical(other.plannedRestSeconds, plannedRestSeconds) || other.plannedRestSeconds == plannedRestSeconds)&&(identical(other.plannedExerciseName, plannedExerciseName) || other.plannedExerciseName == plannedExerciseName)&&(identical(other.isLoggable, isLoggable) || other.isLoggable == isLoggable)&&(identical(other.plannedGroupRole, plannedGroupRole) || other.plannedGroupRole == plannedGroupRole));
}


@override
int get hashCode => Object.hash(runtimeType,sessionExerciseId,displayExerciseName,displayMetadata,effectiveMeasurementType,currentSetIndex,totalPlannedSets,completedSetsCount,currentPlannedValues,plannedSummary,currentPlannedSetIdInSnapshot,lastExecutedValues,plannedRestSeconds,plannedExerciseName,isLoggable,plannedGroupRole);

@override
String toString() {
  return 'FocusModeViewModel(sessionExerciseId: $sessionExerciseId, displayExerciseName: $displayExerciseName, displayMetadata: $displayMetadata, effectiveMeasurementType: $effectiveMeasurementType, currentSetIndex: $currentSetIndex, totalPlannedSets: $totalPlannedSets, completedSetsCount: $completedSetsCount, currentPlannedValues: $currentPlannedValues, plannedSummary: $plannedSummary, currentPlannedSetIdInSnapshot: $currentPlannedSetIdInSnapshot, lastExecutedValues: $lastExecutedValues, plannedRestSeconds: $plannedRestSeconds, plannedExerciseName: $plannedExerciseName, isLoggable: $isLoggable, plannedGroupRole: $plannedGroupRole)';
}


}

/// @nodoc
abstract mixin class _$FocusModeViewModelCopyWith<$Res> implements $FocusModeViewModelCopyWith<$Res> {
  factory _$FocusModeViewModelCopyWith(_FocusModeViewModel value, $Res Function(_FocusModeViewModel) _then) = __$FocusModeViewModelCopyWithImpl;
@override @useResult
$Res call({
 String sessionExerciseId, String displayExerciseName, ExerciseMetadata? displayMetadata, MeasurementType effectiveMeasurementType, int currentSetIndex, int totalPlannedSets, int completedSetsCount, PlannedSetValues? currentPlannedValues, String plannedSummary, String? currentPlannedSetIdInSnapshot, ActualSetValues? lastExecutedValues, int? plannedRestSeconds, String plannedExerciseName, bool isLoggable, ExerciseGroupRole plannedGroupRole
});


@override $ExerciseMetadataCopyWith<$Res>? get displayMetadata;@override $MeasurementTypeCopyWith<$Res> get effectiveMeasurementType;@override $PlannedSetValuesCopyWith<$Res>? get currentPlannedValues;@override $ActualSetValuesCopyWith<$Res>? get lastExecutedValues;

}
/// @nodoc
class __$FocusModeViewModelCopyWithImpl<$Res>
    implements _$FocusModeViewModelCopyWith<$Res> {
  __$FocusModeViewModelCopyWithImpl(this._self, this._then);

  final _FocusModeViewModel _self;
  final $Res Function(_FocusModeViewModel) _then;

/// Create a copy of FocusModeViewModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionExerciseId = null,Object? displayExerciseName = null,Object? displayMetadata = freezed,Object? effectiveMeasurementType = null,Object? currentSetIndex = null,Object? totalPlannedSets = null,Object? completedSetsCount = null,Object? currentPlannedValues = freezed,Object? plannedSummary = null,Object? currentPlannedSetIdInSnapshot = freezed,Object? lastExecutedValues = freezed,Object? plannedRestSeconds = freezed,Object? plannedExerciseName = null,Object? isLoggable = null,Object? plannedGroupRole = null,}) {
  return _then(_FocusModeViewModel(
sessionExerciseId: null == sessionExerciseId ? _self.sessionExerciseId : sessionExerciseId // ignore: cast_nullable_to_non_nullable
as String,displayExerciseName: null == displayExerciseName ? _self.displayExerciseName : displayExerciseName // ignore: cast_nullable_to_non_nullable
as String,displayMetadata: freezed == displayMetadata ? _self.displayMetadata : displayMetadata // ignore: cast_nullable_to_non_nullable
as ExerciseMetadata?,effectiveMeasurementType: null == effectiveMeasurementType ? _self.effectiveMeasurementType : effectiveMeasurementType // ignore: cast_nullable_to_non_nullable
as MeasurementType,currentSetIndex: null == currentSetIndex ? _self.currentSetIndex : currentSetIndex // ignore: cast_nullable_to_non_nullable
as int,totalPlannedSets: null == totalPlannedSets ? _self.totalPlannedSets : totalPlannedSets // ignore: cast_nullable_to_non_nullable
as int,completedSetsCount: null == completedSetsCount ? _self.completedSetsCount : completedSetsCount // ignore: cast_nullable_to_non_nullable
as int,currentPlannedValues: freezed == currentPlannedValues ? _self.currentPlannedValues : currentPlannedValues // ignore: cast_nullable_to_non_nullable
as PlannedSetValues?,plannedSummary: null == plannedSummary ? _self.plannedSummary : plannedSummary // ignore: cast_nullable_to_non_nullable
as String,currentPlannedSetIdInSnapshot: freezed == currentPlannedSetIdInSnapshot ? _self.currentPlannedSetIdInSnapshot : currentPlannedSetIdInSnapshot // ignore: cast_nullable_to_non_nullable
as String?,lastExecutedValues: freezed == lastExecutedValues ? _self.lastExecutedValues : lastExecutedValues // ignore: cast_nullable_to_non_nullable
as ActualSetValues?,plannedRestSeconds: freezed == plannedRestSeconds ? _self.plannedRestSeconds : plannedRestSeconds // ignore: cast_nullable_to_non_nullable
as int?,plannedExerciseName: null == plannedExerciseName ? _self.plannedExerciseName : plannedExerciseName // ignore: cast_nullable_to_non_nullable
as String,isLoggable: null == isLoggable ? _self.isLoggable : isLoggable // ignore: cast_nullable_to_non_nullable
as bool,plannedGroupRole: null == plannedGroupRole ? _self.plannedGroupRole : plannedGroupRole // ignore: cast_nullable_to_non_nullable
as ExerciseGroupRole,
  ));
}

/// Create a copy of FocusModeViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseMetadataCopyWith<$Res>? get displayMetadata {
    if (_self.displayMetadata == null) {
    return null;
  }

  return $ExerciseMetadataCopyWith<$Res>(_self.displayMetadata!, (value) {
    return _then(_self.copyWith(displayMetadata: value));
  });
}/// Create a copy of FocusModeViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementTypeCopyWith<$Res> get effectiveMeasurementType {
  
  return $MeasurementTypeCopyWith<$Res>(_self.effectiveMeasurementType, (value) {
    return _then(_self.copyWith(effectiveMeasurementType: value));
  });
}/// Create a copy of FocusModeViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlannedSetValuesCopyWith<$Res>? get currentPlannedValues {
    if (_self.currentPlannedValues == null) {
    return null;
  }

  return $PlannedSetValuesCopyWith<$Res>(_self.currentPlannedValues!, (value) {
    return _then(_self.copyWith(currentPlannedValues: value));
  });
}/// Create a copy of FocusModeViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActualSetValuesCopyWith<$Res>? get lastExecutedValues {
    if (_self.lastExecutedValues == null) {
    return null;
  }

  return $ActualSetValuesCopyWith<$Res>(_self.lastExecutedValues!, (value) {
    return _then(_self.copyWith(lastExecutedValues: value));
  });
}
}

// dart format on

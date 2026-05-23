// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'focus_mode_group_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FocusModeGroupViewModel {

 String get sessionId; String get workoutDayName;/// Shared superset tag, or null when the group is a single exercise.
 String? get supersetTag;/// Panels in this group, in position order. Includes only exercises
/// that are still loggable or completed — skipped exercises are hidden
/// from focus mode.
 List<FocusModeViewModel> get panels;/// Display name of the next group past this one — either a single
/// exercise name or a "Superset (A + B)" label. Null when this is the
/// last group with any open or completed panels.
 String? get upNextGroupLabel;/// Session-exercise id of the first loggable exercise in the next
/// group, used as the anchor when the user taps "switch to next".
/// Null when no next group has open targets.
 String? get upNextGroupAnchorId;/// Session-exercise id of the panel that should render as ACTIVE
/// (full editor + target of the pinned LOG SET button). Equals the
/// only loggable panel for singles; chosen by auto-rotation or by a
/// user pin in supersets. Null when no panel in the group is
/// loggable (terminal group; bloc transitions away).
 String? get activeSessionExerciseId;/// True when [activeSessionExerciseId] was chosen by the user via a
/// manual pin, false when chosen by auto-rotation. Used for
/// analytics/diagnostics only; UI doesn't need to differentiate.
 bool get activeIsUserPinned;
/// Create a copy of FocusModeGroupViewModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FocusModeGroupViewModelCopyWith<FocusModeGroupViewModel> get copyWith => _$FocusModeGroupViewModelCopyWithImpl<FocusModeGroupViewModel>(this as FocusModeGroupViewModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FocusModeGroupViewModel&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.workoutDayName, workoutDayName) || other.workoutDayName == workoutDayName)&&(identical(other.supersetTag, supersetTag) || other.supersetTag == supersetTag)&&const DeepCollectionEquality().equals(other.panels, panels)&&(identical(other.upNextGroupLabel, upNextGroupLabel) || other.upNextGroupLabel == upNextGroupLabel)&&(identical(other.upNextGroupAnchorId, upNextGroupAnchorId) || other.upNextGroupAnchorId == upNextGroupAnchorId)&&(identical(other.activeSessionExerciseId, activeSessionExerciseId) || other.activeSessionExerciseId == activeSessionExerciseId)&&(identical(other.activeIsUserPinned, activeIsUserPinned) || other.activeIsUserPinned == activeIsUserPinned));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,workoutDayName,supersetTag,const DeepCollectionEquality().hash(panels),upNextGroupLabel,upNextGroupAnchorId,activeSessionExerciseId,activeIsUserPinned);

@override
String toString() {
  return 'FocusModeGroupViewModel(sessionId: $sessionId, workoutDayName: $workoutDayName, supersetTag: $supersetTag, panels: $panels, upNextGroupLabel: $upNextGroupLabel, upNextGroupAnchorId: $upNextGroupAnchorId, activeSessionExerciseId: $activeSessionExerciseId, activeIsUserPinned: $activeIsUserPinned)';
}


}

/// @nodoc
abstract mixin class $FocusModeGroupViewModelCopyWith<$Res>  {
  factory $FocusModeGroupViewModelCopyWith(FocusModeGroupViewModel value, $Res Function(FocusModeGroupViewModel) _then) = _$FocusModeGroupViewModelCopyWithImpl;
@useResult
$Res call({
 String sessionId, String workoutDayName, String? supersetTag, List<FocusModeViewModel> panels, String? upNextGroupLabel, String? upNextGroupAnchorId, String? activeSessionExerciseId, bool activeIsUserPinned
});




}
/// @nodoc
class _$FocusModeGroupViewModelCopyWithImpl<$Res>
    implements $FocusModeGroupViewModelCopyWith<$Res> {
  _$FocusModeGroupViewModelCopyWithImpl(this._self, this._then);

  final FocusModeGroupViewModel _self;
  final $Res Function(FocusModeGroupViewModel) _then;

/// Create a copy of FocusModeGroupViewModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? workoutDayName = null,Object? supersetTag = freezed,Object? panels = null,Object? upNextGroupLabel = freezed,Object? upNextGroupAnchorId = freezed,Object? activeSessionExerciseId = freezed,Object? activeIsUserPinned = null,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,workoutDayName: null == workoutDayName ? _self.workoutDayName : workoutDayName // ignore: cast_nullable_to_non_nullable
as String,supersetTag: freezed == supersetTag ? _self.supersetTag : supersetTag // ignore: cast_nullable_to_non_nullable
as String?,panels: null == panels ? _self.panels : panels // ignore: cast_nullable_to_non_nullable
as List<FocusModeViewModel>,upNextGroupLabel: freezed == upNextGroupLabel ? _self.upNextGroupLabel : upNextGroupLabel // ignore: cast_nullable_to_non_nullable
as String?,upNextGroupAnchorId: freezed == upNextGroupAnchorId ? _self.upNextGroupAnchorId : upNextGroupAnchorId // ignore: cast_nullable_to_non_nullable
as String?,activeSessionExerciseId: freezed == activeSessionExerciseId ? _self.activeSessionExerciseId : activeSessionExerciseId // ignore: cast_nullable_to_non_nullable
as String?,activeIsUserPinned: null == activeIsUserPinned ? _self.activeIsUserPinned : activeIsUserPinned // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FocusModeGroupViewModel].
extension FocusModeGroupViewModelPatterns on FocusModeGroupViewModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FocusModeGroupViewModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FocusModeGroupViewModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FocusModeGroupViewModel value)  $default,){
final _that = this;
switch (_that) {
case _FocusModeGroupViewModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FocusModeGroupViewModel value)?  $default,){
final _that = this;
switch (_that) {
case _FocusModeGroupViewModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId,  String workoutDayName,  String? supersetTag,  List<FocusModeViewModel> panels,  String? upNextGroupLabel,  String? upNextGroupAnchorId,  String? activeSessionExerciseId,  bool activeIsUserPinned)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FocusModeGroupViewModel() when $default != null:
return $default(_that.sessionId,_that.workoutDayName,_that.supersetTag,_that.panels,_that.upNextGroupLabel,_that.upNextGroupAnchorId,_that.activeSessionExerciseId,_that.activeIsUserPinned);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId,  String workoutDayName,  String? supersetTag,  List<FocusModeViewModel> panels,  String? upNextGroupLabel,  String? upNextGroupAnchorId,  String? activeSessionExerciseId,  bool activeIsUserPinned)  $default,) {final _that = this;
switch (_that) {
case _FocusModeGroupViewModel():
return $default(_that.sessionId,_that.workoutDayName,_that.supersetTag,_that.panels,_that.upNextGroupLabel,_that.upNextGroupAnchorId,_that.activeSessionExerciseId,_that.activeIsUserPinned);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId,  String workoutDayName,  String? supersetTag,  List<FocusModeViewModel> panels,  String? upNextGroupLabel,  String? upNextGroupAnchorId,  String? activeSessionExerciseId,  bool activeIsUserPinned)?  $default,) {final _that = this;
switch (_that) {
case _FocusModeGroupViewModel() when $default != null:
return $default(_that.sessionId,_that.workoutDayName,_that.supersetTag,_that.panels,_that.upNextGroupLabel,_that.upNextGroupAnchorId,_that.activeSessionExerciseId,_that.activeIsUserPinned);case _:
  return null;

}
}

}

/// @nodoc


class _FocusModeGroupViewModel implements FocusModeGroupViewModel {
  const _FocusModeGroupViewModel({required this.sessionId, required this.workoutDayName, required this.supersetTag, required final  List<FocusModeViewModel> panels, required this.upNextGroupLabel, required this.upNextGroupAnchorId, required this.activeSessionExerciseId, this.activeIsUserPinned = false}): _panels = panels;
  

@override final  String sessionId;
@override final  String workoutDayName;
/// Shared superset tag, or null when the group is a single exercise.
@override final  String? supersetTag;
/// Panels in this group, in position order. Includes only exercises
/// that are still loggable or completed — skipped exercises are hidden
/// from focus mode.
 final  List<FocusModeViewModel> _panels;
/// Panels in this group, in position order. Includes only exercises
/// that are still loggable or completed — skipped exercises are hidden
/// from focus mode.
@override List<FocusModeViewModel> get panels {
  if (_panels is EqualUnmodifiableListView) return _panels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_panels);
}

/// Display name of the next group past this one — either a single
/// exercise name or a "Superset (A + B)" label. Null when this is the
/// last group with any open or completed panels.
@override final  String? upNextGroupLabel;
/// Session-exercise id of the first loggable exercise in the next
/// group, used as the anchor when the user taps "switch to next".
/// Null when no next group has open targets.
@override final  String? upNextGroupAnchorId;
/// Session-exercise id of the panel that should render as ACTIVE
/// (full editor + target of the pinned LOG SET button). Equals the
/// only loggable panel for singles; chosen by auto-rotation or by a
/// user pin in supersets. Null when no panel in the group is
/// loggable (terminal group; bloc transitions away).
@override final  String? activeSessionExerciseId;
/// True when [activeSessionExerciseId] was chosen by the user via a
/// manual pin, false when chosen by auto-rotation. Used for
/// analytics/diagnostics only; UI doesn't need to differentiate.
@override@JsonKey() final  bool activeIsUserPinned;

/// Create a copy of FocusModeGroupViewModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FocusModeGroupViewModelCopyWith<_FocusModeGroupViewModel> get copyWith => __$FocusModeGroupViewModelCopyWithImpl<_FocusModeGroupViewModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FocusModeGroupViewModel&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.workoutDayName, workoutDayName) || other.workoutDayName == workoutDayName)&&(identical(other.supersetTag, supersetTag) || other.supersetTag == supersetTag)&&const DeepCollectionEquality().equals(other._panels, _panels)&&(identical(other.upNextGroupLabel, upNextGroupLabel) || other.upNextGroupLabel == upNextGroupLabel)&&(identical(other.upNextGroupAnchorId, upNextGroupAnchorId) || other.upNextGroupAnchorId == upNextGroupAnchorId)&&(identical(other.activeSessionExerciseId, activeSessionExerciseId) || other.activeSessionExerciseId == activeSessionExerciseId)&&(identical(other.activeIsUserPinned, activeIsUserPinned) || other.activeIsUserPinned == activeIsUserPinned));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,workoutDayName,supersetTag,const DeepCollectionEquality().hash(_panels),upNextGroupLabel,upNextGroupAnchorId,activeSessionExerciseId,activeIsUserPinned);

@override
String toString() {
  return 'FocusModeGroupViewModel(sessionId: $sessionId, workoutDayName: $workoutDayName, supersetTag: $supersetTag, panels: $panels, upNextGroupLabel: $upNextGroupLabel, upNextGroupAnchorId: $upNextGroupAnchorId, activeSessionExerciseId: $activeSessionExerciseId, activeIsUserPinned: $activeIsUserPinned)';
}


}

/// @nodoc
abstract mixin class _$FocusModeGroupViewModelCopyWith<$Res> implements $FocusModeGroupViewModelCopyWith<$Res> {
  factory _$FocusModeGroupViewModelCopyWith(_FocusModeGroupViewModel value, $Res Function(_FocusModeGroupViewModel) _then) = __$FocusModeGroupViewModelCopyWithImpl;
@override @useResult
$Res call({
 String sessionId, String workoutDayName, String? supersetTag, List<FocusModeViewModel> panels, String? upNextGroupLabel, String? upNextGroupAnchorId, String? activeSessionExerciseId, bool activeIsUserPinned
});




}
/// @nodoc
class __$FocusModeGroupViewModelCopyWithImpl<$Res>
    implements _$FocusModeGroupViewModelCopyWith<$Res> {
  __$FocusModeGroupViewModelCopyWithImpl(this._self, this._then);

  final _FocusModeGroupViewModel _self;
  final $Res Function(_FocusModeGroupViewModel) _then;

/// Create a copy of FocusModeGroupViewModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? workoutDayName = null,Object? supersetTag = freezed,Object? panels = null,Object? upNextGroupLabel = freezed,Object? upNextGroupAnchorId = freezed,Object? activeSessionExerciseId = freezed,Object? activeIsUserPinned = null,}) {
  return _then(_FocusModeGroupViewModel(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,workoutDayName: null == workoutDayName ? _self.workoutDayName : workoutDayName // ignore: cast_nullable_to_non_nullable
as String,supersetTag: freezed == supersetTag ? _self.supersetTag : supersetTag // ignore: cast_nullable_to_non_nullable
as String?,panels: null == panels ? _self._panels : panels // ignore: cast_nullable_to_non_nullable
as List<FocusModeViewModel>,upNextGroupLabel: freezed == upNextGroupLabel ? _self.upNextGroupLabel : upNextGroupLabel // ignore: cast_nullable_to_non_nullable
as String?,upNextGroupAnchorId: freezed == upNextGroupAnchorId ? _self.upNextGroupAnchorId : upNextGroupAnchorId // ignore: cast_nullable_to_non_nullable
as String?,activeSessionExerciseId: freezed == activeSessionExerciseId ? _self.activeSessionExerciseId : activeSessionExerciseId // ignore: cast_nullable_to_non_nullable
as String?,activeIsUserPinned: null == activeIsUserPinned ? _self.activeIsUserPinned : activeIsUserPinned // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'set_row_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SetRowViewModel {

 int get position; PlannedSetValues? get plannedValues; String? get plannedSetIdInSnapshot; ExecutedSet? get executedSet;/// True when this row is the next chronological slot to log on a
/// loggable exercise — equivalent to `position == executedSets.length`
/// for an exercise present in [SessionState.openTargets]. UI renders
/// loggable rows pre-expanded with an inline editor; all other unlogged
/// rows render as inert "future" rows.
 bool get isLoggable; ActualSetValues? get suggestedActualValues;
/// Create a copy of SetRowViewModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetRowViewModelCopyWith<SetRowViewModel> get copyWith => _$SetRowViewModelCopyWithImpl<SetRowViewModel>(this as SetRowViewModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetRowViewModel&&(identical(other.position, position) || other.position == position)&&(identical(other.plannedValues, plannedValues) || other.plannedValues == plannedValues)&&(identical(other.plannedSetIdInSnapshot, plannedSetIdInSnapshot) || other.plannedSetIdInSnapshot == plannedSetIdInSnapshot)&&(identical(other.executedSet, executedSet) || other.executedSet == executedSet)&&(identical(other.isLoggable, isLoggable) || other.isLoggable == isLoggable)&&(identical(other.suggestedActualValues, suggestedActualValues) || other.suggestedActualValues == suggestedActualValues));
}


@override
int get hashCode => Object.hash(runtimeType,position,plannedValues,plannedSetIdInSnapshot,executedSet,isLoggable,suggestedActualValues);

@override
String toString() {
  return 'SetRowViewModel(position: $position, plannedValues: $plannedValues, plannedSetIdInSnapshot: $plannedSetIdInSnapshot, executedSet: $executedSet, isLoggable: $isLoggable, suggestedActualValues: $suggestedActualValues)';
}


}

/// @nodoc
abstract mixin class $SetRowViewModelCopyWith<$Res>  {
  factory $SetRowViewModelCopyWith(SetRowViewModel value, $Res Function(SetRowViewModel) _then) = _$SetRowViewModelCopyWithImpl;
@useResult
$Res call({
 int position, PlannedSetValues? plannedValues, String? plannedSetIdInSnapshot, ExecutedSet? executedSet, bool isLoggable, ActualSetValues? suggestedActualValues
});


$PlannedSetValuesCopyWith<$Res>? get plannedValues;$ExecutedSetCopyWith<$Res>? get executedSet;$ActualSetValuesCopyWith<$Res>? get suggestedActualValues;

}
/// @nodoc
class _$SetRowViewModelCopyWithImpl<$Res>
    implements $SetRowViewModelCopyWith<$Res> {
  _$SetRowViewModelCopyWithImpl(this._self, this._then);

  final SetRowViewModel _self;
  final $Res Function(SetRowViewModel) _then;

/// Create a copy of SetRowViewModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? position = null,Object? plannedValues = freezed,Object? plannedSetIdInSnapshot = freezed,Object? executedSet = freezed,Object? isLoggable = null,Object? suggestedActualValues = freezed,}) {
  return _then(_self.copyWith(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,plannedValues: freezed == plannedValues ? _self.plannedValues : plannedValues // ignore: cast_nullable_to_non_nullable
as PlannedSetValues?,plannedSetIdInSnapshot: freezed == plannedSetIdInSnapshot ? _self.plannedSetIdInSnapshot : plannedSetIdInSnapshot // ignore: cast_nullable_to_non_nullable
as String?,executedSet: freezed == executedSet ? _self.executedSet : executedSet // ignore: cast_nullable_to_non_nullable
as ExecutedSet?,isLoggable: null == isLoggable ? _self.isLoggable : isLoggable // ignore: cast_nullable_to_non_nullable
as bool,suggestedActualValues: freezed == suggestedActualValues ? _self.suggestedActualValues : suggestedActualValues // ignore: cast_nullable_to_non_nullable
as ActualSetValues?,
  ));
}
/// Create a copy of SetRowViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlannedSetValuesCopyWith<$Res>? get plannedValues {
    if (_self.plannedValues == null) {
    return null;
  }

  return $PlannedSetValuesCopyWith<$Res>(_self.plannedValues!, (value) {
    return _then(_self.copyWith(plannedValues: value));
  });
}/// Create a copy of SetRowViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExecutedSetCopyWith<$Res>? get executedSet {
    if (_self.executedSet == null) {
    return null;
  }

  return $ExecutedSetCopyWith<$Res>(_self.executedSet!, (value) {
    return _then(_self.copyWith(executedSet: value));
  });
}/// Create a copy of SetRowViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActualSetValuesCopyWith<$Res>? get suggestedActualValues {
    if (_self.suggestedActualValues == null) {
    return null;
  }

  return $ActualSetValuesCopyWith<$Res>(_self.suggestedActualValues!, (value) {
    return _then(_self.copyWith(suggestedActualValues: value));
  });
}
}


/// Adds pattern-matching-related methods to [SetRowViewModel].
extension SetRowViewModelPatterns on SetRowViewModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SetRowViewModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SetRowViewModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SetRowViewModel value)  $default,){
final _that = this;
switch (_that) {
case _SetRowViewModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SetRowViewModel value)?  $default,){
final _that = this;
switch (_that) {
case _SetRowViewModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int position,  PlannedSetValues? plannedValues,  String? plannedSetIdInSnapshot,  ExecutedSet? executedSet,  bool isLoggable,  ActualSetValues? suggestedActualValues)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SetRowViewModel() when $default != null:
return $default(_that.position,_that.plannedValues,_that.plannedSetIdInSnapshot,_that.executedSet,_that.isLoggable,_that.suggestedActualValues);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int position,  PlannedSetValues? plannedValues,  String? plannedSetIdInSnapshot,  ExecutedSet? executedSet,  bool isLoggable,  ActualSetValues? suggestedActualValues)  $default,) {final _that = this;
switch (_that) {
case _SetRowViewModel():
return $default(_that.position,_that.plannedValues,_that.plannedSetIdInSnapshot,_that.executedSet,_that.isLoggable,_that.suggestedActualValues);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int position,  PlannedSetValues? plannedValues,  String? plannedSetIdInSnapshot,  ExecutedSet? executedSet,  bool isLoggable,  ActualSetValues? suggestedActualValues)?  $default,) {final _that = this;
switch (_that) {
case _SetRowViewModel() when $default != null:
return $default(_that.position,_that.plannedValues,_that.plannedSetIdInSnapshot,_that.executedSet,_that.isLoggable,_that.suggestedActualValues);case _:
  return null;

}
}

}

/// @nodoc


class _SetRowViewModel implements SetRowViewModel {
  const _SetRowViewModel({required this.position, required this.plannedValues, required this.plannedSetIdInSnapshot, required this.executedSet, required this.isLoggable, this.suggestedActualValues});
  

@override final  int position;
@override final  PlannedSetValues? plannedValues;
@override final  String? plannedSetIdInSnapshot;
@override final  ExecutedSet? executedSet;
/// True when this row is the next chronological slot to log on a
/// loggable exercise — equivalent to `position == executedSets.length`
/// for an exercise present in [SessionState.openTargets]. UI renders
/// loggable rows pre-expanded with an inline editor; all other unlogged
/// rows render as inert "future" rows.
@override final  bool isLoggable;
@override final  ActualSetValues? suggestedActualValues;

/// Create a copy of SetRowViewModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SetRowViewModelCopyWith<_SetRowViewModel> get copyWith => __$SetRowViewModelCopyWithImpl<_SetRowViewModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SetRowViewModel&&(identical(other.position, position) || other.position == position)&&(identical(other.plannedValues, plannedValues) || other.plannedValues == plannedValues)&&(identical(other.plannedSetIdInSnapshot, plannedSetIdInSnapshot) || other.plannedSetIdInSnapshot == plannedSetIdInSnapshot)&&(identical(other.executedSet, executedSet) || other.executedSet == executedSet)&&(identical(other.isLoggable, isLoggable) || other.isLoggable == isLoggable)&&(identical(other.suggestedActualValues, suggestedActualValues) || other.suggestedActualValues == suggestedActualValues));
}


@override
int get hashCode => Object.hash(runtimeType,position,plannedValues,plannedSetIdInSnapshot,executedSet,isLoggable,suggestedActualValues);

@override
String toString() {
  return 'SetRowViewModel(position: $position, plannedValues: $plannedValues, plannedSetIdInSnapshot: $plannedSetIdInSnapshot, executedSet: $executedSet, isLoggable: $isLoggable, suggestedActualValues: $suggestedActualValues)';
}


}

/// @nodoc
abstract mixin class _$SetRowViewModelCopyWith<$Res> implements $SetRowViewModelCopyWith<$Res> {
  factory _$SetRowViewModelCopyWith(_SetRowViewModel value, $Res Function(_SetRowViewModel) _then) = __$SetRowViewModelCopyWithImpl;
@override @useResult
$Res call({
 int position, PlannedSetValues? plannedValues, String? plannedSetIdInSnapshot, ExecutedSet? executedSet, bool isLoggable, ActualSetValues? suggestedActualValues
});


@override $PlannedSetValuesCopyWith<$Res>? get plannedValues;@override $ExecutedSetCopyWith<$Res>? get executedSet;@override $ActualSetValuesCopyWith<$Res>? get suggestedActualValues;

}
/// @nodoc
class __$SetRowViewModelCopyWithImpl<$Res>
    implements _$SetRowViewModelCopyWith<$Res> {
  __$SetRowViewModelCopyWithImpl(this._self, this._then);

  final _SetRowViewModel _self;
  final $Res Function(_SetRowViewModel) _then;

/// Create a copy of SetRowViewModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? position = null,Object? plannedValues = freezed,Object? plannedSetIdInSnapshot = freezed,Object? executedSet = freezed,Object? isLoggable = null,Object? suggestedActualValues = freezed,}) {
  return _then(_SetRowViewModel(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,plannedValues: freezed == plannedValues ? _self.plannedValues : plannedValues // ignore: cast_nullable_to_non_nullable
as PlannedSetValues?,plannedSetIdInSnapshot: freezed == plannedSetIdInSnapshot ? _self.plannedSetIdInSnapshot : plannedSetIdInSnapshot // ignore: cast_nullable_to_non_nullable
as String?,executedSet: freezed == executedSet ? _self.executedSet : executedSet // ignore: cast_nullable_to_non_nullable
as ExecutedSet?,isLoggable: null == isLoggable ? _self.isLoggable : isLoggable // ignore: cast_nullable_to_non_nullable
as bool,suggestedActualValues: freezed == suggestedActualValues ? _self.suggestedActualValues : suggestedActualValues // ignore: cast_nullable_to_non_nullable
as ActualSetValues?,
  ));
}

/// Create a copy of SetRowViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlannedSetValuesCopyWith<$Res>? get plannedValues {
    if (_self.plannedValues == null) {
    return null;
  }

  return $PlannedSetValuesCopyWith<$Res>(_self.plannedValues!, (value) {
    return _then(_self.copyWith(plannedValues: value));
  });
}/// Create a copy of SetRowViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExecutedSetCopyWith<$Res>? get executedSet {
    if (_self.executedSet == null) {
    return null;
  }

  return $ExecutedSetCopyWith<$Res>(_self.executedSet!, (value) {
    return _then(_self.copyWith(executedSet: value));
  });
}/// Create a copy of SetRowViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActualSetValuesCopyWith<$Res>? get suggestedActualValues {
    if (_self.suggestedActualValues == null) {
    return null;
  }

  return $ActualSetValuesCopyWith<$Res>(_self.suggestedActualValues!, (value) {
    return _then(_self.copyWith(suggestedActualValues: value));
  });
}
}

// dart format on

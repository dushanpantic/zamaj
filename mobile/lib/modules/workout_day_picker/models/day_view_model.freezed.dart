// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'day_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DayTileStatus {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayTileStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DayTileStatus()';
}


}

/// @nodoc
class $DayTileStatusCopyWith<$Res>  {
$DayTileStatusCopyWith(DayTileStatus _, $Res Function(DayTileStatus) __);
}


/// Adds pattern-matching-related methods to [DayTileStatus].
extension DayTileStatusPatterns on DayTileStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DayTileLoading value)?  loading,TResult Function( DayTileLoaded value)?  loaded,TResult Function( DayTileFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DayTileLoading() when loading != null:
return loading(_that);case DayTileLoaded() when loaded != null:
return loaded(_that);case DayTileFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DayTileLoading value)  loading,required TResult Function( DayTileLoaded value)  loaded,required TResult Function( DayTileFailure value)  failure,}){
final _that = this;
switch (_that) {
case DayTileLoading():
return loading(_that);case DayTileLoaded():
return loaded(_that);case DayTileFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DayTileLoading value)?  loading,TResult? Function( DayTileLoaded value)?  loaded,TResult? Function( DayTileFailure value)?  failure,}){
final _that = this;
switch (_that) {
case DayTileLoading() when loading != null:
return loading(_that);case DayTileLoaded() when loaded != null:
return loaded(_that);case DayTileFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( DayHistorySummary summary)?  loaded,TResult Function( DomainError error)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DayTileLoading() when loading != null:
return loading();case DayTileLoaded() when loaded != null:
return loaded(_that.summary);case DayTileFailure() when failure != null:
return failure(_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( DayHistorySummary summary)  loaded,required TResult Function( DomainError error)  failure,}) {final _that = this;
switch (_that) {
case DayTileLoading():
return loading();case DayTileLoaded():
return loaded(_that.summary);case DayTileFailure():
return failure(_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( DayHistorySummary summary)?  loaded,TResult? Function( DomainError error)?  failure,}) {final _that = this;
switch (_that) {
case DayTileLoading() when loading != null:
return loading();case DayTileLoaded() when loaded != null:
return loaded(_that.summary);case DayTileFailure() when failure != null:
return failure(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class DayTileLoading implements DayTileStatus {
  const DayTileLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayTileLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DayTileStatus.loading()';
}


}




/// @nodoc


class DayTileLoaded implements DayTileStatus {
  const DayTileLoaded(this.summary);
  

 final  DayHistorySummary summary;

/// Create a copy of DayTileStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayTileLoadedCopyWith<DayTileLoaded> get copyWith => _$DayTileLoadedCopyWithImpl<DayTileLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayTileLoaded&&(identical(other.summary, summary) || other.summary == summary));
}


@override
int get hashCode => Object.hash(runtimeType,summary);

@override
String toString() {
  return 'DayTileStatus.loaded(summary: $summary)';
}


}

/// @nodoc
abstract mixin class $DayTileLoadedCopyWith<$Res> implements $DayTileStatusCopyWith<$Res> {
  factory $DayTileLoadedCopyWith(DayTileLoaded value, $Res Function(DayTileLoaded) _then) = _$DayTileLoadedCopyWithImpl;
@useResult
$Res call({
 DayHistorySummary summary
});


$DayHistorySummaryCopyWith<$Res> get summary;

}
/// @nodoc
class _$DayTileLoadedCopyWithImpl<$Res>
    implements $DayTileLoadedCopyWith<$Res> {
  _$DayTileLoadedCopyWithImpl(this._self, this._then);

  final DayTileLoaded _self;
  final $Res Function(DayTileLoaded) _then;

/// Create a copy of DayTileStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? summary = null,}) {
  return _then(DayTileLoaded(
null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as DayHistorySummary,
  ));
}

/// Create a copy of DayTileStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayHistorySummaryCopyWith<$Res> get summary {
  
  return $DayHistorySummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}

/// @nodoc


class DayTileFailure implements DayTileStatus {
  const DayTileFailure(this.error);
  

 final  DomainError error;

/// Create a copy of DayTileStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayTileFailureCopyWith<DayTileFailure> get copyWith => _$DayTileFailureCopyWithImpl<DayTileFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayTileFailure&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,error);

@override
String toString() {
  return 'DayTileStatus.failure(error: $error)';
}


}

/// @nodoc
abstract mixin class $DayTileFailureCopyWith<$Res> implements $DayTileStatusCopyWith<$Res> {
  factory $DayTileFailureCopyWith(DayTileFailure value, $Res Function(DayTileFailure) _then) = _$DayTileFailureCopyWithImpl;
@useResult
$Res call({
 DomainError error
});




}
/// @nodoc
class _$DayTileFailureCopyWithImpl<$Res>
    implements $DayTileFailureCopyWith<$Res> {
  _$DayTileFailureCopyWithImpl(this._self, this._then);

  final DayTileFailure _self;
  final $Res Function(DayTileFailure) _then;

/// Create a copy of DayTileStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(DayTileFailure(
null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as DomainError,
  ));
}


}

/// @nodoc
mixin _$DayViewModel {

 WorkoutDay get workoutDay; DayTileStatus get status;
/// Create a copy of DayViewModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayViewModelCopyWith<DayViewModel> get copyWith => _$DayViewModelCopyWithImpl<DayViewModel>(this as DayViewModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayViewModel&&(identical(other.workoutDay, workoutDay) || other.workoutDay == workoutDay)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,workoutDay,status);

@override
String toString() {
  return 'DayViewModel(workoutDay: $workoutDay, status: $status)';
}


}

/// @nodoc
abstract mixin class $DayViewModelCopyWith<$Res>  {
  factory $DayViewModelCopyWith(DayViewModel value, $Res Function(DayViewModel) _then) = _$DayViewModelCopyWithImpl;
@useResult
$Res call({
 WorkoutDay workoutDay, DayTileStatus status
});


$WorkoutDayCopyWith<$Res> get workoutDay;$DayTileStatusCopyWith<$Res> get status;

}
/// @nodoc
class _$DayViewModelCopyWithImpl<$Res>
    implements $DayViewModelCopyWith<$Res> {
  _$DayViewModelCopyWithImpl(this._self, this._then);

  final DayViewModel _self;
  final $Res Function(DayViewModel) _then;

/// Create a copy of DayViewModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workoutDay = null,Object? status = null,}) {
  return _then(_self.copyWith(
workoutDay: null == workoutDay ? _self.workoutDay : workoutDay // ignore: cast_nullable_to_non_nullable
as WorkoutDay,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DayTileStatus,
  ));
}
/// Create a copy of DayViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkoutDayCopyWith<$Res> get workoutDay {
  
  return $WorkoutDayCopyWith<$Res>(_self.workoutDay, (value) {
    return _then(_self.copyWith(workoutDay: value));
  });
}/// Create a copy of DayViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayTileStatusCopyWith<$Res> get status {
  
  return $DayTileStatusCopyWith<$Res>(_self.status, (value) {
    return _then(_self.copyWith(status: value));
  });
}
}


/// Adds pattern-matching-related methods to [DayViewModel].
extension DayViewModelPatterns on DayViewModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayViewModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayViewModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayViewModel value)  $default,){
final _that = this;
switch (_that) {
case _DayViewModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayViewModel value)?  $default,){
final _that = this;
switch (_that) {
case _DayViewModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorkoutDay workoutDay,  DayTileStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayViewModel() when $default != null:
return $default(_that.workoutDay,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorkoutDay workoutDay,  DayTileStatus status)  $default,) {final _that = this;
switch (_that) {
case _DayViewModel():
return $default(_that.workoutDay,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorkoutDay workoutDay,  DayTileStatus status)?  $default,) {final _that = this;
switch (_that) {
case _DayViewModel() when $default != null:
return $default(_that.workoutDay,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _DayViewModel implements DayViewModel {
  const _DayViewModel({required this.workoutDay, required this.status});
  

@override final  WorkoutDay workoutDay;
@override final  DayTileStatus status;

/// Create a copy of DayViewModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayViewModelCopyWith<_DayViewModel> get copyWith => __$DayViewModelCopyWithImpl<_DayViewModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayViewModel&&(identical(other.workoutDay, workoutDay) || other.workoutDay == workoutDay)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,workoutDay,status);

@override
String toString() {
  return 'DayViewModel(workoutDay: $workoutDay, status: $status)';
}


}

/// @nodoc
abstract mixin class _$DayViewModelCopyWith<$Res> implements $DayViewModelCopyWith<$Res> {
  factory _$DayViewModelCopyWith(_DayViewModel value, $Res Function(_DayViewModel) _then) = __$DayViewModelCopyWithImpl;
@override @useResult
$Res call({
 WorkoutDay workoutDay, DayTileStatus status
});


@override $WorkoutDayCopyWith<$Res> get workoutDay;@override $DayTileStatusCopyWith<$Res> get status;

}
/// @nodoc
class __$DayViewModelCopyWithImpl<$Res>
    implements _$DayViewModelCopyWith<$Res> {
  __$DayViewModelCopyWithImpl(this._self, this._then);

  final _DayViewModel _self;
  final $Res Function(_DayViewModel) _then;

/// Create a copy of DayViewModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workoutDay = null,Object? status = null,}) {
  return _then(_DayViewModel(
workoutDay: null == workoutDay ? _self.workoutDay : workoutDay // ignore: cast_nullable_to_non_nullable
as WorkoutDay,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DayTileStatus,
  ));
}

/// Create a copy of DayViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkoutDayCopyWith<$Res> get workoutDay {
  
  return $WorkoutDayCopyWith<$Res>(_self.workoutDay, (value) {
    return _then(_self.copyWith(workoutDay: value));
  });
}/// Create a copy of DayViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayTileStatusCopyWith<$Res> get status {
  
  return $DayTileStatusCopyWith<$Res>(_self.status, (value) {
    return _then(_self.copyWith(status: value));
  });
}
}

// dart format on

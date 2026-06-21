// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'added_exercise_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AddedExercisePlan {

 String get name; MeasurementType get measurementType; PlannedSetValues get plannedValues; int get setCount; ExerciseMetadata? get metadata; String? get libraryExerciseId;
/// Create a copy of AddedExercisePlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddedExercisePlanCopyWith<AddedExercisePlan> get copyWith => _$AddedExercisePlanCopyWithImpl<AddedExercisePlan>(this as AddedExercisePlan, _$identity);

  /// Serializes this AddedExercisePlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddedExercisePlan&&(identical(other.name, name) || other.name == name)&&(identical(other.measurementType, measurementType) || other.measurementType == measurementType)&&(identical(other.plannedValues, plannedValues) || other.plannedValues == plannedValues)&&(identical(other.setCount, setCount) || other.setCount == setCount)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.libraryExerciseId, libraryExerciseId) || other.libraryExerciseId == libraryExerciseId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,measurementType,plannedValues,setCount,metadata,libraryExerciseId);

@override
String toString() {
  return 'AddedExercisePlan(name: $name, measurementType: $measurementType, plannedValues: $plannedValues, setCount: $setCount, metadata: $metadata, libraryExerciseId: $libraryExerciseId)';
}


}

/// @nodoc
abstract mixin class $AddedExercisePlanCopyWith<$Res>  {
  factory $AddedExercisePlanCopyWith(AddedExercisePlan value, $Res Function(AddedExercisePlan) _then) = _$AddedExercisePlanCopyWithImpl;
@useResult
$Res call({
 String name, MeasurementType measurementType, PlannedSetValues plannedValues, int setCount, ExerciseMetadata? metadata, String? libraryExerciseId
});


$MeasurementTypeCopyWith<$Res> get measurementType;$PlannedSetValuesCopyWith<$Res> get plannedValues;$ExerciseMetadataCopyWith<$Res>? get metadata;

}
/// @nodoc
class _$AddedExercisePlanCopyWithImpl<$Res>
    implements $AddedExercisePlanCopyWith<$Res> {
  _$AddedExercisePlanCopyWithImpl(this._self, this._then);

  final AddedExercisePlan _self;
  final $Res Function(AddedExercisePlan) _then;

/// Create a copy of AddedExercisePlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? measurementType = null,Object? plannedValues = null,Object? setCount = null,Object? metadata = freezed,Object? libraryExerciseId = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,measurementType: null == measurementType ? _self.measurementType : measurementType // ignore: cast_nullable_to_non_nullable
as MeasurementType,plannedValues: null == plannedValues ? _self.plannedValues : plannedValues // ignore: cast_nullable_to_non_nullable
as PlannedSetValues,setCount: null == setCount ? _self.setCount : setCount // ignore: cast_nullable_to_non_nullable
as int,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as ExerciseMetadata?,libraryExerciseId: freezed == libraryExerciseId ? _self.libraryExerciseId : libraryExerciseId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of AddedExercisePlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementTypeCopyWith<$Res> get measurementType {
  
  return $MeasurementTypeCopyWith<$Res>(_self.measurementType, (value) {
    return _then(_self.copyWith(measurementType: value));
  });
}/// Create a copy of AddedExercisePlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlannedSetValuesCopyWith<$Res> get plannedValues {
  
  return $PlannedSetValuesCopyWith<$Res>(_self.plannedValues, (value) {
    return _then(_self.copyWith(plannedValues: value));
  });
}/// Create a copy of AddedExercisePlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseMetadataCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $ExerciseMetadataCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [AddedExercisePlan].
extension AddedExercisePlanPatterns on AddedExercisePlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AddedExercisePlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AddedExercisePlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AddedExercisePlan value)  $default,){
final _that = this;
switch (_that) {
case _AddedExercisePlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AddedExercisePlan value)?  $default,){
final _that = this;
switch (_that) {
case _AddedExercisePlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  MeasurementType measurementType,  PlannedSetValues plannedValues,  int setCount,  ExerciseMetadata? metadata,  String? libraryExerciseId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AddedExercisePlan() when $default != null:
return $default(_that.name,_that.measurementType,_that.plannedValues,_that.setCount,_that.metadata,_that.libraryExerciseId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  MeasurementType measurementType,  PlannedSetValues plannedValues,  int setCount,  ExerciseMetadata? metadata,  String? libraryExerciseId)  $default,) {final _that = this;
switch (_that) {
case _AddedExercisePlan():
return $default(_that.name,_that.measurementType,_that.plannedValues,_that.setCount,_that.metadata,_that.libraryExerciseId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  MeasurementType measurementType,  PlannedSetValues plannedValues,  int setCount,  ExerciseMetadata? metadata,  String? libraryExerciseId)?  $default,) {final _that = this;
switch (_that) {
case _AddedExercisePlan() when $default != null:
return $default(_that.name,_that.measurementType,_that.plannedValues,_that.setCount,_that.metadata,_that.libraryExerciseId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AddedExercisePlan extends AddedExercisePlan {
   _AddedExercisePlan({required this.name, required this.measurementType, required this.plannedValues, required this.setCount, this.metadata, this.libraryExerciseId}): super._();
  factory _AddedExercisePlan.fromJson(Map<String, dynamic> json) => _$AddedExercisePlanFromJson(json);

@override final  String name;
@override final  MeasurementType measurementType;
@override final  PlannedSetValues plannedValues;
@override final  int setCount;
@override final  ExerciseMetadata? metadata;
@override final  String? libraryExerciseId;

/// Create a copy of AddedExercisePlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddedExercisePlanCopyWith<_AddedExercisePlan> get copyWith => __$AddedExercisePlanCopyWithImpl<_AddedExercisePlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AddedExercisePlanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddedExercisePlan&&(identical(other.name, name) || other.name == name)&&(identical(other.measurementType, measurementType) || other.measurementType == measurementType)&&(identical(other.plannedValues, plannedValues) || other.plannedValues == plannedValues)&&(identical(other.setCount, setCount) || other.setCount == setCount)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.libraryExerciseId, libraryExerciseId) || other.libraryExerciseId == libraryExerciseId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,measurementType,plannedValues,setCount,metadata,libraryExerciseId);

@override
String toString() {
  return 'AddedExercisePlan(name: $name, measurementType: $measurementType, plannedValues: $plannedValues, setCount: $setCount, metadata: $metadata, libraryExerciseId: $libraryExerciseId)';
}


}

/// @nodoc
abstract mixin class _$AddedExercisePlanCopyWith<$Res> implements $AddedExercisePlanCopyWith<$Res> {
  factory _$AddedExercisePlanCopyWith(_AddedExercisePlan value, $Res Function(_AddedExercisePlan) _then) = __$AddedExercisePlanCopyWithImpl;
@override @useResult
$Res call({
 String name, MeasurementType measurementType, PlannedSetValues plannedValues, int setCount, ExerciseMetadata? metadata, String? libraryExerciseId
});


@override $MeasurementTypeCopyWith<$Res> get measurementType;@override $PlannedSetValuesCopyWith<$Res> get plannedValues;@override $ExerciseMetadataCopyWith<$Res>? get metadata;

}
/// @nodoc
class __$AddedExercisePlanCopyWithImpl<$Res>
    implements _$AddedExercisePlanCopyWith<$Res> {
  __$AddedExercisePlanCopyWithImpl(this._self, this._then);

  final _AddedExercisePlan _self;
  final $Res Function(_AddedExercisePlan) _then;

/// Create a copy of AddedExercisePlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? measurementType = null,Object? plannedValues = null,Object? setCount = null,Object? metadata = freezed,Object? libraryExerciseId = freezed,}) {
  return _then(_AddedExercisePlan(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,measurementType: null == measurementType ? _self.measurementType : measurementType // ignore: cast_nullable_to_non_nullable
as MeasurementType,plannedValues: null == plannedValues ? _self.plannedValues : plannedValues // ignore: cast_nullable_to_non_nullable
as PlannedSetValues,setCount: null == setCount ? _self.setCount : setCount // ignore: cast_nullable_to_non_nullable
as int,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as ExerciseMetadata?,libraryExerciseId: freezed == libraryExerciseId ? _self.libraryExerciseId : libraryExerciseId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of AddedExercisePlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementTypeCopyWith<$Res> get measurementType {
  
  return $MeasurementTypeCopyWith<$Res>(_self.measurementType, (value) {
    return _then(_self.copyWith(measurementType: value));
  });
}/// Create a copy of AddedExercisePlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlannedSetValuesCopyWith<$Res> get plannedValues {
  
  return $PlannedSetValuesCopyWith<$Res>(_self.plannedValues, (value) {
    return _then(_self.copyWith(plannedValues: value));
  });
}/// Create a copy of AddedExercisePlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseMetadataCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $ExerciseMetadataCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}

// dart format on

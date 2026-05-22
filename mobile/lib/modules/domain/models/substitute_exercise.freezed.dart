// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'substitute_exercise.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubstituteExercise {

 String get name; MeasurementType get measurementType; PlannedSetValues get plannedValues; int get setCount; ExerciseMetadata? get metadata; String? get libraryExerciseId;
/// Create a copy of SubstituteExercise
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubstituteExerciseCopyWith<SubstituteExercise> get copyWith => _$SubstituteExerciseCopyWithImpl<SubstituteExercise>(this as SubstituteExercise, _$identity);

  /// Serializes this SubstituteExercise to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubstituteExercise&&(identical(other.name, name) || other.name == name)&&(identical(other.measurementType, measurementType) || other.measurementType == measurementType)&&(identical(other.plannedValues, plannedValues) || other.plannedValues == plannedValues)&&(identical(other.setCount, setCount) || other.setCount == setCount)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.libraryExerciseId, libraryExerciseId) || other.libraryExerciseId == libraryExerciseId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,measurementType,plannedValues,setCount,metadata,libraryExerciseId);

@override
String toString() {
  return 'SubstituteExercise(name: $name, measurementType: $measurementType, plannedValues: $plannedValues, setCount: $setCount, metadata: $metadata, libraryExerciseId: $libraryExerciseId)';
}


}

/// @nodoc
abstract mixin class $SubstituteExerciseCopyWith<$Res>  {
  factory $SubstituteExerciseCopyWith(SubstituteExercise value, $Res Function(SubstituteExercise) _then) = _$SubstituteExerciseCopyWithImpl;
@useResult
$Res call({
 String name, MeasurementType measurementType, PlannedSetValues plannedValues, int setCount, ExerciseMetadata? metadata, String? libraryExerciseId
});


$MeasurementTypeCopyWith<$Res> get measurementType;$PlannedSetValuesCopyWith<$Res> get plannedValues;$ExerciseMetadataCopyWith<$Res>? get metadata;

}
/// @nodoc
class _$SubstituteExerciseCopyWithImpl<$Res>
    implements $SubstituteExerciseCopyWith<$Res> {
  _$SubstituteExerciseCopyWithImpl(this._self, this._then);

  final SubstituteExercise _self;
  final $Res Function(SubstituteExercise) _then;

/// Create a copy of SubstituteExercise
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
/// Create a copy of SubstituteExercise
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementTypeCopyWith<$Res> get measurementType {
  
  return $MeasurementTypeCopyWith<$Res>(_self.measurementType, (value) {
    return _then(_self.copyWith(measurementType: value));
  });
}/// Create a copy of SubstituteExercise
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlannedSetValuesCopyWith<$Res> get plannedValues {
  
  return $PlannedSetValuesCopyWith<$Res>(_self.plannedValues, (value) {
    return _then(_self.copyWith(plannedValues: value));
  });
}/// Create a copy of SubstituteExercise
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


/// Adds pattern-matching-related methods to [SubstituteExercise].
extension SubstituteExercisePatterns on SubstituteExercise {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubstituteExercise value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubstituteExercise() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubstituteExercise value)  $default,){
final _that = this;
switch (_that) {
case _SubstituteExercise():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubstituteExercise value)?  $default,){
final _that = this;
switch (_that) {
case _SubstituteExercise() when $default != null:
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
case _SubstituteExercise() when $default != null:
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
case _SubstituteExercise():
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
case _SubstituteExercise() when $default != null:
return $default(_that.name,_that.measurementType,_that.plannedValues,_that.setCount,_that.metadata,_that.libraryExerciseId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubstituteExercise extends SubstituteExercise {
   _SubstituteExercise({required this.name, required this.measurementType, required this.plannedValues, required this.setCount, this.metadata, this.libraryExerciseId}): super._();
  factory _SubstituteExercise.fromJson(Map<String, dynamic> json) => _$SubstituteExerciseFromJson(json);

@override final  String name;
@override final  MeasurementType measurementType;
@override final  PlannedSetValues plannedValues;
@override final  int setCount;
@override final  ExerciseMetadata? metadata;
@override final  String? libraryExerciseId;

/// Create a copy of SubstituteExercise
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubstituteExerciseCopyWith<_SubstituteExercise> get copyWith => __$SubstituteExerciseCopyWithImpl<_SubstituteExercise>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubstituteExerciseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubstituteExercise&&(identical(other.name, name) || other.name == name)&&(identical(other.measurementType, measurementType) || other.measurementType == measurementType)&&(identical(other.plannedValues, plannedValues) || other.plannedValues == plannedValues)&&(identical(other.setCount, setCount) || other.setCount == setCount)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.libraryExerciseId, libraryExerciseId) || other.libraryExerciseId == libraryExerciseId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,measurementType,plannedValues,setCount,metadata,libraryExerciseId);

@override
String toString() {
  return 'SubstituteExercise(name: $name, measurementType: $measurementType, plannedValues: $plannedValues, setCount: $setCount, metadata: $metadata, libraryExerciseId: $libraryExerciseId)';
}


}

/// @nodoc
abstract mixin class _$SubstituteExerciseCopyWith<$Res> implements $SubstituteExerciseCopyWith<$Res> {
  factory _$SubstituteExerciseCopyWith(_SubstituteExercise value, $Res Function(_SubstituteExercise) _then) = __$SubstituteExerciseCopyWithImpl;
@override @useResult
$Res call({
 String name, MeasurementType measurementType, PlannedSetValues plannedValues, int setCount, ExerciseMetadata? metadata, String? libraryExerciseId
});


@override $MeasurementTypeCopyWith<$Res> get measurementType;@override $PlannedSetValuesCopyWith<$Res> get plannedValues;@override $ExerciseMetadataCopyWith<$Res>? get metadata;

}
/// @nodoc
class __$SubstituteExerciseCopyWithImpl<$Res>
    implements _$SubstituteExerciseCopyWith<$Res> {
  __$SubstituteExerciseCopyWithImpl(this._self, this._then);

  final _SubstituteExercise _self;
  final $Res Function(_SubstituteExercise) _then;

/// Create a copy of SubstituteExercise
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? measurementType = null,Object? plannedValues = null,Object? setCount = null,Object? metadata = freezed,Object? libraryExerciseId = freezed,}) {
  return _then(_SubstituteExercise(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,measurementType: null == measurementType ? _self.measurementType : measurementType // ignore: cast_nullable_to_non_nullable
as MeasurementType,plannedValues: null == plannedValues ? _self.plannedValues : plannedValues // ignore: cast_nullable_to_non_nullable
as PlannedSetValues,setCount: null == setCount ? _self.setCount : setCount // ignore: cast_nullable_to_non_nullable
as int,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as ExerciseMetadata?,libraryExerciseId: freezed == libraryExerciseId ? _self.libraryExerciseId : libraryExerciseId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of SubstituteExercise
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementTypeCopyWith<$Res> get measurementType {
  
  return $MeasurementTypeCopyWith<$Res>(_self.measurementType, (value) {
    return _then(_self.copyWith(measurementType: value));
  });
}/// Create a copy of SubstituteExercise
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlannedSetValuesCopyWith<$Res> get plannedValues {
  
  return $PlannedSetValuesCopyWith<$Res>(_self.plannedValues, (value) {
    return _then(_self.copyWith(plannedValues: value));
  });
}/// Create a copy of SubstituteExercise
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

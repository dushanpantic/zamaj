// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'canonical_seed_exercise.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CanonicalSeedExercise {

 String get id; String get name; MeasurementType get measurementType; Prominence get prominence; List<MuscleGroup> get primaryMuscles; List<MuscleGroup> get secondaryMuscles; String? get videoUrl; String? get cues;
/// Create a copy of CanonicalSeedExercise
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CanonicalSeedExerciseCopyWith<CanonicalSeedExercise> get copyWith => _$CanonicalSeedExerciseCopyWithImpl<CanonicalSeedExercise>(this as CanonicalSeedExercise, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CanonicalSeedExercise&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.measurementType, measurementType) || other.measurementType == measurementType)&&(identical(other.prominence, prominence) || other.prominence == prominence)&&const DeepCollectionEquality().equals(other.primaryMuscles, primaryMuscles)&&const DeepCollectionEquality().equals(other.secondaryMuscles, secondaryMuscles)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.cues, cues) || other.cues == cues));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,measurementType,prominence,const DeepCollectionEquality().hash(primaryMuscles),const DeepCollectionEquality().hash(secondaryMuscles),videoUrl,cues);

@override
String toString() {
  return 'CanonicalSeedExercise(id: $id, name: $name, measurementType: $measurementType, prominence: $prominence, primaryMuscles: $primaryMuscles, secondaryMuscles: $secondaryMuscles, videoUrl: $videoUrl, cues: $cues)';
}


}

/// @nodoc
abstract mixin class $CanonicalSeedExerciseCopyWith<$Res>  {
  factory $CanonicalSeedExerciseCopyWith(CanonicalSeedExercise value, $Res Function(CanonicalSeedExercise) _then) = _$CanonicalSeedExerciseCopyWithImpl;
@useResult
$Res call({
 String id, String name, MeasurementType measurementType, Prominence prominence, List<MuscleGroup> primaryMuscles, List<MuscleGroup> secondaryMuscles, String? videoUrl, String? cues
});


$MeasurementTypeCopyWith<$Res> get measurementType;

}
/// @nodoc
class _$CanonicalSeedExerciseCopyWithImpl<$Res>
    implements $CanonicalSeedExerciseCopyWith<$Res> {
  _$CanonicalSeedExerciseCopyWithImpl(this._self, this._then);

  final CanonicalSeedExercise _self;
  final $Res Function(CanonicalSeedExercise) _then;

/// Create a copy of CanonicalSeedExercise
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? measurementType = null,Object? prominence = null,Object? primaryMuscles = null,Object? secondaryMuscles = null,Object? videoUrl = freezed,Object? cues = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,measurementType: null == measurementType ? _self.measurementType : measurementType // ignore: cast_nullable_to_non_nullable
as MeasurementType,prominence: null == prominence ? _self.prominence : prominence // ignore: cast_nullable_to_non_nullable
as Prominence,primaryMuscles: null == primaryMuscles ? _self.primaryMuscles : primaryMuscles // ignore: cast_nullable_to_non_nullable
as List<MuscleGroup>,secondaryMuscles: null == secondaryMuscles ? _self.secondaryMuscles : secondaryMuscles // ignore: cast_nullable_to_non_nullable
as List<MuscleGroup>,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,cues: freezed == cues ? _self.cues : cues // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of CanonicalSeedExercise
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementTypeCopyWith<$Res> get measurementType {
  
  return $MeasurementTypeCopyWith<$Res>(_self.measurementType, (value) {
    return _then(_self.copyWith(measurementType: value));
  });
}
}


/// Adds pattern-matching-related methods to [CanonicalSeedExercise].
extension CanonicalSeedExercisePatterns on CanonicalSeedExercise {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CanonicalSeedExercise value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CanonicalSeedExercise() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CanonicalSeedExercise value)  $default,){
final _that = this;
switch (_that) {
case _CanonicalSeedExercise():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CanonicalSeedExercise value)?  $default,){
final _that = this;
switch (_that) {
case _CanonicalSeedExercise() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  MeasurementType measurementType,  Prominence prominence,  List<MuscleGroup> primaryMuscles,  List<MuscleGroup> secondaryMuscles,  String? videoUrl,  String? cues)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CanonicalSeedExercise() when $default != null:
return $default(_that.id,_that.name,_that.measurementType,_that.prominence,_that.primaryMuscles,_that.secondaryMuscles,_that.videoUrl,_that.cues);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  MeasurementType measurementType,  Prominence prominence,  List<MuscleGroup> primaryMuscles,  List<MuscleGroup> secondaryMuscles,  String? videoUrl,  String? cues)  $default,) {final _that = this;
switch (_that) {
case _CanonicalSeedExercise():
return $default(_that.id,_that.name,_that.measurementType,_that.prominence,_that.primaryMuscles,_that.secondaryMuscles,_that.videoUrl,_that.cues);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  MeasurementType measurementType,  Prominence prominence,  List<MuscleGroup> primaryMuscles,  List<MuscleGroup> secondaryMuscles,  String? videoUrl,  String? cues)?  $default,) {final _that = this;
switch (_that) {
case _CanonicalSeedExercise() when $default != null:
return $default(_that.id,_that.name,_that.measurementType,_that.prominence,_that.primaryMuscles,_that.secondaryMuscles,_that.videoUrl,_that.cues);case _:
  return null;

}
}

}

/// @nodoc


class _CanonicalSeedExercise extends CanonicalSeedExercise {
   _CanonicalSeedExercise({required this.id, required this.name, required this.measurementType, required this.prominence, required final  List<MuscleGroup> primaryMuscles, final  List<MuscleGroup> secondaryMuscles = const <MuscleGroup>[], this.videoUrl, this.cues}): _primaryMuscles = primaryMuscles,_secondaryMuscles = secondaryMuscles,super._();
  

@override final  String id;
@override final  String name;
@override final  MeasurementType measurementType;
@override final  Prominence prominence;
 final  List<MuscleGroup> _primaryMuscles;
@override List<MuscleGroup> get primaryMuscles {
  if (_primaryMuscles is EqualUnmodifiableListView) return _primaryMuscles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_primaryMuscles);
}

 final  List<MuscleGroup> _secondaryMuscles;
@override@JsonKey() List<MuscleGroup> get secondaryMuscles {
  if (_secondaryMuscles is EqualUnmodifiableListView) return _secondaryMuscles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_secondaryMuscles);
}

@override final  String? videoUrl;
@override final  String? cues;

/// Create a copy of CanonicalSeedExercise
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CanonicalSeedExerciseCopyWith<_CanonicalSeedExercise> get copyWith => __$CanonicalSeedExerciseCopyWithImpl<_CanonicalSeedExercise>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CanonicalSeedExercise&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.measurementType, measurementType) || other.measurementType == measurementType)&&(identical(other.prominence, prominence) || other.prominence == prominence)&&const DeepCollectionEquality().equals(other._primaryMuscles, _primaryMuscles)&&const DeepCollectionEquality().equals(other._secondaryMuscles, _secondaryMuscles)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.cues, cues) || other.cues == cues));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,measurementType,prominence,const DeepCollectionEquality().hash(_primaryMuscles),const DeepCollectionEquality().hash(_secondaryMuscles),videoUrl,cues);

@override
String toString() {
  return 'CanonicalSeedExercise(id: $id, name: $name, measurementType: $measurementType, prominence: $prominence, primaryMuscles: $primaryMuscles, secondaryMuscles: $secondaryMuscles, videoUrl: $videoUrl, cues: $cues)';
}


}

/// @nodoc
abstract mixin class _$CanonicalSeedExerciseCopyWith<$Res> implements $CanonicalSeedExerciseCopyWith<$Res> {
  factory _$CanonicalSeedExerciseCopyWith(_CanonicalSeedExercise value, $Res Function(_CanonicalSeedExercise) _then) = __$CanonicalSeedExerciseCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, MeasurementType measurementType, Prominence prominence, List<MuscleGroup> primaryMuscles, List<MuscleGroup> secondaryMuscles, String? videoUrl, String? cues
});


@override $MeasurementTypeCopyWith<$Res> get measurementType;

}
/// @nodoc
class __$CanonicalSeedExerciseCopyWithImpl<$Res>
    implements _$CanonicalSeedExerciseCopyWith<$Res> {
  __$CanonicalSeedExerciseCopyWithImpl(this._self, this._then);

  final _CanonicalSeedExercise _self;
  final $Res Function(_CanonicalSeedExercise) _then;

/// Create a copy of CanonicalSeedExercise
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? measurementType = null,Object? prominence = null,Object? primaryMuscles = null,Object? secondaryMuscles = null,Object? videoUrl = freezed,Object? cues = freezed,}) {
  return _then(_CanonicalSeedExercise(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,measurementType: null == measurementType ? _self.measurementType : measurementType // ignore: cast_nullable_to_non_nullable
as MeasurementType,prominence: null == prominence ? _self.prominence : prominence // ignore: cast_nullable_to_non_nullable
as Prominence,primaryMuscles: null == primaryMuscles ? _self._primaryMuscles : primaryMuscles // ignore: cast_nullable_to_non_nullable
as List<MuscleGroup>,secondaryMuscles: null == secondaryMuscles ? _self._secondaryMuscles : secondaryMuscles // ignore: cast_nullable_to_non_nullable
as List<MuscleGroup>,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,cues: freezed == cues ? _self.cues : cues // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of CanonicalSeedExercise
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementTypeCopyWith<$Res> get measurementType {
  
  return $MeasurementTypeCopyWith<$Res>(_self.measurementType, (value) {
    return _then(_self.copyWith(measurementType: value));
  });
}
}

// dart format on

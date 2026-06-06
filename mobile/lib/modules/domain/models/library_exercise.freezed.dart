// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_exercise.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LibraryExercise {

 String get id; String get name; MeasurementType get measurementType; Prominence get prominence; List<MuscleGroup> get primaryMuscles; List<MuscleGroup> get secondaryMuscles; LibrarySource get source; String? get videoUrl; String? get cues; DateTime? get archivedAt; DateTime get createdAt; DateTime get updatedAt; int get schemaVersion;
/// Create a copy of LibraryExercise
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryExerciseCopyWith<LibraryExercise> get copyWith => _$LibraryExerciseCopyWithImpl<LibraryExercise>(this as LibraryExercise, _$identity);

  /// Serializes this LibraryExercise to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryExercise&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.measurementType, measurementType) || other.measurementType == measurementType)&&(identical(other.prominence, prominence) || other.prominence == prominence)&&const DeepCollectionEquality().equals(other.primaryMuscles, primaryMuscles)&&const DeepCollectionEquality().equals(other.secondaryMuscles, secondaryMuscles)&&(identical(other.source, source) || other.source == source)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.cues, cues) || other.cues == cues)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,measurementType,prominence,const DeepCollectionEquality().hash(primaryMuscles),const DeepCollectionEquality().hash(secondaryMuscles),source,videoUrl,cues,archivedAt,createdAt,updatedAt,schemaVersion);

@override
String toString() {
  return 'LibraryExercise(id: $id, name: $name, measurementType: $measurementType, prominence: $prominence, primaryMuscles: $primaryMuscles, secondaryMuscles: $secondaryMuscles, source: $source, videoUrl: $videoUrl, cues: $cues, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class $LibraryExerciseCopyWith<$Res>  {
  factory $LibraryExerciseCopyWith(LibraryExercise value, $Res Function(LibraryExercise) _then) = _$LibraryExerciseCopyWithImpl;
@useResult
$Res call({
 String id, String name, MeasurementType measurementType, Prominence prominence, List<MuscleGroup> primaryMuscles, List<MuscleGroup> secondaryMuscles, LibrarySource source, String? videoUrl, String? cues, DateTime? archivedAt, DateTime createdAt, DateTime updatedAt, int schemaVersion
});


$MeasurementTypeCopyWith<$Res> get measurementType;

}
/// @nodoc
class _$LibraryExerciseCopyWithImpl<$Res>
    implements $LibraryExerciseCopyWith<$Res> {
  _$LibraryExerciseCopyWithImpl(this._self, this._then);

  final LibraryExercise _self;
  final $Res Function(LibraryExercise) _then;

/// Create a copy of LibraryExercise
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? measurementType = null,Object? prominence = null,Object? primaryMuscles = null,Object? secondaryMuscles = null,Object? source = null,Object? videoUrl = freezed,Object? cues = freezed,Object? archivedAt = freezed,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,measurementType: null == measurementType ? _self.measurementType : measurementType // ignore: cast_nullable_to_non_nullable
as MeasurementType,prominence: null == prominence ? _self.prominence : prominence // ignore: cast_nullable_to_non_nullable
as Prominence,primaryMuscles: null == primaryMuscles ? _self.primaryMuscles : primaryMuscles // ignore: cast_nullable_to_non_nullable
as List<MuscleGroup>,secondaryMuscles: null == secondaryMuscles ? _self.secondaryMuscles : secondaryMuscles // ignore: cast_nullable_to_non_nullable
as List<MuscleGroup>,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as LibrarySource,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,cues: freezed == cues ? _self.cues : cues // ignore: cast_nullable_to_non_nullable
as String?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of LibraryExercise
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeasurementTypeCopyWith<$Res> get measurementType {
  
  return $MeasurementTypeCopyWith<$Res>(_self.measurementType, (value) {
    return _then(_self.copyWith(measurementType: value));
  });
}
}


/// Adds pattern-matching-related methods to [LibraryExercise].
extension LibraryExercisePatterns on LibraryExercise {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibraryExercise value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibraryExercise() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibraryExercise value)  $default,){
final _that = this;
switch (_that) {
case _LibraryExercise():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibraryExercise value)?  $default,){
final _that = this;
switch (_that) {
case _LibraryExercise() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  MeasurementType measurementType,  Prominence prominence,  List<MuscleGroup> primaryMuscles,  List<MuscleGroup> secondaryMuscles,  LibrarySource source,  String? videoUrl,  String? cues,  DateTime? archivedAt,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibraryExercise() when $default != null:
return $default(_that.id,_that.name,_that.measurementType,_that.prominence,_that.primaryMuscles,_that.secondaryMuscles,_that.source,_that.videoUrl,_that.cues,_that.archivedAt,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  MeasurementType measurementType,  Prominence prominence,  List<MuscleGroup> primaryMuscles,  List<MuscleGroup> secondaryMuscles,  LibrarySource source,  String? videoUrl,  String? cues,  DateTime? archivedAt,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)  $default,) {final _that = this;
switch (_that) {
case _LibraryExercise():
return $default(_that.id,_that.name,_that.measurementType,_that.prominence,_that.primaryMuscles,_that.secondaryMuscles,_that.source,_that.videoUrl,_that.cues,_that.archivedAt,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  MeasurementType measurementType,  Prominence prominence,  List<MuscleGroup> primaryMuscles,  List<MuscleGroup> secondaryMuscles,  LibrarySource source,  String? videoUrl,  String? cues,  DateTime? archivedAt,  DateTime createdAt,  DateTime updatedAt,  int schemaVersion)?  $default,) {final _that = this;
switch (_that) {
case _LibraryExercise() when $default != null:
return $default(_that.id,_that.name,_that.measurementType,_that.prominence,_that.primaryMuscles,_that.secondaryMuscles,_that.source,_that.videoUrl,_that.cues,_that.archivedAt,_that.createdAt,_that.updatedAt,_that.schemaVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LibraryExercise extends LibraryExercise {
   _LibraryExercise({required this.id, required this.name, required this.measurementType, this.prominence = Prominence.common, final  List<MuscleGroup> primaryMuscles = const <MuscleGroup>[], final  List<MuscleGroup> secondaryMuscles = const <MuscleGroup>[], this.source = LibrarySource.user, this.videoUrl, this.cues, this.archivedAt, required this.createdAt, required this.updatedAt, required this.schemaVersion}): _primaryMuscles = primaryMuscles,_secondaryMuscles = secondaryMuscles,super._();
  factory _LibraryExercise.fromJson(Map<String, dynamic> json) => _$LibraryExerciseFromJson(json);

@override final  String id;
@override final  String name;
@override final  MeasurementType measurementType;
@override@JsonKey() final  Prominence prominence;
 final  List<MuscleGroup> _primaryMuscles;
@override@JsonKey() List<MuscleGroup> get primaryMuscles {
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

@override@JsonKey() final  LibrarySource source;
@override final  String? videoUrl;
@override final  String? cues;
@override final  DateTime? archivedAt;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  int schemaVersion;

/// Create a copy of LibraryExercise
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibraryExerciseCopyWith<_LibraryExercise> get copyWith => __$LibraryExerciseCopyWithImpl<_LibraryExercise>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LibraryExerciseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibraryExercise&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.measurementType, measurementType) || other.measurementType == measurementType)&&(identical(other.prominence, prominence) || other.prominence == prominence)&&const DeepCollectionEquality().equals(other._primaryMuscles, _primaryMuscles)&&const DeepCollectionEquality().equals(other._secondaryMuscles, _secondaryMuscles)&&(identical(other.source, source) || other.source == source)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.cues, cues) || other.cues == cues)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,measurementType,prominence,const DeepCollectionEquality().hash(_primaryMuscles),const DeepCollectionEquality().hash(_secondaryMuscles),source,videoUrl,cues,archivedAt,createdAt,updatedAt,schemaVersion);

@override
String toString() {
  return 'LibraryExercise(id: $id, name: $name, measurementType: $measurementType, prominence: $prominence, primaryMuscles: $primaryMuscles, secondaryMuscles: $secondaryMuscles, source: $source, videoUrl: $videoUrl, cues: $cues, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class _$LibraryExerciseCopyWith<$Res> implements $LibraryExerciseCopyWith<$Res> {
  factory _$LibraryExerciseCopyWith(_LibraryExercise value, $Res Function(_LibraryExercise) _then) = __$LibraryExerciseCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, MeasurementType measurementType, Prominence prominence, List<MuscleGroup> primaryMuscles, List<MuscleGroup> secondaryMuscles, LibrarySource source, String? videoUrl, String? cues, DateTime? archivedAt, DateTime createdAt, DateTime updatedAt, int schemaVersion
});


@override $MeasurementTypeCopyWith<$Res> get measurementType;

}
/// @nodoc
class __$LibraryExerciseCopyWithImpl<$Res>
    implements _$LibraryExerciseCopyWith<$Res> {
  __$LibraryExerciseCopyWithImpl(this._self, this._then);

  final _LibraryExercise _self;
  final $Res Function(_LibraryExercise) _then;

/// Create a copy of LibraryExercise
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? measurementType = null,Object? prominence = null,Object? primaryMuscles = null,Object? secondaryMuscles = null,Object? source = null,Object? videoUrl = freezed,Object? cues = freezed,Object? archivedAt = freezed,Object? createdAt = null,Object? updatedAt = null,Object? schemaVersion = null,}) {
  return _then(_LibraryExercise(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,measurementType: null == measurementType ? _self.measurementType : measurementType // ignore: cast_nullable_to_non_nullable
as MeasurementType,prominence: null == prominence ? _self.prominence : prominence // ignore: cast_nullable_to_non_nullable
as Prominence,primaryMuscles: null == primaryMuscles ? _self._primaryMuscles : primaryMuscles // ignore: cast_nullable_to_non_nullable
as List<MuscleGroup>,secondaryMuscles: null == secondaryMuscles ? _self._secondaryMuscles : secondaryMuscles // ignore: cast_nullable_to_non_nullable
as List<MuscleGroup>,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as LibrarySource,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,cues: freezed == cues ? _self.cues : cues // ignore: cast_nullable_to_non_nullable
as String?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of LibraryExercise
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

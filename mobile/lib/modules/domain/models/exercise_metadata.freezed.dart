// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExerciseMetadata {

 String? get notes; String? get videoUrl;
/// Create a copy of ExerciseMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseMetadataCopyWith<ExerciseMetadata> get copyWith => _$ExerciseMetadataCopyWithImpl<ExerciseMetadata>(this as ExerciseMetadata, _$identity);

  /// Serializes this ExerciseMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseMetadata&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notes,videoUrl);

@override
String toString() {
  return 'ExerciseMetadata(notes: $notes, videoUrl: $videoUrl)';
}


}

/// @nodoc
abstract mixin class $ExerciseMetadataCopyWith<$Res>  {
  factory $ExerciseMetadataCopyWith(ExerciseMetadata value, $Res Function(ExerciseMetadata) _then) = _$ExerciseMetadataCopyWithImpl;
@useResult
$Res call({
 String? notes, String? videoUrl
});




}
/// @nodoc
class _$ExerciseMetadataCopyWithImpl<$Res>
    implements $ExerciseMetadataCopyWith<$Res> {
  _$ExerciseMetadataCopyWithImpl(this._self, this._then);

  final ExerciseMetadata _self;
  final $Res Function(ExerciseMetadata) _then;

/// Create a copy of ExerciseMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notes = freezed,Object? videoUrl = freezed,}) {
  return _then(_self.copyWith(
notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExerciseMetadata].
extension ExerciseMetadataPatterns on ExerciseMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExerciseMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExerciseMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExerciseMetadata value)  $default,){
final _that = this;
switch (_that) {
case _ExerciseMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExerciseMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _ExerciseMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? notes,  String? videoUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExerciseMetadata() when $default != null:
return $default(_that.notes,_that.videoUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? notes,  String? videoUrl)  $default,) {final _that = this;
switch (_that) {
case _ExerciseMetadata():
return $default(_that.notes,_that.videoUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? notes,  String? videoUrl)?  $default,) {final _that = this;
switch (_that) {
case _ExerciseMetadata() when $default != null:
return $default(_that.notes,_that.videoUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExerciseMetadata implements ExerciseMetadata {
  const _ExerciseMetadata({this.notes, this.videoUrl});
  factory _ExerciseMetadata.fromJson(Map<String, dynamic> json) => _$ExerciseMetadataFromJson(json);

@override final  String? notes;
@override final  String? videoUrl;

/// Create a copy of ExerciseMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseMetadataCopyWith<_ExerciseMetadata> get copyWith => __$ExerciseMetadataCopyWithImpl<_ExerciseMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExerciseMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExerciseMetadata&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notes,videoUrl);

@override
String toString() {
  return 'ExerciseMetadata(notes: $notes, videoUrl: $videoUrl)';
}


}

/// @nodoc
abstract mixin class _$ExerciseMetadataCopyWith<$Res> implements $ExerciseMetadataCopyWith<$Res> {
  factory _$ExerciseMetadataCopyWith(_ExerciseMetadata value, $Res Function(_ExerciseMetadata) _then) = __$ExerciseMetadataCopyWithImpl;
@override @useResult
$Res call({
 String? notes, String? videoUrl
});




}
/// @nodoc
class __$ExerciseMetadataCopyWithImpl<$Res>
    implements _$ExerciseMetadataCopyWith<$Res> {
  __$ExerciseMetadataCopyWithImpl(this._self, this._then);

  final _ExerciseMetadata _self;
  final $Res Function(_ExerciseMetadata) _then;

/// Create a copy of ExerciseMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? notes = freezed,Object? videoUrl = freezed,}) {
  return _then(_ExerciseMetadata(
notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

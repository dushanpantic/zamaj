// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'superset_group_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SupersetGroupViewModel {

 String? get supersetTag; List<ExerciseViewModel> get exercises;
/// Create a copy of SupersetGroupViewModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupersetGroupViewModelCopyWith<SupersetGroupViewModel> get copyWith => _$SupersetGroupViewModelCopyWithImpl<SupersetGroupViewModel>(this as SupersetGroupViewModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupersetGroupViewModel&&(identical(other.supersetTag, supersetTag) || other.supersetTag == supersetTag)&&const DeepCollectionEquality().equals(other.exercises, exercises));
}


@override
int get hashCode => Object.hash(runtimeType,supersetTag,const DeepCollectionEquality().hash(exercises));

@override
String toString() {
  return 'SupersetGroupViewModel(supersetTag: $supersetTag, exercises: $exercises)';
}


}

/// @nodoc
abstract mixin class $SupersetGroupViewModelCopyWith<$Res>  {
  factory $SupersetGroupViewModelCopyWith(SupersetGroupViewModel value, $Res Function(SupersetGroupViewModel) _then) = _$SupersetGroupViewModelCopyWithImpl;
@useResult
$Res call({
 String? supersetTag, List<ExerciseViewModel> exercises
});




}
/// @nodoc
class _$SupersetGroupViewModelCopyWithImpl<$Res>
    implements $SupersetGroupViewModelCopyWith<$Res> {
  _$SupersetGroupViewModelCopyWithImpl(this._self, this._then);

  final SupersetGroupViewModel _self;
  final $Res Function(SupersetGroupViewModel) _then;

/// Create a copy of SupersetGroupViewModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? supersetTag = freezed,Object? exercises = null,}) {
  return _then(_self.copyWith(
supersetTag: freezed == supersetTag ? _self.supersetTag : supersetTag // ignore: cast_nullable_to_non_nullable
as String?,exercises: null == exercises ? _self.exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<ExerciseViewModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [SupersetGroupViewModel].
extension SupersetGroupViewModelPatterns on SupersetGroupViewModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupersetGroupViewModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupersetGroupViewModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupersetGroupViewModel value)  $default,){
final _that = this;
switch (_that) {
case _SupersetGroupViewModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupersetGroupViewModel value)?  $default,){
final _that = this;
switch (_that) {
case _SupersetGroupViewModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? supersetTag,  List<ExerciseViewModel> exercises)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupersetGroupViewModel() when $default != null:
return $default(_that.supersetTag,_that.exercises);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? supersetTag,  List<ExerciseViewModel> exercises)  $default,) {final _that = this;
switch (_that) {
case _SupersetGroupViewModel():
return $default(_that.supersetTag,_that.exercises);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? supersetTag,  List<ExerciseViewModel> exercises)?  $default,) {final _that = this;
switch (_that) {
case _SupersetGroupViewModel() when $default != null:
return $default(_that.supersetTag,_that.exercises);case _:
  return null;

}
}

}

/// @nodoc


class _SupersetGroupViewModel implements SupersetGroupViewModel {
  const _SupersetGroupViewModel({required this.supersetTag, required final  List<ExerciseViewModel> exercises}): _exercises = exercises;
  

@override final  String? supersetTag;
 final  List<ExerciseViewModel> _exercises;
@override List<ExerciseViewModel> get exercises {
  if (_exercises is EqualUnmodifiableListView) return _exercises;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exercises);
}


/// Create a copy of SupersetGroupViewModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupersetGroupViewModelCopyWith<_SupersetGroupViewModel> get copyWith => __$SupersetGroupViewModelCopyWithImpl<_SupersetGroupViewModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupersetGroupViewModel&&(identical(other.supersetTag, supersetTag) || other.supersetTag == supersetTag)&&const DeepCollectionEquality().equals(other._exercises, _exercises));
}


@override
int get hashCode => Object.hash(runtimeType,supersetTag,const DeepCollectionEquality().hash(_exercises));

@override
String toString() {
  return 'SupersetGroupViewModel(supersetTag: $supersetTag, exercises: $exercises)';
}


}

/// @nodoc
abstract mixin class _$SupersetGroupViewModelCopyWith<$Res> implements $SupersetGroupViewModelCopyWith<$Res> {
  factory _$SupersetGroupViewModelCopyWith(_SupersetGroupViewModel value, $Res Function(_SupersetGroupViewModel) _then) = __$SupersetGroupViewModelCopyWithImpl;
@override @useResult
$Res call({
 String? supersetTag, List<ExerciseViewModel> exercises
});




}
/// @nodoc
class __$SupersetGroupViewModelCopyWithImpl<$Res>
    implements _$SupersetGroupViewModelCopyWith<$Res> {
  __$SupersetGroupViewModelCopyWithImpl(this._self, this._then);

  final _SupersetGroupViewModel _self;
  final $Res Function(_SupersetGroupViewModel) _then;

/// Create a copy of SupersetGroupViewModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? supersetTag = freezed,Object? exercises = null,}) {
  return _then(_SupersetGroupViewModel(
supersetTag: freezed == supersetTag ? _self.supersetTag : supersetTag // ignore: cast_nullable_to_non_nullable
as String?,exercises: null == exercises ? _self._exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<ExerciseViewModel>,
  ));
}


}

// dart format on

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





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupersetGroupViewModel);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SupersetGroupViewModel()';
}


}

/// @nodoc
class $SupersetGroupViewModelCopyWith<$Res>  {
$SupersetGroupViewModelCopyWith(SupersetGroupViewModel _, $Res Function(SupersetGroupViewModel) __);
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SingleGroupViewModel value)?  single,TResult Function( SupersetGroup value)?  superset,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SingleGroupViewModel() when single != null:
return single(_that);case SupersetGroup() when superset != null:
return superset(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SingleGroupViewModel value)  single,required TResult Function( SupersetGroup value)  superset,}){
final _that = this;
switch (_that) {
case SingleGroupViewModel():
return single(_that);case SupersetGroup():
return superset(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SingleGroupViewModel value)?  single,TResult? Function( SupersetGroup value)?  superset,}){
final _that = this;
switch (_that) {
case SingleGroupViewModel() when single != null:
return single(_that);case SupersetGroup() when superset != null:
return superset(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ExerciseViewModel exercise)?  single,TResult Function( String tag,  List<ExerciseViewModel> exercises)?  superset,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SingleGroupViewModel() when single != null:
return single(_that.exercise);case SupersetGroup() when superset != null:
return superset(_that.tag,_that.exercises);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ExerciseViewModel exercise)  single,required TResult Function( String tag,  List<ExerciseViewModel> exercises)  superset,}) {final _that = this;
switch (_that) {
case SingleGroupViewModel():
return single(_that.exercise);case SupersetGroup():
return superset(_that.tag,_that.exercises);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ExerciseViewModel exercise)?  single,TResult? Function( String tag,  List<ExerciseViewModel> exercises)?  superset,}) {final _that = this;
switch (_that) {
case SingleGroupViewModel() when single != null:
return single(_that.exercise);case SupersetGroup() when superset != null:
return superset(_that.tag,_that.exercises);case _:
  return null;

}
}

}

/// @nodoc


class SingleGroupViewModel implements SupersetGroupViewModel {
  const SingleGroupViewModel({required this.exercise});
  

 final  ExerciseViewModel exercise;

/// Create a copy of SupersetGroupViewModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SingleGroupViewModelCopyWith<SingleGroupViewModel> get copyWith => _$SingleGroupViewModelCopyWithImpl<SingleGroupViewModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SingleGroupViewModel&&(identical(other.exercise, exercise) || other.exercise == exercise));
}


@override
int get hashCode => Object.hash(runtimeType,exercise);

@override
String toString() {
  return 'SupersetGroupViewModel.single(exercise: $exercise)';
}


}

/// @nodoc
abstract mixin class $SingleGroupViewModelCopyWith<$Res> implements $SupersetGroupViewModelCopyWith<$Res> {
  factory $SingleGroupViewModelCopyWith(SingleGroupViewModel value, $Res Function(SingleGroupViewModel) _then) = _$SingleGroupViewModelCopyWithImpl;
@useResult
$Res call({
 ExerciseViewModel exercise
});


$ExerciseViewModelCopyWith<$Res> get exercise;

}
/// @nodoc
class _$SingleGroupViewModelCopyWithImpl<$Res>
    implements $SingleGroupViewModelCopyWith<$Res> {
  _$SingleGroupViewModelCopyWithImpl(this._self, this._then);

  final SingleGroupViewModel _self;
  final $Res Function(SingleGroupViewModel) _then;

/// Create a copy of SupersetGroupViewModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? exercise = null,}) {
  return _then(SingleGroupViewModel(
exercise: null == exercise ? _self.exercise : exercise // ignore: cast_nullable_to_non_nullable
as ExerciseViewModel,
  ));
}

/// Create a copy of SupersetGroupViewModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseViewModelCopyWith<$Res> get exercise {
  
  return $ExerciseViewModelCopyWith<$Res>(_self.exercise, (value) {
    return _then(_self.copyWith(exercise: value));
  });
}
}

/// @nodoc


class SupersetGroup implements SupersetGroupViewModel {
  const SupersetGroup({required this.tag, required final  List<ExerciseViewModel> exercises}): _exercises = exercises;
  

 final  String tag;
 final  List<ExerciseViewModel> _exercises;
 List<ExerciseViewModel> get exercises {
  if (_exercises is EqualUnmodifiableListView) return _exercises;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exercises);
}


/// Create a copy of SupersetGroupViewModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupersetGroupCopyWith<SupersetGroup> get copyWith => _$SupersetGroupCopyWithImpl<SupersetGroup>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupersetGroup&&(identical(other.tag, tag) || other.tag == tag)&&const DeepCollectionEquality().equals(other._exercises, _exercises));
}


@override
int get hashCode => Object.hash(runtimeType,tag,const DeepCollectionEquality().hash(_exercises));

@override
String toString() {
  return 'SupersetGroupViewModel.superset(tag: $tag, exercises: $exercises)';
}


}

/// @nodoc
abstract mixin class $SupersetGroupCopyWith<$Res> implements $SupersetGroupViewModelCopyWith<$Res> {
  factory $SupersetGroupCopyWith(SupersetGroup value, $Res Function(SupersetGroup) _then) = _$SupersetGroupCopyWithImpl;
@useResult
$Res call({
 String tag, List<ExerciseViewModel> exercises
});




}
/// @nodoc
class _$SupersetGroupCopyWithImpl<$Res>
    implements $SupersetGroupCopyWith<$Res> {
  _$SupersetGroupCopyWithImpl(this._self, this._then);

  final SupersetGroup _self;
  final $Res Function(SupersetGroup) _then;

/// Create a copy of SupersetGroupViewModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tag = null,Object? exercises = null,}) {
  return _then(SupersetGroup(
tag: null == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as String,exercises: null == exercises ? _self._exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<ExerciseViewModel>,
  ));
}


}

// dart format on

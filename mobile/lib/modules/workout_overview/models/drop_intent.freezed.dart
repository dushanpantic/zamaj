// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drop_intent.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DropTarget {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DropTarget);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DropTarget()';
}


}

/// @nodoc
class $DropTargetCopyWith<$Res>  {
$DropTargetCopyWith(DropTarget _, $Res Function(DropTarget) __);
}


/// Adds pattern-matching-related methods to [DropTarget].
extension DropTargetPatterns on DropTarget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DropTargetGap value)?  beforeIndex,TResult Function( DropTargetExercise value)?  ontoExercise,TResult Function( DropTargetOutside value)?  outside,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DropTargetGap() when beforeIndex != null:
return beforeIndex(_that);case DropTargetExercise() when ontoExercise != null:
return ontoExercise(_that);case DropTargetOutside() when outside != null:
return outside(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DropTargetGap value)  beforeIndex,required TResult Function( DropTargetExercise value)  ontoExercise,required TResult Function( DropTargetOutside value)  outside,}){
final _that = this;
switch (_that) {
case DropTargetGap():
return beforeIndex(_that);case DropTargetExercise():
return ontoExercise(_that);case DropTargetOutside():
return outside(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DropTargetGap value)?  beforeIndex,TResult? Function( DropTargetExercise value)?  ontoExercise,TResult? Function( DropTargetOutside value)?  outside,}){
final _that = this;
switch (_that) {
case DropTargetGap() when beforeIndex != null:
return beforeIndex(_that);case DropTargetExercise() when ontoExercise != null:
return ontoExercise(_that);case DropTargetOutside() when outside != null:
return outside(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int unfinishedIndex)?  beforeIndex,TResult Function( String sessionExerciseId)?  ontoExercise,TResult Function()?  outside,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DropTargetGap() when beforeIndex != null:
return beforeIndex(_that.unfinishedIndex);case DropTargetExercise() when ontoExercise != null:
return ontoExercise(_that.sessionExerciseId);case DropTargetOutside() when outside != null:
return outside();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int unfinishedIndex)  beforeIndex,required TResult Function( String sessionExerciseId)  ontoExercise,required TResult Function()  outside,}) {final _that = this;
switch (_that) {
case DropTargetGap():
return beforeIndex(_that.unfinishedIndex);case DropTargetExercise():
return ontoExercise(_that.sessionExerciseId);case DropTargetOutside():
return outside();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int unfinishedIndex)?  beforeIndex,TResult? Function( String sessionExerciseId)?  ontoExercise,TResult? Function()?  outside,}) {final _that = this;
switch (_that) {
case DropTargetGap() when beforeIndex != null:
return beforeIndex(_that.unfinishedIndex);case DropTargetExercise() when ontoExercise != null:
return ontoExercise(_that.sessionExerciseId);case DropTargetOutside() when outside != null:
return outside();case _:
  return null;

}
}

}

/// @nodoc


class DropTargetGap implements DropTarget {
  const DropTargetGap(this.unfinishedIndex);
  

 final  int unfinishedIndex;

/// Create a copy of DropTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DropTargetGapCopyWith<DropTargetGap> get copyWith => _$DropTargetGapCopyWithImpl<DropTargetGap>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DropTargetGap&&(identical(other.unfinishedIndex, unfinishedIndex) || other.unfinishedIndex == unfinishedIndex));
}


@override
int get hashCode => Object.hash(runtimeType,unfinishedIndex);

@override
String toString() {
  return 'DropTarget.beforeIndex(unfinishedIndex: $unfinishedIndex)';
}


}

/// @nodoc
abstract mixin class $DropTargetGapCopyWith<$Res> implements $DropTargetCopyWith<$Res> {
  factory $DropTargetGapCopyWith(DropTargetGap value, $Res Function(DropTargetGap) _then) = _$DropTargetGapCopyWithImpl;
@useResult
$Res call({
 int unfinishedIndex
});




}
/// @nodoc
class _$DropTargetGapCopyWithImpl<$Res>
    implements $DropTargetGapCopyWith<$Res> {
  _$DropTargetGapCopyWithImpl(this._self, this._then);

  final DropTargetGap _self;
  final $Res Function(DropTargetGap) _then;

/// Create a copy of DropTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? unfinishedIndex = null,}) {
  return _then(DropTargetGap(
null == unfinishedIndex ? _self.unfinishedIndex : unfinishedIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class DropTargetExercise implements DropTarget {
  const DropTargetExercise(this.sessionExerciseId);
  

 final  String sessionExerciseId;

/// Create a copy of DropTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DropTargetExerciseCopyWith<DropTargetExercise> get copyWith => _$DropTargetExerciseCopyWithImpl<DropTargetExercise>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DropTargetExercise&&(identical(other.sessionExerciseId, sessionExerciseId) || other.sessionExerciseId == sessionExerciseId));
}


@override
int get hashCode => Object.hash(runtimeType,sessionExerciseId);

@override
String toString() {
  return 'DropTarget.ontoExercise(sessionExerciseId: $sessionExerciseId)';
}


}

/// @nodoc
abstract mixin class $DropTargetExerciseCopyWith<$Res> implements $DropTargetCopyWith<$Res> {
  factory $DropTargetExerciseCopyWith(DropTargetExercise value, $Res Function(DropTargetExercise) _then) = _$DropTargetExerciseCopyWithImpl;
@useResult
$Res call({
 String sessionExerciseId
});




}
/// @nodoc
class _$DropTargetExerciseCopyWithImpl<$Res>
    implements $DropTargetExerciseCopyWith<$Res> {
  _$DropTargetExerciseCopyWithImpl(this._self, this._then);

  final DropTargetExercise _self;
  final $Res Function(DropTargetExercise) _then;

/// Create a copy of DropTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sessionExerciseId = null,}) {
  return _then(DropTargetExercise(
null == sessionExerciseId ? _self.sessionExerciseId : sessionExerciseId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class DropTargetOutside implements DropTarget {
  const DropTargetOutside();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DropTargetOutside);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DropTarget.outside()';
}


}




/// @nodoc
mixin _$DropIntent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DropIntent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DropIntent()';
}


}

/// @nodoc
class $DropIntentCopyWith<$Res>  {
$DropIntentCopyWith(DropIntent _, $Res Function(DropIntent) __);
}


/// Adds pattern-matching-related methods to [DropIntent].
extension DropIntentPatterns on DropIntent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReorderIntent value)?  reorder,TResult Function( CreateSupersetIntent value)?  createSuperset,TResult Function( AppendToSupersetIntent value)?  appendToSuperset,TResult Function( NoopIntent value)?  noop,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReorderIntent() when reorder != null:
return reorder(_that);case CreateSupersetIntent() when createSuperset != null:
return createSuperset(_that);case AppendToSupersetIntent() when appendToSuperset != null:
return appendToSuperset(_that);case NoopIntent() when noop != null:
return noop(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReorderIntent value)  reorder,required TResult Function( CreateSupersetIntent value)  createSuperset,required TResult Function( AppendToSupersetIntent value)  appendToSuperset,required TResult Function( NoopIntent value)  noop,}){
final _that = this;
switch (_that) {
case ReorderIntent():
return reorder(_that);case CreateSupersetIntent():
return createSuperset(_that);case AppendToSupersetIntent():
return appendToSuperset(_that);case NoopIntent():
return noop(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReorderIntent value)?  reorder,TResult? Function( CreateSupersetIntent value)?  createSuperset,TResult? Function( AppendToSupersetIntent value)?  appendToSuperset,TResult? Function( NoopIntent value)?  noop,}){
final _that = this;
switch (_that) {
case ReorderIntent() when reorder != null:
return reorder(_that);case CreateSupersetIntent() when createSuperset != null:
return createSuperset(_that);case AppendToSupersetIntent() when appendToSuperset != null:
return appendToSuperset(_that);case NoopIntent() when noop != null:
return noop(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String sessionId,  List<String> orderedUnfinishedIds)?  reorder,TResult Function( String sessionId,  List<String> sessionExerciseIds)?  createSuperset,TResult Function( String sessionId,  String supersetTag,  String sessionExerciseId)?  appendToSuperset,TResult Function()?  noop,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReorderIntent() when reorder != null:
return reorder(_that.sessionId,_that.orderedUnfinishedIds);case CreateSupersetIntent() when createSuperset != null:
return createSuperset(_that.sessionId,_that.sessionExerciseIds);case AppendToSupersetIntent() when appendToSuperset != null:
return appendToSuperset(_that.sessionId,_that.supersetTag,_that.sessionExerciseId);case NoopIntent() when noop != null:
return noop();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String sessionId,  List<String> orderedUnfinishedIds)  reorder,required TResult Function( String sessionId,  List<String> sessionExerciseIds)  createSuperset,required TResult Function( String sessionId,  String supersetTag,  String sessionExerciseId)  appendToSuperset,required TResult Function()  noop,}) {final _that = this;
switch (_that) {
case ReorderIntent():
return reorder(_that.sessionId,_that.orderedUnfinishedIds);case CreateSupersetIntent():
return createSuperset(_that.sessionId,_that.sessionExerciseIds);case AppendToSupersetIntent():
return appendToSuperset(_that.sessionId,_that.supersetTag,_that.sessionExerciseId);case NoopIntent():
return noop();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String sessionId,  List<String> orderedUnfinishedIds)?  reorder,TResult? Function( String sessionId,  List<String> sessionExerciseIds)?  createSuperset,TResult? Function( String sessionId,  String supersetTag,  String sessionExerciseId)?  appendToSuperset,TResult? Function()?  noop,}) {final _that = this;
switch (_that) {
case ReorderIntent() when reorder != null:
return reorder(_that.sessionId,_that.orderedUnfinishedIds);case CreateSupersetIntent() when createSuperset != null:
return createSuperset(_that.sessionId,_that.sessionExerciseIds);case AppendToSupersetIntent() when appendToSuperset != null:
return appendToSuperset(_that.sessionId,_that.supersetTag,_that.sessionExerciseId);case NoopIntent() when noop != null:
return noop();case _:
  return null;

}
}

}

/// @nodoc


class ReorderIntent implements DropIntent {
  const ReorderIntent({required this.sessionId, required final  List<String> orderedUnfinishedIds}): _orderedUnfinishedIds = orderedUnfinishedIds;
  

 final  String sessionId;
 final  List<String> _orderedUnfinishedIds;
 List<String> get orderedUnfinishedIds {
  if (_orderedUnfinishedIds is EqualUnmodifiableListView) return _orderedUnfinishedIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orderedUnfinishedIds);
}


/// Create a copy of DropIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReorderIntentCopyWith<ReorderIntent> get copyWith => _$ReorderIntentCopyWithImpl<ReorderIntent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReorderIntent&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&const DeepCollectionEquality().equals(other._orderedUnfinishedIds, _orderedUnfinishedIds));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,const DeepCollectionEquality().hash(_orderedUnfinishedIds));

@override
String toString() {
  return 'DropIntent.reorder(sessionId: $sessionId, orderedUnfinishedIds: $orderedUnfinishedIds)';
}


}

/// @nodoc
abstract mixin class $ReorderIntentCopyWith<$Res> implements $DropIntentCopyWith<$Res> {
  factory $ReorderIntentCopyWith(ReorderIntent value, $Res Function(ReorderIntent) _then) = _$ReorderIntentCopyWithImpl;
@useResult
$Res call({
 String sessionId, List<String> orderedUnfinishedIds
});




}
/// @nodoc
class _$ReorderIntentCopyWithImpl<$Res>
    implements $ReorderIntentCopyWith<$Res> {
  _$ReorderIntentCopyWithImpl(this._self, this._then);

  final ReorderIntent _self;
  final $Res Function(ReorderIntent) _then;

/// Create a copy of DropIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? orderedUnfinishedIds = null,}) {
  return _then(ReorderIntent(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,orderedUnfinishedIds: null == orderedUnfinishedIds ? _self._orderedUnfinishedIds : orderedUnfinishedIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class CreateSupersetIntent implements DropIntent {
  const CreateSupersetIntent({required this.sessionId, required final  List<String> sessionExerciseIds}): _sessionExerciseIds = sessionExerciseIds;
  

 final  String sessionId;
 final  List<String> _sessionExerciseIds;
 List<String> get sessionExerciseIds {
  if (_sessionExerciseIds is EqualUnmodifiableListView) return _sessionExerciseIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sessionExerciseIds);
}


/// Create a copy of DropIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateSupersetIntentCopyWith<CreateSupersetIntent> get copyWith => _$CreateSupersetIntentCopyWithImpl<CreateSupersetIntent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateSupersetIntent&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&const DeepCollectionEquality().equals(other._sessionExerciseIds, _sessionExerciseIds));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,const DeepCollectionEquality().hash(_sessionExerciseIds));

@override
String toString() {
  return 'DropIntent.createSuperset(sessionId: $sessionId, sessionExerciseIds: $sessionExerciseIds)';
}


}

/// @nodoc
abstract mixin class $CreateSupersetIntentCopyWith<$Res> implements $DropIntentCopyWith<$Res> {
  factory $CreateSupersetIntentCopyWith(CreateSupersetIntent value, $Res Function(CreateSupersetIntent) _then) = _$CreateSupersetIntentCopyWithImpl;
@useResult
$Res call({
 String sessionId, List<String> sessionExerciseIds
});




}
/// @nodoc
class _$CreateSupersetIntentCopyWithImpl<$Res>
    implements $CreateSupersetIntentCopyWith<$Res> {
  _$CreateSupersetIntentCopyWithImpl(this._self, this._then);

  final CreateSupersetIntent _self;
  final $Res Function(CreateSupersetIntent) _then;

/// Create a copy of DropIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? sessionExerciseIds = null,}) {
  return _then(CreateSupersetIntent(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,sessionExerciseIds: null == sessionExerciseIds ? _self._sessionExerciseIds : sessionExerciseIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class AppendToSupersetIntent implements DropIntent {
  const AppendToSupersetIntent({required this.sessionId, required this.supersetTag, required this.sessionExerciseId});
  

 final  String sessionId;
 final  String supersetTag;
 final  String sessionExerciseId;

/// Create a copy of DropIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppendToSupersetIntentCopyWith<AppendToSupersetIntent> get copyWith => _$AppendToSupersetIntentCopyWithImpl<AppendToSupersetIntent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppendToSupersetIntent&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.supersetTag, supersetTag) || other.supersetTag == supersetTag)&&(identical(other.sessionExerciseId, sessionExerciseId) || other.sessionExerciseId == sessionExerciseId));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,supersetTag,sessionExerciseId);

@override
String toString() {
  return 'DropIntent.appendToSuperset(sessionId: $sessionId, supersetTag: $supersetTag, sessionExerciseId: $sessionExerciseId)';
}


}

/// @nodoc
abstract mixin class $AppendToSupersetIntentCopyWith<$Res> implements $DropIntentCopyWith<$Res> {
  factory $AppendToSupersetIntentCopyWith(AppendToSupersetIntent value, $Res Function(AppendToSupersetIntent) _then) = _$AppendToSupersetIntentCopyWithImpl;
@useResult
$Res call({
 String sessionId, String supersetTag, String sessionExerciseId
});




}
/// @nodoc
class _$AppendToSupersetIntentCopyWithImpl<$Res>
    implements $AppendToSupersetIntentCopyWith<$Res> {
  _$AppendToSupersetIntentCopyWithImpl(this._self, this._then);

  final AppendToSupersetIntent _self;
  final $Res Function(AppendToSupersetIntent) _then;

/// Create a copy of DropIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? supersetTag = null,Object? sessionExerciseId = null,}) {
  return _then(AppendToSupersetIntent(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,supersetTag: null == supersetTag ? _self.supersetTag : supersetTag // ignore: cast_nullable_to_non_nullable
as String,sessionExerciseId: null == sessionExerciseId ? _self.sessionExerciseId : sessionExerciseId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class NoopIntent implements DropIntent {
  const NoopIntent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoopIntent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DropIntent.noop()';
}


}




// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
ExerciseState _$ExerciseStateFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'unfinished':
          return UnfinishedState.fromJson(
            json
          );
                case 'completed':
          return CompletedState.fromJson(
            json
          );
                case 'skipped':
          return SkippedState.fromJson(
            json
          );
                case 'replaced':
          return ReplacedState.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'ExerciseState',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$ExerciseState {



  /// Serializes this ExerciseState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseState);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExerciseState()';
}


}

/// @nodoc
class $ExerciseStateCopyWith<$Res>  {
$ExerciseStateCopyWith(ExerciseState _, $Res Function(ExerciseState) __);
}


/// Adds pattern-matching-related methods to [ExerciseState].
extension ExerciseStatePatterns on ExerciseState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UnfinishedState value)?  unfinished,TResult Function( CompletedState value)?  completed,TResult Function( SkippedState value)?  skipped,TResult Function( ReplacedState value)?  replaced,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UnfinishedState() when unfinished != null:
return unfinished(_that);case CompletedState() when completed != null:
return completed(_that);case SkippedState() when skipped != null:
return skipped(_that);case ReplacedState() when replaced != null:
return replaced(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UnfinishedState value)  unfinished,required TResult Function( CompletedState value)  completed,required TResult Function( SkippedState value)  skipped,required TResult Function( ReplacedState value)  replaced,}){
final _that = this;
switch (_that) {
case UnfinishedState():
return unfinished(_that);case CompletedState():
return completed(_that);case SkippedState():
return skipped(_that);case ReplacedState():
return replaced(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UnfinishedState value)?  unfinished,TResult? Function( CompletedState value)?  completed,TResult? Function( SkippedState value)?  skipped,TResult? Function( ReplacedState value)?  replaced,}){
final _that = this;
switch (_that) {
case UnfinishedState() when unfinished != null:
return unfinished(_that);case CompletedState() when completed != null:
return completed(_that);case SkippedState() when skipped != null:
return skipped(_that);case ReplacedState() when replaced != null:
return replaced(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  unfinished,TResult Function()?  completed,TResult Function()?  skipped,TResult Function( SubstituteExercise substitute)?  replaced,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UnfinishedState() when unfinished != null:
return unfinished();case CompletedState() when completed != null:
return completed();case SkippedState() when skipped != null:
return skipped();case ReplacedState() when replaced != null:
return replaced(_that.substitute);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  unfinished,required TResult Function()  completed,required TResult Function()  skipped,required TResult Function( SubstituteExercise substitute)  replaced,}) {final _that = this;
switch (_that) {
case UnfinishedState():
return unfinished();case CompletedState():
return completed();case SkippedState():
return skipped();case ReplacedState():
return replaced(_that.substitute);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  unfinished,TResult? Function()?  completed,TResult? Function()?  skipped,TResult? Function( SubstituteExercise substitute)?  replaced,}) {final _that = this;
switch (_that) {
case UnfinishedState() when unfinished != null:
return unfinished();case CompletedState() when completed != null:
return completed();case SkippedState() when skipped != null:
return skipped();case ReplacedState() when replaced != null:
return replaced(_that.substitute);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class UnfinishedState implements ExerciseState {
  const UnfinishedState({final  String? $type}): $type = $type ?? 'unfinished';
  factory UnfinishedState.fromJson(Map<String, dynamic> json) => _$UnfinishedStateFromJson(json);



@JsonKey(name: 'type')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$UnfinishedStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnfinishedState);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExerciseState.unfinished()';
}


}




/// @nodoc
@JsonSerializable()

class CompletedState implements ExerciseState {
  const CompletedState({final  String? $type}): $type = $type ?? 'completed';
  factory CompletedState.fromJson(Map<String, dynamic> json) => _$CompletedStateFromJson(json);



@JsonKey(name: 'type')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$CompletedStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompletedState);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExerciseState.completed()';
}


}




/// @nodoc
@JsonSerializable()

class SkippedState implements ExerciseState {
  const SkippedState({final  String? $type}): $type = $type ?? 'skipped';
  factory SkippedState.fromJson(Map<String, dynamic> json) => _$SkippedStateFromJson(json);



@JsonKey(name: 'type')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$SkippedStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkippedState);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExerciseState.skipped()';
}


}




/// @nodoc
@JsonSerializable()

class ReplacedState implements ExerciseState {
  const ReplacedState({required this.substitute, final  String? $type}): $type = $type ?? 'replaced';
  factory ReplacedState.fromJson(Map<String, dynamic> json) => _$ReplacedStateFromJson(json);

 final  SubstituteExercise substitute;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ExerciseState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReplacedStateCopyWith<ReplacedState> get copyWith => _$ReplacedStateCopyWithImpl<ReplacedState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReplacedStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReplacedState&&(identical(other.substitute, substitute) || other.substitute == substitute));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,substitute);

@override
String toString() {
  return 'ExerciseState.replaced(substitute: $substitute)';
}


}

/// @nodoc
abstract mixin class $ReplacedStateCopyWith<$Res> implements $ExerciseStateCopyWith<$Res> {
  factory $ReplacedStateCopyWith(ReplacedState value, $Res Function(ReplacedState) _then) = _$ReplacedStateCopyWithImpl;
@useResult
$Res call({
 SubstituteExercise substitute
});


$SubstituteExerciseCopyWith<$Res> get substitute;

}
/// @nodoc
class _$ReplacedStateCopyWithImpl<$Res>
    implements $ReplacedStateCopyWith<$Res> {
  _$ReplacedStateCopyWithImpl(this._self, this._then);

  final ReplacedState _self;
  final $Res Function(ReplacedState) _then;

/// Create a copy of ExerciseState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? substitute = null,}) {
  return _then(ReplacedState(
substitute: null == substitute ? _self.substitute : substitute // ignore: cast_nullable_to_non_nullable
as SubstituteExercise,
  ));
}

/// Create a copy of ExerciseState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubstituteExerciseCopyWith<$Res> get substitute {
  
  return $SubstituteExerciseCopyWith<$Res>(_self.substitute, (value) {
    return _then(_self.copyWith(substitute: value));
  });
}
}

// dart format on

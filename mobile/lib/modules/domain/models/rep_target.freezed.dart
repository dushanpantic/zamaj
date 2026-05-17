// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rep_target.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
RepTarget _$RepTargetFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'fixed':
          return RepTargetFixed.fromJson(
            json
          );
                case 'range':
          return RepTargetRange.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'RepTarget',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$RepTarget {



  /// Serializes this RepTarget to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RepTarget);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RepTarget()';
}


}

/// @nodoc
class $RepTargetCopyWith<$Res>  {
$RepTargetCopyWith(RepTarget _, $Res Function(RepTarget) __);
}


/// Adds pattern-matching-related methods to [RepTarget].
extension RepTargetPatterns on RepTarget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RepTargetFixed value)?  fixed,TResult Function( RepTargetRange value)?  range,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RepTargetFixed() when fixed != null:
return fixed(_that);case RepTargetRange() when range != null:
return range(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RepTargetFixed value)  fixed,required TResult Function( RepTargetRange value)  range,}){
final _that = this;
switch (_that) {
case RepTargetFixed():
return fixed(_that);case RepTargetRange():
return range(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RepTargetFixed value)?  fixed,TResult? Function( RepTargetRange value)?  range,}){
final _that = this;
switch (_that) {
case RepTargetFixed() when fixed != null:
return fixed(_that);case RepTargetRange() when range != null:
return range(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int reps)?  fixed,TResult Function( int minReps,  int maxReps)?  range,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RepTargetFixed() when fixed != null:
return fixed(_that.reps);case RepTargetRange() when range != null:
return range(_that.minReps,_that.maxReps);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int reps)  fixed,required TResult Function( int minReps,  int maxReps)  range,}) {final _that = this;
switch (_that) {
case RepTargetFixed():
return fixed(_that.reps);case RepTargetRange():
return range(_that.minReps,_that.maxReps);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int reps)?  fixed,TResult? Function( int minReps,  int maxReps)?  range,}) {final _that = this;
switch (_that) {
case RepTargetFixed() when fixed != null:
return fixed(_that.reps);case RepTargetRange() when range != null:
return range(_that.minReps,_that.maxReps);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class RepTargetFixed extends RepTarget {
   RepTargetFixed({required this.reps, final  String? $type}): $type = $type ?? 'fixed',super._();
  factory RepTargetFixed.fromJson(Map<String, dynamic> json) => _$RepTargetFixedFromJson(json);

 final  int reps;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of RepTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RepTargetFixedCopyWith<RepTargetFixed> get copyWith => _$RepTargetFixedCopyWithImpl<RepTargetFixed>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RepTargetFixedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RepTargetFixed&&(identical(other.reps, reps) || other.reps == reps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reps);

@override
String toString() {
  return 'RepTarget.fixed(reps: $reps)';
}


}

/// @nodoc
abstract mixin class $RepTargetFixedCopyWith<$Res> implements $RepTargetCopyWith<$Res> {
  factory $RepTargetFixedCopyWith(RepTargetFixed value, $Res Function(RepTargetFixed) _then) = _$RepTargetFixedCopyWithImpl;
@useResult
$Res call({
 int reps
});




}
/// @nodoc
class _$RepTargetFixedCopyWithImpl<$Res>
    implements $RepTargetFixedCopyWith<$Res> {
  _$RepTargetFixedCopyWithImpl(this._self, this._then);

  final RepTargetFixed _self;
  final $Res Function(RepTargetFixed) _then;

/// Create a copy of RepTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reps = null,}) {
  return _then(RepTargetFixed(
reps: null == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class RepTargetRange extends RepTarget {
   RepTargetRange({required this.minReps, required this.maxReps, final  String? $type}): $type = $type ?? 'range',super._();
  factory RepTargetRange.fromJson(Map<String, dynamic> json) => _$RepTargetRangeFromJson(json);

 final  int minReps;
 final  int maxReps;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of RepTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RepTargetRangeCopyWith<RepTargetRange> get copyWith => _$RepTargetRangeCopyWithImpl<RepTargetRange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RepTargetRangeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RepTargetRange&&(identical(other.minReps, minReps) || other.minReps == minReps)&&(identical(other.maxReps, maxReps) || other.maxReps == maxReps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minReps,maxReps);

@override
String toString() {
  return 'RepTarget.range(minReps: $minReps, maxReps: $maxReps)';
}


}

/// @nodoc
abstract mixin class $RepTargetRangeCopyWith<$Res> implements $RepTargetCopyWith<$Res> {
  factory $RepTargetRangeCopyWith(RepTargetRange value, $Res Function(RepTargetRange) _then) = _$RepTargetRangeCopyWithImpl;
@useResult
$Res call({
 int minReps, int maxReps
});




}
/// @nodoc
class _$RepTargetRangeCopyWithImpl<$Res>
    implements $RepTargetRangeCopyWith<$Res> {
  _$RepTargetRangeCopyWithImpl(this._self, this._then);

  final RepTargetRange _self;
  final $Res Function(RepTargetRange) _then;

/// Create a copy of RepTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? minReps = null,Object? maxReps = null,}) {
  return _then(RepTargetRange(
minReps: null == minReps ? _self.minReps : minReps // ignore: cast_nullable_to_non_nullable
as int,maxReps: null == maxReps ? _self.maxReps : maxReps // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

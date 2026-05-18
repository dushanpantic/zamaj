// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'planned_set_values.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
PlannedSetValues _$PlannedSetValuesFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'repBased':
          return PlannedRepBased.fromJson(
            json
          );
                case 'timeBased':
          return PlannedTimeBased.fromJson(
            json
          );
                case 'bodyweight':
          return PlannedBodyweight.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'PlannedSetValues',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$PlannedSetValues {



  /// Serializes this PlannedSetValues to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlannedSetValues);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlannedSetValues()';
}


}

/// @nodoc
class $PlannedSetValuesCopyWith<$Res>  {
$PlannedSetValuesCopyWith(PlannedSetValues _, $Res Function(PlannedSetValues) __);
}


/// Adds pattern-matching-related methods to [PlannedSetValues].
extension PlannedSetValuesPatterns on PlannedSetValues {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlannedRepBased value)?  repBased,TResult Function( PlannedTimeBased value)?  timeBased,TResult Function( PlannedBodyweight value)?  bodyweight,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlannedRepBased() when repBased != null:
return repBased(_that);case PlannedTimeBased() when timeBased != null:
return timeBased(_that);case PlannedBodyweight() when bodyweight != null:
return bodyweight(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlannedRepBased value)  repBased,required TResult Function( PlannedTimeBased value)  timeBased,required TResult Function( PlannedBodyweight value)  bodyweight,}){
final _that = this;
switch (_that) {
case PlannedRepBased():
return repBased(_that);case PlannedTimeBased():
return timeBased(_that);case PlannedBodyweight():
return bodyweight(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlannedRepBased value)?  repBased,TResult? Function( PlannedTimeBased value)?  timeBased,TResult? Function( PlannedBodyweight value)?  bodyweight,}){
final _that = this;
switch (_that) {
case PlannedRepBased() when repBased != null:
return repBased(_that);case PlannedTimeBased() when timeBased != null:
return timeBased(_that);case PlannedBodyweight() when bodyweight != null:
return bodyweight(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( double weightKg,  RepTarget repTarget)?  repBased,TResult Function( int durationSeconds,  double? weightKg)?  timeBased,TResult Function( RepTarget repTarget)?  bodyweight,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PlannedRepBased() when repBased != null:
return repBased(_that.weightKg,_that.repTarget);case PlannedTimeBased() when timeBased != null:
return timeBased(_that.durationSeconds,_that.weightKg);case PlannedBodyweight() when bodyweight != null:
return bodyweight(_that.repTarget);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( double weightKg,  RepTarget repTarget)  repBased,required TResult Function( int durationSeconds,  double? weightKg)  timeBased,required TResult Function( RepTarget repTarget)  bodyweight,}) {final _that = this;
switch (_that) {
case PlannedRepBased():
return repBased(_that.weightKg,_that.repTarget);case PlannedTimeBased():
return timeBased(_that.durationSeconds,_that.weightKg);case PlannedBodyweight():
return bodyweight(_that.repTarget);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( double weightKg,  RepTarget repTarget)?  repBased,TResult? Function( int durationSeconds,  double? weightKg)?  timeBased,TResult? Function( RepTarget repTarget)?  bodyweight,}) {final _that = this;
switch (_that) {
case PlannedRepBased() when repBased != null:
return repBased(_that.weightKg,_that.repTarget);case PlannedTimeBased() when timeBased != null:
return timeBased(_that.durationSeconds,_that.weightKg);case PlannedBodyweight() when bodyweight != null:
return bodyweight(_that.repTarget);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class PlannedRepBased implements PlannedSetValues {
  const PlannedRepBased({required this.weightKg, required this.repTarget, final  String? $type}): $type = $type ?? 'repBased';
  factory PlannedRepBased.fromJson(Map<String, dynamic> json) => _$PlannedRepBasedFromJson(json);

 final  double weightKg;
 final  RepTarget repTarget;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of PlannedSetValues
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlannedRepBasedCopyWith<PlannedRepBased> get copyWith => _$PlannedRepBasedCopyWithImpl<PlannedRepBased>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlannedRepBasedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlannedRepBased&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.repTarget, repTarget) || other.repTarget == repTarget));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weightKg,repTarget);

@override
String toString() {
  return 'PlannedSetValues.repBased(weightKg: $weightKg, repTarget: $repTarget)';
}


}

/// @nodoc
abstract mixin class $PlannedRepBasedCopyWith<$Res> implements $PlannedSetValuesCopyWith<$Res> {
  factory $PlannedRepBasedCopyWith(PlannedRepBased value, $Res Function(PlannedRepBased) _then) = _$PlannedRepBasedCopyWithImpl;
@useResult
$Res call({
 double weightKg, RepTarget repTarget
});


$RepTargetCopyWith<$Res> get repTarget;

}
/// @nodoc
class _$PlannedRepBasedCopyWithImpl<$Res>
    implements $PlannedRepBasedCopyWith<$Res> {
  _$PlannedRepBasedCopyWithImpl(this._self, this._then);

  final PlannedRepBased _self;
  final $Res Function(PlannedRepBased) _then;

/// Create a copy of PlannedSetValues
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? weightKg = null,Object? repTarget = null,}) {
  return _then(PlannedRepBased(
weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double,repTarget: null == repTarget ? _self.repTarget : repTarget // ignore: cast_nullable_to_non_nullable
as RepTarget,
  ));
}

/// Create a copy of PlannedSetValues
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RepTargetCopyWith<$Res> get repTarget {
  
  return $RepTargetCopyWith<$Res>(_self.repTarget, (value) {
    return _then(_self.copyWith(repTarget: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class PlannedTimeBased implements PlannedSetValues {
  const PlannedTimeBased({required this.durationSeconds, this.weightKg, final  String? $type}): $type = $type ?? 'timeBased';
  factory PlannedTimeBased.fromJson(Map<String, dynamic> json) => _$PlannedTimeBasedFromJson(json);

 final  int durationSeconds;
 final  double? weightKg;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of PlannedSetValues
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlannedTimeBasedCopyWith<PlannedTimeBased> get copyWith => _$PlannedTimeBasedCopyWithImpl<PlannedTimeBased>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlannedTimeBasedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlannedTimeBased&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,durationSeconds,weightKg);

@override
String toString() {
  return 'PlannedSetValues.timeBased(durationSeconds: $durationSeconds, weightKg: $weightKg)';
}


}

/// @nodoc
abstract mixin class $PlannedTimeBasedCopyWith<$Res> implements $PlannedSetValuesCopyWith<$Res> {
  factory $PlannedTimeBasedCopyWith(PlannedTimeBased value, $Res Function(PlannedTimeBased) _then) = _$PlannedTimeBasedCopyWithImpl;
@useResult
$Res call({
 int durationSeconds, double? weightKg
});




}
/// @nodoc
class _$PlannedTimeBasedCopyWithImpl<$Res>
    implements $PlannedTimeBasedCopyWith<$Res> {
  _$PlannedTimeBasedCopyWithImpl(this._self, this._then);

  final PlannedTimeBased _self;
  final $Res Function(PlannedTimeBased) _then;

/// Create a copy of PlannedSetValues
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? durationSeconds = null,Object? weightKg = freezed,}) {
  return _then(PlannedTimeBased(
durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class PlannedBodyweight implements PlannedSetValues {
  const PlannedBodyweight({required this.repTarget, final  String? $type}): $type = $type ?? 'bodyweight';
  factory PlannedBodyweight.fromJson(Map<String, dynamic> json) => _$PlannedBodyweightFromJson(json);

 final  RepTarget repTarget;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of PlannedSetValues
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlannedBodyweightCopyWith<PlannedBodyweight> get copyWith => _$PlannedBodyweightCopyWithImpl<PlannedBodyweight>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlannedBodyweightToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlannedBodyweight&&(identical(other.repTarget, repTarget) || other.repTarget == repTarget));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,repTarget);

@override
String toString() {
  return 'PlannedSetValues.bodyweight(repTarget: $repTarget)';
}


}

/// @nodoc
abstract mixin class $PlannedBodyweightCopyWith<$Res> implements $PlannedSetValuesCopyWith<$Res> {
  factory $PlannedBodyweightCopyWith(PlannedBodyweight value, $Res Function(PlannedBodyweight) _then) = _$PlannedBodyweightCopyWithImpl;
@useResult
$Res call({
 RepTarget repTarget
});


$RepTargetCopyWith<$Res> get repTarget;

}
/// @nodoc
class _$PlannedBodyweightCopyWithImpl<$Res>
    implements $PlannedBodyweightCopyWith<$Res> {
  _$PlannedBodyweightCopyWithImpl(this._self, this._then);

  final PlannedBodyweight _self;
  final $Res Function(PlannedBodyweight) _then;

/// Create a copy of PlannedSetValues
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? repTarget = null,}) {
  return _then(PlannedBodyweight(
repTarget: null == repTarget ? _self.repTarget : repTarget // ignore: cast_nullable_to_non_nullable
as RepTarget,
  ));
}

/// Create a copy of PlannedSetValues
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RepTargetCopyWith<$Res> get repTarget {
  
  return $RepTargetCopyWith<$Res>(_self.repTarget, (value) {
    return _then(_self.copyWith(repTarget: value));
  });
}
}

// dart format on

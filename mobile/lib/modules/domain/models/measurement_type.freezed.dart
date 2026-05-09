// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'measurement_type.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
MeasurementType _$MeasurementTypeFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'repBased':
          return RepBasedMeasurement.fromJson(
            json
          );
                case 'timeBased':
          return TimeBasedMeasurement.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'MeasurementType',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$MeasurementType {



  /// Serializes this MeasurementType to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MeasurementType);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MeasurementType()';
}


}

/// @nodoc
class $MeasurementTypeCopyWith<$Res>  {
$MeasurementTypeCopyWith(MeasurementType _, $Res Function(MeasurementType) __);
}


/// Adds pattern-matching-related methods to [MeasurementType].
extension MeasurementTypePatterns on MeasurementType {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RepBasedMeasurement value)?  repBased,TResult Function( TimeBasedMeasurement value)?  timeBased,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RepBasedMeasurement() when repBased != null:
return repBased(_that);case TimeBasedMeasurement() when timeBased != null:
return timeBased(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RepBasedMeasurement value)  repBased,required TResult Function( TimeBasedMeasurement value)  timeBased,}){
final _that = this;
switch (_that) {
case RepBasedMeasurement():
return repBased(_that);case TimeBasedMeasurement():
return timeBased(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RepBasedMeasurement value)?  repBased,TResult? Function( TimeBasedMeasurement value)?  timeBased,}){
final _that = this;
switch (_that) {
case RepBasedMeasurement() when repBased != null:
return repBased(_that);case TimeBasedMeasurement() when timeBased != null:
return timeBased(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  repBased,TResult Function()?  timeBased,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RepBasedMeasurement() when repBased != null:
return repBased();case TimeBasedMeasurement() when timeBased != null:
return timeBased();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  repBased,required TResult Function()  timeBased,}) {final _that = this;
switch (_that) {
case RepBasedMeasurement():
return repBased();case TimeBasedMeasurement():
return timeBased();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  repBased,TResult? Function()?  timeBased,}) {final _that = this;
switch (_that) {
case RepBasedMeasurement() when repBased != null:
return repBased();case TimeBasedMeasurement() when timeBased != null:
return timeBased();case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class RepBasedMeasurement implements MeasurementType {
  const RepBasedMeasurement({final  String? $type}): $type = $type ?? 'repBased';
  factory RepBasedMeasurement.fromJson(Map<String, dynamic> json) => _$RepBasedMeasurementFromJson(json);



@JsonKey(name: 'type')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$RepBasedMeasurementToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RepBasedMeasurement);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MeasurementType.repBased()';
}


}




/// @nodoc
@JsonSerializable()

class TimeBasedMeasurement implements MeasurementType {
  const TimeBasedMeasurement({final  String? $type}): $type = $type ?? 'timeBased';
  factory TimeBasedMeasurement.fromJson(Map<String, dynamic> json) => _$TimeBasedMeasurementFromJson(json);



@JsonKey(name: 'type')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$TimeBasedMeasurementToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeBasedMeasurement);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MeasurementType.timeBased()';
}


}




// dart format on

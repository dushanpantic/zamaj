// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'actual_set_values.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
ActualSetValues _$ActualSetValuesFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'repBased':
          return ActualRepBased.fromJson(
            json
          );
                case 'timeBased':
          return ActualTimeBased.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'ActualSetValues',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$ActualSetValues {



  /// Serializes this ActualSetValues to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActualSetValues);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ActualSetValues()';
}


}

/// @nodoc
class $ActualSetValuesCopyWith<$Res>  {
$ActualSetValuesCopyWith(ActualSetValues _, $Res Function(ActualSetValues) __);
}


/// Adds pattern-matching-related methods to [ActualSetValues].
extension ActualSetValuesPatterns on ActualSetValues {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ActualRepBased value)?  repBased,TResult Function( ActualTimeBased value)?  timeBased,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ActualRepBased() when repBased != null:
return repBased(_that);case ActualTimeBased() when timeBased != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ActualRepBased value)  repBased,required TResult Function( ActualTimeBased value)  timeBased,}){
final _that = this;
switch (_that) {
case ActualRepBased():
return repBased(_that);case ActualTimeBased():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ActualRepBased value)?  repBased,TResult? Function( ActualTimeBased value)?  timeBased,}){
final _that = this;
switch (_that) {
case ActualRepBased() when repBased != null:
return repBased(_that);case ActualTimeBased() when timeBased != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( double weightKg,  int reps)?  repBased,TResult Function( int durationSeconds)?  timeBased,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ActualRepBased() when repBased != null:
return repBased(_that.weightKg,_that.reps);case ActualTimeBased() when timeBased != null:
return timeBased(_that.durationSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( double weightKg,  int reps)  repBased,required TResult Function( int durationSeconds)  timeBased,}) {final _that = this;
switch (_that) {
case ActualRepBased():
return repBased(_that.weightKg,_that.reps);case ActualTimeBased():
return timeBased(_that.durationSeconds);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( double weightKg,  int reps)?  repBased,TResult? Function( int durationSeconds)?  timeBased,}) {final _that = this;
switch (_that) {
case ActualRepBased() when repBased != null:
return repBased(_that.weightKg,_that.reps);case ActualTimeBased() when timeBased != null:
return timeBased(_that.durationSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class ActualRepBased implements ActualSetValues {
  const ActualRepBased({required this.weightKg, required this.reps, final  String? $type}): $type = $type ?? 'repBased';
  factory ActualRepBased.fromJson(Map<String, dynamic> json) => _$ActualRepBasedFromJson(json);

 final  double weightKg;
 final  int reps;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ActualSetValues
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActualRepBasedCopyWith<ActualRepBased> get copyWith => _$ActualRepBasedCopyWithImpl<ActualRepBased>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActualRepBasedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActualRepBased&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.reps, reps) || other.reps == reps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weightKg,reps);

@override
String toString() {
  return 'ActualSetValues.repBased(weightKg: $weightKg, reps: $reps)';
}


}

/// @nodoc
abstract mixin class $ActualRepBasedCopyWith<$Res> implements $ActualSetValuesCopyWith<$Res> {
  factory $ActualRepBasedCopyWith(ActualRepBased value, $Res Function(ActualRepBased) _then) = _$ActualRepBasedCopyWithImpl;
@useResult
$Res call({
 double weightKg, int reps
});




}
/// @nodoc
class _$ActualRepBasedCopyWithImpl<$Res>
    implements $ActualRepBasedCopyWith<$Res> {
  _$ActualRepBasedCopyWithImpl(this._self, this._then);

  final ActualRepBased _self;
  final $Res Function(ActualRepBased) _then;

/// Create a copy of ActualSetValues
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? weightKg = null,Object? reps = null,}) {
  return _then(ActualRepBased(
weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double,reps: null == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ActualTimeBased implements ActualSetValues {
  const ActualTimeBased({required this.durationSeconds, final  String? $type}): $type = $type ?? 'timeBased';
  factory ActualTimeBased.fromJson(Map<String, dynamic> json) => _$ActualTimeBasedFromJson(json);

 final  int durationSeconds;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ActualSetValues
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActualTimeBasedCopyWith<ActualTimeBased> get copyWith => _$ActualTimeBasedCopyWithImpl<ActualTimeBased>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActualTimeBasedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActualTimeBased&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,durationSeconds);

@override
String toString() {
  return 'ActualSetValues.timeBased(durationSeconds: $durationSeconds)';
}


}

/// @nodoc
abstract mixin class $ActualTimeBasedCopyWith<$Res> implements $ActualSetValuesCopyWith<$Res> {
  factory $ActualTimeBasedCopyWith(ActualTimeBased value, $Res Function(ActualTimeBased) _then) = _$ActualTimeBasedCopyWithImpl;
@useResult
$Res call({
 int durationSeconds
});




}
/// @nodoc
class _$ActualTimeBasedCopyWithImpl<$Res>
    implements $ActualTimeBasedCopyWith<$Res> {
  _$ActualTimeBasedCopyWithImpl(this._self, this._then);

  final ActualTimeBased _self;
  final $Res Function(ActualTimeBased) _then;

/// Create a copy of ActualSetValues
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? durationSeconds = null,}) {
  return _then(ActualTimeBased(
durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

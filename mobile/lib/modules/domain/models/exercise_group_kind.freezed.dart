// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_group_kind.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
ExerciseGroupKind _$ExerciseGroupKindFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'single':
          return SingleKind.fromJson(
            json
          );
                case 'superset':
          return SupersetKind.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'ExerciseGroupKind',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$ExerciseGroupKind {



  /// Serializes this ExerciseGroupKind to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseGroupKind);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExerciseGroupKind()';
}


}

/// @nodoc
class $ExerciseGroupKindCopyWith<$Res>  {
$ExerciseGroupKindCopyWith(ExerciseGroupKind _, $Res Function(ExerciseGroupKind) __);
}


/// Adds pattern-matching-related methods to [ExerciseGroupKind].
extension ExerciseGroupKindPatterns on ExerciseGroupKind {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SingleKind value)?  single,TResult Function( SupersetKind value)?  superset,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SingleKind() when single != null:
return single(_that);case SupersetKind() when superset != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SingleKind value)  single,required TResult Function( SupersetKind value)  superset,}){
final _that = this;
switch (_that) {
case SingleKind():
return single(_that);case SupersetKind():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SingleKind value)?  single,TResult? Function( SupersetKind value)?  superset,}){
final _that = this;
switch (_that) {
case SingleKind() when single != null:
return single(_that);case SupersetKind() when superset != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  single,TResult Function()?  superset,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SingleKind() when single != null:
return single();case SupersetKind() when superset != null:
return superset();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  single,required TResult Function()  superset,}) {final _that = this;
switch (_that) {
case SingleKind():
return single();case SupersetKind():
return superset();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  single,TResult? Function()?  superset,}) {final _that = this;
switch (_that) {
case SingleKind() when single != null:
return single();case SupersetKind() when superset != null:
return superset();case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class SingleKind implements ExerciseGroupKind {
  const SingleKind({final  String? $type}): $type = $type ?? 'single';
  factory SingleKind.fromJson(Map<String, dynamic> json) => _$SingleKindFromJson(json);



@JsonKey(name: 'type')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$SingleKindToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SingleKind);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExerciseGroupKind.single()';
}


}




/// @nodoc
@JsonSerializable()

class SupersetKind implements ExerciseGroupKind {
  const SupersetKind({final  String? $type}): $type = $type ?? 'superset';
  factory SupersetKind.fromJson(Map<String, dynamic> json) => _$SupersetKindFromJson(json);



@JsonKey(name: 'type')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$SupersetKindToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupersetKind);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExerciseGroupKind.superset()';
}


}




// dart format on

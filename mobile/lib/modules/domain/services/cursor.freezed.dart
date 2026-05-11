// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cursor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
Cursor _$CursorFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'active':
          return ActiveCursor.fromJson(
            json
          );
                case 'completed':
          return CompletedCursor.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'Cursor',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$Cursor {



  /// Serializes this Cursor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Cursor);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Cursor()';
}


}

/// @nodoc
class $CursorCopyWith<$Res>  {
$CursorCopyWith(Cursor _, $Res Function(Cursor) __);
}


/// Adds pattern-matching-related methods to [Cursor].
extension CursorPatterns on Cursor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ActiveCursor value)?  active,TResult Function( CompletedCursor value)?  completed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ActiveCursor() when active != null:
return active(_that);case CompletedCursor() when completed != null:
return completed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ActiveCursor value)  active,required TResult Function( CompletedCursor value)  completed,}){
final _that = this;
switch (_that) {
case ActiveCursor():
return active(_that);case CompletedCursor():
return completed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ActiveCursor value)?  active,TResult? Function( CompletedCursor value)?  completed,}){
final _that = this;
switch (_that) {
case ActiveCursor() when active != null:
return active(_that);case CompletedCursor() when completed != null:
return completed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String sessionExerciseId,  int setIndex)?  active,TResult Function()?  completed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ActiveCursor() when active != null:
return active(_that.sessionExerciseId,_that.setIndex);case CompletedCursor() when completed != null:
return completed();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String sessionExerciseId,  int setIndex)  active,required TResult Function()  completed,}) {final _that = this;
switch (_that) {
case ActiveCursor():
return active(_that.sessionExerciseId,_that.setIndex);case CompletedCursor():
return completed();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String sessionExerciseId,  int setIndex)?  active,TResult? Function()?  completed,}) {final _that = this;
switch (_that) {
case ActiveCursor() when active != null:
return active(_that.sessionExerciseId,_that.setIndex);case CompletedCursor() when completed != null:
return completed();case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class ActiveCursor implements Cursor {
  const ActiveCursor({required this.sessionExerciseId, required this.setIndex, final  String? $type}): $type = $type ?? 'active';
  factory ActiveCursor.fromJson(Map<String, dynamic> json) => _$ActiveCursorFromJson(json);

 final  String sessionExerciseId;
 final  int setIndex;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of Cursor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveCursorCopyWith<ActiveCursor> get copyWith => _$ActiveCursorCopyWithImpl<ActiveCursor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActiveCursorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveCursor&&(identical(other.sessionExerciseId, sessionExerciseId) || other.sessionExerciseId == sessionExerciseId)&&(identical(other.setIndex, setIndex) || other.setIndex == setIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionExerciseId,setIndex);

@override
String toString() {
  return 'Cursor.active(sessionExerciseId: $sessionExerciseId, setIndex: $setIndex)';
}


}

/// @nodoc
abstract mixin class $ActiveCursorCopyWith<$Res> implements $CursorCopyWith<$Res> {
  factory $ActiveCursorCopyWith(ActiveCursor value, $Res Function(ActiveCursor) _then) = _$ActiveCursorCopyWithImpl;
@useResult
$Res call({
 String sessionExerciseId, int setIndex
});




}
/// @nodoc
class _$ActiveCursorCopyWithImpl<$Res>
    implements $ActiveCursorCopyWith<$Res> {
  _$ActiveCursorCopyWithImpl(this._self, this._then);

  final ActiveCursor _self;
  final $Res Function(ActiveCursor) _then;

/// Create a copy of Cursor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sessionExerciseId = null,Object? setIndex = null,}) {
  return _then(ActiveCursor(
sessionExerciseId: null == sessionExerciseId ? _self.sessionExerciseId : sessionExerciseId // ignore: cast_nullable_to_non_nullable
as String,setIndex: null == setIndex ? _self.setIndex : setIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class CompletedCursor implements Cursor {
  const CompletedCursor({final  String? $type}): $type = $type ?? 'completed';
  factory CompletedCursor.fromJson(Map<String, dynamic> json) => _$CompletedCursorFromJson(json);



@JsonKey(name: 'type')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$CompletedCursorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompletedCursor);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Cursor.completed()';
}


}




// dart format on

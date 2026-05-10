// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan_parse_error.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlanParseError {

 int get line; int get column; PlanParseErrorCode get code; String get message;
/// Create a copy of PlanParseError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanParseErrorCopyWith<PlanParseError> get copyWith => _$PlanParseErrorCopyWithImpl<PlanParseError>(this as PlanParseError, _$identity);

  /// Serializes this PlanParseError to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanParseError&&(identical(other.line, line) || other.line == line)&&(identical(other.column, column) || other.column == column)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,line,column,code,message);

@override
String toString() {
  return 'PlanParseError(line: $line, column: $column, code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class $PlanParseErrorCopyWith<$Res>  {
  factory $PlanParseErrorCopyWith(PlanParseError value, $Res Function(PlanParseError) _then) = _$PlanParseErrorCopyWithImpl;
@useResult
$Res call({
 int line, int column, PlanParseErrorCode code, String message
});




}
/// @nodoc
class _$PlanParseErrorCopyWithImpl<$Res>
    implements $PlanParseErrorCopyWith<$Res> {
  _$PlanParseErrorCopyWithImpl(this._self, this._then);

  final PlanParseError _self;
  final $Res Function(PlanParseError) _then;

/// Create a copy of PlanParseError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? line = null,Object? column = null,Object? code = null,Object? message = null,}) {
  return _then(_self.copyWith(
line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as int,column: null == column ? _self.column : column // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as PlanParseErrorCode,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanParseError].
extension PlanParseErrorPatterns on PlanParseError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanParseError value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanParseError() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanParseError value)  $default,){
final _that = this;
switch (_that) {
case _PlanParseError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanParseError value)?  $default,){
final _that = this;
switch (_that) {
case _PlanParseError() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int line,  int column,  PlanParseErrorCode code,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanParseError() when $default != null:
return $default(_that.line,_that.column,_that.code,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int line,  int column,  PlanParseErrorCode code,  String message)  $default,) {final _that = this;
switch (_that) {
case _PlanParseError():
return $default(_that.line,_that.column,_that.code,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int line,  int column,  PlanParseErrorCode code,  String message)?  $default,) {final _that = this;
switch (_that) {
case _PlanParseError() when $default != null:
return $default(_that.line,_that.column,_that.code,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanParseError implements PlanParseError {
  const _PlanParseError({required this.line, required this.column, required this.code, required this.message});
  factory _PlanParseError.fromJson(Map<String, dynamic> json) => _$PlanParseErrorFromJson(json);

@override final  int line;
@override final  int column;
@override final  PlanParseErrorCode code;
@override final  String message;

/// Create a copy of PlanParseError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanParseErrorCopyWith<_PlanParseError> get copyWith => __$PlanParseErrorCopyWithImpl<_PlanParseError>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanParseErrorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanParseError&&(identical(other.line, line) || other.line == line)&&(identical(other.column, column) || other.column == column)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,line,column,code,message);

@override
String toString() {
  return 'PlanParseError(line: $line, column: $column, code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class _$PlanParseErrorCopyWith<$Res> implements $PlanParseErrorCopyWith<$Res> {
  factory _$PlanParseErrorCopyWith(_PlanParseError value, $Res Function(_PlanParseError) _then) = __$PlanParseErrorCopyWithImpl;
@override @useResult
$Res call({
 int line, int column, PlanParseErrorCode code, String message
});




}
/// @nodoc
class __$PlanParseErrorCopyWithImpl<$Res>
    implements _$PlanParseErrorCopyWith<$Res> {
  __$PlanParseErrorCopyWithImpl(this._self, this._then);

  final _PlanParseError _self;
  final $Res Function(_PlanParseError) _then;

/// Create a copy of PlanParseError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? line = null,Object? column = null,Object? code = null,Object? message = null,}) {
  return _then(_PlanParseError(
line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as int,column: null == column ? _self.column : column // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as PlanParseErrorCode,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

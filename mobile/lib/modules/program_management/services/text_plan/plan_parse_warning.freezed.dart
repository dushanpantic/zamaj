// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan_parse_warning.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlanParseWarning {

 int get line; int get column; PlanParseWarningCode get code; String get offendingToken; String get exerciseDraftId;
/// Create a copy of PlanParseWarning
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanParseWarningCopyWith<PlanParseWarning> get copyWith => _$PlanParseWarningCopyWithImpl<PlanParseWarning>(this as PlanParseWarning, _$identity);

  /// Serializes this PlanParseWarning to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanParseWarning&&(identical(other.line, line) || other.line == line)&&(identical(other.column, column) || other.column == column)&&(identical(other.code, code) || other.code == code)&&(identical(other.offendingToken, offendingToken) || other.offendingToken == offendingToken)&&(identical(other.exerciseDraftId, exerciseDraftId) || other.exerciseDraftId == exerciseDraftId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,line,column,code,offendingToken,exerciseDraftId);

@override
String toString() {
  return 'PlanParseWarning(line: $line, column: $column, code: $code, offendingToken: $offendingToken, exerciseDraftId: $exerciseDraftId)';
}


}

/// @nodoc
abstract mixin class $PlanParseWarningCopyWith<$Res>  {
  factory $PlanParseWarningCopyWith(PlanParseWarning value, $Res Function(PlanParseWarning) _then) = _$PlanParseWarningCopyWithImpl;
@useResult
$Res call({
 int line, int column, PlanParseWarningCode code, String offendingToken, String exerciseDraftId
});




}
/// @nodoc
class _$PlanParseWarningCopyWithImpl<$Res>
    implements $PlanParseWarningCopyWith<$Res> {
  _$PlanParseWarningCopyWithImpl(this._self, this._then);

  final PlanParseWarning _self;
  final $Res Function(PlanParseWarning) _then;

/// Create a copy of PlanParseWarning
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? line = null,Object? column = null,Object? code = null,Object? offendingToken = null,Object? exerciseDraftId = null,}) {
  return _then(_self.copyWith(
line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as int,column: null == column ? _self.column : column // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as PlanParseWarningCode,offendingToken: null == offendingToken ? _self.offendingToken : offendingToken // ignore: cast_nullable_to_non_nullable
as String,exerciseDraftId: null == exerciseDraftId ? _self.exerciseDraftId : exerciseDraftId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanParseWarning].
extension PlanParseWarningPatterns on PlanParseWarning {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanParseWarning value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanParseWarning() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanParseWarning value)  $default,){
final _that = this;
switch (_that) {
case _PlanParseWarning():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanParseWarning value)?  $default,){
final _that = this;
switch (_that) {
case _PlanParseWarning() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int line,  int column,  PlanParseWarningCode code,  String offendingToken,  String exerciseDraftId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanParseWarning() when $default != null:
return $default(_that.line,_that.column,_that.code,_that.offendingToken,_that.exerciseDraftId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int line,  int column,  PlanParseWarningCode code,  String offendingToken,  String exerciseDraftId)  $default,) {final _that = this;
switch (_that) {
case _PlanParseWarning():
return $default(_that.line,_that.column,_that.code,_that.offendingToken,_that.exerciseDraftId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int line,  int column,  PlanParseWarningCode code,  String offendingToken,  String exerciseDraftId)?  $default,) {final _that = this;
switch (_that) {
case _PlanParseWarning() when $default != null:
return $default(_that.line,_that.column,_that.code,_that.offendingToken,_that.exerciseDraftId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanParseWarning implements PlanParseWarning {
  const _PlanParseWarning({required this.line, required this.column, required this.code, required this.offendingToken, required this.exerciseDraftId});
  factory _PlanParseWarning.fromJson(Map<String, dynamic> json) => _$PlanParseWarningFromJson(json);

@override final  int line;
@override final  int column;
@override final  PlanParseWarningCode code;
@override final  String offendingToken;
@override final  String exerciseDraftId;

/// Create a copy of PlanParseWarning
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanParseWarningCopyWith<_PlanParseWarning> get copyWith => __$PlanParseWarningCopyWithImpl<_PlanParseWarning>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanParseWarningToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanParseWarning&&(identical(other.line, line) || other.line == line)&&(identical(other.column, column) || other.column == column)&&(identical(other.code, code) || other.code == code)&&(identical(other.offendingToken, offendingToken) || other.offendingToken == offendingToken)&&(identical(other.exerciseDraftId, exerciseDraftId) || other.exerciseDraftId == exerciseDraftId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,line,column,code,offendingToken,exerciseDraftId);

@override
String toString() {
  return 'PlanParseWarning(line: $line, column: $column, code: $code, offendingToken: $offendingToken, exerciseDraftId: $exerciseDraftId)';
}


}

/// @nodoc
abstract mixin class _$PlanParseWarningCopyWith<$Res> implements $PlanParseWarningCopyWith<$Res> {
  factory _$PlanParseWarningCopyWith(_PlanParseWarning value, $Res Function(_PlanParseWarning) _then) = __$PlanParseWarningCopyWithImpl;
@override @useResult
$Res call({
 int line, int column, PlanParseWarningCode code, String offendingToken, String exerciseDraftId
});




}
/// @nodoc
class __$PlanParseWarningCopyWithImpl<$Res>
    implements _$PlanParseWarningCopyWith<$Res> {
  __$PlanParseWarningCopyWithImpl(this._self, this._then);

  final _PlanParseWarning _self;
  final $Res Function(_PlanParseWarning) _then;

/// Create a copy of PlanParseWarning
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? line = null,Object? column = null,Object? code = null,Object? offendingToken = null,Object? exerciseDraftId = null,}) {
  return _then(_PlanParseWarning(
line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as int,column: null == column ? _self.column : column // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as PlanParseWarningCode,offendingToken: null == offendingToken ? _self.offendingToken : offendingToken // ignore: cast_nullable_to_non_nullable
as String,exerciseDraftId: null == exerciseDraftId ? _self.exerciseDraftId : exerciseDraftId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

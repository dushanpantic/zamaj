// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'parse_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ParseResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParseResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ParseResult()';
}


}

/// @nodoc
class $ParseResultCopyWith<$Res>  {
$ParseResultCopyWith(ParseResult _, $Res Function(ParseResult) __);
}


/// Adds pattern-matching-related methods to [ParseResult].
extension ParseResultPatterns on ParseResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlanParseSuccess value)?  success,TResult Function( PlanParseFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlanParseSuccess() when success != null:
return success(_that);case PlanParseFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlanParseSuccess value)  success,required TResult Function( PlanParseFailure value)  failure,}){
final _that = this;
switch (_that) {
case PlanParseSuccess():
return success(_that);case PlanParseFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlanParseSuccess value)?  success,TResult? Function( PlanParseFailure value)?  failure,}){
final _that = this;
switch (_that) {
case PlanParseSuccess() when success != null:
return success(_that);case PlanParseFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( PlanDraft draft,  List<PlanParseWarning> warnings)?  success,TResult Function( PlanParseError error)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PlanParseSuccess() when success != null:
return success(_that.draft,_that.warnings);case PlanParseFailure() when failure != null:
return failure(_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( PlanDraft draft,  List<PlanParseWarning> warnings)  success,required TResult Function( PlanParseError error)  failure,}) {final _that = this;
switch (_that) {
case PlanParseSuccess():
return success(_that.draft,_that.warnings);case PlanParseFailure():
return failure(_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( PlanDraft draft,  List<PlanParseWarning> warnings)?  success,TResult? Function( PlanParseError error)?  failure,}) {final _that = this;
switch (_that) {
case PlanParseSuccess() when success != null:
return success(_that.draft,_that.warnings);case PlanParseFailure() when failure != null:
return failure(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class PlanParseSuccess implements ParseResult {
  const PlanParseSuccess({required this.draft, required final  List<PlanParseWarning> warnings}): _warnings = warnings;
  

 final  PlanDraft draft;
 final  List<PlanParseWarning> _warnings;
 List<PlanParseWarning> get warnings {
  if (_warnings is EqualUnmodifiableListView) return _warnings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_warnings);
}


/// Create a copy of ParseResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanParseSuccessCopyWith<PlanParseSuccess> get copyWith => _$PlanParseSuccessCopyWithImpl<PlanParseSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanParseSuccess&&(identical(other.draft, draft) || other.draft == draft)&&const DeepCollectionEquality().equals(other._warnings, _warnings));
}


@override
int get hashCode => Object.hash(runtimeType,draft,const DeepCollectionEquality().hash(_warnings));

@override
String toString() {
  return 'ParseResult.success(draft: $draft, warnings: $warnings)';
}


}

/// @nodoc
abstract mixin class $PlanParseSuccessCopyWith<$Res> implements $ParseResultCopyWith<$Res> {
  factory $PlanParseSuccessCopyWith(PlanParseSuccess value, $Res Function(PlanParseSuccess) _then) = _$PlanParseSuccessCopyWithImpl;
@useResult
$Res call({
 PlanDraft draft, List<PlanParseWarning> warnings
});


$PlanDraftCopyWith<$Res> get draft;

}
/// @nodoc
class _$PlanParseSuccessCopyWithImpl<$Res>
    implements $PlanParseSuccessCopyWith<$Res> {
  _$PlanParseSuccessCopyWithImpl(this._self, this._then);

  final PlanParseSuccess _self;
  final $Res Function(PlanParseSuccess) _then;

/// Create a copy of ParseResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? draft = null,Object? warnings = null,}) {
  return _then(PlanParseSuccess(
draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as PlanDraft,warnings: null == warnings ? _self._warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<PlanParseWarning>,
  ));
}

/// Create a copy of ParseResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanDraftCopyWith<$Res> get draft {
  
  return $PlanDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

/// @nodoc


class PlanParseFailure implements ParseResult {
  const PlanParseFailure(this.error);
  

 final  PlanParseError error;

/// Create a copy of ParseResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanParseFailureCopyWith<PlanParseFailure> get copyWith => _$PlanParseFailureCopyWithImpl<PlanParseFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanParseFailure&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,error);

@override
String toString() {
  return 'ParseResult.failure(error: $error)';
}


}

/// @nodoc
abstract mixin class $PlanParseFailureCopyWith<$Res> implements $ParseResultCopyWith<$Res> {
  factory $PlanParseFailureCopyWith(PlanParseFailure value, $Res Function(PlanParseFailure) _then) = _$PlanParseFailureCopyWithImpl;
@useResult
$Res call({
 PlanParseError error
});


$PlanParseErrorCopyWith<$Res> get error;

}
/// @nodoc
class _$PlanParseFailureCopyWithImpl<$Res>
    implements $PlanParseFailureCopyWith<$Res> {
  _$PlanParseFailureCopyWithImpl(this._self, this._then);

  final PlanParseFailure _self;
  final $Res Function(PlanParseFailure) _then;

/// Create a copy of ParseResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(PlanParseFailure(
null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as PlanParseError,
  ));
}

/// Create a copy of ParseResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanParseErrorCopyWith<$Res> get error {
  
  return $PlanParseErrorCopyWith<$Res>(_self.error, (value) {
    return _then(_self.copyWith(error: value));
  });
}
}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SessionState {

 Session get session; Cursor get cursor; ActualSetValues? get suggestedValues;
/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionStateCopyWith<SessionState> get copyWith => _$SessionStateCopyWithImpl<SessionState>(this as SessionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionState&&(identical(other.session, session) || other.session == session)&&(identical(other.cursor, cursor) || other.cursor == cursor)&&(identical(other.suggestedValues, suggestedValues) || other.suggestedValues == suggestedValues));
}


@override
int get hashCode => Object.hash(runtimeType,session,cursor,suggestedValues);

@override
String toString() {
  return 'SessionState(session: $session, cursor: $cursor, suggestedValues: $suggestedValues)';
}


}

/// @nodoc
abstract mixin class $SessionStateCopyWith<$Res>  {
  factory $SessionStateCopyWith(SessionState value, $Res Function(SessionState) _then) = _$SessionStateCopyWithImpl;
@useResult
$Res call({
 Session session, Cursor cursor, ActualSetValues? suggestedValues
});


$SessionCopyWith<$Res> get session;$CursorCopyWith<$Res> get cursor;$ActualSetValuesCopyWith<$Res>? get suggestedValues;

}
/// @nodoc
class _$SessionStateCopyWithImpl<$Res>
    implements $SessionStateCopyWith<$Res> {
  _$SessionStateCopyWithImpl(this._self, this._then);

  final SessionState _self;
  final $Res Function(SessionState) _then;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? session = null,Object? cursor = null,Object? suggestedValues = freezed,}) {
  return _then(_self.copyWith(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as Session,cursor: null == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as Cursor,suggestedValues: freezed == suggestedValues ? _self.suggestedValues : suggestedValues // ignore: cast_nullable_to_non_nullable
as ActualSetValues?,
  ));
}
/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionCopyWith<$Res> get session {
  
  return $SessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CursorCopyWith<$Res> get cursor {
  
  return $CursorCopyWith<$Res>(_self.cursor, (value) {
    return _then(_self.copyWith(cursor: value));
  });
}/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActualSetValuesCopyWith<$Res>? get suggestedValues {
    if (_self.suggestedValues == null) {
    return null;
  }

  return $ActualSetValuesCopyWith<$Res>(_self.suggestedValues!, (value) {
    return _then(_self.copyWith(suggestedValues: value));
  });
}
}


/// Adds pattern-matching-related methods to [SessionState].
extension SessionStatePatterns on SessionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionState value)  $default,){
final _that = this;
switch (_that) {
case _SessionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionState value)?  $default,){
final _that = this;
switch (_that) {
case _SessionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Session session,  Cursor cursor,  ActualSetValues? suggestedValues)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionState() when $default != null:
return $default(_that.session,_that.cursor,_that.suggestedValues);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Session session,  Cursor cursor,  ActualSetValues? suggestedValues)  $default,) {final _that = this;
switch (_that) {
case _SessionState():
return $default(_that.session,_that.cursor,_that.suggestedValues);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Session session,  Cursor cursor,  ActualSetValues? suggestedValues)?  $default,) {final _that = this;
switch (_that) {
case _SessionState() when $default != null:
return $default(_that.session,_that.cursor,_that.suggestedValues);case _:
  return null;

}
}

}

/// @nodoc


class _SessionState implements SessionState {
  const _SessionState({required this.session, required this.cursor, this.suggestedValues});
  

@override final  Session session;
@override final  Cursor cursor;
@override final  ActualSetValues? suggestedValues;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionStateCopyWith<_SessionState> get copyWith => __$SessionStateCopyWithImpl<_SessionState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionState&&(identical(other.session, session) || other.session == session)&&(identical(other.cursor, cursor) || other.cursor == cursor)&&(identical(other.suggestedValues, suggestedValues) || other.suggestedValues == suggestedValues));
}


@override
int get hashCode => Object.hash(runtimeType,session,cursor,suggestedValues);

@override
String toString() {
  return 'SessionState(session: $session, cursor: $cursor, suggestedValues: $suggestedValues)';
}


}

/// @nodoc
abstract mixin class _$SessionStateCopyWith<$Res> implements $SessionStateCopyWith<$Res> {
  factory _$SessionStateCopyWith(_SessionState value, $Res Function(_SessionState) _then) = __$SessionStateCopyWithImpl;
@override @useResult
$Res call({
 Session session, Cursor cursor, ActualSetValues? suggestedValues
});


@override $SessionCopyWith<$Res> get session;@override $CursorCopyWith<$Res> get cursor;@override $ActualSetValuesCopyWith<$Res>? get suggestedValues;

}
/// @nodoc
class __$SessionStateCopyWithImpl<$Res>
    implements _$SessionStateCopyWith<$Res> {
  __$SessionStateCopyWithImpl(this._self, this._then);

  final _SessionState _self;
  final $Res Function(_SessionState) _then;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? session = null,Object? cursor = null,Object? suggestedValues = freezed,}) {
  return _then(_SessionState(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as Session,cursor: null == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as Cursor,suggestedValues: freezed == suggestedValues ? _self.suggestedValues : suggestedValues // ignore: cast_nullable_to_non_nullable
as ActualSetValues?,
  ));
}

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionCopyWith<$Res> get session {
  
  return $SessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CursorCopyWith<$Res> get cursor {
  
  return $CursorCopyWith<$Res>(_self.cursor, (value) {
    return _then(_self.copyWith(cursor: value));
  });
}/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActualSetValuesCopyWith<$Res>? get suggestedValues {
    if (_self.suggestedValues == null) {
    return null;
  }

  return $ActualSetValuesCopyWith<$Res>(_self.suggestedValues!, (value) {
    return _then(_self.copyWith(suggestedValues: value));
  });
}
}

// dart format on

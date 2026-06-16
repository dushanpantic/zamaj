// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cap_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CapHistoryEntry {

 DateTime get date; String get programId; String get sourceWorkoutDayName; List<PlannedSetValues> get plannedSets; List<ActualSetValues> get actualSets; bool get isCapped;
/// Create a copy of CapHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CapHistoryEntryCopyWith<CapHistoryEntry> get copyWith => _$CapHistoryEntryCopyWithImpl<CapHistoryEntry>(this as CapHistoryEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CapHistoryEntry&&(identical(other.date, date) || other.date == date)&&(identical(other.programId, programId) || other.programId == programId)&&(identical(other.sourceWorkoutDayName, sourceWorkoutDayName) || other.sourceWorkoutDayName == sourceWorkoutDayName)&&const DeepCollectionEquality().equals(other.plannedSets, plannedSets)&&const DeepCollectionEquality().equals(other.actualSets, actualSets)&&(identical(other.isCapped, isCapped) || other.isCapped == isCapped));
}


@override
int get hashCode => Object.hash(runtimeType,date,programId,sourceWorkoutDayName,const DeepCollectionEquality().hash(plannedSets),const DeepCollectionEquality().hash(actualSets),isCapped);

@override
String toString() {
  return 'CapHistoryEntry(date: $date, programId: $programId, sourceWorkoutDayName: $sourceWorkoutDayName, plannedSets: $plannedSets, actualSets: $actualSets, isCapped: $isCapped)';
}


}

/// @nodoc
abstract mixin class $CapHistoryEntryCopyWith<$Res>  {
  factory $CapHistoryEntryCopyWith(CapHistoryEntry value, $Res Function(CapHistoryEntry) _then) = _$CapHistoryEntryCopyWithImpl;
@useResult
$Res call({
 DateTime date, String programId, String sourceWorkoutDayName, List<PlannedSetValues> plannedSets, List<ActualSetValues> actualSets, bool isCapped
});




}
/// @nodoc
class _$CapHistoryEntryCopyWithImpl<$Res>
    implements $CapHistoryEntryCopyWith<$Res> {
  _$CapHistoryEntryCopyWithImpl(this._self, this._then);

  final CapHistoryEntry _self;
  final $Res Function(CapHistoryEntry) _then;

/// Create a copy of CapHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? programId = null,Object? sourceWorkoutDayName = null,Object? plannedSets = null,Object? actualSets = null,Object? isCapped = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,sourceWorkoutDayName: null == sourceWorkoutDayName ? _self.sourceWorkoutDayName : sourceWorkoutDayName // ignore: cast_nullable_to_non_nullable
as String,plannedSets: null == plannedSets ? _self.plannedSets : plannedSets // ignore: cast_nullable_to_non_nullable
as List<PlannedSetValues>,actualSets: null == actualSets ? _self.actualSets : actualSets // ignore: cast_nullable_to_non_nullable
as List<ActualSetValues>,isCapped: null == isCapped ? _self.isCapped : isCapped // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CapHistoryEntry].
extension CapHistoryEntryPatterns on CapHistoryEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CapHistoryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CapHistoryEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CapHistoryEntry value)  $default,){
final _that = this;
switch (_that) {
case _CapHistoryEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CapHistoryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _CapHistoryEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  String programId,  String sourceWorkoutDayName,  List<PlannedSetValues> plannedSets,  List<ActualSetValues> actualSets,  bool isCapped)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CapHistoryEntry() when $default != null:
return $default(_that.date,_that.programId,_that.sourceWorkoutDayName,_that.plannedSets,_that.actualSets,_that.isCapped);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  String programId,  String sourceWorkoutDayName,  List<PlannedSetValues> plannedSets,  List<ActualSetValues> actualSets,  bool isCapped)  $default,) {final _that = this;
switch (_that) {
case _CapHistoryEntry():
return $default(_that.date,_that.programId,_that.sourceWorkoutDayName,_that.plannedSets,_that.actualSets,_that.isCapped);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  String programId,  String sourceWorkoutDayName,  List<PlannedSetValues> plannedSets,  List<ActualSetValues> actualSets,  bool isCapped)?  $default,) {final _that = this;
switch (_that) {
case _CapHistoryEntry() when $default != null:
return $default(_that.date,_that.programId,_that.sourceWorkoutDayName,_that.plannedSets,_that.actualSets,_that.isCapped);case _:
  return null;

}
}

}

/// @nodoc


class _CapHistoryEntry implements CapHistoryEntry {
  const _CapHistoryEntry({required this.date, required this.programId, required this.sourceWorkoutDayName, required final  List<PlannedSetValues> plannedSets, required final  List<ActualSetValues> actualSets, required this.isCapped}): _plannedSets = plannedSets,_actualSets = actualSets;
  

@override final  DateTime date;
@override final  String programId;
@override final  String sourceWorkoutDayName;
 final  List<PlannedSetValues> _plannedSets;
@override List<PlannedSetValues> get plannedSets {
  if (_plannedSets is EqualUnmodifiableListView) return _plannedSets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_plannedSets);
}

 final  List<ActualSetValues> _actualSets;
@override List<ActualSetValues> get actualSets {
  if (_actualSets is EqualUnmodifiableListView) return _actualSets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_actualSets);
}

@override final  bool isCapped;

/// Create a copy of CapHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CapHistoryEntryCopyWith<_CapHistoryEntry> get copyWith => __$CapHistoryEntryCopyWithImpl<_CapHistoryEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CapHistoryEntry&&(identical(other.date, date) || other.date == date)&&(identical(other.programId, programId) || other.programId == programId)&&(identical(other.sourceWorkoutDayName, sourceWorkoutDayName) || other.sourceWorkoutDayName == sourceWorkoutDayName)&&const DeepCollectionEquality().equals(other._plannedSets, _plannedSets)&&const DeepCollectionEquality().equals(other._actualSets, _actualSets)&&(identical(other.isCapped, isCapped) || other.isCapped == isCapped));
}


@override
int get hashCode => Object.hash(runtimeType,date,programId,sourceWorkoutDayName,const DeepCollectionEquality().hash(_plannedSets),const DeepCollectionEquality().hash(_actualSets),isCapped);

@override
String toString() {
  return 'CapHistoryEntry(date: $date, programId: $programId, sourceWorkoutDayName: $sourceWorkoutDayName, plannedSets: $plannedSets, actualSets: $actualSets, isCapped: $isCapped)';
}


}

/// @nodoc
abstract mixin class _$CapHistoryEntryCopyWith<$Res> implements $CapHistoryEntryCopyWith<$Res> {
  factory _$CapHistoryEntryCopyWith(_CapHistoryEntry value, $Res Function(_CapHistoryEntry) _then) = __$CapHistoryEntryCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, String programId, String sourceWorkoutDayName, List<PlannedSetValues> plannedSets, List<ActualSetValues> actualSets, bool isCapped
});




}
/// @nodoc
class __$CapHistoryEntryCopyWithImpl<$Res>
    implements _$CapHistoryEntryCopyWith<$Res> {
  __$CapHistoryEntryCopyWithImpl(this._self, this._then);

  final _CapHistoryEntry _self;
  final $Res Function(_CapHistoryEntry) _then;

/// Create a copy of CapHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? programId = null,Object? sourceWorkoutDayName = null,Object? plannedSets = null,Object? actualSets = null,Object? isCapped = null,}) {
  return _then(_CapHistoryEntry(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,sourceWorkoutDayName: null == sourceWorkoutDayName ? _self.sourceWorkoutDayName : sourceWorkoutDayName // ignore: cast_nullable_to_non_nullable
as String,plannedSets: null == plannedSets ? _self._plannedSets : plannedSets // ignore: cast_nullable_to_non_nullable
as List<PlannedSetValues>,actualSets: null == actualSets ? _self._actualSets : actualSets // ignore: cast_nullable_to_non_nullable
as List<ActualSetValues>,isCapped: null == isCapped ? _self.isCapped : isCapped // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$CapHistory {

 List<CapHistoryEntry> get entries;
/// Create a copy of CapHistory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CapHistoryCopyWith<CapHistory> get copyWith => _$CapHistoryCopyWithImpl<CapHistory>(this as CapHistory, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CapHistory&&const DeepCollectionEquality().equals(other.entries, entries));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(entries));

@override
String toString() {
  return 'CapHistory(entries: $entries)';
}


}

/// @nodoc
abstract mixin class $CapHistoryCopyWith<$Res>  {
  factory $CapHistoryCopyWith(CapHistory value, $Res Function(CapHistory) _then) = _$CapHistoryCopyWithImpl;
@useResult
$Res call({
 List<CapHistoryEntry> entries
});




}
/// @nodoc
class _$CapHistoryCopyWithImpl<$Res>
    implements $CapHistoryCopyWith<$Res> {
  _$CapHistoryCopyWithImpl(this._self, this._then);

  final CapHistory _self;
  final $Res Function(CapHistory) _then;

/// Create a copy of CapHistory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entries = null,}) {
  return _then(_self.copyWith(
entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<CapHistoryEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [CapHistory].
extension CapHistoryPatterns on CapHistory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CapHistory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CapHistory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CapHistory value)  $default,){
final _that = this;
switch (_that) {
case _CapHistory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CapHistory value)?  $default,){
final _that = this;
switch (_that) {
case _CapHistory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CapHistoryEntry> entries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CapHistory() when $default != null:
return $default(_that.entries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CapHistoryEntry> entries)  $default,) {final _that = this;
switch (_that) {
case _CapHistory():
return $default(_that.entries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CapHistoryEntry> entries)?  $default,) {final _that = this;
switch (_that) {
case _CapHistory() when $default != null:
return $default(_that.entries);case _:
  return null;

}
}

}

/// @nodoc


class _CapHistory extends CapHistory {
  const _CapHistory({required final  List<CapHistoryEntry> entries}): _entries = entries,super._();
  

 final  List<CapHistoryEntry> _entries;
@override List<CapHistoryEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}


/// Create a copy of CapHistory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CapHistoryCopyWith<_CapHistory> get copyWith => __$CapHistoryCopyWithImpl<_CapHistory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CapHistory&&const DeepCollectionEquality().equals(other._entries, _entries));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_entries));

@override
String toString() {
  return 'CapHistory(entries: $entries)';
}


}

/// @nodoc
abstract mixin class _$CapHistoryCopyWith<$Res> implements $CapHistoryCopyWith<$Res> {
  factory _$CapHistoryCopyWith(_CapHistory value, $Res Function(_CapHistory) _then) = __$CapHistoryCopyWithImpl;
@override @useResult
$Res call({
 List<CapHistoryEntry> entries
});




}
/// @nodoc
class __$CapHistoryCopyWithImpl<$Res>
    implements _$CapHistoryCopyWith<$Res> {
  __$CapHistoryCopyWithImpl(this._self, this._then);

  final _CapHistory _self;
  final $Res Function(_CapHistory) _then;

/// Create a copy of CapHistory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entries = null,}) {
  return _then(_CapHistory(
entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<CapHistoryEntry>,
  ));
}


}

// dart format on

import 'package:zamaj/core/deserialization.dart';

/// How prominent a library exercise is, used as the primary sort key.
///
/// [common] sorts before [specialized] — the ordering is the intent of the
/// name, not an alphabetical coincidence (see [Prominence] usage in the
/// exercise-library ordering).
enum Prominence {
  common,
  specialized;

  String toJson() => name;

  static Prominence fromJson(String json) =>
      decodeEnum(Prominence.values, json, 'Prominence');
}

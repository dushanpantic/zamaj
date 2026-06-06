import 'package:zamaj/core/deserialization.dart';

/// A muscle group an exercise targets.
///
/// Captured on every library exercise as primary/secondary lists; the
/// muscle-filter UI that consumes them is a deferred follow-up. The value
/// list is finalized against the authored canonical catalog (the seeding
/// step) — add new groups here when the catalog needs them.
enum MuscleGroup {
  chest,
  upperBack,
  lats,
  lowerBack,
  traps,
  shoulders,
  biceps,
  triceps,
  forearms,
  abs,
  obliques,
  quadriceps,
  hamstrings,
  glutes,
  calves,
  adductors,
  abductors,
  hipFlexors,
  neck;

  String toJson() => name;

  static MuscleGroup fromJson(String json) =>
      decodeEnum(MuscleGroup.values, json, 'MuscleGroup');
}

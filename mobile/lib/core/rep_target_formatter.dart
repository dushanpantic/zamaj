import 'package:zamaj/modules/domain/models/rep_target.dart';

/// Single source of truth for "rep target → display string".
///
/// Uses ASCII `-` as the range separator so output stays stable across
/// export targets (WhatsApp, SMS, plain-text email).
abstract final class RepTargetFormatter {
  static String format(RepTarget target) => switch (target) {
    RepTargetFixed(:final reps) => reps.toString(),
    RepTargetRange(:final minReps, :final maxReps) => '$minReps-$maxReps',
  };
}

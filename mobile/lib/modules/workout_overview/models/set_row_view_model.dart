import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/modules/domain/domain.dart';

part 'set_row_view_model.freezed.dart';

@freezed
abstract class SetRowViewModel with _$SetRowViewModel {
  const factory SetRowViewModel({
    required int position,
    required PlannedSetValues? plannedValues,
    required ExecutedSet? executedSet,
    required bool isNextLogTarget,
  }) = _SetRowViewModel;
}

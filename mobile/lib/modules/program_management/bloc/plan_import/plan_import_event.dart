import 'package:equatable/equatable.dart';

sealed class PlanImportEvent extends Equatable {
  const PlanImportEvent();
}

final class PlanImportTextChanged extends PlanImportEvent {
  const PlanImportTextChanged({required this.text});

  final String text;

  @override
  List<Object?> get props => [text];
}

final class PlanImportParseRequested extends PlanImportEvent {
  const PlanImportParseRequested();

  @override
  List<Object?> get props => [];
}

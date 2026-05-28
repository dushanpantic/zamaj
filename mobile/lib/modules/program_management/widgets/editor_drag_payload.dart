enum GroupMenuAction { toggleWarmup, group, ungroup, delete }

class ExerciseDragPayload {
  const ExerciseDragPayload({
    required this.groupDraftId,
    required this.exerciseDraftId,
  });

  final String groupDraftId;
  final String exerciseDraftId;
}

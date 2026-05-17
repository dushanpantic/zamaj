/// Route arguments for the focus-mode screen.
///
/// Carries the session id plus the session-exercise id the screen should
/// anchor on. The anchor selects which group (single exercise or superset)
/// is initially focused; the user can switch to other groups in-screen.
class FocusModeArgs {
  const FocusModeArgs({
    required this.sessionId,
    required this.anchorSessionExerciseId,
  });

  final String sessionId;
  final String anchorSessionExerciseId;
}

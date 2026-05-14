/// Route arguments for the focus-mode screen.
///
/// The screen always operates on an existing session id; the bloc resumes
/// from persisted state via [SessionFlowEngine.resumeSession].
class FocusModeArgs {
  const FocusModeArgs({required this.sessionId});

  final String sessionId;
}

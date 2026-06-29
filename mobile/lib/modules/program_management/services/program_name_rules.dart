import 'package:zamaj/modules/domain/services/program_rules.dart';

/// The single create-time validity rule for a program name, shared by the
/// name-first creation dialog and the list bloc's create handler.
///
/// The numeric bound is single-sourced from domain [ProgramRules]; only the
/// trivial "non-empty after trim, within bound" predicate lives here.
abstract final class ProgramNameRules {
  /// True when [name] can create a program: non-empty once trimmed and no
  /// longer than [ProgramRules.programNameMaxLength].
  static bool canCreate(String name) {
    final trimmed = name.trim();
    return trimmed.isNotEmpty &&
        trimmed.length <= ProgramRules.programNameMaxLength;
  }
}

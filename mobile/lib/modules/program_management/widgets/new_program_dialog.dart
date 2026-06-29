import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/services/program_rules.dart';
import 'package:zamaj/modules/program_management/services/program_name_rules.dart';

/// Whether dismissing the new-program dialog should ask for confirmation first.
///
/// True once the user has typed a non-empty (trimmed) name — there is work to
/// lose. An empty field dismisses silently.
bool shouldConfirmDiscard(String typedName) => typedName.trim().isNotEmpty;

/// Name-first program creation dialog. The program is named (required) before
/// it exists; [show] resolves to the entered name when the user creates, or
/// `null` when they cancel/dismiss. The caller performs the single create write.
class NewProgramDialog extends StatefulWidget {
  const NewProgramDialog({super.key});

  /// Opens the dialog and resolves to the trimmed program name on create, or
  /// `null` on cancel/dismiss.
  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      // Dismissal is funnelled through Cancel / system back so a typed name
      // can be guarded by a discard confirmation; the scrim is inert.
      barrierDismissible: false,
      builder: (_) => const NewProgramDialog(),
    );
  }

  @override
  State<NewProgramDialog> createState() => _NewProgramDialogState();
}

class _NewProgramDialogState extends State<NewProgramDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _canCreate => ProgramNameRules.canCreate(_controller.text);

  void _create() {
    if (!_canCreate) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  /// Cancel / system back. Confirms before discarding a typed name; an empty
  /// field closes immediately.
  Future<void> _attemptDismiss() async {
    if (!shouldConfirmDiscard(_controller.text)) {
      Navigator.of(context).pop();
      return;
    }
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Discard new program?',
      body: "You haven't created this program yet.",
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      isDestructive: true,
    );
    if (confirmed == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _attemptDismiss();
      },
      child: AlertDialog(
        backgroundColor: colors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'New program',
          style: typography.titleSmall.copyWith(color: colors.onSurface),
        ),
        content: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          maxLength: ProgramRules.programNameMaxLength,
          style: typography.body.copyWith(color: colors.onSurface),
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. Push Pull Legs',
          ),
          onSubmitted: (_) => _create(),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        actions: [
          TextButton(
            onPressed: _attemptDismiss,
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSpacing.touchMin),
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _canCreate ? _create : null,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              minimumSize: const Size.fromHeight(AppSpacing.touchMin),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

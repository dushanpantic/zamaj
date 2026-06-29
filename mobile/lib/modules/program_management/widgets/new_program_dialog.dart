import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/services/program_rules.dart';
import 'package:zamaj/modules/program_management/services/program_name_rules.dart';

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

  void _cancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return AlertDialog(
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
        TextButton(onPressed: _cancel, child: const Text('Cancel')),
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
    );
  }
}

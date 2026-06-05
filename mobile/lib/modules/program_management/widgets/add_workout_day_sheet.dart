import 'package:flutter/material.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';

class AddWorkoutDaySheet extends StatefulWidget {
  const AddWorkoutDaySheet({
    super.key,
    required this.existingDays,
    required this.onCreateEmpty,
    required this.onDuplicateExisting,
    required this.onOpenPasteImport,
  });

  final List<WorkoutDayDraft> existingDays;
  final ValueChanged<String> onCreateEmpty;
  final ValueChanged<String> onDuplicateExisting;
  final VoidCallback onOpenPasteImport;

  @override
  State<AddWorkoutDaySheet> createState() => _AddWorkoutDaySheetState();
}

enum _AddWorkoutDayMode { menu, empty, duplicate }

class _AddWorkoutDaySheetState extends State<AddWorkoutDaySheet> {
  _AddWorkoutDayMode _mode = _AddWorkoutDayMode.menu;
  final TextEditingController _nameController = TextEditingController();
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submitEmpty() {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _nameError = 'Name cannot be empty');
      return;
    }
    Navigator.of(context).pop();
    widget.onCreateEmpty(trimmed);
  }

  void _submitDuplicate(String draftId) {
    Navigator.of(context).pop();
    widget.onDuplicateExisting(draftId);
  }

  void _submitPasteImport() {
    Navigator.of(context).pop();
    widget.onOpenPasteImport();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (_mode != _AddWorkoutDayMode.menu)
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: colors.onSurfaceMuted,
                      ),
                      onPressed: () => setState(() {
                        _mode = _AddWorkoutDayMode.menu;
                        _nameError = null;
                      }),
                      tooltip: 'Back',
                    ),
                  Expanded(
                    child: Text(
                      switch (_mode) {
                        _AddWorkoutDayMode.menu => 'Add workout day',
                        _AddWorkoutDayMode.empty => 'New empty day',
                        _AddWorkoutDayMode.duplicate => 'Duplicate a day',
                      },
                      style: typography.titleSmall.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              switch (_mode) {
                _AddWorkoutDayMode.menu => _buildMenu(colors, typography),
                _AddWorkoutDayMode.empty => _buildEmptyForm(colors, typography),
                _AddWorkoutDayMode.duplicate => _buildDuplicatePicker(
                  colors,
                  typography,
                ),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(AppColors colors, AppTypography typography) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetOption(
          icon: Icons.add,
          title: 'Empty day',
          subtitle: 'Start from a blank workout day.',
          onTap: () => setState(() => _mode = _AddWorkoutDayMode.empty),
        ),
        _SheetOption(
          icon: Icons.copy,
          title: 'Duplicate of…',
          subtitle: widget.existingDays.isEmpty
              ? 'No existing days to copy yet.'
              : 'Copy an existing day as a starting point.',
          enabled: widget.existingDays.isNotEmpty,
          onTap: () => setState(() => _mode = _AddWorkoutDayMode.duplicate),
        ),
        _SheetOption(
          icon: Icons.content_paste,
          title: 'Paste plain text',
          subtitle: 'Import a typed-out plan from your clipboard.',
          onTap: _submitPasteImport,
        ),
      ],
    );
  }

  Widget _buildEmptyForm(AppColors colors, AppTypography typography) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          style: typography.body.copyWith(color: colors.onSurface),
          decoration: InputDecoration(
            labelText: 'Day name',
            hintText: 'e.g. Push A',
            errorText: _nameError,
          ),
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
          onSubmitted: (_) => _submitEmpty(),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: _submitEmpty,
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            minimumSize: const Size.fromHeight(AppSpacing.touchMin),
          ),
          child: const Text('Add day'),
        ),
      ],
    );
  }

  Widget _buildDuplicatePicker(AppColors colors, AppTypography typography) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: widget.existingDays.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, index) {
          final day = widget.existingDays[index];
          return _SheetOption(
            icon: Icons.copy,
            title: day.name,
            subtitle: 'Copies the day and renames it "<name> (copy)".',
            onTap: () => _submitDuplicate(day.draftId),
          );
        },
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final fg = enabled ? colors.onSurface : colors.onSurfaceMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.outline),
            ),
            child: Row(
              children: [
                Icon(icon, color: fg),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: typography.titleSmall.copyWith(color: fg),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: typography.caption.copyWith(
                          color: colors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (enabled)
                  Icon(Icons.chevron_right, color: colors.onSurfaceMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

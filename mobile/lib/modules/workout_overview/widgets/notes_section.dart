import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';

class SessionNotesSection extends StatelessWidget {
  const SessionNotesSection({
    super.key,
    required this.notes,
    required this.canAdd,
    required this.onAddPressed,
  });

  final List<SessionNote> notes;
  final bool canAdd;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Notes',
      icon: Icons.sticky_note_2_outlined,
      canAdd: canAdd,
      onAddPressed: onAddPressed,
      addLabel: 'Add note',
      emptyHint: 'No notes yet.',
      items: notes.map((n) => n.body).toList(),
    );
  }
}

class ExtraWorkSection extends StatelessWidget {
  const ExtraWorkSection({
    super.key,
    required this.extraWork,
    required this.canAdd,
    required this.onAddPressed,
  });

  final List<ExtraWork> extraWork;
  final bool canAdd;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final sorted = List<ExtraWork>.of(extraWork)
      ..sort((a, b) => a.position.compareTo(b.position));
    return _Section(
      title: 'Extra work',
      icon: Icons.add_task,
      canAdd: canAdd,
      onAddPressed: onAddPressed,
      addLabel: 'Add extra',
      emptyHint: 'No extra work logged.',
      items: sorted.map((e) => e.body).toList(),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.canAdd,
    required this.onAddPressed,
    required this.addLabel,
    required this.emptyHint,
    required this.items,
  });

  final String title;
  final IconData icon;
  final bool canAdd;
  final VoidCallback onAddPressed;
  final String addLabel;
  final String emptyHint;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outline),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title,
            icon: icon,
            trailing: canAdd
                ? TextButton.icon(
                    onPressed: onAddPressed,
                    icon: const AppIcon(Icons.add, size: AppIconSize.sm),
                    label: Text(addLabel),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, AppSpacing.compactAction),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                    ),
                  )
                : null,
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(
                emptyHint,
                style: typography.bodySmall.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
            )
          else
            ...items.map(
              (body) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 6,
                        right: AppSpacing.sm,
                      ),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.onSurfaceMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        body,
                        style: typography.bodySmall.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

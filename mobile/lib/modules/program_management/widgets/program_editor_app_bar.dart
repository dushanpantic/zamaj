import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/program_management/bloc/program_editor/program_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/program_editor/program_editor_event.dart';

class ProgramEditorAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const ProgramEditorAppBar({
    super.key,
    required this.nameController,
    required this.nameFocus,
    required this.isSaving,
    required this.onAddWorkoutDay,
  });

  final TextEditingController nameController;
  final FocusNode nameFocus;
  final bool isSaving;
  final VoidCallback onAddWorkoutDay;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final showEditAffordance = !nameFocus.hasFocus;

    return AppBar(
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: TextField(
          controller: nameController,
          focusNode: nameFocus,
          style: typography.title.copyWith(color: colors.onSurface),
          decoration: InputDecoration(
            hintText: 'Program name',
            hintStyle: typography.title.copyWith(color: colors.onSurfaceMuted),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
            ),
            suffixIcon: showEditAffordance
                ? AppIcon(
                    Icons.edit,
                    size: AppIconSize.sm,
                    color: colors.onSurfaceMuted,
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
          ),
          onChanged: (value) {
            context.read<ProgramEditorBloc>().add(
              ProgramEditorNameChanged(name: value),
            );
          },
        ),
      ),
      actions: [
        if (isSaving)
          const Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: Center(child: AppInlineSpinner()),
          ),
        IconButton(
          icon: Icon(Icons.add, color: colors.primary),
          tooltip: 'Add workout day',
          onPressed: isSaving ? null : onAddWorkoutDay,
        ),
      ],
    );
  }
}

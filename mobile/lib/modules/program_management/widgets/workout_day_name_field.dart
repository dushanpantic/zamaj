import 'package:flutter/material.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

class WorkoutDayNameField extends StatefulWidget {
  const WorkoutDayNameField({
    super.key,
    required this.controller,
    required this.isValid,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isValid;
  final void Function(String) onChanged;

  @override
  State<WorkoutDayNameField> createState() => _WorkoutDayNameFieldState();
}

class _WorkoutDayNameFieldState extends State<WorkoutDayNameField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final showEditAffordance = !_focusNode.hasFocus;
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      style: AppTypography.standard.body.copyWith(color: colors.onSurface),
      decoration: InputDecoration(
        hintText: 'Day name',
        hintStyle: AppTypography.standard.body.copyWith(
          color: colors.onSurfaceMuted,
        ),
        border: InputBorder.none,
        suffixIcon: showEditAffordance
            ? Icon(Icons.edit, size: 14, color: colors.onSurfaceMuted)
            : null,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 24,
          minHeight: 24,
        ),
        errorText: widget.isValid || widget.controller.text.isEmpty
            ? null
            : 'Name must be 1–100 characters',
        errorStyle: AppTypography.standard.caption.copyWith(
          color: colors.error,
        ),
      ),
      maxLength: 100,
      buildCounter:
          (_, {required currentLength, required isFocused, maxLength}) => null,
    );
  }
}

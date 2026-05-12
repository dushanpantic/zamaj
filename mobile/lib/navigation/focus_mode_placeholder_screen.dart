// Placeholder destination for [SessionRoutes.focus]. Replaced wholesale by
// the future focus-mode-screen spec; the router binding swaps without
// touching the workout-overview module.
import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

class FocusModePlaceholderScreen extends StatelessWidget {
  const FocusModePlaceholderScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Focus mode')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Session id',
              style: typography.caption.copyWith(color: colors.onSurfaceMuted),
            ),
            const SizedBox(height: AppSpacing.xs),
            SelectableText(
              sessionId,
              style: typography.numeric.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

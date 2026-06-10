import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/app_skeleton.dart';
import 'package:zamaj/core/app_spacing.dart';

/// A generic, non-interactive placeholder for a loading editor form: a few
/// label-over-field [AppSkeletonBar] pairs so an editor shows steady chrome
/// instead of flashing a centered spinner before its draft arrives.
///
/// Deliberately generic — it stands in for "a form", not any specific field
/// set, so it stays correct as editors change shape. Drop it inside the
/// editor's own scaffold so the app bar stays put while the body loads.
class AppFormSkeleton extends StatelessWidget {
  const AppFormSkeleton({super.key, this.fieldCount = 3, this.padding});

  /// Number of label-over-field pairs to render.
  final int fieldCount;

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final resolvedPadding = padding ?? const EdgeInsets.all(AppSpacing.lg);
    return Semantics(
      label: 'Loading',
      container: true,
      child: ExcludeSemantics(
        child: Padding(
          padding: resolvedPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < fieldCount; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.xl),
                const AppSkeletonBar(widthFactor: 0.3, height: AppSpacing.sm),
                const SizedBox(height: AppSpacing.sm),
                const AppSkeletonBar(widthFactor: 1, height: AppSpacing.xxl),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

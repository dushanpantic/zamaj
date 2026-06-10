import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';

/// The one centered, theme-coloured spinner for a screen or sheet whose content
/// is not yet available and whose final layout can't be skeletoned — the
/// live-session surfaces (workout overview, focus mode) and the plan preview.
///
/// List screens use [AppListSkeleton] and editor screens use [AppFormSkeleton]
/// instead; a bare [CircularProgressIndicator] should not appear elsewhere.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.semanticsLabel = 'Loading'});

  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: AppStroke.indicator,
        color: Theme.of(context).appColors.primary,
        semanticsLabel: semanticsLabel,
      ),
    );
  }
}

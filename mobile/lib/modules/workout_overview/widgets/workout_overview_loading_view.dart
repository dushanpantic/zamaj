import 'package:flutter/material.dart';
import 'package:zamaj/core/app_theme.dart';

class WorkoutOverviewLoadingView extends StatelessWidget {
  const WorkoutOverviewLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Center(child: CircularProgressIndicator(color: colors.primary));
  }
}

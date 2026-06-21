import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/status_badge.dart';
import 'package:zamaj/core/app_theme.dart';

/// The one DELOAD marker, reused across every surface a deload session appears
/// on (the overview header, the review header, and the recent-sessions tile).
///
/// A thin wrapper over [StatusBadge.pill] so the marker stays visually
/// consistent with the other exception pills (CAPPED / Skipped),
/// tinted with the semantic [AppColors.deload] accent.
class DeloadBadge extends StatelessWidget {
  const DeloadBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return StatusBadge.pill(
      label: 'DELOAD',
      color: Theme.of(context).appColors.deload,
    );
  }
}

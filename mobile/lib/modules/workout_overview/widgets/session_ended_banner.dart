import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/modules/domain/domain.dart';

/// Post-end summary shown at the top of the overview once a session is ended:
/// the session's headline stats (time, sets, volume) plus a reminder that
/// completed sets stay editable.
///
/// Rendered only while the session is ended (gated by the call site), so the
/// duration is final and the stats never tick.
class SessionEndedBanner extends StatelessWidget {
  const SessionEndedBanner({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: SessionSummaryCard(
        summary: SessionSummary.fromSession(session),
        footer: 'Completed sets remain editable.',
      ),
    );
  }
}

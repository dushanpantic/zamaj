import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';

/// Transitional shim that forwards to [AppConfirmDialog], the single confirm
/// path (see `lib/building_blocks/app_confirm_dialog.dart`).
///
/// Kept only so the live-session callers (`workout_overview/`, `focus_mode/`)
/// keep compiling without editing those files in this slice — they migrate to
/// [AppConfirmDialog] in Prompt 5, when this shim is removed. (Intentionally
/// not `@Deprecated`: that would emit same-package usage infos at those two
/// call sites, which `flutter analyze` treats as fatal.)
abstract final class ConfirmationDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String body,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return AppConfirmDialog.show(
      context: context,
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
    );
  }
}

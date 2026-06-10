import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/core/app_typography.dart';

/// Guards the typography contract: one bundled family (Barlow) across every
/// style, and tabular figures on every numeric readout style.
///
/// Scope note: this guards the *declared* family and font features only. It
/// cannot guard rendered glyph behaviour — a font file lacking real `tnum`
/// variants would still pass — nor the height/letterSpacing metrics tuning.
/// The on-device jitter check (rest timer ticking, stepper crossing 99 → 100)
/// is the true acceptance gate for those.
void main() {
  const t = AppTypography.standard;

  final allStyles = <String, TextStyle>{
    'display': t.display,
    'displaySmall': t.displaySmall,
    'title': t.title,
    'titleSmall': t.titleSmall,
    'body': t.body,
    'bodySmall': t.bodySmall,
    'label': t.label,
    'labelSmall': t.labelSmall,
    'caption': t.caption,
    'numeric': t.numeric,
    'numericXs': t.numericXs,
    'numericSm': t.numericSm,
    'numericMd': t.numericMd,
    'numericLarge': t.numericLarge,
    'numericHero': t.numericHero,
    'actionLabel': t.actionLabel,
    'badge': t.badge,
    'overline': t.overline,
  };

  final numericStyles = <String, TextStyle>{
    'numeric': t.numeric,
    'numericXs': t.numericXs,
    'numericSm': t.numericSm,
    'numericMd': t.numericMd,
    'numericLarge': t.numericLarge,
    'numericHero': t.numericHero,
  };

  group('AppTypography.standard', () {
    test('every style uses the bundled Barlow family', () {
      for (final entry in allStyles.entries) {
        expect(
          entry.value.fontFamily,
          'Barlow',
          reason: '${entry.key} should use the bundled Barlow family',
        );
      }
    });

    test('every numeric* style enables tabular figures', () {
      for (final entry in numericStyles.entries) {
        expect(
          entry.value.fontFeatures,
          contains(const FontFeature.tabularFigures()),
          reason: '${entry.key} should enable tabular figures',
        );
      }
    });
  });
}

/// Spacing scale used across the Zamaj UI.
///
/// Every padding/gap/margin reads from [AppSpacing] instead of hard-coded
/// pixel values. [touchMin] is the minimum one-handed-friendly tap target
/// edge; keep interactive widgets at or above this size.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  static const double touchMin = 48;
}

/// Corner radius scale paired with [AppSpacing].
abstract final class AppRadius {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 16;
  static const double pill = 999;
}

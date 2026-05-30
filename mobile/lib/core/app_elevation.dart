/// Elevation (z-axis shadow) tokens for the Zamaj UI.
///
/// The dark-first house style draws depth from a lighter tonal surface + an
/// outline, **not** a drop-shadow (see `app_theme.dart`). So there is exactly
/// one sanctioned shadow in the app: the lifted proxy under an actively-dragged
/// item, where a shadow genuinely earns its keep — it's the Material drag
/// convention, and it's the one place the user needs unmistakable "this is
/// floating above everything" feedback. Every other surface (cards, modals,
/// sheets, banners) stays at elevation 0.
abstract final class AppElevation {
  /// Material elevation for the lifted proxy of an actively-dragged item
  /// (reorder / drag feedback). The single sanctioned drop-shadow in the app;
  /// both the editor row drag feedback and the live drag handle read from it.
  static const double drag = 8;
}

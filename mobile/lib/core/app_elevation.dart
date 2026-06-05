/// Elevation (z-axis shadow) tokens for the Zamaj UI.
///
/// The dark-first house style draws depth from a lighter tonal surface plus an
/// outline, not a drop-shadow. The one sanctioned shadow is the lifted proxy
/// under an actively-dragged item; every other surface stays at elevation 0.
abstract final class AppElevation {
  /// Material elevation for the lifted proxy of an actively-dragged item
  /// (reorder / drag feedback).
  static const double drag = 8;
}

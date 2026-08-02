// Member names describe the small, class-documented presentation API.
// ignore_for_file: public_member_api_docs

/// Shared non-theme dimensions approved for the MVP UI.
abstract final class AppDimensions {
  static const radiusSmall = 6.0;
  static const radiusMedium = 8.0;
  static const radiusLarge = 12.0;

  /// Standard card, button, and input corner radius.
  static const double componentRadius = radiusMedium;

  /// Reserved override for later status-chip stories.
  static const statusPillRadius = 999.0;

  /// Android accessibility floor for applicable controls.
  static const minimumTapTarget = 48.0;
}

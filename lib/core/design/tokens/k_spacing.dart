/// Spacing scale. Every gap, padding and inset in Knightly comes from here.
///
/// The scale is a 4pt base grid. Do not use raw numbers in widgets.
abstract final class KSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Horizontal inset between screen edge and content on phones.
  static const double gutter = 20;
}

/// Corner radii. Surfaces get softer as they get larger.
abstract final class KRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

/// Stroke widths for outlines and dividers.
abstract final class KStroke {
  static const double hairline = 0.75;
  static const double regular = 1.25;
  static const double emphasis = 2;
}

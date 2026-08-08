import 'package:flutter/material.dart';

/// Breakpoints and sizing helpers for phones, tablets, and iPads.
class Responsive {
  Responsive._(this.context, this.size);

  factory Responsive.of(BuildContext context) {
    return Responsive._(context, MediaQuery.sizeOf(context));
  }

  final BuildContext context;
  final Size size;

  double get width => size.width;
  double get height => size.height;
  double get shortest => size.shortestSide;

  /// Phones (incl. large phones in portrait)
  bool get isPhone => shortest < 600;

  /// Tablets / iPads
  bool get isTablet => shortest >= 600 && shortest < 900;

  /// Large tablets / iPad Pro-class
  bool get isLargeTablet => shortest >= 900;

  bool get isLandscape => width > height;

  /// Horizontal page gutter
  double get pagePadding {
    if (width < 360) return 12;
    if (isPhone) return 16;
    if (isTablet) return 24;
    return 32;
  }

  /// Max content width so tablets don't stretch edge-to-edge
  double get contentMaxWidth {
    if (width >= 1200) return 1080;
    if (width >= 900) return 860;
    if (width >= 700) return 680;
    return width;
  }

  /// Narrow column for auth / forms
  double get formMaxWidth {
    if (width < 480) return width;
    return 440;
  }

  int get productColumns {
    if (width >= 1100) return 4;
    if (width >= 700) return 3;
    return 2;
  }

  double get productAspectRatio {
    if (width < 360) return 0.60;
    if (width >= 1100) return 0.78;
    if (width >= 700) return 0.74;
    return 0.66;
  }

  double get gridSpacing {
    if (width < 360) return 10;
    if (isPhone) return 14;
    return 18;
  }

  double get carouselHeight {
    if (width < 360) return 168;
    if (isPhone) return (width * 0.48).clamp(180.0, 220.0);
    if (isTablet) return 240;
    return 280;
  }

  double get carouselViewport {
    if (width >= 900) return 0.55;
    if (width >= 700) return 0.7;
    return 0.88;
  }

  double get featuredHeight {
    if (width < 360) return 108;
    if (isPhone) return 118;
    return 132;
  }

  double get categoryTileSize {
    if (width < 360) return 56;
    if (isPhone) return 64;
    return 72;
  }

  double get bottomNavHeight => 64;

  /// Slightly scale type without blowing up on tablets
  double sp(double base) {
    final scale = (width / 390).clamp(0.88, 1.15);
    return base * scale;
  }

  EdgeInsets get screenInsets => MediaQuery.paddingOf(context);

  /// Wrap page body so wide devices keep a readable column.
  Widget constrain(Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth),
        child: child,
      ),
    );
  }
}

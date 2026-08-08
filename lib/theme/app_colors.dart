import 'package:flutter/material.dart';

/// BeanBloss design tokens — single source of truth for UI.
abstract final class AppColors {
  static const Color primaryBg = Color(0xFFF5F1EB);
  static const Color cardBg = Color(0xFFFFFBF7);
  static const Color primaryBrown = Color(0xFF8B4513);
  static const Color lightBrown = Color(0xFFA0522D);
  static const Color accentGold = Color(0xFFD4A574);
  static const Color textDark = Color(0xFF2C1810);
  static const Color textLight = Color(0xFF8B7355);
  static const Color destructive = Color(0xFFC45C4A);
  static const Color success = Color(0xFF5A7A4A);

  static Color border([double opacity = 0.18]) =>
      accentGold.withOpacity(opacity);

  static Color softFill([double opacity = 0.14]) =>
      accentGold.withOpacity(opacity);
}

abstract final class AppRadii {
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 18;
  static const double xxl = 24;
  static const double pill = 28;
}

abstract final class AppShadows {
  /// Soft brown glow for heroes / FAB only.
  static List<BoxShadow> soft({double opacity = 0.12}) => [
        BoxShadow(
          color: AppColors.primaryBrown.withOpacity(opacity),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> nav = [
    BoxShadow(
      color: AppColors.primaryBrown.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, -6),
    ),
  ];
}

abstract final class AppBrand {
  static const String name = 'BeanBloss';
  static const String tagline = 'Where Beans Meet Blossoms';
  static const String street = '123 Coffee Lane';
  static const String cityLine = 'Seattle, WA 98101';
  static const String hours = 'Open daily · 7:00 AM – 8:00 PM';
  static const String phone = '(555) 010-2040';
  static const String email = 'hello@beanbloss.com';
  static const String fullAddress = '$street\n$cityLine';
}

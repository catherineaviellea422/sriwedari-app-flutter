import 'package:material_ui/material_ui.dart';

/// Palet warna resmi "Nusantara Heritage Elegance" — Galeri Sriwedari Surakarta.
/// Dipertahankan presisi dari DESIGN_SYSTEM.md & tailwind.config.ts.
class AppColors {
  const AppColors._();

  // Brand Primary & Deep Forest Greens
  static const Color primary = Color(0xFF033325);
  static const Color brandGreen = Color(0xFF1F4A3A);
  static const Color brandGreenDark = Color(0xFF14382C);
  static const Color deepForest = Color(0xFF0D1E18);
  static const Color primaryContainer = Color(0xFF1F4A3A);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF8CB9A4);
  static const Color primaryFixed = Color(0xFFBEEDD7);
  static const Color primaryFixedDim = Color(0xFFA3D0BB);

  // Accent Gold (Prada)
  static const Color gold = Color(0xFFC8A25A);
  static const Color goldWarm = Color(0xFFD4AF37);
  static const Color goldDark = Color(0xFF785918);
  static const Color goldDeep = Color(0xFF9B7832);
  static const Color goldLight = Color(0xFFFFF1D0);
  static const Color secondaryContainer = Color(0xFFFED487);
  static const Color onSecondaryContainer = Color(0xFF795A19);
  static const Color secondaryFixed = Color(0xFFFFDEA5);

  // Canvas & Surface Elevation Tiers
  static const Color canvas = Color(0xFFF6F1E7);
  static const Color surface = Color(0xFFFEF9EF);
  static const Color parchment = Color(0xFFFBF8F2);
  static const Color ivory = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF8F3E9);
  static const Color surfaceContainer = Color(0xFFF2EDE3);
  static const Color surfaceContainerHigh = Color(0xFFEDE8DE);
  static const Color surfaceContainerHighest = Color(0xFFE7E2D8);
  static const Color surfaceDim = Color(0xFFDEDAD0);

  // Text & Borders
  static const Color textPrimary = Color(0xFF1D1C16);
  static const Color textMuted = Color(0xFF414944);
  static const Color textSubtle = Color(0xFF717974);
  static const Color warmGray = Color(0xFF9A9A94);
  static const Color divider = Color(0xFFE8E0D2);
  static const Color outlineVariant = Color(0xFFC0C8C3);

  // Semantic & Status Colors
  static const Color error = Color(0xFFD64545);
  static const Color errorMaterial = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color successBg = Color(0xFFE8F5E9);
  static const Color successText = Color(0xFF2E7D32);

  static const Color warningBg = Color(0xFFFFF8E1);
  static const Color warningText = Color(0xFFB45309);

  static const Color infoBg = Color(0xFFE3F2FD);
  static const Color infoText = Color(0xFF1565C0);

  // Admin Stat Metric Card Pastel Surfaces
  static const Color metricMint = Color(0xFFDDEBE3);
  static const Color metricPeach = Color(0xFFF6E1D6);
  static const Color metricLightPeach = Color(0xFFF9EBE3);
  static const Color metricLavender = Color(0xFFE6E8EE);

  // Overlay & Shadows
  static Color cardBorder = brandGreen.withValues(alpha: 0.08);
  static Color cardShadow = brandGreenDark.withValues(alpha: 0.05);
  static Color modalScrim = brandGreenDark.withValues(alpha: 0.65);

  static const LinearGradient heroGreenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandGreen, brandGreenDark, deepForest],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, gold, goldDeep],
  );
}

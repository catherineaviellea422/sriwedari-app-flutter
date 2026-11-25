import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'app_colors.dart';

class AppTypography {
  const AppTypography._();

  static const List<FontFeature> tabularLining = [
    FontFeature.tabularFigures(),
    FontFeature.liningFigures(),
  ];

  static TextStyle displayLg({Color color = AppColors.textPrimary}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 38 / 30,
        letterSpacing: -0.3,
        color: color,
      );

  static TextStyle headlineLg({Color color = AppColors.textPrimary}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 28 / 22,
        color: color,
      );

  static TextStyle headlineMd({Color color = AppColors.textPrimary}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 24 / 18,
        color: color,
      );

  static TextStyle cardTitleSerif({Color color = AppColors.textPrimary}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 20 / 15,
        color: color,
      );

  static TextStyle titleMd({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 20 / 15,
        color: color,
      );

  static TextStyle bodyLg({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: color,
      );

  static TextStyle bodyMd({Color color = AppColors.textMuted}) =>
      GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 18 / 13,
        color: color,
      );

  static TextStyle labelMd({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        color: color,
      );

  static TextStyle labelSm({Color color = AppColors.textSubtle}) =>
      GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 14 / 10,
        color: color,
      );

  static TextStyle metricNumber({
    double fontSize = 22,
    Color color = AppColors.textPrimary,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
        fontFeatures: tabularLining,
      );

  static TextStyle priceText({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.brandGreen,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        fontFeatures: tabularLining,
      );

  static TextTheme buildTextTheme() {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: displayLg(),
      headlineLarge: headlineLg(),
      headlineMedium: headlineMd(),
      titleLarge: headlineMd(),
      titleMedium: titleMd(),
      titleSmall: labelMd(),
      bodyLarge: bodyLg(),
      bodyMedium: bodyMd(),
      bodySmall: labelSm(),
      labelLarge: titleMd(),
      labelMedium: labelMd(),
      labelSmall: labelSm(),
    );
  }
}

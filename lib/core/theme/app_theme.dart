import 'package:material_ui/material_ui.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

@immutable
class SriwedariThemeExtension extends ThemeExtension<SriwedariThemeExtension> {
  const SriwedariThemeExtension({
    required this.parchment,
    required this.gold,
    required this.brandGreen,
    required this.brandGreenDark,
    required this.metricMint,
    required this.metricPeach,
    required this.metricLightPeach,
    required this.metricLavender,
    required this.dividerColor,
  });

  final Color parchment;
  final Color gold;
  final Color brandGreen;
  final Color brandGreenDark;
  final Color metricMint;
  final Color metricPeach;
  final Color metricLightPeach;
  final Color metricLavender;
  final Color dividerColor;

  static const light = SriwedariThemeExtension(
    parchment: AppColors.parchment,
    gold: AppColors.gold,
    brandGreen: AppColors.brandGreen,
    brandGreenDark: AppColors.brandGreenDark,
    metricMint: AppColors.metricMint,
    metricPeach: AppColors.metricPeach,
    metricLightPeach: AppColors.metricLightPeach,
    metricLavender: AppColors.metricLavender,
    dividerColor: AppColors.divider,
  );

  @override
  SriwedariThemeExtension copyWith({
    Color? parchment,
    Color? gold,
    Color? brandGreen,
    Color? brandGreenDark,
    Color? metricMint,
    Color? metricPeach,
    Color? metricLightPeach,
    Color? metricLavender,
    Color? dividerColor,
  }) {
    return SriwedariThemeExtension(
      parchment: parchment ?? this.parchment,
      gold: gold ?? this.gold,
      brandGreen: brandGreen ?? this.brandGreen,
      brandGreenDark: brandGreenDark ?? this.brandGreenDark,
      metricMint: metricMint ?? this.metricMint,
      metricPeach: metricPeach ?? this.metricPeach,
      metricLightPeach: metricLightPeach ?? this.metricLightPeach,
      metricLavender: metricLavender ?? this.metricLavender,
      dividerColor: dividerColor ?? this.dividerColor,
    );
  }

  @override
  SriwedariThemeExtension lerp(
    covariant ThemeExtension<SriwedariThemeExtension>? other,
    double t,
  ) {
    if (other is! SriwedariThemeExtension) return this;
    return SriwedariThemeExtension(
      parchment: Color.lerp(parchment, other.parchment, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      brandGreen: Color.lerp(brandGreen, other.brandGreen, t)!,
      brandGreenDark: Color.lerp(brandGreenDark, other.brandGreenDark, t)!,
      metricMint: Color.lerp(metricMint, other.metricMint, t)!,
      metricPeach: Color.lerp(metricPeach, other.metricPeach, t)!,
      metricLightPeach: Color.lerp(metricLightPeach, other.metricLightPeach, t)!,
      metricLavender: Color.lerp(metricLavender, other.metricLavender, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
    );
  }
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.brandGreen,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.gold,
      onSecondary: AppColors.brandGreenDark,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.primary,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textMuted,
      outline: AppColors.textSubtle,
      outlineVariant: AppColors.outlineVariant,
      surfaceContainerLowest: AppColors.ivory,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: AppTypography.buildTextTheme(),
      extensions: const [SriwedariThemeExtension.light],
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.parchment,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.headlineMd(color: AppColors.brandGreen),
      ),
      cardTheme: CardThemeData(
        color: AppColors.parchment,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.ivory,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: AppTypography.bodyMd(color: AppColors.warmGray),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          borderSide: BorderSide(color: AppColors.warmGray.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          borderSide: BorderSide(color: AppColors.warmGray.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(88, AppSpacing.touchTargetHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
          elevation: 0,
          textStyle: AppTypography.labelMd(color: Colors.white).copyWith(fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandGreen,
          minimumSize: const Size(88, AppSpacing.touchTargetHeight),
          side: const BorderSide(color: AppColors.brandGreen, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
          textStyle: AppTypography.labelMd(color: AppColors.brandGreen).copyWith(fontSize: 14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSpacing.bottomNavHeight,
        backgroundColor: AppColors.parchment,
        indicatorColor: AppColors.primaryFixed.withValues(alpha: 0.45),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return AppTypography.labelSm(
            color: isSelected ? AppColors.brandGreen : AppColors.warmGray,
          ).copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? AppColors.brandGreen : AppColors.warmGray,
            size: 22,
          );
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.ivory,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusModal),
        ),
      ),
    );
  }
}

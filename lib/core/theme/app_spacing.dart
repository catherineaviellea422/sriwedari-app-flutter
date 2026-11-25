import 'package:material_ui/material_ui.dart';

enum WindowSizeClass { compact, medium, expanded }

class AppSpacing {
  const AppSpacing._();

  // Base 8pt spatial cadence
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  static const double canvasMarginMobile = 20.0;
  static const double canvasMarginDesktop = 32.0;
  static const double gridGutter = 12.0;
  static const double bottomNavHeight = 64.0;
  static const double touchTargetHeight = 48.0;
  static const double inputHeight = 44.0;

  // Border Radii
  static const double radiusSm = 4.0;
  static const double radiusInput = 8.0;
  static const double radiusButton = 10.0;
  static const double radiusCard = 14.0;
  static const double radiusModal = 16.0;
  static const double radiusHero = 20.0;
  static const double radiusPill = 9999.0;

  // Breakpoints
  static const double compactMaxWidth = 600.0;
  static const double mediumMaxWidth = 1024.0;
  static const double maxContentWidth = 1200.0;
}

class ResponsiveHelper {
  const ResponsiveHelper._();

  static WindowSizeClass classifyWidth(double width) {
    if (width < AppSpacing.compactMaxWidth) return WindowSizeClass.compact;
    if (width < AppSpacing.mediumMaxWidth) return WindowSizeClass.medium;
    return WindowSizeClass.expanded;
  }

  static WindowSizeClass of(BuildContext context) {
    return classifyWidth(MediaQuery.sizeOf(context).width);
  }

  static bool isCompact(BuildContext context) =>
      of(context) == WindowSizeClass.compact;

  static bool isMedium(BuildContext context) =>
      of(context) == WindowSizeClass.medium;

  static bool isExpanded(BuildContext context) =>
      of(context) == WindowSizeClass.expanded;

  static int galleryColumnsForWidth(double width) {
    if (width < AppSpacing.compactMaxWidth) return 2;
    if (width < AppSpacing.mediumMaxWidth) return 3;
    return 4;
  }

  static int adminMetricColumnsForWidth(double width) {
    if (width < AppSpacing.compactMaxWidth) return 2;
    return 4;
  }

  static double horizontalMarginForWidth(double width) {
    return width < AppSpacing.compactMaxWidth
        ? AppSpacing.canvasMarginMobile
        : AppSpacing.canvasMarginDesktop;
  }
}

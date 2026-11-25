import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Perilaku scroll adaptif lintas platform (iOS/Android/Web/Desktop).
/// Memungkinkan scrolling mulus melalui sentuhan, trackpad, roda mouse,
/// maupun click-and-drag pada Web/Desktop dengan mempertahankan fisika native.
class SwScrollBehavior extends MaterialScrollBehavior {
  const SwScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    final platform = getPlatform(context);
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
    }
    return super.getScrollPhysics(context);
  }
}

/// Menghitung padding horizontal sliver agar konten tetap terpusat di dalam
/// batas [maxContentWidth] tanpa membungkus grid dengan `shrinkWrap`.
double centeredSliverHorizontalPadding(
  double viewportWidth, {
  required double horizontalMargin,
  required double maxContentWidth,
}) {
  final outerPad = viewportWidth > maxContentWidth
      ? (viewportWidth - maxContentWidth) / 2
      : 0.0;
  return outerPad + horizontalMargin;
}

/// Membaca parameter `?heroTag=...` secara aman dengan fallback tag unik halaman detail
/// agar transisi `Hero` tidak pernah bertabrakan antar tab shell atau di unit test.
String resolveHeroTag(BuildContext context, String fallbackTag) {
  try {
    final param = GoRouterState.of(context).uri.queryParameters['heroTag'];
    if (param != null && param.isNotEmpty) return param;
  } catch (_) {
    // Aman saat dirender di luar konteks GoRouter.
  }
  return fallbackTag;
}

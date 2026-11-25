import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Transisi halaman halus berarah (maju vs mundur) dengan efek *secondary parallax*
/// pada layar sebelumnya serta kurva natural `Curves.easeOutCubic`.
class SmoothPageTransition {
  const SmoothPageTransition._();

  static CustomTransitionPage<T> build<T>({
    required LocalKey key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 280),
    Duration reverseDuration = const Duration(milliseconds: 240),
    Offset beginOffset = const Offset(1.0, 0.0),
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.disableAnimationsOf(context)) return child;

        final enterCurve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final parallaxCurve = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.18, 0.0),
          ).animate(parallaxCurve),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.90, end: 1.0).animate(enterCurve),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: beginOffset,
                end: Offset.zero,
              ).animate(enterCurve),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

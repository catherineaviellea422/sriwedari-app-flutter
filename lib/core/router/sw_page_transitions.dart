import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Kumpulan helper transisi halaman dan pergantian step/tab terarah
/// dengan kurva natural (`Curves.easeOutCubic` / `Curves.easeInCubic`).
class SwPageTransitions {
  const SwPageTransitions._();

  static const Duration _forwardDuration = Duration(milliseconds: 280);
  static const Duration _reverseDuration = Duration(milliseconds: 240);

  /// Transisi geser horizontal (kanan -> kiri saat maju, kiri -> kanan saat kembali)
  /// untuk rute detail, sub-halaman admin, atau alur sekunder auth.
  static CustomTransitionPage<void> slideHorizontal({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: _forwardDuration,
      reverseTransitionDuration: _reverseDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.disableAnimationsOf(context)) return child;

        final slideCurve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final fadeCurve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );

        return FadeTransition(
          opacity: Tween<double>(begin: 0.88, end: 1.0).animate(fadeCurve),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(slideCurve),
            child: child,
          ),
        );
      },
    );
  }

  /// Transisi vertikal lembut (bawah -> atas) untuk halaman konfirmasi/sukses.
  static CustomTransitionPage<void> slideUpFade({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: _forwardDuration,
      reverseTransitionDuration: _reverseDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.disableAnimationsOf(context)) return child;

        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.12),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

/// Wrapper `AnimatedSwitcher` dua arah untuk perpindahan step atau segmen tab
/// di dalam satu layar: maju menggeser masuk dari kanan, mundur dari kiri.
class SwDirectionalSwitcher extends StatelessWidget {
  const SwDirectionalSwitcher({
    super.key,
    required this.child,
    this.isForward = true,
    this.duration = const Duration(milliseconds: 240),
  });

  final Widget child;
  final bool isForward;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final enterOffset = Offset(isForward ? 0.14 : -0.14, 0.0);

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (widget, animation) {
        final offset = animation.status == AnimationStatus.reverse
            ? Offset(-enterOffset.dx, 0.0)
            : enterOffset;
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: offset,
              end: Offset.zero,
            ).animate(animation),
            child: widget,
          ),
        );
      },
      child: child,
    );
  }
}

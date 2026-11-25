import 'package:material_ui/material_ui.dart';

/// Transisi halus antar-state konten (mis. loading skeleton -> data asli, atau
/// pergantian hasil filter) dengan kurva `Curves.easeOutCubic`.
class SwContentSwitcher extends StatelessWidget {
  const SwContentSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 240),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
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
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.025),
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

/// Wrapper ekspansi tinggi halus berbasis `AnimatedSize` agar panel info,
/// catatan diskon, maupun kontrol tambahan tidak muncul tiba-tiba (*snap*).
class SwAnimatedExpand extends StatelessWidget {
  const SwAnimatedExpand({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 220),
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final Duration duration;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: alignment,
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }
}

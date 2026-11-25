import 'package:material_ui/material_ui.dart';

/// Efek tekan responsif (`scale: 0.97`, durasi `140ms`) berbasis `Listener` pasif
/// sehingga tidak pernah mengganggu `GestureArena` maupun `InkWell` anak.
class ScaleOnTap extends StatefulWidget {
  const ScaleOnTap({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = 0.97,
    this.hoverScale = 1.0,
    this.enableHover = false,
  });

  final Widget child;
  final bool enabled;
  final double pressedScale;
  final double hoverScale;
  final bool enableHover;

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap> {
  bool _isPressed = false;
  bool _isHovered = false;

  void _setPressed(bool value) {
    if (!widget.enabled || _isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final double targetScale;
    if (!widget.enabled || disableAnimations) {
      targetScale = 1.0;
    } else if (_isPressed) {
      targetScale = widget.pressedScale;
    } else if (widget.enableHover && _isHovered) {
      targetScale = widget.hoverScale;
    } else {
      targetScale = 1.0;
    }

    Widget content = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: widget.enabled ? (_) => _setPressed(true) : null,
      onPointerUp: widget.enabled ? (_) => _setPressed(false) : null,
      onPointerCancel: widget.enabled ? (_) => _setPressed(false) : null,
      child: disableAnimations
          ? widget.child
          : AnimatedScale(
              scale: targetScale,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              child: widget.child,
            ),
    );

    if (widget.enableHover && widget.enabled) {
      content = MouseRegion(
        onEnter: (_) {
          if (!_isHovered) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (_isHovered || _isPressed) {
            setState(() {
              _isHovered = false;
              _isPressed = false;
            });
          }
        },
        child: content,
      );
    }

    return content;
  }
}

/// Wrapper efek hover khusus Desktop/Web (elevasi/border lembut 160ms) +
/// feedback tekan `ScaleOnTap` yang ringan.
class InteractiveCard extends StatefulWidget {
  const InteractiveCard({
    super.key,
    required this.child,
    this.enabled = true,
    this.borderRadius = 14.0,
    this.pressedScale = 0.97,
  });

  final Widget child;
  final bool enabled;
  final double borderRadius;
  final double pressedScale;

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final radius = BorderRadius.circular(widget.borderRadius);

    return ScaleOnTap(
      enabled: widget.enabled,
      pressedScale: widget.pressedScale,
      hoverScale: 1.0,
      child: MouseRegion(
        onEnter: widget.enabled && !disableAnimations
            ? (_) => setState(() => _hovered = true)
            : null,
        onExit: widget.enabled && !disableAnimations
            ? (_) => setState(() => _hovered = false)
            : null,
        child: AnimatedContainer(
          duration: disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: widget.enabled && _hovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF14382C).withValues(alpha: 0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

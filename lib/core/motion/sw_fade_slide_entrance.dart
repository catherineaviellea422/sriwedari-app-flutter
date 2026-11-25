import 'package:material_ui/material_ui.dart';

/// Animasi masuk halus (`fade` + geser vertikal `slideOffset`) sekali jalan saat
/// elemen pertama kali muncul, menggunakan `Interval` pada `AnimationController`
/// tanpa `Timer`/`Future.delayed` agar zero ticker/timer leak saat pengujian.
class FadeSlideEntrance extends StatefulWidget {
  const FadeSlideEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.staggerStepMs = 42,
    this.maxStaggerIndex = 6,
    this.duration = const Duration(milliseconds: 260),
    this.slideOffset = 14.0,
    this.onceKey,
  });

  final Widget child;
  final int index;
  final int staggerStepMs;
  final int maxStaggerIndex;
  final Duration duration;
  final double slideOffset;

  /// Kunci opsional untuk menyimpan status "sudah tampil" di [PageStorage]
  /// sehingga item list panjang tidak mengulang animasi saat di-scroll ulang.
  final String? onceKey;

  @override
  State<FadeSlideEntrance> createState() => _FadeSlideEntranceState();
}

class _FadeSlideEntranceState extends State<FadeSlideEntrance>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _curved;
  bool _started = false;
  bool _completedOnce = false;

  int get _delayMs =>
      widget.index.clamp(0, widget.maxStaggerIndex) * widget.staggerStepMs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final storage = PageStorage.maybeOf(context);
    final alreadyShown = widget.onceKey != null &&
        (storage?.readState(context, identifier: widget.onceKey) == true);

    if (disableAnimations || alreadyShown) {
      _completedOnce = true;
      return;
    }

    final baseMs = widget.duration.inMilliseconds;
    final delayMs = _delayMs;
    final totalMs = baseMs + delayMs;
    final startFrac = totalMs > 0 ? (delayMs / totalMs).clamp(0.0, 0.85) : 0.0;

    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );
    _controller = controller;
    _curved = CurvedAnimation(
      parent: controller,
      curve: Interval(startFrac, 1.0, curve: Curves.easeOutCubic),
    );

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onceKey != null) {
        PageStorage.maybeOf(context)
            ?.writeState(context, true, identifier: widget.onceKey);
      }
    });

    controller.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anim = _curved;
    if (_completedOnce || anim == null) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: anim,
      child: widget.child,
      builder: (context, child) {
        final t = anim.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1.0 - t) * widget.slideOffset),
            child: child,
          ),
        );
      },
    );
  }
}

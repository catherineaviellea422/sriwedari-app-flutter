import 'package:material_ui/material_ui.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SwLoadingSkeleton extends StatefulWidget {
  const SwLoadingSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = AppSpacing.radiusInput,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<SwLoadingSkeleton> createState() => _SwLoadingSkeletonState();
}

class _SwLoadingSkeletonState extends State<SwLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(begin: 0.45, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disable = MediaQuery.disableAnimationsOf(context);
    if (disable == _reducedMotion && (_controller.isAnimating || disable)) {
      return;
    }
    _reducedMotion = disable;
    if (disable) {
      _controller.stop();
      _controller.value = 0.7;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class SwCardSkeleton extends StatelessWidget {
  const SwCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwLoadingSkeleton(height: 112, borderRadius: 10),
          SizedBox(height: 10),
          SwLoadingSkeleton(height: 14, width: 130),
          SizedBox(height: 6),
          SwLoadingSkeleton(height: 11, width: 90),
        ],
      ),
    );
  }
}

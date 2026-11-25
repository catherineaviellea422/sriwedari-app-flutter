import 'package:material_ui/material_ui.dart';
import '../motion/sw_interactive_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SwCard extends StatelessWidget {
  const SwCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.backgroundColor = AppColors.parchment,
    this.borderRadius = AppSpacing.radiusCard,
    this.borderColor,
    this.onTap,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final double borderRadius;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final decoration = BoxDecoration(
      color: backgroundColor,
      borderRadius: radius,
      border: Border.all(color: borderColor ?? AppColors.cardBorder),
      boxShadow: [
        BoxShadow(
          color: AppColors.brandGreenDark.withValues(alpha: elevated ? 0.12 : 0.04),
          blurRadius: elevated ? 24 : 8,
          offset: Offset(0, elevated ? 8 : 2),
        ),
      ],
    );

    final content = Padding(padding: padding, child: child);

    if (onTap == null) {
      return Container(decoration: decoration, child: content);
    }

    return InteractiveCard(
      borderRadius: borderRadius,
      pressedScale: 0.985,
      child: Container(
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: content,
          ),
        ),
      ),
    );
  }
}

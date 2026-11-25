import 'package:material_ui/material_ui.dart';
import '../motion/sw_interactive_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class SwFilterChip extends StatelessWidget {
  const SwFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bgColor = selected ? AppColors.brandGreen : AppColors.parchment;
    final fgColor = selected ? Colors.white : AppColors.brandGreen;
    final borderColor = selected
        ? AppColors.brandGreen
        : AppColors.brandGreen.withValues(alpha: 0.16);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return ScaleOnTap(
      pressedScale: 0.96,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          child: AnimatedContainer(
            duration: disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: fgColor),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppTypography.labelMd(color: fgColor).copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

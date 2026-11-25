import 'package:material_ui/material_ui.dart';
import '../motion/sw_interactive_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum SwButtonVariant { primary, secondary, gold, destructive, ghost }

class SwButton extends StatelessWidget {
  const SwButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = SwButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = false,
    this.height = AppSpacing.touchTargetHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final SwButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool fullWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    final (bgColor, fgColor, borderSide) = switch (variant) {
      SwButtonVariant.primary => (
          AppColors.brandGreen,
          Colors.white,
          BorderSide.none,
        ),
      SwButtonVariant.secondary => (
          Colors.transparent,
          AppColors.brandGreen,
          const BorderSide(color: AppColors.brandGreen, width: 1.5),
        ),
      SwButtonVariant.gold => (
          AppColors.gold,
          AppColors.brandGreenDark,
          BorderSide.none,
        ),
      SwButtonVariant.destructive => (
          AppColors.error,
          Colors.white,
          BorderSide.none,
        ),
      SwButtonVariant.ghost => (
          Colors.transparent,
          AppColors.brandGreen,
          BorderSide.none,
        ),
    };

    final child = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 18, color: fgColor),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMd(color: fgColor).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (!isLoading && trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: 18, color: fgColor),
        ],
      ],
    );

    final button = ScaleOnTap(
      enabled: effectiveOnPressed != null,
      pressedScale: 0.97,
      enableHover: true,
      hoverScale: 1.005,
      child: Material(
        color: effectiveOnPressed == null
            ? bgColor.withValues(alpha: 0.55)
            : bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        child: InkWell(
          onTap: effectiveOnPressed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
              border: borderSide == BorderSide.none
                  ? null
                  : Border.fromBorderSide(borderSide),
            ),
            child: child,
          ),
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

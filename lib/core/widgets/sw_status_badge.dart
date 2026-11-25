import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum SwBadgeTone { success, warning, error, info, gold, neutral }

class SwStatusBadge extends StatelessWidget {
  const SwStatusBadge({
    super.key,
    required this.label,
    this.tone = SwBadgeTone.neutral,
    this.icon,
  });

  final String label;
  final SwBadgeTone tone;
  final IconData? icon;

  factory SwStatusBadge.fromOrderStatus(String status) {
    return switch (status) {
      'Dikonfirmasi' ||
      'Aktif' ||
      'Tampil' ||
      'tampil' ||
      'Grade A' => SwStatusBadge(label: status, tone: SwBadgeTone.success),
      'Menunggu' ||
      'Pending' ||
      'Grade B' => SwStatusBadge(label: status, tone: SwBadgeTone.warning),
      'Sedang Disewa' ||
      'Selesai' ||
      'Check-in' => SwStatusBadge(label: status, tone: SwBadgeTone.info),
      'Dibatalkan' ||
      'Kedaluwarsa' ||
      'Grade D' ||
      'disembunyikan' => SwStatusBadge(label: status, tone: SwBadgeTone.error),
      'Grade C' => SwStatusBadge(label: status, tone: SwBadgeTone.gold),
      _ => SwStatusBadge(label: status, tone: SwBadgeTone.neutral),
    };
  }

  factory SwStatusBadge.fromRole(String role) {
    if (role.toLowerCase() == 'admin') {
      return const SwStatusBadge(
        label: 'Admin',
        tone: SwBadgeTone.gold,
        icon: Icons.verified_user_outlined,
      );
    }
    return const SwStatusBadge(
      label: 'User',
      tone: SwBadgeTone.neutral,
      icon: Icons.person_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      SwBadgeTone.success => (AppColors.successBg, AppColors.successText),
      SwBadgeTone.warning => (AppColors.warningBg, AppColors.warningText),
      SwBadgeTone.error => (AppColors.errorContainer, AppColors.error),
      SwBadgeTone.info => (AppColors.infoBg, AppColors.infoText),
      SwBadgeTone.gold => (AppColors.secondaryFixed, AppColors.goldDark),
      SwBadgeTone.neutral => (
        AppColors.surfaceContainerHigh,
        AppColors.textMuted,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSm(color: fg).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

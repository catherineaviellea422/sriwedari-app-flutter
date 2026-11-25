import 'package:material_ui/material_ui.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'sw_button.dart';

class SwConfirmDialog extends StatelessWidget {
  const SwConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Ya, Lanjutkan',
    this.cancelLabel = 'Batal',
    this.icon = Icons.logout_rounded,
    this.iconColor = AppColors.error,
    this.confirmVariant = SwButtonVariant.primary,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final Color iconColor;
  final SwButtonVariant confirmVariant;

  static Future<bool> showLogoutModal(
    BuildContext context, {
    String subtitle = 'Kamu akan kembali ke halaman login.',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.modalScrim,
      builder: (_) => SwConfirmDialog(
        title: 'Keluar dari akun?',
        message: subtitle,
        confirmLabel: 'Ya, Keluar',
        cancelLabel: 'Batal',
        icon: Icons.logout_rounded,
        iconColor: AppColors.error,
        confirmVariant: SwButtonVariant.primary,
      ),
    );
    return result ?? false;
  }

  static Future<bool> showDeleteModal(
    BuildContext context, {
    required String itemName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.modalScrim,
      builder: (_) => SwConfirmDialog(
        title: 'Hapus data ini?',
        message: 'Data "$itemName" akan dihapus secara permanen dari basis data.',
        confirmLabel: 'Ya, Hapus',
        cancelLabel: 'Batal',
        icon: Icons.delete_outline_rounded,
        iconColor: AppColors.error,
        confirmVariant: SwButtonVariant.destructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.ivory,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusModal),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: iconColor),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.headlineMd(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd(color: AppColors.textSubtle),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SwButton(
                      label: cancelLabel,
                      variant: SwButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SwButton(
                      label: confirmLabel,
                      variant: confirmVariant,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

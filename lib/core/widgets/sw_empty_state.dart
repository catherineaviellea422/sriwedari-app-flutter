import 'package:material_ui/material_ui.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'sw_button.dart';
import 'sw_card.dart';

class SwEmptyState extends StatelessWidget {
  const SwEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.museum_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SwCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.metricMint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: AppColors.brandGreen),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.headlineMd(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd(color: AppColors.textSubtle),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                SwButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  variant: SwButtonVariant.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SwErrorView extends StatelessWidget {
  const SwErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return SwEmptyState(
      icon: Icons.error_outline_rounded,
      title: 'Gagal Memuat Data',
      description: message,
      actionLabel: onRetry != null ? 'Coba Lagi' : null,
      onAction: onRetry,
    );
  }
}

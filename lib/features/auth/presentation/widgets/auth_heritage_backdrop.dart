import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Latar belakang khas Galeri Sriwedari (Hijau Gelap Keraton + ornamen batik emas).
class AuthHeritageBackdrop extends StatelessWidget {
  const AuthHeritageBackdrop({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.badgeText,
    this.showBackButton = false,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? badgeText;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandGreenDark,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.heroGreenGradient,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BatikOrnamentPainter(),
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xxl,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FadeSlideEntrance(
                            index: 0,
                            onceKey: 'auth_header_$title',
                            slideOffset: 10,
                            child: _HeritageBrandHeader(
                              title: title,
                              subtitle: subtitle,
                              badgeText: badgeText,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FadeSlideEntrance(
                            index: 1,
                            onceKey: 'auth_card_$title',
                            slideOffset: 14,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.xxl),
                              decoration: BoxDecoration(
                                color: AppColors.brandGreenDark
                                    .withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.35),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 28,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: child,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (showBackButton)
                  Positioned(
                    top: 10,
                    left: 12,
                    child: ScaleOnTap(
                      pressedScale: 0.9,
                      child: Material(
                        color: AppColors.brandGreenDark.withValues(alpha: 0.85),
                        shape: CircleBorder(
                          side: BorderSide(
                            color: AppColors.gold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: IconButton(
                          key: const ValueKey('auth-back-btn'),
                          onPressed: onBack ??
                              () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go(AppRoutes.login);
                                }
                              },
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.goldLight,
                          ),
                          tooltip: 'Kembali',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeritageBrandHeader extends StatelessWidget {
  const _HeritageBrandHeader({
    required this.title,
    required this.subtitle,
    this.badgeText,
  });

  final String title;
  final String subtitle;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.brandGreen,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.22),
                blurRadius: 16,
              ),
            ],
          ),
          child: Image.asset(
            AppConstants.heritageLogoAsset,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.temple_buddhist_rounded,
              color: AppColors.gold,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.headlineLg(color: AppColors.goldLight),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMd(
            color: AppColors.canvas.withValues(alpha: 0.78),
          ),
        ),
        if (badgeText != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
            ),
            child: Text(
              badgeText!,
              style: AppTypography.labelSm(color: AppColors.goldLight).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BatikOrnamentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final bottomCenter = Offset(size.width * 0.12, size.height * 0.94);
    for (var i = 1; i <= 5; i++) {
      canvas.drawCircle(bottomCenter, i * 26.0, paint);
    }

    final topRight = Offset(size.width * 0.92, size.height * 0.08);
    for (var i = 0; i < 8; i++) {
      final angle = (math.pi * 2 / 8) * i;
      final petal = Offset(
        topRight.dx + math.cos(angle) * 42,
        topRight.dy + math.sin(angle) * 42,
      );
      canvas.drawCircle(petal, 24, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

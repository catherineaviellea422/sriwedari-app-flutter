import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../providers/user_transactions_providers.dart';

class BookingSuccessScreen extends ConsumerWidget {
  const BookingSuccessScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider);
    final order = (ordersAsync.value ?? const [])
        .where((o) => o.id == orderId)
        .firstOrNull;
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go(AppRoutes.userDashboard);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.brandGreenDark,
          foregroundColor: AppColors.goldLight,
          leading: IconButton(
            key: const ValueKey('booking-success-home-btn'),
            onPressed: () => context.go(AppRoutes.userDashboard),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Ke Beranda',
          ),
          title: Text(
            'Konfirmasi Reservasi',
            style: AppTypography.titleMd(color: AppColors.goldLight),
          ),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: margin,
                  vertical: AppSpacing.xxl,
                ),
                child: FadeSlideEntrance(
                  index: 0,
                  onceKey: 'booking_success_card_$orderId',
                  slideOffset: 16,
                  child: SwCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            color: AppColors.successBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.successText,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Pesanan Sewa Berhasil Dibuat!',
                          textAlign: TextAlign.center,
                          style: AppTypography.headlineLg(),
                        ),
                        const SizedBox(height: 6),
                        SwStatusBadge(
                          label: 'Invoice: $orderId',
                          tone: SwBadgeTone.gold,
                        ),
                        const SizedBox(height: 16),
                        if (order != null) ...[
                          FadeSlideEntrance(
                            index: 1,
                            onceKey: 'booking_success_inv_$orderId',
                            slideOffset: 10,
                            child: SwCard(
                              backgroundColor: AppColors.surfaceContainerLow,
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                children: [
                                  _DetailLine('Busana', order.costumeName),
                                  const SizedBox(height: 6),
                                  _DetailLine('Tanggal Mulai', order.startDate),
                                  const SizedBox(height: 6),
                                  _DetailLine(
                                    'Metode Bayar',
                                    order.paymentMethod,
                                  ),
                                  const SizedBox(height: 6),
                                  _DetailLine(
                                    'Total Tagihan',
                                    CurrencyFormatter.formatRupiah(
                                      order.totalPrice,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        Text(
                          'Silakan selesaikan pembayaran dan unggah bukti transfer melalui halaman Profil pada tab Sewa agar kurator dapat segera memverifikasi pesanan Anda.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMd(color: AppColors.textSubtle),
                        ),
                        const SizedBox(height: 20),
                        SwButton(
                          label: 'Lihat Pesanan & Unggah Bukti',
                          leadingIcon: Icons.upload_file_rounded,
                          fullWidth: true,
                          onPressed: () => context.go(
                            AppRoutes.userProfileWithTab('orders'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SwButton(
                          label: 'Kembali ke Beranda',
                          variant: SwButtonVariant.secondary,
                          fullWidth: true,
                          onPressed: () => context.go(AppRoutes.userDashboard),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMd(color: AppColors.textSubtle)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.labelMd(),
          ),
        ),
      ],
    );
  }
}

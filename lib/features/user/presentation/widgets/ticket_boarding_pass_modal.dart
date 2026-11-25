import 'package:barcode_widget/barcode_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/models/user_models.dart';

class TicketBoardingPassModal extends StatelessWidget {
  const TicketBoardingPassModal({super.key, required this.ticket});

  final UserTicketModel ticket;

  static Future<void> show(
    BuildContext context, {
    required UserTicketModel ticket,
  }) async {
    await showDialog<void>(
      context: context,
      barrierColor: AppColors.modalScrim,
      builder: (_) => TicketBoardingPassModal(ticket: ticket),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = ticket.status == 'Check-in';

    return Dialog(
      backgroundColor: const Color(0xFFFAF5E9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.6), width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Keraton
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGreenGradient,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.theater_comedy_rounded,
                        color: AppColors.brandGreenDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GEDUNG WAYANG ORANG SRIWEDARI',
                            style: AppTypography.labelSm(color: AppColors.goldLight)
                                .copyWith(fontSize: 9, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'PAS MASUK PAGELARAN',
                            style: AppTypography.headlineMd(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    SwStatusBadge(
                      label: 'Zona ${ticket.zone}',
                      tone: SwBadgeTone.gold,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LAKON PEMENTASAN',
                      style: AppTypography.labelSm(color: AppColors.textSubtle)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ticket.eventTitle,
                      style: AppTypography.headlineMd(
                        color: AppColors.brandGreenDark,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Detail Grid
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _TicketField(
                                  label: 'Pemesan',
                                  value: ticket.userName,
                                ),
                              ),
                              Expanded(
                                child: _TicketField(
                                  label: 'Nomor Kursi',
                                  value: ticket.seats.isNotEmpty
                                      ? ticket.seats.join(', ')
                                      : '-',
                                  highlight: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _TicketField(
                                  label: 'Jumlah',
                                  value: '${ticket.quantity} Kursi',
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Status', style: AppTypography.labelSm()),
                                    const SizedBox(height: 3),
                                    SwStatusBadge(
                                      label: isCheckedIn
                                          ? 'Sudah Masuk'
                                          : 'Sah / Valid',
                                      tone: isCheckedIn
                                          ? SwBadgeTone.info
                                          : SwBadgeTone.success,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // QR Pass + Booking Code Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.brandGreenDark,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'KODE BOARDING PASS',
                                  style: AppTypography.labelSm(
                                    color: AppColors.goldLight,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ticket.bookingCode,
                                  style: AppTypography.headlineLg(
                                    color: AppColors.gold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ID: ${ticket.id}',
                                  style: AppTypography.labelSm(
                                    color: AppColors.canvas.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: BarcodeWidget(
                                    barcode: Barcode.code128(),
                                    data: ticket.bookingCode,
                                    width: 145,
                                    height: 28,
                                    drawText: false,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: QrImageView(
                              data: ticket.bookingCode,
                              version: QrVersions.auto,
                              size: 86,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Pintu teater dibuka 30 menit sebelum pementasan.\n• Tiket ini tersimpan offline dan sah dipindai di gerbang GWO Sriwedari.',
                      style: AppTypography.labelSm(),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Pembayaran',
                                style: AppTypography.labelSm(),
                              ),
                              Text(
                                CurrencyFormatter.formatRupiah(ticket.totalPrice),
                                style: AppTypography.priceText(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SwButton(
                          label: 'Tutup',
                          variant: SwButtonVariant.primary,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketField extends StatelessWidget {
  const _TicketField({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSm()),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelMd(
            color: highlight ? AppColors.brandGreen : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

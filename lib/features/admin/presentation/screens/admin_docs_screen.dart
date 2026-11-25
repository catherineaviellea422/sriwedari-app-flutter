import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/core_widgets.dart';

class AdminDocsScreen extends StatelessWidget {
  const AdminDocsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);

    const sections = [
      (
        '1. Alur Verifikasi Pembayaran & Serah Terima Sewa',
        Icons.receipt_long_rounded,
        '• Penyewa mengirim pesanan multi-busana dengan deposit jaminan keamanan Rp 100.000.\n'
            '• Kurator memeriksa bukti transfer pada menu Pesanan & QC, lalu menekan Konfirmasi Bayar (status: Dikonfirmasi).\n'
            '• Saat penyewa mengambil busana di sanggar, tekan Serahkan Kostum (status: Sedang Disewa).',
        AppRoutes.adminOrders,
        'Buka Antrean Pesanan',
      ),
      (
        '2. Mesin Inspeksi QC Retur (Grade A–D)',
        Icons.fact_check_outlined,
        '• Grade A: Mulus sempurna — Potongan Rp 0 (Refund penuh Rp 100.000).\n'
            '• Grade B: Noda ringan / perlu cuci khusus — Potongan Rp 25.000.\n'
            '• Grade C: Payet lepas / jahitan minor — Potongan Rp 50.000.\n'
            '• Grade D: Kerusakan berat / aksesori hilang — Potongan Rp 100.000.\n'
            '• Menyelesaikan QC otomatis menandai pesanan Selesai dan mengembalikan stok kostum + mencatat mutasi stok.',
        AppRoutes.adminCostumes,
        'Buka Inventaris Kostum',
      ),
      (
        '3. Kasir Loket (POS) & Validasi Gerbang QR',
        Icons.qr_code_scanner_rounded,
        '• Tiket walk-in diterbitkan secara atomik per kursi (anti double-booking lintas User & Admin).\n'
            '• Gunakan tab Gate QR Check-In atau menu Kunjungan untuk memindai/memasukkan kode booking SWD-XXXXX.\n'
            '• Tiket yang sudah Check-in tidak dapat dipakai ulang.',
        AppRoutes.adminPos,
        'Buka Kasir Loket',
      ),
      (
        '4. Arsitektur Isolasi Dual-Database (User vs Admin)',
        Icons.security_rounded,
        '• Data operasional Admin (audit log, kurasi master, akun admin) tersimpan terpisah di sriwedari-admin-db.json & AdminLocalStorage (sriwedari_admin_store::).\n'
            '• Data pengunjung & transaksi publik tersimpan terpisah di sriwedari-user-db.json & UserLocalStorage (sriwedari_user_store::).\n'
            '• Ekspor Audit Trail ke CSV tersedia kapan saja untuk keperluan pelaporan dinas.',
        AppRoutes.adminAudit,
        'Buka Audit Trail',
      ),
    ];

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidth,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: margin,
              vertical: AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dokumentasi Alur Operasional',
                  style: AppTypography.headlineLg(),
                ),
                const SizedBox(height: 4),
                Text(
                  'Standar Prosedur Operasional (SOP) Kurator, Kasir Loket & Inspeksi QC Galeri Sriwedari',
                  style: AppTypography.bodyMd(color: AppColors.textSubtle),
                ),
                const SizedBox(height: 16),
                ...sections.map(
                  (sec) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SwCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.metricMint,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  sec.$2,
                                  color: AppColors.brandGreen,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  sec.$1,
                                  style: AppTypography.titleMd(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(sec.$3, style: AppTypography.bodyMd()),
                          const SizedBox(height: 12),
                          SwButton(
                            label: sec.$5,
                            variant: SwButtonVariant.secondary,
                            height: 36,
                            onPressed: () => context.go(sec.$4),
                          ),
                        ],
                      ),
                    ),
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

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/core_widgets.dart';

class AboutHistoryScreen extends StatelessWidget {
  const AboutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);

    const milestones = [
      (
        era: 'TAHUN 1899 — ERA PAKUBUWANA X',
        title: 'Pendirian Kebon Raja Sriwedari',
        desc:
            'Taman Sriwedari didirikan sebagai tempat rekreasi keluarga istana dan hiburan rakyat (bonrojo). Nama Sriwedari diambil dari mitologi pewayangan yang berarti taman surga yang indah di Kahyangan.',
      ),
      (
        era: 'TAHUN 1910 — LAHIRNYA GEDUNG WAYANG ORANG',
        title: 'Panggung Wayang Orang Paling Legendaris',
        desc:
            'Kelompok kesenian Wayang Orang Sriwedari mulai menggelar pertunjukan rutin setiap malam. Para seniman keraton membawa tradisi tari beksan keluar dari tembok istana untuk dinikmati seluruh masyarakat.',
      ),
      (
        era: 'ERA MODERN & DIGITALISASI',
        title: 'Galeri Sriwedari: Arsip Budaya & Sewa Busana',
        desc:
            'Melalui aplikasi Galeri Sriwedari, seluruh dokumentasi panggung, filosofi tari, koleksi busana adat, dan pemesanan tiket terhubung dalam satu ekosistem terpadu untuk menjaga nyala api kebudayaan Surakarta.',
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
                FadeSlideEntrance(
                  index: 0,
                  onceKey: 'about_history_hero',
                  slideOffset: 12,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGreenGradient,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SwStatusBadge(
                          label: 'Kronik Sejarah Keraton',
                          tone: SwBadgeTone.gold,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Sejarah Panjang Taman Sriwedari (1899 – Sekarang)',
                          style: AppTypography.headlineLg(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Menelusuri jejak Sri Susuhunan Pakubuwana X dalam mendirikan pusat kebudayaan rakyat dan gedung pertunjukan Wayang Orang tertua di Nusantara.',
                          style: AppTypography.bodyMd(
                            color: AppColors.canvas.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SwImage(
                  source: '/images/tari-jawa-dramatic-stage.png',
                  width: double.infinity,
                  height: width >= 600 ? 280 : 200,
                  borderRadius: AppSpacing.radiusCard,
                ),
                const SizedBox(height: 18),
                ...milestones.asMap().entries.map(
                  (entry) => FadeSlideEntrance(
                    index: entry.key + 1,
                    onceKey: 'about_history_${entry.key}',
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SwCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value.era,
                              style: AppTypography.labelSm(
                                color: AppColors.brandGreen,
                              ).copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(entry.value.title, style: AppTypography.headlineMd()),
                            const SizedBox(height: 6),
                            Text(
                              entry.value.desc,
                              style: AppTypography.bodyMd(
                                color: AppColors.textMuted,
                              ).copyWith(height: 1.55),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SwButton(
                        label: 'Dewan Kurator',
                        variant: SwButtonVariant.secondary,
                        fullWidth: true,
                        onPressed: () => context.push(AppRoutes.aboutCurators),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SwButton(
                        label: 'Jadwal Pagelaran',
                        variant: SwButtonVariant.gold,
                        fullWidth: true,
                        onPressed: () => context.go(AppRoutes.userSchedule),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

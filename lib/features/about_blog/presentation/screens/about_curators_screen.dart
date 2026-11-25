import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/core_widgets.dart';

class AboutCuratorsScreen extends StatelessWidget {
  const AboutCuratorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);

    const curators = [
      (
        name: 'K.R.M. Sasangka Hadiningrat',
        role: 'Kurator Utama & Pengawas Pakem Keraton',
        origin: 'Keraton Surakarta Hadiningrat',
        bio:
            'Mengabdi lebih dari 35 tahun dalam pelestarian tari Bedhaya, Srimpi, dan tata busana adat pusaka keraton Surakarta.',
        initial: 'K',
        badge: 'Senior Kurator',
      ),
      (
        name: 'Dra. Nyi Ayu Condrowati',
        role: 'Kurator Kostum & Tekstil Batik Kuno',
        origin: 'Paguyuban Busana Sriwedari',
        bio:
            'Pakar konservasi kain dodot ageng, prada emas, dan pemeliharaan mahkota omprok kuningan tari tradisional.',
        initial: 'D',
        badge: 'Konservasi Kain',
      ),
      (
        name: 'Ki Anom Sutrisno',
        role: 'Sutradara & Pengarah Musik Gamelan',
        origin: 'Gedung Wayang Orang Sriwedari',
        bio:
            'Memimpin aransemen gending gamelan kyai pelog-salendro dan pelatihan koreografi wayang orang lintas generasi.',
        initial: 'A',
        badge: 'Maestro Gamelan',
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
                  onceKey: 'about_curators_hero',
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
                          label: 'Dewan Kurator & Pengampu Budaya',
                          tone: SwBadgeTone.gold,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Para Penjaga Warisan Luhur Sriwedari',
                          style: AppTypography.headlineLg(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Mengenal para empu, kurator seni, dan maestro yang menjaga keaslian pakem kesenian tari dan wayang orang.',
                          style: AppTypography.bodyMd(
                            color: AppColors.canvas.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ...curators.asMap().entries.map(
                  (entry) {
                    final c = entry.value;
                    return FadeSlideEntrance(
                      index: entry.key + 1,
                      onceKey: 'about_curator_${entry.key}',
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SwCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.brandGreen,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.gold.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Text(
                                      c.initial,
                                      style: AppTypography.headlineMd(
                                        color: AppColors.goldLight,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              c.name,
                                              style:
                                                  AppTypography.cardTitleSerif(),
                                            ),
                                            SwStatusBadge(
                                              label: c.badge,
                                              tone: SwBadgeTone.gold,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          c.role,
                                          style: AppTypography.labelMd(
                                            color: AppColors.brandGreen,
                                          ),
                                        ),
                                        Text(
                                          c.origin,
                                          style: AppTypography.labelSm(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 10),
                              Text(
                                c.bio,
                                style: AppTypography.bodyMd(
                                  color: AppColors.textMuted,
                                ).copyWith(height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                SwButton(
                  label: 'Buka Formulir Sewa Busana',
                  variant: SwButtonVariant.gold,
                  trailingIcon: Icons.arrow_forward_rounded,
                  fullWidth: true,
                  onPressed: () => context.push(AppRoutes.userBooking),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

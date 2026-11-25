import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/core_widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);

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
                  onceKey: 'about_hero_banner',
                  slideOffset: 12,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGreenGradient,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SwStatusBadge(
                          label: 'Sejarah & Warisan Luhur',
                          tone: SwBadgeTone.gold,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Menjaga Napas Kebudayaan Keraton Surakarta',
                          style: AppTypography.headlineLg(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Galeri Sriwedari adalah pusat digitalisasi dan pelestarian karya seni tari tradisional, busana adat pementasan, dan denyut panggung Wayang Orang Sriwedari sejak masa Sri Susuhunan Pakubuwana X.',
                          style: AppTypography.bodyMd(
                            color: AppColors.canvas.withValues(alpha: 0.85),
                          ).copyWith(height: 1.55),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            SwButton(
                              label: 'Sejarah 1899',
                              variant: SwButtonVariant.gold,
                              leadingIcon: Icons.history_edu_outlined,
                              height: 40,
                              onPressed: () =>
                                  context.push(AppRoutes.aboutHistory),
                            ),
                            SwButton(
                              label: 'Dewan Kurator',
                              variant: SwButtonVariant.secondary,
                              leadingIcon: Icons.groups_outlined,
                              height: 40,
                              onPressed: () =>
                                  context.push(AppRoutes.aboutCurators),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  '3 Pilar Pelestarian Budaya',
                  style: AppTypography.headlineMd(),
                ),
                const SizedBox(height: 12),
                FadeSlideEntrance(
                  index: 1,
                  onceKey: 'about_pillar_1',
                  child: _PillarCard(
                    icon: Icons.history_edu_rounded,
                    title: 'Didirikan Sejak 1899',
                    description:
                        'Taman Sriwedari dibangun sebagai taman rekreasi dan kebudayaan rakyat oleh Pakubuwana X, menghidupkan tradisi wayang orang setiap malam.',
                    onTap: () => context.push(AppRoutes.aboutHistory),
                  ),
                ),
                const SizedBox(height: 10),
                FadeSlideEntrance(
                  index: 2,
                  onceKey: 'about_pillar_2',
                  child: _PillarCard(
                    icon: Icons.checkroom_rounded,
                    title: 'Busana Pakem Adat',
                    description:
                        'Merawat ratusan koleksi busana panggung, mahkota omprok, topeng kayu, hingga dodot keraton asli dengan standar kurasi ketat.',
                    onTap: () => context.go(AppRoutes.userCostumes),
                  ),
                ),
                const SizedBox(height: 10),
                FadeSlideEntrance(
                  index: 3,
                  onceKey: 'about_pillar_3',
                  child: _PillarCard(
                    icon: Icons.diversity_3_rounded,
                    title: 'Regenerasi Seniman',
                    description:
                        'Mewadahi generasi muda dan sanggar tari Nusantara untuk terus berkarya, menyewa busana, dan mementaskan lakon budaya adiluhung.',
                    onTap: () => context.push(AppRoutes.aboutCurators),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreenDark,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gedung Wayang Orang & Galeri Pusaka',
                        style: AppTypography.headlineMd(
                          color: AppColors.goldLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Jl. Brigjend Slamet Riyadi No. 275, Sriwedari, Laweyan, Surakarta. Jam buka loket & galeri: 08.00 – 22.00 WIB.',
                        style: AppTypography.bodyMd(
                          color: AppColors.canvas.withValues(alpha: 0.82),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SwButton(
                        label: 'Lihat Jadwal Pentas Wayang',
                        variant: SwButtonVariant.gold,
                        trailingIcon: Icons.calendar_month_rounded,
                        fullWidth: true,
                        onPressed: () => context.go(AppRoutes.userSchedule),
                      ),
                    ],
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

class _PillarCard extends StatelessWidget {
  const _PillarCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SwCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.metricMint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.brandGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: AppTypography.titleMd()),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.brandGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodyMd(color: AppColors.textSubtle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

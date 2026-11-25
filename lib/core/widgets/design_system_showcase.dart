import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:material_ui/material_ui.dart';
import '../config/app_config.dart';
import '../providers/core_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/currency_formatter.dart';
import 'core_widgets.dart';

class DesignSystemShowcaseScreen extends ConsumerStatefulWidget {
  const DesignSystemShowcaseScreen({super.key});

  @override
  ConsumerState<DesignSystemShowcaseScreen> createState() =>
      _DesignSystemShowcaseScreenState();
}

class _DesignSystemShowcaseScreenState
    extends ConsumerState<DesignSystemShowcaseScreen> {
  String _selectedFilter = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final width = MediaQuery.sizeOf(context).width;
    final horizontalMargin = ResponsiveHelper.horizontalMarginForWidth(width);
    final metricCols = ResponsiveHelper.adminMetricColumnsForWidth(width);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              AppConstants.heritageLogoAsset,
              width: 28,
              height: 28,
              errorBuilder: (_, _, _) => const Icon(
                Icons.account_balance_rounded,
                color: AppColors.gold,
              ),
            ),
            const Gap(10),
            const Expanded(
              child: Text(
                'Galeri Sriwedari — Fase 1',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: SwStatusBadge(
                label: config.flavor.name.toUpperCase(),
                tone: SwBadgeTone.gold,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalMargin,
              vertical: AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xxl),
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
                      Text(
                        'Nusantara Heritage Elegance',
                        style: AppTypography.displayLg(color: AppColors.goldLight),
                      ),
                      const Gap(8),
                      Text(
                        'Fondasi Design System, Dual Local Storage (User & Admin terpisah), dan API Client (${config.baseUrl}) siap untuk Fase 2.',
                        style: AppTypography.bodyLg(
                          color: AppColors.canvas.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(24),
                Text('Metrik Admin (Pastel Tones)', style: AppTypography.headlineMd()),
                const Gap(12),
                GridView(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: metricCols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 118,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    SwMetricCard(
                      label: 'Total Galeri',
                      value: '9',
                      icon: Icons.photo_library_outlined,
                      tone: SwMetricTone.mint,
                    ),
                    SwMetricCard(
                      label: 'Total Pengguna',
                      value: '3',
                      icon: Icons.people_outline_rounded,
                      tone: SwMetricTone.peach,
                    ),
                    SwMetricCard(
                      label: 'Pesanan Masuk',
                      value: '2',
                      icon: Icons.shopping_bag_outlined,
                      tone: SwMetricTone.lightPeach,
                    ),
                    SwMetricCard(
                      label: 'Kegiatan',
                      value: '2',
                      icon: Icons.event_available_outlined,
                      tone: SwMetricTone.lavender,
                    ),
                  ],
                ),
                const Gap(24),
                Text('Filter & Pencarian', style: AppTypography.headlineMd()),
                const Gap(12),
                SwSearchBar(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                ),
                const Gap(12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Semua', 'Tari Tradisional', 'Kostum', 'Video']
                      .map(
                        (label) => SwFilterChip(
                          label: label,
                          selected: _selectedFilter == label,
                          onTap: () => setState(() => _selectedFilter = label),
                        ),
                      )
                      .toList(),
                ),
                const Gap(24),
                Text('Tombol & Form Input', style: AppTypography.headlineMd()),
                const Gap(12),
                SwCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwInput(
                        controller: _emailController,
                        label: 'Email atau Nomor Telepon',
                        hint: 'contoh@email.com',
                        prefixIcon: Icons.email_outlined,
                      ),
                      const Gap(12),
                      const SwInput(
                        label: 'Kata Sandi',
                        hint: 'Masukkan kata sandi',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        enablePasswordToggle: true,
                      ),
                      const Gap(16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SwButton(
                            label: 'Masuk (Primary)',
                            leadingIcon: Icons.login_rounded,
                            onPressed: () {},
                          ),
                          SwButton(
                            label: 'Sewa Kostum (Gold)',
                            variant: SwButtonVariant.gold,
                            onPressed: () {},
                          ),
                          SwButton(
                            label: 'Batal (Secondary)',
                            variant: SwButtonVariant.secondary,
                            onPressed: () {},
                          ),
                          SwButton(
                            label: 'Keluar (Modal)',
                            variant: SwButtonVariant.destructive,
                            leadingIcon: Icons.logout_rounded,
                            onPressed: () {
                              SwConfirmDialog.showLogoutModal(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(24),
                Text('Kartu Karya & Status', style: AppTypography.headlineMd()),
                const Gap(12),
                SwCard(
                  child: Row(
                    children: [
                      const SwImage(
                        source: '/images/tari-gandrung-banyuwangi.png',
                        width: 84,
                        height: 84,
                      ),
                      const Gap(14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kostum Lengkap Gandrung Omprok',
                              style: AppTypography.cardTitleSerif(),
                            ),
                            const Gap(4),
                            Text(
                              '${CurrencyFormatter.formatRupiah(300000)} / hari',
                              style: AppTypography.priceText(),
                            ),
                            const Gap(8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                SwStatusBadge.fromOrderStatus('Dikonfirmasi'),
                                SwStatusBadge.fromOrderStatus('Grade A'),
                                SwStatusBadge.fromRole('admin'),
                              ],
                            ),
                          ],
                        ),
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

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/user_models.dart';
import '../providers/user_catalog_providers.dart';
import '../widgets/costume_rental_sheet.dart';
import '../widgets/review_section.dart';

class CostumeDetailScreen extends ConsumerWidget {
  const CostumeDetailScreen({super.key, required this.costumeId});

  final String costumeId;

  Future<void> _shareCostume(
    BuildContext context,
    UserCostumeModel costume,
  ) async {
    final text =
        '${costume.name} (${CurrencyFormatter.formatRupiah(costume.price)}/hari) — Sewa Busana Adat Galeri Sriwedari';
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Info busana disalin ke papan klip.')),
        );
      }
    }
  }

  Future<void> _toggleWishlist(
    BuildContext context,
    WidgetRef ref,
    UserCostumeModel costume,
  ) async {
    final auth = ref.read(authProvider);
    if (!auth.isUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masuk sebagai Pengguna untuk menyimpan ke Favorit.'),
        ),
      );
      return;
    }
    await ref.read(userWishlistProvider.notifier).toggleWishlist(
          targetId: costume.id,
          targetType: 'costume',
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final costumesAsync = ref.watch(userCostumesProvider);
    final wishlistAsync = ref.watch(userWishlistProvider);
    final config = ref.watch(appConfigProvider);
    final width = MediaQuery.sizeOf(context).width;
    final topInset = MediaQuery.paddingOf(context).top;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);

    return costumesAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.brandGreenDark,
          foregroundColor: AppColors.goldLight,
          title: Text(
            'Detail Busana Adat',
            style: AppTypography.titleMd(color: AppColors.goldLight),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.brandGreenDark,
          foregroundColor: AppColors.goldLight,
          title: Text(
            'Detail Busana Adat',
            style: AppTypography.titleMd(color: AppColors.goldLight),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: SwErrorView(
            message: err.toString(),
            onRetry: () => ref.read(userCostumesProvider.notifier).refresh(),
          ),
        ),
      ),
      data: (list) {
        final costume = list.where((c) => c.id == costumeId).firstOrNull;
        if (costume == null) {
          return Scaffold(
            backgroundColor: AppColors.canvas,
            appBar: AppBar(
              backgroundColor: AppColors.brandGreenDark,
              foregroundColor: AppColors.goldLight,
              title: Text(
                'Detail Busana Adat',
                style: AppTypography.titleMd(color: AppColors.goldLight),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: SwEmptyState(
                icon: Icons.checkroom_outlined,
                title: 'Busana Tidak Ditemukan',
                description: 'Busana dengan ID "$costumeId" tidak tersedia.',
                actionLabel: 'Kembali ke Katalog',
                onAction: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.userCostumes);
                  }
                },
              ),
            ),
          );
        }

        final isWishlisted = (wishlistAsync.value ?? const [])
            .any((w) => w.targetId == costume.id);
        final sizes =
            costume.sizes.isNotEmpty ? costume.sizes : const ['All Size'];
        final heroTag = resolveHeroTag(context, 'detail-cos-${costume.id}');
        final expandedHeroHeight = width >= 600
            ? (340.0 - topInset).clamp(240.0, 340.0)
            : 260.0;

        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: CustomScrollView(
                scrollCacheExtent: const ScrollCacheExtent.pixels(450),
                slivers: [
                  SliverAppBar(
                    expandedHeight: expandedHeroHeight,
                    pinned: true,
                    stretch: true,
                    automaticallyImplyLeading: false,
                    backgroundColor: AppColors.brandGreenDark,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 2,
                    leadingWidth: 64,
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
                      child: Center(
                        child: _CostumeFloatingAction(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Kembali',
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(AppRoutes.userCostumes);
                            }
                          },
                        ),
                      ),
                    ),
                    actions: [
                      _CostumeFloatingAction(
                        icon: isWishlisted
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        tooltip: 'Favorit',
                        iconColor: isWishlisted
                            ? AppColors.error
                            : AppColors.brandGreenDark,
                        onTap: () => _toggleWishlist(context, ref, costume),
                      ),
                      const SizedBox(width: 8),
                      _CostumeFloatingAction(
                        icon: Icons.share_outlined,
                        tooltip: 'Bagikan',
                        onTap: () => _shareCostume(context, costume),
                      ),
                      const SizedBox(width: 12),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
                      stretchModes: const [StretchMode.zoomBackground],
                      background: Hero(
                        tag: heroTag,
                        child: SwImage(
                          source: costume.image,
                          baseUrl: config.baseUrl,
                          width: double.infinity,
                          height: width >= 600 ? 340 : 260 + topInset,
                          borderRadius: 0,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: margin,
                      vertical: AppSpacing.xl,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              SwStatusBadge(
                                label: costume.category,
                                tone: SwBadgeTone.gold,
                              ),
                              SwStatusBadge(
                                label: costume.isAvailable
                                    ? 'Stok ${costume.stock} Set'
                                    : 'Stok Habis',
                                tone: costume.isAvailable
                                    ? SwBadgeTone.success
                                    : SwBadgeTone.error,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(costume.name, style: AppTypography.headlineLg()),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '${CurrencyFormatter.formatRupiah(costume.price)} / hari',
                                style: AppTypography.priceText(fontSize: 18),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.star_rounded,
                                color: AppColors.gold,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${costume.rating.toStringAsFixed(1)} (${costume.reviewCount} ulasan)',
                                style: AppTypography.labelMd(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FadeSlideEntrance(
                            index: 0,
                            onceKey: 'cos_detail_body_${costume.id}',
                            slideOffset: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  costume.description,
                                  style: AppTypography.bodyLg().copyWith(
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                SwCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ukuran Tersedia & Kelengkapan',
                                        style: AppTypography.titleMd(),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: sizes.map((s) {
                                          final stock = costume.sizeStocks[s];
                                          return SwStatusBadge(
                                            label: stock != null
                                                ? '$s ($stock set)'
                                                : s,
                                            tone: SwBadgeTone.neutral,
                                          );
                                        }).toList(),
                                      ),
                                      if (costume.origin.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          'Asal Pakem Daerah: ${costume.origin}',
                                          style: AppTypography.bodyMd(
                                            color: AppColors.textSubtle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ReviewSection(
                            targetId: costume.id,
                            targetType: 'costume',
                            targetTitle: costume.name,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.parchment,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: SwButton(
                label: costume.isAvailable
                    ? 'Pilih Ukuran & Sewa Sekarang'
                    : 'Stok Busana Sedang Kosong',
                leadingIcon: Icons.checkroom_outlined,
                fullWidth: true,
                onPressed: costume.isAvailable
                    ? () => CostumeRentalSheet.show(context, costume: costume)
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CostumeFloatingAction extends StatelessWidget {
  const _CostumeFloatingAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconColor = AppColors.brandGreenDark,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      pressedScale: 0.9,
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        elevation: 2,
        child: IconButton(
          onPressed: onTap,
          tooltip: tooltip,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              icon,
              key: ValueKey(icon),
              color: iconColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

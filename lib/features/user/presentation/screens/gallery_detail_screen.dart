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
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/user_models.dart';
import '../providers/user_catalog_providers.dart';
import '../widgets/heritage_audio_player.dart';
import '../widgets/review_section.dart';

class GalleryDetailScreen extends ConsumerWidget {
  const GalleryDetailScreen({super.key, required this.galleryId});

  final String galleryId;

  Future<void> _shareGallery(
    BuildContext context,
    UserGalleryModel item,
  ) async {
    final text =
        '${item.title} (${item.origin}) — Arsip Budaya Galeri Sriwedari';
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tautan karya disalin ke papan klip.')),
        );
      }
    }
  }

  Future<void> _toggleWishlist(
    BuildContext context,
    WidgetRef ref,
    UserGalleryModel item,
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
          targetId: item.id,
          targetType: 'gallery',
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleriesAsync = ref.watch(userGalleriesProvider);
    final wishlistAsync = ref.watch(userWishlistProvider);
    final config = ref.watch(appConfigProvider);
    final width = MediaQuery.sizeOf(context).width;
    final topInset = MediaQuery.paddingOf(context).top;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);

    return galleriesAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.brandGreenDark,
          foregroundColor: AppColors.goldLight,
          title: Text(
            'Detail Karya Galeri',
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
            'Detail Karya Galeri',
            style: AppTypography.titleMd(color: AppColors.goldLight),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: SwErrorView(
            message: err.toString(),
            onRetry: () => ref.read(userGalleriesProvider.notifier).refresh(),
          ),
        ),
      ),
      data: (list) {
        final item = list.where((g) => g.id == galleryId).firstOrNull;
        if (item == null) {
          return Scaffold(
            backgroundColor: AppColors.canvas,
            appBar: AppBar(
              backgroundColor: AppColors.brandGreenDark,
              foregroundColor: AppColors.goldLight,
              title: Text(
                'Detail Karya Galeri',
                style: AppTypography.titleMd(color: AppColors.goldLight),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: SwEmptyState(
                icon: Icons.image_not_supported_outlined,
                title: 'Karya Tidak Ditemukan',
                description:
                    'Arsip karya seni dengan ID "$galleryId" tidak tersedia.',
                actionLabel: 'Kembali ke Galeri',
                onAction: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.userGallery);
                  }
                },
              ),
            ),
          );
        }

        final isWishlisted = (wishlistAsync.value ?? const [])
            .any((w) => w.targetId == item.id);
        final heroTag = resolveHeroTag(context, 'detail-gal-${item.id}');
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
                        child: _FloatingCircleButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Kembali',
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(AppRoutes.userGallery);
                            }
                          },
                        ),
                      ),
                    ),
                    actions: [
                      _FloatingCircleButton(
                        icon: isWishlisted
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        tooltip: 'Favorit',
                        iconColor: isWishlisted
                            ? AppColors.goldDark
                            : AppColors.brandGreenDark,
                        onTap: () => _toggleWishlist(context, ref, item),
                      ),
                      const SizedBox(width: 8),
                      _FloatingCircleButton(
                        icon: Icons.share_outlined,
                        tooltip: 'Bagikan',
                        onTap: () => _shareGallery(context, item),
                      ),
                      const SizedBox(width: 12),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
                      stretchModes: const [StretchMode.zoomBackground],
                      background: Hero(
                        tag: heroTag,
                        child: SwImage(
                          source: item.image,
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: AppTypography.headlineLg(),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.isVideo ? "Video" : "Foto"} • ${DateFormatter.formatShortDate(item.date)}',
                                      style: AppTypography.bodyMd(
                                        color: AppColors.textSubtle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              ScaleOnTap(
                                pressedScale: 0.92,
                                child: InkWell(
                                  onTap: () => ref
                                      .read(userGalleriesProvider.notifier)
                                      .toggleLike(item.id),
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOutCubic,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.isLiked
                                          ? AppColors.errorContainer
                                          : AppColors.parchment,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: item.isLiked
                                            ? AppColors.error
                                            : AppColors.divider,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 180),
                                          transitionBuilder: (child, anim) =>
                                              ScaleTransition(
                                            scale: anim,
                                            child: child,
                                          ),
                                          child: Icon(
                                            item.isLiked
                                                ? Icons.favorite_rounded
                                                : Icons.favorite_border_rounded,
                                            key: ValueKey(item.isLiked),
                                            size: 18,
                                            color: item.isLiked
                                                ? AppColors.error
                                                : AppColors.brandGreen,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${item.likes}',
                                          style: AppTypography.labelMd(
                                            color: item.isLiked
                                                ? AppColors.error
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FadeSlideEntrance(
                            index: 0,
                            onceKey: 'gal_detail_body_${item.id}',
                            slideOffset: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.description,
                                  style: AppTypography.bodyLg(
                                    color: AppColors.textPrimary,
                                  ).copyWith(height: 1.6),
                                ),
                                const SizedBox(height: 18),
                                const HeritageAudioPlayer(),
                                const SizedBox(height: 18),
                                SwCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Informasi Galeri',
                                        style: AppTypography.titleMd(),
                                      ),
                                      const SizedBox(height: 12),
                                      _InfoRow(
                                        icon: Icons.sell_outlined,
                                        label: 'Kategori',
                                        value: item.categoryName,
                                      ),
                                      const SizedBox(height: 10),
                                      _InfoRow(
                                        icon: Icons.location_on_outlined,
                                        label: 'Asal / Lokasi',
                                        value: item.origin.isNotEmpty
                                            ? item.origin
                                            : 'Galeri Sriwedari Surakarta',
                                      ),
                                      const SizedBox(height: 10),
                                      _InfoRow(
                                        icon: Icons.calendar_today_outlined,
                                        label: 'Tanggal Arsip',
                                        value: DateFormatter.formatFullDate(
                                          item.date,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ReviewSection(
                            targetId: item.id,
                            targetType: 'gallery',
                            targetTitle: item.title,
                          ),
                          const SizedBox(height: 24),
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
                border: Border(
                  top: BorderSide(color: AppColors.cardBorder),
                ),
              ),
              child: Row(
                children: [
                  if (item.costumeId != null)
                    Expanded(
                      child: SwButton(
                        label: 'Sewa Kostum Terkait',
                        leadingIcon: Icons.checkroom_outlined,
                        fullWidth: true,
                        onPressed: () => context.push(
                          '${AppRoutes.userBooking}?costumeId=${Uri.encodeComponent(item.costumeId!)}',
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: SwButton(
                        label: 'Lihat Katalog Kostum',
                        leadingIcon: Icons.checkroom_outlined,
                        fullWidth: true,
                        onPressed: () => context.go(AppRoutes.userCostumes),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FloatingCircleButton extends StatelessWidget {
  const _FloatingCircleButton({
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
        color: Colors.white.withValues(alpha: 0.9),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.brandGreen),
        const SizedBox(width: 10),
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: AppTypography.bodyMd(color: AppColors.textSubtle),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.labelMd(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

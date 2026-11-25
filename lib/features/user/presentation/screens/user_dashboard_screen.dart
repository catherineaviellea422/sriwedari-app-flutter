import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/user_models.dart';
import '../providers/user_catalog_providers.dart';
import '../widgets/theater_seat_map_sheet.dart';

class UserDashboardScreen extends ConsumerStatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  ConsumerState<UserDashboardScreen> createState() =>
      _UserDashboardScreenState();
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      context.go(AppRoutes.userGallery);
    } else {
      context.go('${AppRoutes.userGallery}?q=${Uri.encodeComponent(trimmed)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final galleriesAsync = ref.watch(userGalleriesProvider);
    final eventsAsync = ref.watch(userEventsProvider);
    final wishlistAsync = ref.watch(userWishlistProvider);
    final config = ref.watch(appConfigProvider);
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);
    final gridCols = ResponsiveHelper.galleryColumnsForWidth(width);

    final firstName = auth.displayName.split(' ').first;
    final points = auth.userAccount?.points ?? 0;
    final hPad = centeredSliverHorizontalPadding(
      width,
      horizontalMargin: margin,
      maxContentWidth: AppSpacing.maxContentWidth,
    );

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(userGalleriesProvider.notifier).refresh();
        ref.invalidate(userEventsProvider);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        scrollCacheExtent: const ScrollCacheExtent.pixels(600),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, AppSpacing.xl, hPad, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Greeting Header
                  FadeSlideEntrance(
                    index: 0,
                    onceKey: 'dash_greeting',
                    slideOffset: 10,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, $firstName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.headlineLg(),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Selamat datang di Galeri Sriwedari',
                                style: AppTypography.bodyMd(
                                  color: AppColors.textSubtle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (auth.isUser)
                          SwStatusBadge(
                            label: '$points Poin Budaya',
                            tone: SwBadgeTone.gold,
                            icon: Icons.auto_awesome_rounded,
                          )
                        else
                          SwButton(
                            label: 'Masuk',
                            variant: SwButtonVariant.secondary,
                            height: 38,
                            onPressed: () => context.go(AppRoutes.login),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SwSearchBar(
                    controller: _searchController,
                    hint: 'Cari galeri, tari daerah, atau kostum...',
                    onSubmitted: _submitSearch,
                  ),
                  const SizedBox(height: 18),

                  // Hero Banner
                  FadeSlideEntrance(
                    index: 1,
                    onceKey: 'dash_hero_banner',
                    slideOffset: 12,
                    child: _HeroBanner(
                      onExploreTap: () => context.go(AppRoutes.userGallery),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Quick Menu 4 Columns (Pintasan Eksklusif di Luar Bottom Nav)
                  Text('Akses Cepat', style: AppTypography.headlineMd()),
                  const SizedBox(height: 12),
                  const FadeSlideEntrance(
                    index: 2,
                    onceKey: 'dash_quick_menu',
                    child: _QuickMenuGrid(),
                  ),
                  const SizedBox(height: 24),

                  // Galeri Terbaru
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Galeri Terbaru',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headlineMd(),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.go(AppRoutes.userGallery),
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.brandGreen,
                        ),
                        iconAlignment: IconAlignment.end,
                        label: Text(
                          'Lihat Semua',
                          style: AppTypography.labelMd(
                            color: AppColors.brandGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          galleriesAsync.when(
            loading: () => SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridCols,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 220,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, _) => const SwCardSkeleton(),
                  childCount: gridCols * 2,
                ),
              ),
            ),
            error: (err, _) => SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              sliver: SliverToBoxAdapter(
                child: SwErrorView(
                  message: err.toString(),
                  onRetry: () =>
                      ref.read(userGalleriesProvider.notifier).refresh(),
                ),
              ),
            ),
            data: (galleries) {
              final featured = galleries.take(gridCols * 2).toList();
              final savedIds = (wishlistAsync.value ?? const [])
                  .map((w) => w.targetId)
                  .toSet();
              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridCols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 238,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = featured[index];
                      final heroTag = 'dash-gal-${item.id}';
                      return RepaintBoundary(
                        child: FadeSlideEntrance(
                          index: index,
                          onceKey: 'dash_gal_${item.id}',
                          child: _DashboardGalleryCard(
                            item: item,
                            baseUrl: config.baseUrl,
                            heroTag: heroTag,
                            isWishlisted: savedIds.contains(item.id),
                            onTap: () => context.push(
                              '${AppRoutes.galleryDetailPath(item.id)}?heroTag=${Uri.encodeComponent(heroTag)}',
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: featured.length,
                  ),
                ),
              );
            },
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, 24, hPad, AppSpacing.xl),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sorotan Pagelaran Terdekat
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Pagelaran Terdekat',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headlineMd(),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.userSchedule),
                        child: Text(
                          'Semua Jadwal',
                          style: AppTypography.labelMd(
                            color: AppColors.brandGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SwContentSwitcher(
                    child: eventsAsync.when(
                      loading: () => const SwLoadingSkeleton(
                        key: ValueKey('dash_evt_loading'),
                        height: 92,
                      ),
                      error: (err, _) => SwErrorView(
                        key: const ValueKey('dash_evt_error'),
                        message: err.toString(),
                        onRetry: () => ref.invalidate(userEventsProvider),
                      ),
                      data: (events) {
                        if (events.isEmpty) {
                          return const SwEmptyState(
                            key: ValueKey('dash_evt_empty'),
                            title: 'Belum Ada Jadwal',
                            description:
                                'Jadwal pagelaran Wayang Orang akan segera diumumkan.',
                          );
                        }
                        return Column(
                          key: ValueKey('dash_evt_${events.length}'),
                          children: events
                              .take(2)
                              .toList()
                              .asMap()
                              .entries
                              .map(
                                (entry) => RepaintBoundary(
                                  child: FadeSlideEntrance(
                                    index: entry.key,
                                    onceKey: 'dash_evt_${entry.value.id}',
                                    child: _UpcomingEventCard(
                                      event: entry.value,
                                      onTap: () => TheaterSeatMapSheet.show(
                                        context,
                                        event: entry.value,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onExploreTap});

  final VoidCallback onExploreTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.heroGreenGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'WARISAN KERATON SURAKARTA',
                    style: AppTypography.labelSm(color: AppColors.goldLight)
                        .copyWith(fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Lestarikan Budaya Melalui Seni Tari',
                  style: AppTypography.headlineLg(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Jelajahi arsip tari adiluhung, sewa busana panggung, dan pesan tiket Wayang Orang.',
                  style: AppTypography.bodyMd(
                    color: AppColors.canvas.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 14),
                SwButton(
                  label: 'Jelajahi Galeri',
                  variant: SwButtonVariant.gold,
                  trailingIcon: Icons.arrow_forward_rounded,
                  height: 40,
                  onPressed: onExploreTap,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Flexible(
            flex: 2,
            child: SwImage(
              source: '/images/tari-gandrung-banyuwangi.png',
              height: 142,
              borderRadius: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickMenuGrid extends StatelessWidget {
  const _QuickMenuGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        label: 'Sewa Busana',
        icon: Icons.shopping_bag_outlined,
        route: AppRoutes.userBooking,
        bg: AppColors.metricMint,
        usePush: true,
      ),
      (
        label: 'Pentas Hari Ini',
        icon: Icons.today_outlined,
        route: AppRoutes.userScheduleToday,
        bg: AppColors.metricPeach,
        usePush: false,
      ),
      (
        label: 'Warta Budaya',
        icon: Icons.menu_book_outlined,
        route: AppRoutes.blog,
        bg: AppColors.metricLightPeach,
        usePush: false,
      ),
      (
        label: 'Sejarah 1899',
        icon: Icons.history_edu_outlined,
        route: AppRoutes.aboutHistory,
        bg: AppColors.metricLavender,
        usePush: false,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 108,
      ),
      itemBuilder: (context, idx) {
        final item = items[idx];
        return SwCard(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          onTap: () {
            if (item.usePush) {
              context.push(item.route);
            } else {
              context.go(item.route);
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: item.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 20, color: AppColors.brandGreen),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSm(color: AppColors.textPrimary)
                      .copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardGalleryCard extends StatelessWidget {
  const _DashboardGalleryCard({
    required this.item,
    required this.baseUrl,
    required this.heroTag,
    required this.isWishlisted,
    required this.onTap,
  });

  final UserGalleryModel item;
  final String baseUrl;
  final String heroTag;
  final bool isWishlisted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SwCard(
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Hero(
                tag: heroTag,
                child: SwImage(
                  source: item.image,
                  baseUrl: baseUrl,
                  width: double.infinity,
                  height: 118,
                  borderRadius: 10,
                ),
              ),
              if (isWishlisted)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 14,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.cardTitleSerif(),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.isVideo ? "Video" : "Foto"} • ${DateFormatter.formatShortDate(item.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSm(),
                ),
              ),
              const Icon(
                Icons.favorite_border_rounded,
                size: 13,
                color: AppColors.textSubtle,
              ),
              const SizedBox(width: 3),
              Text('${item.likes}', style: AppTypography.labelSm()),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingEventCard extends StatelessWidget {
  const _UpcomingEventCard({
    required this.event,
    required this.onTap,
  });

  final UserEventModel event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badge = DateFormatter.splitBadgeDate(event.date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SwCard(
        padding: const EdgeInsets.all(12),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 54,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    badge.day,
                    style: AppTypography.metricNumber(
                      fontSize: 18,
                      color: AppColors.brandGreen,
                    ),
                  ),
                  Text(
                    badge.month.toUpperCase(),
                    style: AppTypography.labelSm(color: AppColors.textMuted)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMd(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${event.time} • ${event.location}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMd(color: AppColors.textSubtle),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.formatRupiah(event.price),
                  style: AppTypography.priceText(fontSize: 13),
                ),
                const SizedBox(height: 4),
                SwStatusBadge(
                  label: 'Sisa ${event.remainingQuota}',
                  tone: SwBadgeTone.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

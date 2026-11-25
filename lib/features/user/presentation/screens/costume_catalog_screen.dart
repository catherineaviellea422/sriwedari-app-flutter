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
import '../../../../core/widgets/core_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/user_models.dart';
import '../providers/user_catalog_providers.dart';
import '../widgets/costume_rental_sheet.dart';

class CostumeCatalogScreen extends ConsumerStatefulWidget {
  const CostumeCatalogScreen({super.key});

  @override
  ConsumerState<CostumeCatalogScreen> createState() =>
      _CostumeCatalogScreenState();
}

class _CostumeCatalogScreenState extends ConsumerState<CostumeCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleWishlist(UserCostumeModel costume) async {
    final auth = ref.read(authProvider);
    if (!auth.isUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masuk sebagai Pengguna untuk menyimpan favorit.'),
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
  Widget build(BuildContext context) {
    final costumesAsync = ref.watch(userCostumesProvider);
    final wishlistAsync = ref.watch(userWishlistProvider);
    final config = ref.watch(appConfigProvider);
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);
    final cols = ResponsiveHelper.galleryColumnsForWidth(width);

    final query = _searchController.text.trim().toLowerCase();
    final savedIds =
        (wishlistAsync.value ?? const []).map((w) => w.targetId).toSet();
    final hPad = centeredSliverHorizontalPadding(
      width,
      horizontalMargin: margin,
      maxContentWidth: AppSpacing.maxContentWidth,
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(userCostumesProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        scrollCacheExtent: const ScrollCacheExtent.pixels(650),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, AppSpacing.xl, hPad, 12),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kostum & Sewa',
                              style: AppTypography.headlineLg(),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Busana tari adat keraton terkurasi dengan standar pementasan',
                              style: AppTypography.bodyMd(
                                color: AppColors.textSubtle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            ref.read(userCostumesProvider.notifier).refresh(),
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.brandGreen,
                        ),
                        tooltip: 'Muat ulang katalog',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SwSearchBar(
                    controller: _searchController,
                    hint: 'Cari kostum tari atau daerah...',
                    onChanged: (_) => setState(() {}),
                    onClear: () => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
          ...costumesAsync.when(
            loading: () => [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 292,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, _) => const SwCardSkeleton(),
                    childCount: cols * 2,
                  ),
                ),
              ),
            ],
            error: (err, _) => [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                sliver: SliverToBoxAdapter(
                  child: SwContentSwitcher(
                    child: SwErrorView(
                      key: const ValueKey('cos_list_error'),
                      message: err.toString(),
                      onRetry: () =>
                          ref.read(userCostumesProvider.notifier).refresh(),
                    ),
                  ),
                ),
              ),
            ],
            data: (costumes) {
              final categories = <String>{
                'Semua',
                ...costumes.map((c) => c.category),
              }.toList();

              final filtered = costumes.where((c) {
                final matchesCat = _selectedCategory == 'Semua' ||
                    c.category == _selectedCategory;
                final matchesQuery = query.isEmpty ||
                    c.name.toLowerCase().contains(query) ||
                    c.category.toLowerCase().contains(query) ||
                    c.origin.toLowerCase().contains(query);
                return matchesCat && matchesQuery;
              }).toList();

              return [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 18),
                  sliver: SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories
                            .map(
                              (cat) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: SwFilterChip(
                                  label: cat,
                                  selected: _selectedCategory == cat,
                                  onTap: () =>
                                      setState(() => _selectedCategory = cat),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                    sliver: SliverToBoxAdapter(
                      child: SwContentSwitcher(
                        child: SwEmptyState(
                          key: ValueKey('cos_empty_$_selectedCategory-$query'),
                          icon: Icons.checkroom_outlined,
                          title: 'Busana Tidak Ditemukan',
                          description:
                              'Tidak ada kostum yang cocok dengan filter pencarian Anda.',
                          actionLabel: 'Reset Filter',
                          onAction: () {
                            _searchController.clear();
                            setState(() => _selectedCategory = 'Semua');
                          },
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                    sliver: SliverGrid(
                      key: ValueKey('cos_grid_$_selectedCategory-${filtered.length}'),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 292,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final costume = filtered[index];
                          final heroTag = 'list-cos-${costume.id}';
                          return RepaintBoundary(
                            child: FadeSlideEntrance(
                              key: ValueKey('list-cos-${costume.id}-$_selectedCategory'),
                              index: index,
                              onceKey: 'list_cos_${_selectedCategory}_${costume.id}',
                              child: _CostumeProductCard(
                                costume: costume,
                                baseUrl: config.baseUrl,
                                heroTag: heroTag,
                                isWishlisted: savedIds.contains(costume.id),
                                onTap: () => context.push(
                                  '${AppRoutes.costumeDetailPath(costume.id)}?heroTag=${Uri.encodeComponent(heroTag)}',
                                ),
                                onToggleWishlist: () =>
                                    _toggleWishlist(costume),
                                onRentTap: () => CostumeRentalSheet.show(
                                  context,
                                  costume: costume,
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

class _CostumeProductCard extends StatelessWidget {
  const _CostumeProductCard({
    required this.costume,
    required this.baseUrl,
    required this.heroTag,
    required this.isWishlisted,
    required this.onTap,
    required this.onToggleWishlist,
    required this.onRentTap,
  });

  final UserCostumeModel costume;
  final String baseUrl;
  final String heroTag;
  final bool isWishlisted;
  final VoidCallback onTap;
  final VoidCallback onToggleWishlist;
  final VoidCallback onRentTap;

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
                  source: costume.image,
                  baseUrl: baseUrl,
                  width: double.infinity,
                  height: 124,
                  borderRadius: 10,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: ScaleOnTap(
                  pressedScale: 0.9,
                  child: InkWell(
                    onTap: onToggleWishlist,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          isWishlisted
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          key: ValueKey(isWishlisted),
                          size: 16,
                          color:
                              isWishlisted ? AppColors.error : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        costume.rating.toStringAsFixed(1),
                        style: AppTypography.labelSm(
                          color: AppColors.textPrimary,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            costume.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.cardTitleSerif(),
          ),
          const SizedBox(height: 4),
          Text(
            '${CurrencyFormatter.formatRupiah(costume.price)} / hari',
            style: AppTypography.priceText(fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            costume.isAvailable
                ? 'Tersedia ${costume.stock} set'
                : 'Stok habis',
            style: AppTypography.labelSm(
              color: costume.isAvailable
                  ? AppColors.successText
                  : AppColors.error,
            ),
          ),
          const Spacer(),
          SwButton(
            label: costume.isAvailable ? 'Sewa' : 'Habis',
            height: 36,
            fullWidth: true,
            onPressed: costume.isAvailable ? onRentTap : null,
          ),
        ],
      ),
    );
  }
}

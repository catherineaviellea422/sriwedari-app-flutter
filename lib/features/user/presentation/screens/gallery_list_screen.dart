import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
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

class GalleryListScreen extends ConsumerStatefulWidget {
  const GalleryListScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<GalleryListScreen> createState() => _GalleryListScreenState();
}

class _GalleryListScreenState extends ConsumerState<GalleryListScreen> {
  late final TextEditingController _searchController;
  String _selectedCategory = 'Semua';
  String _selectedType = 'Semua'; // 'Semua' | 'foto' | 'video'

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
  }

  @override
  void didUpdateWidget(covariant GalleryListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery &&
        widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleWishlistToggle(UserGalleryModel item) async {
    final auth = ref.read(authProvider);
    if (!auth.isUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masuk sebagai Pengguna untuk menyimpan favorit.'),
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
  Widget build(BuildContext context) {
    final galleriesAsync = ref.watch(userGalleriesProvider);
    final categoriesAsync = ref.watch(userCategoriesProvider);
    final wishlistAsync = ref.watch(userWishlistProvider);
    final config = ref.watch(appConfigProvider);
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);
    final cols = ResponsiveHelper.galleryColumnsForWidth(width);

    final query = _searchController.text.trim().toLowerCase();
    final savedIds =
        (wishlistAsync.value ?? const []).map((w) => w.targetId).toSet();

    final categoryLabels = <String>['Semua'];
    final cats = categoriesAsync.value ?? const <UserCategoryModel>[];
    for (final c in cats) {
      if (!categoryLabels.contains(c.name)) {
        categoryLabels.add(c.name);
      }
    }
    final hPad = centeredSliverHorizontalPadding(
      width,
      horizontalMargin: margin,
      maxContentWidth: AppSpacing.maxContentWidth,
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(userGalleriesProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        scrollCacheExtent: const ScrollCacheExtent.pixels(650),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, AppSpacing.xl, hPad, 18),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Galeri Sriwedari', style: AppTypography.headlineLg()),
                  const SizedBox(height: 4),
                  Text(
                    'Arsip foto & video dokumentasi seni tari tradisional Nusantara',
                    style: AppTypography.bodyMd(color: AppColors.textSubtle),
                  ),
                  const SizedBox(height: 14),
                  SwSearchBar(
                    controller: _searchController,
                    hint: 'Cari judul tarian, daerah asal, atau deskripsi...',
                    onChanged: (_) => setState(() {}),
                    onClear: () => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...categoryLabels.map(
                          (cat) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SwFilterChip(
                              label: cat,
                              selected: _selectedCategory == cat,
                              onTap: () =>
                                  setState(() => _selectedCategory = cat),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SwFilterChip(
                          label: 'Foto',
                          icon: Icons.photo_outlined,
                          selected: _selectedType == 'foto',
                          onTap: () => setState(
                            () => _selectedType =
                                _selectedType == 'foto' ? 'Semua' : 'foto',
                          ),
                        ),
                        const SizedBox(width: 8),
                        SwFilterChip(
                          label: 'Video',
                          icon: Icons.videocam_outlined,
                          selected: _selectedType == 'video',
                          onTap: () => setState(
                            () => _selectedType =
                                _selectedType == 'video' ? 'Semua' : 'video',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          galleriesAsync.when(
            loading: () => SliverPadding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 256,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, _) => const SwCardSkeleton(),
                  childCount: cols * 2,
                ),
              ),
            ),
            error: (err, _) => SliverPadding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
              sliver: SliverToBoxAdapter(
                child: SwContentSwitcher(
                  child: SwErrorView(
                    key: const ValueKey('gal_list_error'),
                    message: err.toString(),
                    onRetry: () =>
                        ref.read(userGalleriesProvider.notifier).refresh(),
                  ),
                ),
              ),
            ),
            data: (items) {
              final filtered = items.where((item) {
                final matchesCat = _selectedCategory == 'Semua' ||
                    item.categoryName.toLowerCase() ==
                        _selectedCategory.toLowerCase();
                final matchesType = _selectedType == 'Semua' ||
                    item.type.toLowerCase() == _selectedType;
                final matchesQuery = query.isEmpty ||
                    item.title.toLowerCase().contains(query) ||
                    item.origin.toLowerCase().contains(query) ||
                    item.description.toLowerCase().contains(query);
                return matchesCat && matchesType && matchesQuery;
              }).toList();

              if (filtered.isEmpty) {
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                  sliver: SliverToBoxAdapter(
                    child: SwContentSwitcher(
                      child: SwEmptyState(
                        key: ValueKey('gal_empty_$_selectedCategory-$_selectedType-$query'),
                        icon: Icons.search_off_rounded,
                        title: 'Karya Tidak Ditemukan',
                        description:
                            'Coba ubah kata kunci pencarian atau pilih filter kategori lain.',
                        actionLabel: 'Reset Filter',
                        onAction: () {
                          _searchController.clear();
                          setState(() {
                            _selectedCategory = 'Semua';
                            _selectedType = 'Semua';
                          });
                        },
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                sliver: SliverGrid(
                  key: ValueKey('gal_grid_$_selectedCategory-$_selectedType-${filtered.length}'),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 256,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filtered[index];
                      final isFav = savedIds.contains(item.id);
                      final heroTag = 'list-gal-${item.id}';
                      return RepaintBoundary(
                        child: FadeSlideEntrance(
                          key: ValueKey('list-gal-${item.id}-$_selectedCategory-$_selectedType'),
                          index: index,
                          onceKey: 'list_gal_${_selectedCategory}_${_selectedType}_${item.id}',
                          child: _GalleryCatalogCard(
                            item: item,
                            baseUrl: config.baseUrl,
                            heroTag: heroTag,
                            isWishlisted: isFav,
                            onTap: () => context.push(
                              '${AppRoutes.galleryDetailPath(item.id)}?heroTag=${Uri.encodeComponent(heroTag)}',
                            ),
                            onToggleLike: () => ref
                                .read(userGalleriesProvider.notifier)
                                .toggleLike(item.id),
                            onToggleWishlist: () => _handleWishlistToggle(item),
                          ),
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GalleryCatalogCard extends StatelessWidget {
  const _GalleryCatalogCard({
    required this.item,
    required this.baseUrl,
    required this.heroTag,
    required this.isWishlisted,
    required this.onTap,
    required this.onToggleLike,
    required this.onToggleWishlist,
  });

  final UserGalleryModel item;
  final String baseUrl;
  final String heroTag;
  final bool isWishlisted;
  final VoidCallback onTap;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleWishlist;

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
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          key: ValueKey(isWishlisted),
                          size: 16,
                          color: isWishlisted ? AppColors.goldDark : AppColors.textMuted,
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
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreenDark.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.categoryName,
                    style: AppTypography.labelSm(color: AppColors.goldLight),
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
          const SizedBox(height: 3),
          Text(
            item.origin,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSm(),
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
              ScaleOnTap(
                pressedScale: 0.9,
                child: InkWell(
                  onTap: onToggleLike,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            item.isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey(item.isLiked),
                            size: 15,
                            color: item.isLiked ? AppColors.error : AppColors.textSubtle,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${item.likes}',
                          style: AppTypography.labelSm(
                            color: item.isLiked
                                ? AppColors.error
                                : AppColors.textSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

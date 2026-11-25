import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../data/blog_data.dart';

class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});

  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  String _selectedCategory = 'Semua';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);
    final categories = [
      'Semua',
      ...sriwedariBlogPosts.map((p) => p.category),
    ];

    final filtered = sriwedariBlogPosts.where((p) {
      return _selectedCategory == 'Semua' || p.category == _selectedCategory;
    }).toList();
    final hPad = centeredSliverHorizontalPadding(
      width,
      horizontalMargin: margin,
      maxContentWidth: AppSpacing.maxContentWidth,
    );

    return CustomScrollView(
      scrollCacheExtent: const ScrollCacheExtent.pixels(550),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(hPad, AppSpacing.xl, hPad, 18),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warta & Artikel Budaya',
                  style: AppTypography.headlineLg(),
                ),
                const SizedBox(height: 4),
                Text(
                  'Telaah filosofis seni tari klasik, anatomi busana, dan sejarah panggung Sriwedari',
                  style: AppTypography.bodyMd(color: AppColors.textSubtle),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories
                        .map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SwFilterChip(
                              label: c,
                              selected: _selectedCategory == c,
                              onTap: () =>
                                  setState(() => _selectedCategory = c),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = filtered[index];
                final heroTag = 'blog-${post.slug}';
                return RepaintBoundary(
                  child: FadeSlideEntrance(
                    key: ValueKey('blog_card_${post.slug}_$_selectedCategory'),
                    index: index,
                    onceKey: 'blog_${post.slug}_$_selectedCategory',
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: SwCard(
                        onTap: () => context.push(
                          '${AppRoutes.blogDetailPath(post.slug)}?heroTag=${Uri.encodeComponent(heroTag)}',
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Hero(
                              tag: heroTag,
                              child: SwImage(
                                source: post.image,
                                width: double.infinity,
                                height: width >= 600 ? 220 : 170,
                                borderRadius: 10,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                SwStatusBadge(
                                  label: post.category,
                                  tone: SwBadgeTone.gold,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${post.date} • ${post.readTime}',
                                  style: AppTypography.labelSm(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(post.title, style: AppTypography.headlineMd()),
                            const SizedBox(height: 6),
                            Text(
                              post.excerpt,
                              style: AppTypography.bodyMd(
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  'Baca Selengkapnya',
                                  style: AppTypography.labelMd(
                                    color: AppColors.brandGreen,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 15,
                                  color: AppColors.brandGreen,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: filtered.length,
            ),
          ),
        ),
      ],
    );
  }
}

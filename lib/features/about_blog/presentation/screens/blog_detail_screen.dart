import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../data/blog_data.dart';

class BlogDetailScreen extends StatelessWidget {
  const BlogDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final post = sriwedariBlogPosts.where((p) => p.slug == slug).firstOrNull;
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);

    if (post == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: SwEmptyState(
          icon: Icons.article_outlined,
          title: 'Artikel Tidak Ditemukan',
          description: 'Warta budaya dengan slug "$slug" tidak ditemukan.',
          actionLabel: 'Kembali ke Warta Budaya',
          onAction: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.blog);
            }
          },
        ),
      );
    }

    final heroTag = resolveHeroTag(context, 'blog-detail-${post.slug}');
    final hPad = centeredSliverHorizontalPadding(
      width,
      horizontalMargin: margin,
      maxContentWidth: AppSpacing.maxContentWidth,
    );

    return CustomScrollView(
      scrollCacheExtent: const ScrollCacheExtent.pixels(500),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: hPad,
            vertical: AppSpacing.xl,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwStatusBadge(label: post.category, tone: SwBadgeTone.gold),
                const SizedBox(height: 10),
                Text(post.title, style: AppTypography.headlineLg()),
                const SizedBox(height: 8),
                Text(
                  '${post.date} • ${post.readTime} baca • Tim Kurator Sriwedari',
                  style: AppTypography.labelSm(),
                ),
                const SizedBox(height: 14),
                Hero(
                  tag: heroTag,
                  child: SwImage(
                    source: post.image,
                    width: double.infinity,
                    height: width >= 600 ? 320 : 210,
                    borderRadius: AppSpacing.radiusCard,
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideEntrance(
                  index: 0,
                  onceKey: 'blog_detail_${post.slug}',
                  slideOffset: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          border: Border(
                            left: BorderSide(color: AppColors.gold, width: 3),
                          ),
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          '"${post.excerpt}"',
                          style: AppTypography.cardTitleSerif(
                            color: AppColors.textMuted,
                          ).copyWith(fontStyle: FontStyle.italic),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...post.paragraphs.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            p,
                            style: AppTypography.bodyLg().copyWith(height: 1.65),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SwCard(
                        backgroundColor: AppColors.surfaceContainerLow,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ingin menyewa busana ini?',
                              style: AppTypography.titleMd(),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tersedia untuk pementasan sanggar, festival, dan pemotretan budaya.',
                              style: AppTypography.bodyMd(
                                color: AppColors.textSubtle,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SwButton(
                              label: 'Reservasi Sewa Busana',
                              trailingIcon: Icons.arrow_forward_rounded,
                              fullWidth: true,
                              onPressed: () => context.push(AppRoutes.userBooking),
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
      ],
    );
  }
}

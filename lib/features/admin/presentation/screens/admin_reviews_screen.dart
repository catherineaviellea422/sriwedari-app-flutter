import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/models/admin_models.dart';
import '../providers/admin_providers.dart';

class AdminReviewsScreen extends ConsumerStatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  ConsumerState<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends ConsumerState<AdminReviewsScreen> {
  String _statusFilter = 'Semua';

  Future<void> _toggleStatus(AdminReviewModerationModel review) async {
    final nextStatus =
        review.status == 'disembunyikan' ? 'tampil' : 'disembunyikan';
    try {
      await ref.read(adminOperationsRepositoryProvider).updateReviewStatus(
            id: review.id,
            status: nextStatus,
          );
      await ref.read(adminReviewsProvider.notifier).refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _deleteReview(AdminReviewModerationModel review) async {
    final ok = await SwConfirmDialog.showDeleteModal(
      context,
      itemName: 'Ulasan ${review.userName}',
    );
    if (!ok || !mounted) return;
    try {
      await ref
          .read(adminOperationsRepositoryProvider)
          .deleteReview(review.id);
      await ref.read(adminReviewsProvider.notifier).refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(adminReviewsProvider);
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);
    final hPad = centeredSliverHorizontalPadding(
      width,
      horizontalMargin: margin,
      maxContentWidth: AppSpacing.maxContentWidth,
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(adminReviewsProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        scrollCacheExtent: const ScrollCacheExtent.pixels(600),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, AppSpacing.xl, hPad, 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Moderasi Ulasan Budaya',
                    style: AppTypography.headlineLg(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tinjau, sembunyikan sementara, atau hapus ulasan pengunjung galeri dan kostum',
                    style: AppTypography.bodyMd(color: AppColors.textSubtle),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ('Semua', 'Semua'),
                      ('tampil', 'Ditampilkan'),
                      ('disembunyikan', 'Disembunyikan'),
                    ].map((opt) {
                      return SwFilterChip(
                        label: opt.$2,
                        selected: _statusFilter == opt.$1,
                        onTap: () => setState(() => _statusFilter = opt.$1),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          ...reviewsAsync.when(
            loading: () => [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                sliver: const SliverToBoxAdapter(
                  child: SwContentSwitcher(
                    child: SwLoadingSkeleton(
                      key: ValueKey('adm_rev_loading'),
                      height: 140,
                    ),
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
                      key: const ValueKey('adm_rev_error'),
                      message: err.toString(),
                      onRetry: () =>
                          ref.read(adminReviewsProvider.notifier).refresh(),
                    ),
                  ),
                ),
              ),
            ],
            data: (reviews) {
              final filtered = reviews.where((r) {
                return _statusFilter == 'Semua' || r.status == _statusFilter;
              }).toList();

              if (filtered.isEmpty) {
                return [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                    sliver: SliverToBoxAdapter(
                      child: SwContentSwitcher(
                        child: SwEmptyState(
                          key: ValueKey('adm_rev_empty_$_statusFilter'),
                          icon: Icons.rate_review_outlined,
                          title: 'Belum Ada Ulasan',
                          description:
                              'Tidak ada ulasan pengunjung untuk filter status saat ini.',
                        ),
                      ),
                    ),
                  ),
                ];
              }

              return [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final r = filtered[index];
                        final hidden = r.status == 'disembunyikan';
                        return RepaintBoundary(
                          child: FadeSlideEntrance(
                            key: ValueKey('adm_rev_${r.id}_$_statusFilter'),
                            index: index,
                            onceKey: 'adm_rev_${r.id}_$_statusFilter',
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: SwCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${r.userName} • ★ ${r.rating}/5',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.titleMd(),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SwStatusBadge.fromOrderStatus(r.status),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Target: ${r.targetType.toUpperCase()} (${r.targetId}) • ${r.createdAt}',
                                      style: AppTypography.labelSm(),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      r.comment,
                                      style: AppTypography.bodyMd(),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        SwButton(
                                          label: hidden
                                              ? 'Tampilkan Kembali'
                                              : 'Sembunyikan',
                                          variant: SwButtonVariant.secondary,
                                          height: 34,
                                          onPressed: () => _toggleStatus(r),
                                        ),
                                        SwButton(
                                          label: 'Hapus',
                                          variant: SwButtonVariant.destructive,
                                          height: 34,
                                          onPressed: () => _deleteReview(r),
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
              ];
            },
          ),
        ],
      ),
    );
  }
}

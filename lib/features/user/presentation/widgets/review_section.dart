import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/user_models.dart';
import '../providers/user_catalog_providers.dart';

class ReviewSection extends ConsumerStatefulWidget {
  const ReviewSection({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.targetTitle,
  });

  final String targetId;
  final String targetType; // 'gallery' | 'costume'
  final String targetTitle;

  @override
  ConsumerState<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends ConsumerState<ReviewSection> {
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 5;
  bool _isSubmitting = false;
  String? _feedbackMessage;
  bool _isError = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      setState(() {
        _feedbackMessage = 'Tuliskan ulasan apresiasi Anda terlebih dahulu.';
        _isError = true;
      });
      return;
    }

    final auth = ref.read(authProvider);
    if (!auth.isUser) {
      setState(() {
        _feedbackMessage = 'Silakan masuk sebagai Pengguna untuk mengirim ulasan.';
        _isError = true;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _feedbackMessage = null;
      _isError = false;
    });

    try {
      await ref.read(userCatalogRepositoryProvider).submitReview(
            targetId: widget.targetId,
            targetType: widget.targetType,
            rating: _selectedRating,
            comment: comment,
          );
      _commentController.clear();
      ref.invalidate(targetReviewsProvider(widget.targetId));
      if (mounted) {
        setState(() {
          _feedbackMessage =
              'Matur nuwun! Ulasan apresiasi budaya Anda berhasil dipublikasikan.';
          _isError = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _feedbackMessage = e.message;
          _isError = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _feedbackMessage = 'Gagal mengirim ulasan. Coba lagi.';
          _isError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(targetReviewsProvider(widget.targetId));
    final auth = ref.watch(authProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 18),
        reviewsAsync.when(
          loading: () => const Column(
            children: [
              SwLoadingSkeleton(height: 60),
              SizedBox(height: 10),
              SwLoadingSkeleton(height: 80),
            ],
          ),
          error: (err, _) => SwErrorView(
            message: err.toString(),
            onRetry: () => ref.invalidate(targetReviewsProvider(widget.targetId)),
          ),
          data: (reviews) {
            final avg = reviews.isEmpty
                ? 5.0
                : reviews.fold<int>(0, (acc, r) => acc + r.rating) /
                    reviews.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'APRESIASI & ULASAN PELESTARI',
                          style: AppTypography.labelSm(color: AppColors.goldDark)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ulasan Budaya (${reviews.length})',
                          style: AppTypography.headlineMd(),
                        ),
                      ],
                    ),
                    SwCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            avg.toStringAsFixed(1),
                            style: AppTypography.metricNumber(
                              fontSize: 22,
                              color: AppColors.brandGreen,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < avg.round()
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: AppColors.gold,
                                    size: 16,
                                  ),
                                ),
                              ),
                              Text(
                                '${reviews.length} ulasan terverifikasi',
                                style: AppTypography.labelSm(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwCard(
                  backgroundColor: AppColors.surfaceContainerLow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tulis Apresiasi untuk "${widget.targetTitle}"',
                        style: AppTypography.titleMd(),
                      ),
                      const SizedBox(height: 10),
                      if (_feedbackMessage != null) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isError
                                ? AppColors.errorContainer
                                : AppColors.successBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isError
                                    ? Icons.error_outline_rounded
                                    : Icons.verified_rounded,
                                size: 17,
                                color: _isError
                                    ? AppColors.error
                                    : AppColors.successText,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _feedbackMessage!,
                                  style: AppTypography.bodyMd(
                                    color: _isError
                                        ? AppColors.error
                                        : AppColors.successText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Text(
                        'Penilaian Bintang:',
                        style: AppTypography.labelMd(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (idx) {
                          final starVal = idx + 1;
                          final filled = starVal <= _selectedRating;
                          return IconButton(
                            onPressed: () =>
                                setState(() => _selectedRating = starVal),
                            icon: Icon(
                              filled
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: AppColors.gold,
                              size: 26,
                            ),
                            tooltip: '$starVal Bintang',
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            padding: EdgeInsets.zero,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      SwInput(
                        controller: _commentController,
                        hint:
                            'Bagikan kesan estetik, kualitas busana, atau nilai sejarahnya...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      if (auth.isUser)
                        SwButton(
                          label: 'Kirim Ulasan Budaya',
                          leadingIcon: Icons.rate_review_outlined,
                          isLoading: _isSubmitting,
                          onPressed: _submitReview,
                        )
                      else
                        SwButton(
                          label: 'Masuk untuk Menulis Ulasan',
                          variant: SwButtonVariant.secondary,
                          leadingIcon: Icons.login_rounded,
                          onPressed: () => context.go(AppRoutes.login),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (reviews.isEmpty)
                  const SwEmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Belum Ada Ulasan',
                    description:
                        'Jadilah pelestari pertama yang menuliskan apresiasi untuk karya ini.',
                  )
                else
                  Column(
                    children: reviews
                        .map((rev) => _ReviewCard(review: rev))
                        .toList(),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final UserReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SwCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.metricMint,
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : 'P',
                    style: AppTypography.labelMd(color: AppColors.brandGreen),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMd(),
                      ),
                      Text(
                        review.createdAt,
                        style: AppTypography.labelSm(),
                      ),
                    ],
                  ),
                ),
                if (review.verified)
                  const SwStatusBadge(
                    label: 'Terverifikasi Kurator',
                    tone: SwBadgeTone.gold,
                    icon: Icons.verified_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < review.rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 15,
                  color: AppColors.gold,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              review.comment,
              style: AppTypography.bodyMd(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

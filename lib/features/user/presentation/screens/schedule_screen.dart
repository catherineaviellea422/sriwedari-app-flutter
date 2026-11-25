import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/sw_page_transitions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/models/user_models.dart';
import '../providers/user_catalog_providers.dart';
import '../widgets/theater_seat_map_sheet.dart';

enum ScheduleViewMode { all, daily, today }

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({
    super.key,
    this.viewMode = ScheduleViewMode.all,
  });

  final ScheduleViewMode viewMode;

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  String _selectedTab = 'Mendatang'; // 'Mendatang' | 'Selesai'

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(userEventsProvider);
    final config = ref.watch(appConfigProvider);
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);

    final headerTitle = switch (widget.viewMode) {
      ScheduleViewMode.today => 'Pentas Hari Ini',
      ScheduleViewMode.daily => 'Jadwal Pentas Harian',
      ScheduleViewMode.all => 'Jadwal Kegiatan',
    };
    final hPad = centeredSliverHorizontalPadding(
      width,
      horizontalMargin: margin,
      maxContentWidth: AppSpacing.maxContentWidth,
    );

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(userEventsProvider),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        scrollCacheExtent: const ScrollCacheExtent.pixels(550),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, AppSpacing.xl, hPad, 18),
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
                            Text(headerTitle, style: AppTypography.headlineLg()),
                            const SizedBox(height: 2),
                            Text(
                              'Pagelaran Wayang Orang Sriwedari Surakarta',
                              style: AppTypography.bodyMd(
                                color: AppColors.textSubtle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SwFilterChip(
                        label: widget.viewMode == ScheduleViewMode.today
                            ? 'Semua Jadwal'
                            : 'Hari Ini',
                        icon: widget.viewMode == ScheduleViewMode.today
                            ? Icons.arrow_back_rounded
                            : Icons.today_rounded,
                        selected: widget.viewMode == ScheduleViewMode.today,
                        onTap: () {
                          if (widget.viewMode != ScheduleViewMode.all) {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(AppRoutes.userSchedule);
                            }
                          } else {
                            context.push(AppRoutes.userScheduleToday);
                          }
                        },
                      ),
                    ],
                  ),
                  if (widget.viewMode != ScheduleViewMode.today) ...[
                    const SizedBox(height: 14),
                    // Segmented Control: Mendatang vs Selesai
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: ['Mendatang', 'Selesai'].map((tab) {
                          final active = _selectedTab == tab;
                          return Expanded(
                            child: ScaleOnTap(
                              pressedScale: 0.97,
                              child: InkWell(
                                onTap: () => setState(() => _selectedTab = tab),
                                borderRadius: BorderRadius.circular(9),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? AppColors.brandGreen
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Text(
                                    tab,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.labelMd(
                                      color: active
                                          ? Colors.white
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          ...eventsAsync.when(
            loading: () => [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                sliver: const SliverToBoxAdapter(
                  child: SwContentSwitcher(
                    child: Column(
                      key: ValueKey('sch_loading'),
                      children: [
                        SwLoadingSkeleton(height: 150),
                        SizedBox(height: 12),
                        SwLoadingSkeleton(height: 150),
                      ],
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
                      key: const ValueKey('sch_error'),
                      message: err.toString(),
                      onRetry: () => ref.invalidate(userEventsProvider),
                    ),
                  ),
                ),
              ),
            ],
            data: (events) {
              final now = DateTime.now();
              final todayStr =
                  '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

              final filtered = events.where((e) {
                if (widget.viewMode == ScheduleViewMode.today) {
                  return e.date == todayStr;
                }
                final parsed = DateFormatter.tryParse(e.date);
                final isPast = parsed != null &&
                    parsed.isBefore(
                      DateTime(now.year, now.month, now.day),
                    );
                return _selectedTab == 'Selesai' ? isPast : !isPast;
              }).toList();

              // Jika di seed tanggal semua berdekatan & Mendatang kosong, tampilkan semua event aktif di tab Mendatang
              final displayed = filtered.isEmpty &&
                      widget.viewMode == ScheduleViewMode.all &&
                      _selectedTab == 'Mendatang'
                  ? events
                  : filtered;

              if (displayed.isEmpty) {
                return [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                    sliver: SliverToBoxAdapter(
                      child: SwDirectionalSwitcher(
                        isForward: _selectedTab == 'Selesai',
                        child: KeyedSubtree(
                          key: ValueKey(
                            'schedule-empty-$_selectedTab-${widget.viewMode.name}',
                          ),
                          child: SwEmptyState(
                            icon: Icons.event_busy_outlined,
                            title: 'Tidak Ada Jadwal Pentas',
                            description: widget.viewMode == ScheduleViewMode.today
                                ? 'Belum ada pementasan yang dijadwalkan khusus untuk hari ini.'
                                : 'Belum ada jadwal untuk kategori $_selectedTab.',
                            actionLabel: widget.viewMode != ScheduleViewMode.all
                                ? 'Lihat Semua Jadwal'
                                : null,
                            onAction: widget.viewMode != ScheduleViewMode.all
                                ? () {
                                    if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go(AppRoutes.userSchedule);
                                    }
                                  }
                                : null,
                          ),
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
                        final evt = displayed[index];
                        return RepaintBoundary(
                          child: FadeSlideEntrance(
                            key: ValueKey(
                              'sch_${_selectedTab}_${widget.viewMode.name}_${evt.id}',
                            ),
                            index: index,
                            onceKey:
                                'sch_${_selectedTab}_${widget.viewMode.name}_${evt.id}',
                            child: _ScheduleEventCard(
                              event: evt,
                              baseUrl: config.baseUrl,
                              onSelectSeats: () => TheaterSeatMapSheet.show(
                                context,
                                event: evt,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: displayed.length,
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

class _ScheduleEventCard extends StatelessWidget {
  const _ScheduleEventCard({
    required this.event,
    required this.baseUrl,
    required this.onSelectSeats,
  });

  final UserEventModel event;
  final String baseUrl;
  final VoidCallback onSelectSeats;

  @override
  Widget build(BuildContext context) {
    final badge = DateFormatter.splitBadgeDate(event.date);
    final lowestPrice = event.zonePrices?.balkon ?? event.price;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SwCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SwImage(
                  source: event.image,
                  baseUrl: baseUrl,
                  width: double.infinity,
                  height: 170,
                  borderRadius: 0,
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreenDark.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${badge.day} ${badge.month} ${badge.year}',
                      style: AppTypography.labelSm(color: AppColors.goldLight)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      event.time,
                      style: AppTypography.labelSm(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: AppTypography.headlineMd()),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.brandGreen,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: AppTypography.bodyMd(
                            color: AppColors.textSubtle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMd(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.ivory,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sisa Kuota', style: AppTypography.labelSm()),
                            Text(
                              '${event.remainingQuota} dari ${event.quota} kursi',
                              style: AppTypography.labelMd(),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Mulai Dari', style: AppTypography.labelSm()),
                            Text(
                              CurrencyFormatter.formatRupiah(lowestPrice),
                              style: AppTypography.priceText(fontSize: 15),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwButton(
                    label: event.remainingQuota > 0
                        ? 'Pilih Kursi & Pesan Tiket'
                        : 'Kuota Penuh',
                    leadingIcon: Icons.event_seat_outlined,
                    fullWidth: true,
                    onPressed: event.remainingQuota > 0 ? onSelectSeats : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

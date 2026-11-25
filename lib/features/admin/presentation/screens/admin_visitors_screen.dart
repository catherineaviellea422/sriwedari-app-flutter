import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/models/admin_models.dart';
import '../providers/admin_providers.dart';

class AdminVisitorsScreen extends ConsumerStatefulWidget {
  const AdminVisitorsScreen({super.key});

  @override
  ConsumerState<AdminVisitorsScreen> createState() =>
      _AdminVisitorsScreenState();
}

class _AdminVisitorsScreenState extends ConsumerState<AdminVisitorsScreen> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'Semua';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _quickCheckIn(AdminTicketGateModel ticket) async {
    final res = await ref
        .read(adminOperationsRepositoryProvider)
        .validateGateTicket(ticket.bookingCode);
    ref.invalidate(adminTicketsProvider);
    ref.invalidate(adminAnalyticsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(adminTicketsProvider);
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);
    final q = _searchCtrl.text.trim().toLowerCase();
    final hPad = centeredSliverHorizontalPadding(
      width,
      horizontalMargin: margin,
      maxContentWidth: AppSpacing.maxContentWidth,
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(adminTicketsProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        scrollCacheExtent: const ScrollCacheExtent.pixels(600),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, AppSpacing.xl, hPad, 14),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rekap & Presensi Kunjungan',
                    style: AppTypography.headlineLg(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitoring pemegang tiket pertunjukan Wayang Orang dan status check-in pintu teater',
                    style: AppTypography.bodyMd(color: AppColors.textSubtle),
                  ),
                ],
              ),
            ),
          ),
          ...ticketsAsync.when(
            loading: () => [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                sliver: const SliverToBoxAdapter(
                  child: SwContentSwitcher(
                    child: SwLoadingSkeleton(
                      key: ValueKey('adm_vis_loading'),
                      height: 150,
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
                      key: const ValueKey('adm_vis_error'),
                      message: err.toString(),
                      onRetry: () =>
                          ref.read(adminTicketsProvider.notifier).refresh(),
                    ),
                  ),
                ),
              ),
            ],
            data: (tickets) {
              final totalKursi = tickets.fold<int>(
                0,
                (sum, t) => sum + t.quantity,
              );
              final checkedInCount =
                  tickets.where((t) => t.status == 'Check-in').length;
              final activeCount =
                  tickets.where((t) => t.status == 'Aktif').length;

              final filtered = tickets.where((t) {
                final matchStatus =
                    _statusFilter == 'Semua' || t.status == _statusFilter;
                final matchQuery = q.isEmpty ||
                    t.bookingCode.toLowerCase().contains(q) ||
                    t.userName.toLowerCase().contains(q) ||
                    t.eventTitle.toLowerCase().contains(q);
                return matchStatus && matchQuery;
              }).toList();

              return [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 14),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RepaintBoundary(
                          child: LayoutBuilder(
                            builder: (ctx, c) {
                              final cols = c.maxWidth >= 600 ? 3 : 1;
                              const gap = 10.0;
                              final cardW =
                                  (c.maxWidth - gap * (cols - 1)) / cols;
                              return Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: [
                                  SizedBox(
                                    width: cardW,
                                    child: SwMetricCard(
                                      label: 'Total Penonton',
                                      value: '$totalKursi Kursi',
                                      subtitle: '${tickets.length} transaksi tiket',
                                      icon: Icons.groups_outlined,
                                      tone: SwMetricTone.mint,
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardW,
                                    child: SwMetricCard(
                                      label: 'Sudah Check-In',
                                      value: '$checkedInCount Tiket',
                                      icon: Icons.how_to_reg_outlined,
                                      tone: SwMetricTone.lavender,
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardW,
                                    child: SwMetricCard(
                                      label: 'Menunggu Masuk',
                                      value: '$activeCount Tiket',
                                      icon: Icons.schedule_rounded,
                                      tone: SwMetricTone.lightPeach,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        SwInput(
                          controller: _searchCtrl,
                          hint: 'Cari kode tiket, nama penonton, atau lakon...',
                          prefixIcon: Icons.search_rounded,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['Semua', 'Aktif', 'Check-in', 'Kedaluwarsa']
                              .map(
                                (st) => SwFilterChip(
                                  label: st,
                                  selected: _statusFilter == st,
                                  onTap: () =>
                                      setState(() => _statusFilter = st),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                    sliver: SliverToBoxAdapter(
                      child: SwContentSwitcher(
                        child: SwEmptyState(
                          key: ValueKey('adm_vis_empty_$_statusFilter-$q'),
                          icon: Icons.confirmation_number_outlined,
                          title: 'Belum Ada Data Kunjungan',
                          description:
                              'Tidak ada tiket yang cocok dengan filter atau pencarian.',
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final t = filtered[index];
                          return RepaintBoundary(
                            child: FadeSlideEntrance(
                              key: ValueKey('adm_vis_${t.id}_$_statusFilter'),
                              index: index,
                              onceKey: 'adm_vis_${t.id}_$_statusFilter',
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: SwCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${t.bookingCode} • ${t.userName}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.labelMd(
                                                color: AppColors.brandGreen,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SwStatusBadge.fromOrderStatus(
                                            t.status,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        t.eventTitle,
                                        style: AppTypography.titleMd(),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Zona ${t.zone} • Kursi ${t.seats.join(', ')} (${t.quantity} tiket) • ${CurrencyFormatter.formatRupiah(t.totalPrice)}',
                                        style: AppTypography.bodyMd(
                                          color: AppColors.textSubtle,
                                        ),
                                      ),
                                      if (t.status == 'Aktif') ...[
                                        const SizedBox(height: 10),
                                        SwButton(
                                          label: 'Check-In Sekarang',
                                          leadingIcon:
                                              Icons.qr_code_scanner_rounded,
                                          height: 36,
                                          onPressed: () => _quickCheckIn(t),
                                        ),
                                      ],
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

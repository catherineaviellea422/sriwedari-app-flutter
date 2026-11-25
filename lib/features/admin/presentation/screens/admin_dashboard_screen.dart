import 'package:fl_chart/fl_chart.dart';
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
import '../../domain/models/admin_models.dart';
import '../providers/admin_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final analyticsAsync = ref.watch(adminAnalyticsProvider);
    final config = ref.watch(appConfigProvider);
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);
    final isWide = width >= 760;

    return RefreshIndicator(
      onRefresh: () => ref.read(adminAnalyticsProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: margin,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Kurator
                  FadeSlideEntrance(
                    index: 0,
                    onceKey: 'adm_dash_hero',
                    slideOffset: 10,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGreenGradient,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusHero,
                        ),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwStatusBadge(
                            label: 'PORTAL KURATOR • ${auth.displayName}',
                            tone: SwBadgeTone.gold,
                            icon: Icons.verified_user_outlined,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Dasbor Operasional Galeri Sriwedari',
                            style: AppTypography.headlineLg(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pantau omzet sewa busana, penjualan tiket pagelaran, dana escrow deposit, serta aktivitas kurator secara real-time.',
                            style: AppTypography.bodyMd(
                              color: AppColors.canvas.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _QuickNavPill(
                                label: 'Pesanan & QC',
                                icon: Icons.receipt_long_rounded,
                                onTap: () => context.go(AppRoutes.adminOrders),
                              ),
                              _QuickNavPill(
                                label: 'Tambah Galeri',
                                icon: Icons.add_photo_alternate_rounded,
                                onTap: () =>
                                    context.push(AppRoutes.adminGalleryCreate),
                              ),
                              _QuickNavPill(
                                label: 'Kelola Kostum',
                                icon: Icons.checkroom_rounded,
                                onTap: () =>
                                    context.push(AppRoutes.adminCostumes),
                              ),
                              _QuickNavPill(
                                label: 'Kasir Loket',
                                icon: Icons.qr_code_scanner_rounded,
                                onTap: () => context.push(AppRoutes.adminPos),
                              ),
                              _QuickNavPill(
                                label: 'Audit Trail',
                                icon: Icons.security_rounded,
                                onTap: () => context.push(AppRoutes.adminAudit),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  SwContentSwitcher(
                    child: analyticsAsync.when(
                      loading: () => const Column(
                        key: ValueKey('adm_dash_loading'),
                        children: [
                          SwLoadingSkeleton(height: 120),
                          SizedBox(height: 12),
                          SwLoadingSkeleton(height: 240),
                        ],
                      ),
                      error: (err, _) => SwErrorView(
                        key: const ValueKey('adm_dash_error'),
                        message: err.toString(),
                        onRetry: () =>
                            ref.read(adminAnalyticsProvider.notifier).refresh(),
                      ),
                      data: (data) => Column(
                        key: const ValueKey('adm_dash_data'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RepaintBoundary(
                            child: FadeSlideEntrance(
                              index: 1,
                              onceKey: 'adm_dash_kpi',
                              child: _KpiGrid(data: data, isWide: isWide),
                            ),
                          ),
                          const SizedBox(height: 18),

                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: RepaintBoundary(
                                    child: FadeSlideEntrance(
                                      index: 2,
                                      onceKey: 'adm_dash_chart',
                                      child: _WeeklyVisitorsChartCard(
                                        snapshots: data.weeklyVisitors,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: 2,
                                  child: RepaintBoundary(
                                    child: FadeSlideEntrance(
                                      index: 3,
                                      onceKey: 'adm_dash_channels',
                                      child: _PaymentChannelsCard(data: data),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            RepaintBoundary(
                              child: FadeSlideEntrance(
                                index: 2,
                                onceKey: 'adm_dash_chart_m',
                                child: _WeeklyVisitorsChartCard(
                                  snapshots: data.weeklyVisitors,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            RepaintBoundary(
                              child: FadeSlideEntrance(
                                index: 3,
                                onceKey: 'adm_dash_channels_m',
                                child: _PaymentChannelsCard(data: data),
                              ),
                            ),
                          ],

                          const SizedBox(height: 18),
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: RepaintBoundary(
                                    child: _TopGalleriesCard(
                                      galleries: data.topGalleries,
                                      baseUrl: config.baseUrl,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: RepaintBoundary(
                                    child: _RecentAuditCard(
                                      logs: data.recentActivities,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            RepaintBoundary(
                              child: _TopGalleriesCard(
                                galleries: data.topGalleries,
                                baseUrl: config.baseUrl,
                              ),
                            ),
                            const SizedBox(height: 14),
                            RepaintBoundary(
                              child: _RecentAuditCard(
                                logs: data.recentActivities,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickNavPill extends StatelessWidget {
  const _QuickNavPill({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      pressedScale: 0.95,
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: AppColors.goldLight),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelSm(color: Colors.white)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.data, required this.isWide});

  final AnalyticsSummaryModel data;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final cards = [
      SwMetricCard(
        label: 'Total Pendapatan',
        value: CurrencyFormatter.formatCompactRupiah(data.totalRevenue),
        subtitle:
            'Sewa ${CurrencyFormatter.formatCompactRupiah(data.revenueRental)} • Tiket ${CurrencyFormatter.formatCompactRupiah(data.revenueTickets)}',
        icon: Icons.payments_outlined,
        tone: SwMetricTone.mint,
      ),
      SwMetricCard(
        label: 'Dana Deposit (Escrow)',
        value: CurrencyFormatter.formatCompactRupiah(data.escrowDeposit),
        subtitle:
            'Potongan QC: ${CurrencyFormatter.formatCompactRupiah(data.qcDeductions)}',
        icon: Icons.account_balance_wallet_outlined,
        tone: SwMetricTone.lightPeach,
      ),
      SwMetricCard(
        label: 'Pesanan Sewa',
        value: '${data.activeOrders} Aktif',
        subtitle: '${data.completedOrders} selesai dari ${data.totalOrders} total',
        icon: Icons.receipt_long_outlined,
        tone: SwMetricTone.lavender,
      ),
      SwMetricCard(
        label: 'Okupansi & Tiket',
        value: '${data.occupancyRate}% (${data.totalTicketsSold})',
        subtitle: '${data.gateCheckinCount} penonton sudah check-in',
        icon: Icons.confirmation_number_outlined,
        tone: SwMetricTone.peach,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final colCount = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
                ? 2
                : 1;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (colCount - 1)) / colCount;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((card) => SizedBox(width: itemWidth, child: card))
              .toList(),
        );
      },
    );
  }
}

class _WeeklyVisitorsChartCard extends StatelessWidget {
  const _WeeklyVisitorsChartCard({required this.snapshots});

  final List<AnalyticsSnapshotModel> snapshots;

  @override
  Widget build(BuildContext context) {
    final items = snapshots.length > 7
        ? snapshots.sublist(snapshots.length - 7)
        : snapshots;
    final maxVisitors = items.fold<int>(
      10,
      (prev, e) => e.visitors > prev ? e.visitors : prev,
    );

    return SwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                size: 20,
                color: AppColors.brandGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tren Pengunjung 7 Hari Terakhir',
                  style: AppTypography.titleMd(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Jumlah kunjungan galeri dan pementasan harian',
            style: AppTypography.labelSm(),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text('Belum ada data grafik mingguan.')),
            )
          else
            SizedBox(
              height: 210,
              child: BarChart(
                BarChartData(
                  maxY: (maxVisitors * 1.25).ceilToDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: AppColors.divider,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (val, _) => Text(
                          val.toInt().toString(),
                          style: AppTypography.labelSm(),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (val, _) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= items.length) {
                            return const SizedBox.shrink();
                          }
                          final rawDate = items[idx].date;
                          final shortLabel = rawDate.length >= 10
                              ? rawDate.substring(5, 10)
                              : rawDate;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              shortLabel,
                              style: AppTypography.labelSm()
                                  .copyWith(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(items.length, (index) {
                    final s = items[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: s.visitors.toDouble(),
                          color: AppColors.brandGreen,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: (maxVisitors * 1.25).ceilToDouble(),
                            color: AppColors.surfaceContainerLow,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentChannelsCard extends StatelessWidget {
  const _PaymentChannelsCard({required this.data});

  final AnalyticsSummaryModel data;

  @override
  Widget build(BuildContext context) {
    final total = data.paymentChannels.qris +
        data.paymentChannels.va +
        data.paymentChannels.tunai;

    return SwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pie_chart_outline_rounded,
                size: 20,
                color: AppColors.goldDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kanal Pembayaran & Aset',
                  style: AppTypography.titleMd(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ChannelProgress(
            label: 'QRIS Dinamis',
            amount: data.paymentChannels.qris,
            total: total,
            color: AppColors.brandGreen,
          ),
          const SizedBox(height: 10),
          _ChannelProgress(
            label: 'Virtual Account',
            amount: data.paymentChannels.va,
            total: total,
            color: AppColors.goldDark,
          ),
          const SizedBox(height: 10),
          _ChannelProgress(
            label: 'Tunai Loket',
            amount: data.paymentChannels.tunai,
            total: total,
            color: const Color(0xFF4B4E8C),
          ),
          const Divider(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              SwStatusBadge(
                label: '${data.totalGalleries} Karya Galeri',
                tone: SwBadgeTone.neutral,
              ),
              SwStatusBadge(
                label: '${data.totalCostumes} Kostum',
                tone: SwBadgeTone.gold,
              ),
              SwStatusBadge(
                label: '${data.totalEvents} Pentas',
                tone: SwBadgeTone.info,
              ),
              SwStatusBadge(
                label: '${data.totalUsers} Akun',
                tone: SwBadgeTone.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChannelProgress extends StatelessWidget {
  const _ChannelProgress({
    required this.label,
    required this.amount,
    required this.total,
    required this.color,
  });

  final String label;
  final int amount;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMd(),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              CurrencyFormatter.formatRupiah(amount),
              style: AppTypography.priceText(fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: AppColors.surfaceContainerHigh,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TopGalleriesCard extends StatelessWidget {
  const _TopGalleriesCard({
    required this.galleries,
    required this.baseUrl,
  });

  final List<AdminGalleryModel> galleries;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    return SwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_outlined,
                size: 19,
                color: AppColors.brandGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Koleksi Galeri Terpopuler',
                  style: AppTypography.titleMd(),
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.adminGallery),
                child: const Text('Kelola'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (galleries.isEmpty)
            Text(
              'Belum ada koleksi galeri tercatat.',
              style: AppTypography.bodyMd(color: AppColors.textSubtle),
            )
          else
            ...galleries.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SwImage(
                      source: item.image,
                      baseUrl: baseUrl,
                      width: 48,
                      height: 48,
                      borderRadius: 8,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelMd(),
                          ),
                          Text(
                            '${item.categoryName} • ${item.views} tayang • ${item.likes} suka',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSm(),
                          ),
                        ],
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

class _RecentAuditCard extends StatelessWidget {
  const _RecentAuditCard({required this.logs});

  final List<AuditLogModel> logs;

  @override
  Widget build(BuildContext context) {
    return SwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                size: 19,
                color: AppColors.goldDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aktivitas Sistem Terbaru',
                  style: AppTypography.titleMd(),
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.adminAudit),
                child: const Text('Audit'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (logs.isEmpty)
            Text(
              'Belum ada aktivitas audit terekam.',
              style: AppTypography.bodyMd(color: AppColors.textSubtle),
            )
          else
            ...logs.take(5).map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: log.severity == 'warning'
                            ? AppColors.warningText
                            : log.severity == 'critical'
                                ? AppColors.error
                                : AppColors.brandGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.details,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMd(),
                          ),
                          Text(
                            '${log.actorName} (${log.action}) • ${log.timestamp}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSm(),
                          ),
                        ],
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

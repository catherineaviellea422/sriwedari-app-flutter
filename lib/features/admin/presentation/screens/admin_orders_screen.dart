import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/models/admin_models.dart';
import '../providers/admin_providers.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'Semua';

  static const List<String> _statusFilters = [
    'Semua',
    'Menunggu',
    'Dikonfirmasi',
    'Sedang Disewa',
    'Selesai',
    'Dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    _restoreFilter();
  }

  Future<void> _restoreFilter() async {
    final saved =
        await ref.read(adminCatalogRepositoryProvider).getSavedOrderFilter();
    if (saved != null && _statusFilters.contains(saved) && mounted) {
      setState(() => _selectedStatus = saved);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectFilter(String status) {
    setState(() => _selectedStatus = status);
    ref.read(adminCatalogRepositoryProvider).saveOrderFilter(status);
  }

  Future<void> _changeOrderStatus(
    AdminOrderQcModel order,
    String nextStatus,
  ) async {
    try {
      await ref.read(adminCatalogRepositoryProvider).updateOrderStatus(
            orderId: order.id,
            status: nextStatus,
          );
      await ref.read(adminOrdersProvider.notifier).refresh();
      ref.invalidate(adminAnalyticsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status pesanan ${order.id} diperbarui menjadi $nextStatus.',
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _openQcDialog(AdminOrderQcModel order) async {
    var selectedGrade = order.qcStatus != null && order.qcStatus != 'Pending'
        ? order.qcStatus!
        : 'Grade A';
    final noteCtrl = TextEditingController(text: order.deductionNote ?? '');
    var isSaving = false;

    const grades = [
      ('Grade A', 'Mulus Sempurna (Potongan Rp 0)'),
      ('Grade B', 'Noda Ringan (Potongan Rp 25.000)'),
      ('Grade C', 'Perlu Perbaikan (Potongan Rp 50.000)'),
      ('Grade D', 'Rusak Berat / Hilang (Potongan Rp 100.000)'),
    ];

    await showDialog<void>(
      context: context,
      barrierColor: AppColors.modalScrim,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final deduction = AdminOrderQcModel.deductionForQcGrade(selectedGrade);
          final refund = order.computeRefundForGrade(selectedGrade);

          return Dialog(
            backgroundColor: AppColors.parchment,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusModal),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inspeksi QC Retur Busana',
                      style: AppTypography.headlineMd(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.id} • ${order.userName}',
                      style: AppTypography.bodyMd(color: AppColors.textSubtle),
                    ),
                    const SizedBox(height: 14),
                    Text('Pilih Grade Kondisi Retur', style: AppTypography.labelMd()),
                    const SizedBox(height: 8),
                    ...grades.map((g) {
                      final active = selectedGrade == g.$1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () =>
                              setDialogState(() => selectedGrade = g.$1),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.metricMint
                                  : AppColors.ivory,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: active
                                    ? AppColors.brandGreen
                                    : AppColors.divider,
                                width: active ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  active
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  size: 18,
                                  color: active
                                      ? AppColors.brandGreen
                                      : AppColors.textSubtle,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(g.$1, style: AppTypography.labelMd()),
                                      Text(g.$2, style: AppTypography.labelSm()),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    SwInput(
                      controller: noteCtrl,
                      label: 'Catatan Kurator QC',
                      hint: 'Misal: Jahitan payet utuh, kain bersih.',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    SwCard(
                      backgroundColor: AppColors.surfaceContainerLow,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          _QcSummaryRow('Deposit Awal', order.depositFee),
                          const SizedBox(height: 4),
                          _QcSummaryRow('Potongan Kerusakan', -deduction),
                          const Divider(height: 14),
                          _QcSummaryRow(
                            'Refund ke Penyewa',
                            refund,
                            highlight: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: SwButton(
                            label: 'Batal',
                            variant: SwButtonVariant.secondary,
                            onPressed: isSaving
                                ? null
                                : () => Navigator.of(dialogCtx).pop(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SwButton(
                            label: 'Selesaikan QC',
                            isLoading: isSaving,
                            onPressed: () async {
                              setDialogState(() => isSaving = true);
                              try {
                                await ref
                                    .read(adminCatalogRepositoryProvider)
                                    .submitOrderQc(
                                      orderId: order.id,
                                      qcStatus: selectedGrade,
                                      refundAmount: refund,
                                      deductionNote: noteCtrl.text.trim(),
                                    );
                                await ref
                                    .read(adminOrdersProvider.notifier)
                                    .refresh();
                                ref.invalidate(adminCostumesProvider);
                                ref.invalidate(adminAnalyticsProvider);
                                if (dialogCtx.mounted) {
                                  Navigator.of(dialogCtx).pop();
                                }
                              } on ApiException catch (e) {
                                setDialogState(() => isSaving = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.message)),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _launchWhatsApp(AdminOrderQcModel order) async {
    var phone = order.userPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    }
    final msg = Uri.encodeComponent(
      'Halo ${order.userName}, kami dari Galeri Sriwedari terkait pesanan sewa ${order.id} (${order.costumeName}).',
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$msg');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersProvider);
    final config = ref.watch(appConfigProvider);
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);
    final q = _searchController.text.trim().toLowerCase();
    final hPad = centeredSliverHorizontalPadding(
      width,
      horizontalMargin: margin,
      maxContentWidth: AppSpacing.maxContentWidth,
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(adminOrdersProvider.notifier).refresh(),
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
                    'Antrean Pesanan & Mesin QC Retur',
                    style: AppTypography.headlineLg(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Verifikasi bukti transfer, serah terima kostum, inspeksi Grade A–D, & refund deposit',
                    style: AppTypography.bodyMd(color: AppColors.textSubtle),
                  ),
                  const SizedBox(height: 14),
                  SwInput(
                    controller: _searchController,
                    hint: 'Cari kode invoice, nama penyewa, atau busana...',
                    prefixIcon: Icons.search_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statusFilters.map((st) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SwFilterChip(
                            label: st,
                            selected: _selectedStatus == st,
                            onTap: () => _selectFilter(st),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...ordersAsync.when(
            loading: () => [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                sliver: const SliverToBoxAdapter(
                  child: SwContentSwitcher(
                    child: SwLoadingSkeleton(
                      key: ValueKey('adm_ord_loading'),
                      height: 160,
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
                      key: const ValueKey('adm_ord_error'),
                      message: err.toString(),
                      onRetry: () =>
                          ref.read(adminOrdersProvider.notifier).refresh(),
                    ),
                  ),
                ),
              ),
            ],
            data: (orders) {
              final filtered = orders.where((o) {
                final matchStatus = _selectedStatus == 'Semua' ||
                    o.status == _selectedStatus;
                final matchQuery = q.isEmpty ||
                    o.id.toLowerCase().contains(q) ||
                    o.userName.toLowerCase().contains(q) ||
                    o.costumeName.toLowerCase().contains(q);
                return matchStatus && matchQuery;
              }).toList();

              if (filtered.isEmpty) {
                return [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                    sliver: SliverToBoxAdapter(
                      child: SwContentSwitcher(
                        child: SwEmptyState(
                          key: ValueKey('adm_ord_empty_$_selectedStatus-$q'),
                          icon: Icons.receipt_long_outlined,
                          title: 'Tidak Ada Pesanan',
                          description:
                              'Belum ada pesanan penyewaan untuk filter status saat ini.',
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
                        final order = filtered[index];
                        return RepaintBoundary(
                          child: FadeSlideEntrance(
                            key: ValueKey('adm_ord_${order.id}_$_selectedStatus'),
                            index: index,
                            onceKey: 'adm_ord_${order.id}_$_selectedStatus',
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SwCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${order.id} • ${order.userName}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.labelMd(
                                              color: AppColors.brandGreen,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SwStatusBadge.fromOrderStatus(
                                          order.status,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      order.costumeName,
                                      style: AppTypography.titleMd(),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Mulai ${order.startDate} (${order.duration} hari) • ${order.paymentMethod} • ${order.userPhone}',
                                      style: AppTypography.bodyMd(
                                        color: AppColors.textSubtle,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Wrap(
                                        alignment:
                                            WrapAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Text(
                                            'Tagihan (Deposit ${CurrencyFormatter.formatCompactRupiah(order.depositFee)})',
                                            style: AppTypography.labelSm(),
                                          ),
                                          Text(
                                            CurrencyFormatter.formatRupiah(
                                              order.totalPrice,
                                            ),
                                            style: AppTypography.priceText(
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (order.paymentProof != null &&
                                        order.paymentProof!.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          SwImage(
                                            source: order.paymentProof!,
                                            baseUrl: config.baseUrl,
                                            width: 44,
                                            height: 44,
                                            borderRadius: 8,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Bukti transfer tersedia',
                                              style: AppTypography.labelMd(
                                                color: AppColors.successText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (order.qcStatus != null &&
                                        order.qcStatus != 'Pending') ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainerLow,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: AppColors.divider,
                                          ),
                                        ),
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            SwStatusBadge.fromOrderStatus(
                                              order.qcStatus!,
                                            ),
                                            Text(
                                              'Refund: ${CurrencyFormatter.formatRupiah(order.refundAmount ?? 0)}',
                                              style: AppTypography.labelMd(
                                                color: AppColors.successText,
                                              ),
                                            ),
                                            if (order.deductionNote != null &&
                                                order.deductionNote!.isNotEmpty)
                                              Text(
                                                '• ${order.deductionNote}',
                                                style: AppTypography.labelSm(),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (order.status == 'Menunggu') ...[
                                          SwButton(
                                            label: 'Konfirmasi Bayar',
                                            height: 36,
                                            onPressed: () =>
                                                _changeOrderStatus(
                                              order,
                                              'Dikonfirmasi',
                                            ),
                                          ),
                                          SwButton(
                                            label: 'Batalkan',
                                            variant:
                                                SwButtonVariant.destructive,
                                            height: 36,
                                            onPressed: () =>
                                                _changeOrderStatus(
                                              order,
                                              'Dibatalkan',
                                            ),
                                          ),
                                        ],
                                        if (order.status == 'Dikonfirmasi')
                                          SwButton(
                                            label: 'Serahkan Kostum',
                                            variant: SwButtonVariant.gold,
                                            height: 36,
                                            onPressed: () =>
                                                _changeOrderStatus(
                                              order,
                                              'Sedang Disewa',
                                            ),
                                          ),
                                        if (order.status == 'Dikonfirmasi' ||
                                            order.status == 'Sedang Disewa')
                                          SwButton(
                                            label: 'Inspeksi QC Retur',
                                            leadingIcon:
                                                Icons.fact_check_outlined,
                                            height: 36,
                                            onPressed: () =>
                                                _openQcDialog(order),
                                          ),
                                        SwButton(
                                          label: 'WhatsApp',
                                          leadingIcon: Icons.chat_outlined,
                                          variant: SwButtonVariant.secondary,
                                          height: 36,
                                          onPressed: () =>
                                              _launchWhatsApp(order),
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

class _QcSummaryRow extends StatelessWidget {
  const _QcSummaryRow(this.label, this.amount, {this.highlight = false});

  final String label;
  final int amount;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final prefix = amount < 0 ? '-' : '';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: highlight
                ? AppTypography.titleMd()
                : AppTypography.bodyMd(color: AppColors.textMuted),
          ),
        ),
        Text(
          '$prefix${CurrencyFormatter.formatRupiah(amount.abs())}',
          style: AppTypography.priceText(
            fontSize: highlight ? 15 : 13,
            color: highlight ? AppColors.successText : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

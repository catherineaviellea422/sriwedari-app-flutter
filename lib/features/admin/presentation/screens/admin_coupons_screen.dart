import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/models/admin_models.dart';
import '../providers/admin_providers.dart';

class AdminCouponsScreen extends ConsumerStatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  ConsumerState<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends ConsumerState<AdminCouponsScreen> {
  Future<void> _openCouponForm([AdminCouponModel? existing]) async {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final valueCtrl = TextEditingController(
      text: (existing?.value ?? 10).toString(),
    );
    final minOrderCtrl = TextEditingController(
      text: (existing?.minOrder ?? 100000).toString(),
    );
    final maxUsesCtrl = TextEditingController(
      text: (existing?.maxUses ?? 100).toString(),
    );
    final expiresCtrl = TextEditingController(
      text: existing?.expiresAt ?? '2026-12-31',
    );
    final descCtrl = TextEditingController(text: existing?.description ?? '');

    var type = existing?.type ?? 'PERCENTAGE';
    var isActive = existing?.isActive ?? true;
    var isSaving = false;

    await showDialog<void>(
      context: context,
      barrierColor: AppColors.modalScrim,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            backgroundColor: AppColors.parchment,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusModal),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        existing == null
                            ? 'Tambah Kupon Promo'
                            : 'Ubah Kupon Promo',
                        style: AppTypography.headlineMd(),
                      ),
                      const SizedBox(height: 14),
                      SwInput(
                        controller: codeCtrl,
                        label: 'Kode Voucher',
                        hint: 'SRIWEDARI15',
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: SwInputFormatters.alphaNumCode,
                        validator: (v) =>
                            SwValidators.requiredField(v, 'Kode kupon'),
                      ),
                      const SizedBox(height: 12),
                      Text('Tipe Diskon', style: AppTypography.labelMd()),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          SwFilterChip(
                            label: 'Persentase (%)',
                            selected: type == 'PERCENTAGE',
                            onTap: () =>
                                setDialogState(() => type = 'PERCENTAGE'),
                          ),
                          SwFilterChip(
                            label: 'Potongan Tetap (Rp)',
                            selected: type == 'FIXED',
                            onTap: () => setDialogState(() => type = 'FIXED'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SwInput(
                              controller: valueCtrl,
                              label: type == 'PERCENTAGE'
                                  ? 'Persentase (%)'
                                  : 'Nominal (Rp)',
                              keyboardType: TextInputType.number,
                              inputFormatters: SwInputFormatters.digitsOnly,
                              validator: (v) => SwValidators.intRange(
                                v,
                                fieldName: 'Nilai diskon',
                                min: 1,
                                max: type == 'PERCENTAGE' ? 100 : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SwInput(
                              controller: minOrderCtrl,
                              label: 'Min. Order (Rp)',
                              keyboardType: TextInputType.number,
                              inputFormatters: SwInputFormatters.digitsOnly,
                              validator: (v) => SwValidators.intRange(
                                v,
                                fieldName: 'Min. order',
                                min: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SwInput(
                              controller: maxUsesCtrl,
                              label: 'Batas Pakai',
                              keyboardType: TextInputType.number,
                              inputFormatters: SwInputFormatters.digitsOnly,
                              validator: (v) => SwValidators.intRange(
                                v,
                                fieldName: 'Batas pakai',
                                min: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SwInput(
                              controller: expiresCtrl,
                              label: 'Berlaku s.d.',
                              hint: 'YYYY-MM-DD',
                              keyboardType: TextInputType.datetime,
                              inputFormatters: SwInputFormatters.isoDate,
                              validator: (v) => SwValidators.isoDate(
                                v,
                                'Tanggal kedaluwarsa',
                              ),
                              suffixWidget: IconButton(
                                icon: const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                ),
                                onPressed: () async {
                                  final initial =
                                      DateTime.tryParse(expiresCtrl.text.trim()) ??
                                          DateTime.now();
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: initial,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                    initialEntryMode:
                                        DatePickerEntryMode.calendarOnly,
                                  );
                                  if (picked != null) {
                                    expiresCtrl.text =
                                        picked.toIso8601String().substring(0, 10);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Status Kupon Aktif',
                              style: AppTypography.labelMd(),
                            ),
                          ),
                          Switch(
                            value: isActive,
                            onChanged: (v) =>
                                setDialogState(() => isActive = v),
                          ),
                        ],
                      ),
                      SwInput(
                        controller: descCtrl,
                        label: 'Keterangan Promo (Opsional)',
                        maxLines: 2,
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
                              label: 'Simpan Kupon',
                              isLoading: isSaving,
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                setDialogState(() => isSaving = true);
                                try {
                                  await ref
                                      .read(adminOperationsRepositoryProvider)
                                      .saveCoupon(
                                        AdminCouponModel(
                                          id: existing?.id ?? '',
                                          code: codeCtrl.text.trim().toUpperCase(),
                                          type: type,
                                          value:
                                              int.tryParse(valueCtrl.text.trim()) ??
                                                  0,
                                          minOrder: int.tryParse(
                                                  minOrderCtrl.text.trim()) ??
                                              0,
                                          maxUses: int.tryParse(
                                                  maxUsesCtrl.text.trim()) ??
                                              100,
                                          usedCount: existing?.usedCount ?? 0,
                                          isActive: isActive,
                                          expiresAt: expiresCtrl.text.trim(),
                                          description:
                                              descCtrl.text.trim().isNotEmpty
                                                  ? descCtrl.text.trim()
                                                  : null,
                                        ),
                                      );
                                  await ref
                                      .read(adminCouponsProvider.notifier)
                                      .refresh();
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
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteCoupon(AdminCouponModel coupon) async {
    final ok = await SwConfirmDialog.showDeleteModal(
      context,
      itemName: coupon.code,
    );
    if (!ok || !mounted) return;
    try {
      await ref
          .read(adminOperationsRepositoryProvider)
          .deleteCoupon(coupon.id);
      await ref.read(adminCouponsProvider.notifier).refresh();
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
    final couponsAsync = ref.watch(adminCouponsProvider);
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);
    final hPad = centeredSliverHorizontalPadding(
      width,
      horizontalMargin: margin,
      maxContentWidth: AppSpacing.maxContentWidth,
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(adminCouponsProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        scrollCacheExtent: const ScrollCacheExtent.pixels(600),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, AppSpacing.xl, hPad, 16),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manajemen Kupon Diskon',
                          style: AppTypography.headlineLg(),
                        ),
                        Text(
                          'Buat dan kelola kode promo penyewaan busana adat',
                          style: AppTypography.bodyMd(
                            color: AppColors.textSubtle,
                          ),
                        ),
                      ],
                    ),
                    SwButton(
                      label: 'Tambah Kupon',
                      leadingIcon: Icons.add_rounded,
                      onPressed: () => _openCouponForm(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ...couponsAsync.when(
            loading: () => [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                sliver: const SliverToBoxAdapter(
                  child: SwContentSwitcher(
                    child: SwLoadingSkeleton(
                      key: ValueKey('adm_cpn_loading'),
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
                      key: const ValueKey('adm_cpn_error'),
                      message: err.toString(),
                      onRetry: () =>
                          ref.read(adminCouponsProvider.notifier).refresh(),
                    ),
                  ),
                ),
              ),
            ],
            data: (coupons) {
              if (coupons.isEmpty) {
                return [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                    sliver: SliverToBoxAdapter(
                      child: SwContentSwitcher(
                        child: SwEmptyState(
                          key: const ValueKey('adm_cpn_empty'),
                          icon: Icons.local_offer_outlined,
                          title: 'Belum Ada Kupon Promo',
                          description:
                              'Tambahkan voucher potongan harga untuk menarik penyewa busana.',
                          actionLabel: 'Tambah Kupon',
                          onAction: () => _openCouponForm(),
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
                        final c = coupons[index];
                        final valueLabel = c.type == 'PERCENTAGE'
                            ? 'Diskon ${c.value}%'
                            : 'Potongan ${CurrencyFormatter.formatRupiah(c.value)}';
                        return RepaintBoundary(
                          child: FadeSlideEntrance(
                            key: ValueKey('adm_cpn_${c.id}'),
                            index: index,
                            onceKey: 'adm_cpn_${c.id}',
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
                                            c.code,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.titleMd(
                                              color: AppColors.brandGreen,
                                            ),
                                          ),
                                        ),
                                        SwStatusBadge(
                                          label: c.isActive
                                              ? 'Aktif'
                                              : 'Nonaktif',
                                          tone: c.isActive
                                              ? SwBadgeTone.success
                                              : SwBadgeTone.error,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$valueLabel • Min. order ${CurrencyFormatter.formatRupiah(c.minOrder)}',
                                      style: AppTypography.labelMd(),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Terpakai ${c.usedCount}/${c.maxUses} • Berakhir ${c.expiresAt}',
                                      style: AppTypography.labelSm(),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        SwButton(
                                          label: 'Ubah',
                                          variant: SwButtonVariant.secondary,
                                          height: 34,
                                          onPressed: () => _openCouponForm(c),
                                        ),
                                        SwButton(
                                          label: 'Hapus',
                                          variant: SwButtonVariant.destructive,
                                          height: 34,
                                          onPressed: () => _deleteCoupon(c),
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
                      childCount: coupons.length,
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/models/admin_models.dart';
import '../providers/admin_providers.dart';

class AdminCostumesScreen extends ConsumerStatefulWidget {
  const AdminCostumesScreen({super.key});

  @override
  ConsumerState<AdminCostumesScreen> createState() =>
      _AdminCostumesScreenState();
}

class _AdminCostumesScreenState extends ConsumerState<AdminCostumesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCostumeForm([AdminCostumeModel? existing]) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final categoryCtrl = TextEditingController(
      text: existing?.category ?? 'Klasik Keraton',
    );
    final priceCtrl = TextEditingController(
      text: existing != null ? existing.price.toString() : '200000',
    );
    final stockCtrl = TextEditingController(
      text: existing != null ? existing.stock.toString() : '4',
    );
    final originCtrl = TextEditingController(
      text: existing?.origin ?? 'Surakarta, Jawa Tengah',
    );
    final imageCtrl = TextEditingController(
      text: existing?.image ?? '/images/tari-topeng-malangan.png',
    );
    final descCtrl = TextEditingController(text: existing?.description ?? '');

    final selectedSizes = Set<String>.from(
      existing?.sizes.isNotEmpty == true ? existing!.sizes : ['S', 'M', 'L'],
    );
    var isSaving = false;
    var isUploading = false;

    const allSizeChoices = ['S', 'M', 'L', 'XL', 'All Size'];

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
              constraints: const BoxConstraints(maxWidth: 520),
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
                            ? 'Tambah Kostum Keraton'
                            : 'Ubah Kostum Keraton',
                        style: AppTypography.headlineMd(),
                      ),
                      const SizedBox(height: 14),
                      SwInput(
                        controller: nameCtrl,
                        label: 'Nama Kostum',
                        validator: (v) =>
                            SwValidators.requiredField(v, 'Nama kostum'),
                      ),
                      const SizedBox(height: 12),
                      SwInput(
                        controller: categoryCtrl,
                        label: 'Kategori Busana',
                        validator: (v) =>
                            SwValidators.requiredField(v, 'Kategori'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SwInput(
                              controller: priceCtrl,
                              label: 'Tarif Sewa / Hari (Rp)',
                              keyboardType: TextInputType.number,
                              inputFormatters: SwInputFormatters.digitsOnly,
                              validator: (v) {
                                final numVal = int.tryParse(v ?? '');
                                if (numVal == null || numVal <= 0) {
                                  return 'Harga harus > 0';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SwInput(
                              controller: stockCtrl,
                              label: 'Stok Total',
                              keyboardType: TextInputType.number,
                              inputFormatters: SwInputFormatters.digitsOnly,
                              validator: (v) {
                                final numVal = int.tryParse(v ?? '');
                                if (numVal == null || numVal < 0) {
                                  return 'Stok >= 0';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Ukuran Tersedia', style: AppTypography.labelMd()),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: allSizeChoices.map((s) {
                          final active = selectedSizes.contains(s);
                          return SwFilterChip(
                            label: s,
                            selected: active,
                            onTap: () => setDialogState(() {
                              if (active && selectedSizes.length > 1) {
                                selectedSizes.remove(s);
                              } else {
                                selectedSizes.add(s);
                              }
                            }),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      SwInput(
                        controller: originCtrl,
                        label: 'Asal Pakem / Daerah',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: SwInput(
                              controller: imageCtrl,
                              label: 'Path / URL Foto Busana',
                              validator: (v) =>
                                  SwValidators.requiredField(v, 'Foto busana'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SwButton(
                            label: 'Unggah',
                            variant: SwButtonVariant.secondary,
                            height: 46,
                            isLoading: isUploading,
                            onPressed: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 85,
                              );
                              if (picked == null) return;
                              setDialogState(() => isUploading = true);
                              try {
                                final bytes = await picked.readAsBytes();
                                final url = await ref
                                    .read(adminCatalogRepositoryProvider)
                                    .uploadMediaBytes(
                                      bytes: bytes,
                                      filename: picked.name,
                                      prefix: 'costume',
                                    );
                                setDialogState(() {
                                  imageCtrl.text = url;
                                  isUploading = false;
                                });
                              } catch (_) {
                                setDialogState(() => isUploading = false);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwInput(
                        controller: descCtrl,
                        label: 'Deskripsi & Kelengkapan',
                        maxLines: 3,
                        validator: (v) =>
                            SwValidators.requiredField(v, 'Deskripsi'),
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
                              label: 'Simpan Kostum',
                              isLoading: isSaving,
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                setDialogState(() => isSaving = true);
                                try {
                                  final model = AdminCostumeModel(
                                    id: existing?.id ?? '',
                                    name: nameCtrl.text.trim(),
                                    category: categoryCtrl.text.trim(),
                                    price: int.parse(priceCtrl.text.trim()),
                                    rating: existing?.rating ?? 5.0,
                                    reviewCount: existing?.reviewCount ?? 0,
                                    stock: int.parse(stockCtrl.text.trim()),
                                    sizes: selectedSizes.toList(),
                                    sizeStocks: existing?.sizeStocks ?? const {},
                                    image: imageCtrl.text.trim(),
                                    description: descCtrl.text.trim(),
                                    origin: originCtrl.text.trim(),
                                  );
                                  await ref
                                      .read(adminCatalogRepositoryProvider)
                                      .saveCostume(model);
                                  await ref
                                      .read(adminCostumesProvider.notifier)
                                      .refresh();
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
            ),
          );
        },
      ),
    );
  }

  Future<void> _openStockLedgerSheet(AdminCostumeModel costume) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.parchment,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _StockLedgerSheet(costume: costume),
    );
  }

  Future<void> _deleteCostume(AdminCostumeModel costume) async {
    final confirm = await SwConfirmDialog.showDeleteModal(
      context,
      itemName: costume.name,
    );
    if (!confirm || !mounted) return;
    try {
      await ref.read(adminCatalogRepositoryProvider).deleteCostume(costume.id);
      await ref.read(adminCostumesProvider.notifier).refresh();
      ref.invalidate(adminAnalyticsProvider);
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
    final costumesAsync = ref.watch(adminCostumesProvider);
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
      onRefresh: () => ref.read(adminCostumesProvider.notifier).refresh(),
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
                  SizedBox(
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
                              'Kelola Kostum & Mutasi Stok',
                              style: AppTypography.headlineLg(),
                            ),
                            Text(
                              'Inventaris busana keraton beserta ledger pergerakan stok',
                              style: AppTypography.bodyMd(
                                color: AppColors.textSubtle,
                              ),
                            ),
                          ],
                        ),
                        SwButton(
                          label: 'Tambah Kostum',
                          leadingIcon: Icons.add_rounded,
                          onPressed: () => _openCostumeForm(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SwInput(
                    controller: _searchController,
                    hint: 'Cari nama kostum atau kategori...',
                    prefixIcon: Icons.search_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
          ...costumesAsync.when(
            loading: () => [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                sliver: const SliverToBoxAdapter(
                  child: SwContentSwitcher(
                    child: SwLoadingSkeleton(
                      key: ValueKey('adm_cos_loading'),
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
                      key: const ValueKey('adm_cos_error'),
                      message: err.toString(),
                      onRetry: () =>
                          ref.read(adminCostumesProvider.notifier).refresh(),
                    ),
                  ),
                ),
              ),
            ],
            data: (costumes) {
              final filtered = costumes.where((c) {
                return q.isEmpty ||
                    c.name.toLowerCase().contains(q) ||
                    c.category.toLowerCase().contains(q);
              }).toList();

              if (filtered.isEmpty) {
                return [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                    sliver: SliverToBoxAdapter(
                      child: SwContentSwitcher(
                        child: SwEmptyState(
                          key: ValueKey('adm_cos_empty_$q'),
                          icon: Icons.checkroom_outlined,
                          title: 'Tidak Ada Data Kostum',
                          description:
                              'Tambahkan busana baru atau ubah kata kunci pencarian.',
                          actionLabel: 'Tambah Kostum',
                          onAction: () => _openCostumeForm(),
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
                        final c = filtered[index];
                        final lowStock = c.stock <= 2;
                        return RepaintBoundary(
                          child: FadeSlideEntrance(
                            key: ValueKey('adm_cos_${c.id}'),
                            index: index,
                            onceKey: 'adm_cos_${c.id}',
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SwCard(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SwImage(
                                      source: c.image,
                                      baseUrl: config.baseUrl,
                                      width: 72,
                                      height: 72,
                                      borderRadius: 10,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.titleMd(),
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              SwStatusBadge(
                                                label: c.category,
                                                tone: SwBadgeTone.gold,
                                              ),
                                              SwStatusBadge(
                                                label: 'Stok: ${c.stock}',
                                                tone: lowStock
                                                    ? SwBadgeTone.warning
                                                    : SwBadgeTone.success,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${CurrencyFormatter.formatRupiah(c.price)}/hari • Ukuran: ${c.sizes.join(', ')}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.labelMd(
                                              color: AppColors.brandGreen,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: [
                                              SwButton(
                                                label: 'Mutasi Stok',
                                                leadingIcon:
                                                    Icons.swap_vert_rounded,
                                                variant:
                                                    SwButtonVariant.primary,
                                                height: 34,
                                                onPressed: () =>
                                                    _openStockLedgerSheet(c),
                                              ),
                                              SwButton(
                                                label: 'Ubah',
                                                variant:
                                                    SwButtonVariant.secondary,
                                                height: 34,
                                                onPressed: () =>
                                                    _openCostumeForm(c),
                                              ),
                                              SwButton(
                                                label: 'Hapus',
                                                variant:
                                                    SwButtonVariant.destructive,
                                                height: 34,
                                                onPressed: () =>
                                                    _deleteCostume(c),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
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

class _StockLedgerSheet extends ConsumerStatefulWidget {
  const _StockLedgerSheet({required this.costume});

  final AdminCostumeModel costume;

  @override
  ConsumerState<_StockLedgerSheet> createState() => _StockLedgerSheetState();
}

class _StockLedgerSheetState extends ConsumerState<_StockLedgerSheet> {
  final _deltaCtrl = TextEditingController(text: '1');
  final _noteCtrl = TextEditingController();
  late String _selectedSize;
  String _selectedReason = 'restock';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.costume.sizes.isNotEmpty
        ? widget.costume.sizes.first
        : 'All Size';
  }

  @override
  void dispose() {
    _deltaCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitMovement(int currentStock) async {
    final delta = int.tryParse(_deltaCtrl.text.trim());
    if (delta == null || delta == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan perubahan stok non-nol (misal +2 atau -1).'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final stockAfter = (currentStock + delta).clamp(0, 9999);
      await ref.read(adminCatalogRepositoryProvider).recordStockMovement(
            costumeId: widget.costume.id,
            costumeName: widget.costume.name,
            size: _selectedSize,
            delta: delta,
            stockAfter: stockAfter,
            reason: _selectedReason,
            note: _noteCtrl.text.trim(),
          );
      _noteCtrl.clear();
      ref.invalidate(adminStockMovementsProvider(widget.costume.id));
      await ref.read(adminCostumesProvider.notifier).refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movementsAsync =
        ref.watch(adminStockMovementsProvider(widget.costume.id));
    final currentCostumes = ref.watch(adminCostumesProvider).value ?? const [];
    final liveCostume = currentCostumes
            .where((c) => c.id == widget.costume.id)
            .firstOrNull ??
        widget.costume;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ledger Mutasi Stok',
                          style: AppTypography.headlineMd(),
                        ),
                        Text(
                          '${liveCostume.name} • Stok Saat Ini: ${liveCostume.stock}',
                          style: AppTypography.bodyMd(
                            color: AppColors.textSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SwCard(
                backgroundColor: AppColors.surfaceContainerLow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catat Penyesuaian Stok',
                      style: AppTypography.titleMd(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SwInput(
                            controller: _deltaCtrl,
                            label: 'Delta (+/-)',
                            hint: '+2 atau -1',
                            inputFormatters: SwInputFormatters.signedInt,
                            keyboardType: const TextInputType.numberWithOptions(
                              signed: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedReason,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Alasan',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'restock',
                                child: Text(
                                  'Restock',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'koreksi',
                                child: Text(
                                  'Koreksi Opname',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'rusak',
                                child: Text(
                                  'Rusak / Perbaikan',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'sewa',
                                child: Text(
                                  'Keluar Sewa',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedReason = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: (liveCostume.sizes.isNotEmpty
                              ? liveCostume.sizes
                              : const ['All Size'])
                          .map(
                            (s) => SwFilterChip(
                              label: s,
                              selected: _selectedSize == s,
                              onTap: () => setState(() => _selectedSize = s),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    SwInput(
                      controller: _noteCtrl,
                      label: 'Catatan Kurator (Opsional)',
                      hint: 'Misal: Jahit ulang bordir selesai',
                    ),
                    const SizedBox(height: 12),
                    SwButton(
                      label: 'Simpan Mutasi Stok',
                      fullWidth: true,
                      isLoading: _isSubmitting,
                      onPressed: () => _submitMovement(liveCostume.stock),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Riwayat Mutasi', style: AppTypography.titleMd()),
              const SizedBox(height: 8),
              movementsAsync.when(
                loading: () => const SwLoadingSkeleton(height: 90),
                error: (err, _) => SwErrorView(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(
                    adminStockMovementsProvider(widget.costume.id),
                  ),
                ),
                data: (movements) {
                  if (movements.isEmpty) {
                    return Text(
                      'Belum ada riwayat mutasi stok untuk kostum ini.',
                      style: AppTypography.bodyMd(color: AppColors.textSubtle),
                    );
                  }
                  return Column(
                    children: movements.map((m) {
                      final isPlus = m.delta >= 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SwCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              SwStatusBadge(
                                label: '${isPlus ? '+' : ''}${m.delta}',
                                tone: isPlus
                                    ? SwBadgeTone.success
                                    : SwBadgeTone.warning,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${m.reason.toUpperCase()} (${m.size}) • Stok akhir: ${m.stockAfter}',
                                      style: AppTypography.labelMd(),
                                    ),
                                    if (m.note != null && m.note!.isNotEmpty)
                                      Text(
                                        m.note!,
                                        style: AppTypography.bodyMd(
                                          color: AppColors.textSubtle,
                                        ),
                                      ),
                                    Text(
                                      '${m.actorName} • ${m.createdAt}',
                                      style: AppTypography.labelSm(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

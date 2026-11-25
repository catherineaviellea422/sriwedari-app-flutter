import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/models/admin_models.dart';
import '../providers/admin_providers.dart';

class AdminGalleryScreen extends ConsumerStatefulWidget {
  const AdminGalleryScreen({
    super.key,
    this.openCreateOnLoad = false,
  });

  final bool openCreateOnLoad;

  @override
  ConsumerState<AdminGalleryScreen> createState() => _AdminGalleryScreenState();
}

class _AdminGalleryScreenState extends ConsumerState<AdminGalleryScreen> {
  final _searchController = TextEditingController();
  String _selectedType = 'semua';
  bool _handledAutoOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.openCreateOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _handledAutoOpen) return;
        _handledAutoOpen = true;
        _openGalleryForm();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openGalleryForm([AdminGalleryModel? existing]) async {
    final categories = ref.read(adminCategoriesProvider).value ?? const [];
    final costumes = ref.read(adminCostumesProvider).value ?? const [];

    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final originCtrl = TextEditingController(
      text: existing?.origin ?? 'Surakarta, Jawa Tengah',
    );
    final dateCtrl = TextEditingController(
      text: existing?.date ??
          DateTime.now().toIso8601String().substring(0, 10),
    );
    final imageCtrl = TextEditingController(
      text: existing?.image ?? '/images/tari-topeng-malangan.png',
    );
    final descCtrl = TextEditingController(text: existing?.description ?? '');

    var selectedType = existing?.type ?? 'foto';
    var selectedCategorySlug = existing?.category ??
        (categories.isNotEmpty
            ? categories.first.name.toLowerCase().replaceAll(' ', '-')
            : 'tari-tradisional');
    var selectedCategoryName = existing?.categoryName ??
        (categories.isNotEmpty ? categories.first.name : 'Tari Tradisional');
    String? selectedCostumeId = existing?.costumeId;
    var isSaving = false;
    var isUploading = false;

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
                            ? 'Tambah Karya Galeri'
                            : 'Ubah Karya Galeri',
                        style: AppTypography.headlineMd(),
                      ),
                      const SizedBox(height: 14),
                      SwInput(
                        controller: titleCtrl,
                        label: 'Judul Karya / Tarian',
                        hint: 'Contoh: Tari Bedhaya Ketawang',
                        validator: (v) =>
                            SwValidators.requiredField(v, 'Judul karya'),
                      ),
                      const SizedBox(height: 12),
                      if (categories.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          initialValue: categories
                                  .any((c) => c.name == selectedCategoryName)
                              ? selectedCategoryName
                              : categories.first.name,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Kategori Seni',
                          ),
                          items: categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.name,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            setDialogState(() {
                              selectedCategoryName = val;
                              selectedCategorySlug =
                                  val.toLowerCase().replaceAll(' ', '-');
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text('Tipe Media', style: AppTypography.labelMd()),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          SwFilterChip(
                            label: 'Foto',
                            selected: selectedType == 'foto',
                            onTap: () =>
                                setDialogState(() => selectedType = 'foto'),
                          ),
                          SwFilterChip(
                            label: 'Video',
                            selected: selectedType == 'video',
                            onTap: () =>
                                setDialogState(() => selectedType = 'video'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwInput(
                        controller: originCtrl,
                        label: 'Asal Daerah / Keraton',
                        validator: (v) =>
                            SwValidators.requiredField(v, 'Asal daerah'),
                      ),
                      const SizedBox(height: 12),
                      SwInput(
                        controller: dateCtrl,
                        label: 'Tanggal Arsip (YYYY-MM-DD)',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: SwInputFormatters.isoDate,
                        validator: (v) =>
                            SwValidators.isoDate(v, 'Tanggal arsip'),
                        suffixWidget: IconButton(
                          icon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                          ),
                          onPressed: () async {
                            final initial =
                                DateTime.tryParse(dateCtrl.text.trim()) ??
                                    DateTime.now();
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: initial,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2035),
                              initialEntryMode:
                                  DatePickerEntryMode.calendarOnly,
                            );
                            if (picked != null) {
                              dateCtrl.text =
                                  picked.toIso8601String().substring(0, 10);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: SwInput(
                              controller: imageCtrl,
                              label: 'Path / URL Gambar',
                              validator: (v) =>
                                  SwValidators.requiredField(v, 'Gambar'),
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
                                      prefix: 'gallery',
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
                      if (costumes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          initialValue: costumes.any(
                            (c) => c.id == selectedCostumeId,
                          )
                              ? selectedCostumeId
                              : null,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Tautkan Kostum Sewa (Opsional)',
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Tidak ditautkan'),
                            ),
                            ...costumes.map(
                              (c) => DropdownMenuItem<String?>(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setDialogState(() => selectedCostumeId = val),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SwInput(
                        controller: descCtrl,
                        label: 'Deskripsi Kuratorial',
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
                              label: 'Simpan Karya',
                              isLoading: isSaving,
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                setDialogState(() => isSaving = true);
                                try {
                                  final model = AdminGalleryModel(
                                    id: existing?.id ?? '',
                                    title: titleCtrl.text.trim(),
                                    category: selectedCategorySlug,
                                    categoryName: selectedCategoryName,
                                    type: selectedType,
                                    date: dateCtrl.text.trim(),
                                    description: descCtrl.text.trim(),
                                    image: imageCtrl.text.trim(),
                                    views: existing?.views ?? 0,
                                    likes: existing?.likes ?? 0,
                                    origin: originCtrl.text.trim(),
                                    costumeId: selectedCostumeId,
                                  );
                                  await ref
                                      .read(adminCatalogRepositoryProvider)
                                      .saveGallery(model);
                                  await ref
                                      .read(adminGalleriesProvider.notifier)
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

  Future<void> _deleteGallery(AdminGalleryModel item) async {
    final confirm = await SwConfirmDialog.showDeleteModal(
      context,
      itemName: item.title,
    );
    if (!confirm || !mounted) return;
    try {
      await ref.read(adminCatalogRepositoryProvider).deleteGallery(item.id);
      await ref.read(adminGalleriesProvider.notifier).refresh();
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
    final galleriesAsync = ref.watch(adminGalleriesProvider);
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
      onRefresh: () => ref.read(adminGalleriesProvider.notifier).refresh(),
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
                              'Kelola Koleksi Galeri',
                              style: AppTypography.headlineLg(),
                            ),
                            Text(
                              'CRUD arsip seni tari Nusantara & dokumentasi pementasan',
                              style: AppTypography.bodyMd(
                                color: AppColors.textSubtle,
                              ),
                            ),
                          ],
                        ),
                        SwButton(
                          label: 'Tambah Karya',
                          leadingIcon: Icons.add_photo_alternate_outlined,
                          onPressed: () => _openGalleryForm(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SwInput(
                    controller: _searchController,
                    hint: 'Cari judul karya, kategori, atau daerah asal...',
                    prefixIcon: Icons.search_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SwFilterChip(
                        label: 'Semua Tipe',
                        selected: _selectedType == 'semua',
                        onTap: () => setState(() => _selectedType = 'semua'),
                      ),
                      SwFilterChip(
                        label: 'Foto',
                        selected: _selectedType == 'foto',
                        onTap: () => setState(() => _selectedType = 'foto'),
                      ),
                      SwFilterChip(
                        label: 'Video',
                        selected: _selectedType == 'video',
                        onTap: () => setState(() => _selectedType = 'video'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ...galleriesAsync.when(
            loading: () => [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                sliver: const SliverToBoxAdapter(
                  child: SwContentSwitcher(
                    child: SwLoadingSkeleton(
                      key: ValueKey('adm_gal_loading'),
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
                      key: const ValueKey('adm_gal_error'),
                      message: err.toString(),
                      onRetry: () =>
                          ref.read(adminGalleriesProvider.notifier).refresh(),
                    ),
                  ),
                ),
              ),
            ],
            data: (items) {
              final filtered = items.where((g) {
                final matchesType =
                    _selectedType == 'semua' || g.type == _selectedType;
                final matchesQuery = q.isEmpty ||
                    g.title.toLowerCase().contains(q) ||
                    g.categoryName.toLowerCase().contains(q) ||
                    g.origin.toLowerCase().contains(q);
                return matchesType && matchesQuery;
              }).toList();

              if (filtered.isEmpty) {
                return [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                    sliver: SliverToBoxAdapter(
                      child: SwContentSwitcher(
                        child: SwEmptyState(
                          key: ValueKey('adm_gal_empty_$_selectedType-$q'),
                          icon: Icons.photo_library_outlined,
                          title: 'Belum Ada Karya Galeri',
                          description:
                              'Tambahkan koleksi baru atau sesuaikan kata kunci pencarian.',
                          actionLabel: 'Tambah Karya',
                          onAction: () => _openGalleryForm(),
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
                        final item = filtered[index];
                        return RepaintBoundary(
                          child: FadeSlideEntrance(
                            key: ValueKey('adm_gal_${item.id}_$_selectedType'),
                            index: index,
                            onceKey: 'adm_gal_${item.id}_$_selectedType',
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SwCard(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SwImage(
                                      source: item.image,
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
                                            item.title,
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
                                                label: item.categoryName,
                                                tone: SwBadgeTone.gold,
                                              ),
                                              SwStatusBadge(
                                                label: item.type.toUpperCase(),
                                                tone: SwBadgeTone.info,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${item.origin} • ${item.views} tayang • ${item.likes} suka',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.labelSm(),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: [
                                              SwButton(
                                                label: 'Ubah',
                                                variant:
                                                    SwButtonVariant.secondary,
                                                height: 34,
                                                onPressed: () =>
                                                    _openGalleryForm(item),
                                              ),
                                              SwButton(
                                                label: 'Hapus',
                                                variant:
                                                    SwButtonVariant.destructive,
                                                height: 34,
                                                onPressed: () =>
                                                    _deleteGallery(item),
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/models/admin_models.dart';
import '../providers/admin_providers.dart';

class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  ConsumerState<AdminCategoriesScreen> createState() =>
      _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends ConsumerState<AdminCategoriesScreen> {
  Future<void> _openCategoryForm([AdminCategoryModel? existing]) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    var selectedIcon = existing?.icon ?? 'theater_comedy';
    var isSaving = false;

    const iconChoices = [
      ('theater_comedy', 'Tari / Topeng'),
      ('auto_awesome', 'Kreasi'),
      ('checkroom', 'Busana'),
      ('music_note', 'Karawitan'),
      ('history_edu', 'Pusaka'),
    ];

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
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        existing == null
                            ? 'Tambah Kategori Seni'
                            : 'Ubah Kategori Seni',
                        style: AppTypography.headlineMd(),
                      ),
                      const SizedBox(height: 14),
                      SwInput(
                        controller: nameCtrl,
                        label: 'Nama Kategori',
                        hint: 'Contoh: Tari Klasik Keraton',
                        validator: (v) =>
                            SwValidators.requiredField(v, 'Nama kategori'),
                      ),
                      const SizedBox(height: 12),
                      Text('Ikon Kategori', style: AppTypography.labelMd()),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: iconChoices.map((choice) {
                          return SwFilterChip(
                            label: choice.$2,
                            selected: selectedIcon == choice.$1,
                            onTap: () =>
                                setDialogState(() => selectedIcon = choice.$1),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      SwInput(
                        controller: descCtrl,
                        label: 'Deskripsi Singkat',
                        maxLines: 2,
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
                              label: 'Simpan',
                              isLoading: isSaving,
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                setDialogState(() => isSaving = true);
                                try {
                                  await ref
                                      .read(adminCatalogRepositoryProvider)
                                      .saveCategory(
                                        AdminCategoryModel(
                                          id: existing?.id ?? '',
                                          name: nameCtrl.text.trim(),
                                          icon: selectedIcon,
                                          description: descCtrl.text.trim(),
                                          count: existing?.count ?? 0,
                                        ),
                                      );
                                  await ref
                                      .read(adminCategoriesProvider.notifier)
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

  Future<void> _deleteCategory(AdminCategoryModel cat) async {
    final confirm = await SwConfirmDialog.showDeleteModal(
      context,
      itemName: cat.name,
    );
    if (!confirm || !mounted) return;
    try {
      await ref.read(adminCatalogRepositoryProvider).deleteCategory(cat.id);
      await ref.read(adminCategoriesProvider.notifier).refresh();
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
    final categoriesAsync = ref.watch(adminCategoriesProvider);
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);

    return RefreshIndicator(
      onRefresh: () => ref.read(adminCategoriesProvider.notifier).refresh(),
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
                              'Kategori Galeri Seni',
                              style: AppTypography.headlineLg(),
                            ),
                            Text(
                              'Atur taksonomi rumpun seni tari & kebudayaan Sriwedari',
                              style: AppTypography.bodyMd(
                                color: AppColors.textSubtle,
                              ),
                            ),
                          ],
                        ),
                        SwButton(
                          label: 'Tambah Kategori',
                          leadingIcon: Icons.add_rounded,
                          onPressed: () => _openCategoryForm(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  categoriesAsync.when(
                    loading: () => const SwLoadingSkeleton(height: 120),
                    error: (err, _) => SwErrorView(
                      message: err.toString(),
                      onRetry: () =>
                          ref.read(adminCategoriesProvider.notifier).refresh(),
                    ),
                    data: (items) {
                      if (items.isEmpty) {
                        return SwEmptyState(
                          icon: Icons.category_outlined,
                          title: 'Belum Ada Kategori',
                          description: 'Tambahkan kategori seni pertama.',
                          actionLabel: 'Tambah Kategori',
                          onAction: () => _openCategoryForm(),
                        );
                      }

                      return Column(
                        children: items.map((cat) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SwCard(
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.metricMint,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.category_rounded,
                                      color: AppColors.brandGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cat.name,
                                          style: AppTypography.titleMd(),
                                        ),
                                        Text(
                                          cat.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.bodyMd(
                                            color: AppColors.textSubtle,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        SwStatusBadge(
                                          label: '${cat.count} Karya',
                                          tone: SwBadgeTone.gold,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _openCategoryForm(cat),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: AppColors.brandGreen,
                                    ),
                                    tooltip: 'Ubah',
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteCategory(cat),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.error,
                                    ),
                                    tooltip: 'Hapus',
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
        ),
      ),
    );
  }
}

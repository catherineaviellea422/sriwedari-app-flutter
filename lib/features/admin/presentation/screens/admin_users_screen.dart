import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/models/admin_models.dart';
import '../providers/admin_providers.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchCtrl = TextEditingController();
  String _roleFilter = 'Semua';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openUserForm([AdminAccountModel? existing]) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final passCtrl = TextEditingController();

    var role = existing?.role ?? 'user';
    var status = existing?.status ?? 'active';
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
              constraints: const BoxConstraints(maxWidth: 460),
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
                            ? 'Tambah Pengguna / Kurator'
                            : 'Ubah Data Akun',
                        style: AppTypography.headlineMd(),
                      ),
                      const SizedBox(height: 14),
                      SwInput(
                        controller: nameCtrl,
                        label: 'Nama Lengkap',
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: SwInputFormatters.personName,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (v) =>
                            SwValidators.personName(v, 'Nama lengkap'),
                      ),
                      const SizedBox(height: 12),
                      SwInput(
                        controller: emailCtrl,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        inputFormatters: SwInputFormatters.noWhitespace,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: SwValidators.email,
                      ),
                      const SizedBox(height: 12),
                      SwInput(
                        controller: phoneCtrl,
                        label: 'No. WhatsApp',
                        keyboardType: TextInputType.phone,
                        inputFormatters: SwInputFormatters.phoneDigits,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: SwValidators.phoneId,
                      ),
                      const SizedBox(height: 12),
                      SwInput(
                        controller: passCtrl,
                        label: existing == null
                            ? 'Kata Sandi'
                            : 'Kata Sandi Baru (Opsional)',
                        hint: existing == null
                            ? 'Minimal 6 karakter'
                            : 'Kosongkan jika tidak diubah',
                        obscureText: true,
                        enablePasswordToggle: true,
                        validator: (v) {
                          if (existing == null &&
                              (v == null || v.trim().length < 6)) {
                            return 'Kata sandi minimal 6 karakter';
                          }
                          if (existing != null &&
                              v != null &&
                              v.isNotEmpty &&
                              v.trim().length < 6) {
                            return 'Kata sandi minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Text('Peran Akun', style: AppTypography.labelMd()),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          SwFilterChip(
                            label: 'Pengguna (User)',
                            selected: role == 'user',
                            onTap: () => setDialogState(() => role = 'user'),
                          ),
                          SwFilterChip(
                            label: 'Kurator (Admin)',
                            selected: role == 'admin',
                            onTap: () => setDialogState(() => role = 'admin'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Status Akun Aktif',
                              style: AppTypography.labelMd(),
                            ),
                          ),
                          Switch(
                            value: status == 'active',
                            onChanged: (v) => setDialogState(
                              () => status = v ? 'active' : 'inactive',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
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
                              label: 'Simpan Akun',
                              isLoading: isSaving,
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                setDialogState(() => isSaving = true);
                                try {
                                  await ref
                                      .read(adminOperationsRepositoryProvider)
                                      .saveUser(
                                        AdminAccountModel(
                                          id: existing?.id ?? '',
                                          name: nameCtrl.text.trim(),
                                          email: emailCtrl.text.trim(),
                                          phone: phoneCtrl.text.trim(),
                                          role: role,
                                          status: status,
                                          points: existing?.points ?? 0,
                                          registeredAt: existing?.registeredAt ??
                                              DateTime.now()
                                                  .toIso8601String()
                                                  .substring(0, 10),
                                        ),
                                        password: passCtrl.text,
                                      );
                                  await ref
                                      .read(adminUsersProvider.notifier)
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

  Future<void> _deleteUser(AdminAccountModel user) async {
    final ok = await SwConfirmDialog.showDeleteModal(
      context,
      itemName: user.name,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(adminOperationsRepositoryProvider).deleteUser(user.id);
      await ref.read(adminUsersProvider.notifier).refresh();
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
    final usersAsync = ref.watch(adminUsersProvider);
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);
    final q = _searchCtrl.text.trim().toLowerCase();
    final hPad = centeredSliverHorizontalPadding(
      width,
      horizontalMargin: margin,
      maxContentWidth: AppSpacing.maxContentWidth,
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(adminUsersProvider.notifier).refresh(),
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
                              'Kelola Pengguna & Kurator',
                              style: AppTypography.headlineLg(),
                            ),
                            Text(
                              'Manajemen akun pengunjung (`user-db`) & kurator (`admin-db`)',
                              style: AppTypography.bodyMd(
                                color: AppColors.textSubtle,
                              ),
                            ),
                          ],
                        ),
                        SwButton(
                          label: 'Tambah Akun',
                          leadingIcon: Icons.person_add_alt_1_outlined,
                          onPressed: () => _openUserForm(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SwInput(
                    controller: _searchCtrl,
                    hint: 'Cari nama, email, atau nomor WhatsApp...',
                    prefixIcon: Icons.search_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Semua', 'admin', 'user'].map((role) {
                      return SwFilterChip(
                        label: role == 'Semua'
                            ? 'Semua Peran'
                            : role == 'admin'
                                ? 'Kurator (Admin)'
                                : 'Pengguna (User)',
                        selected: _roleFilter == role,
                        onTap: () => setState(() => _roleFilter = role),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          ...usersAsync.when(
            loading: () => [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                sliver: const SliverToBoxAdapter(
                  child: SwContentSwitcher(
                    child: SwLoadingSkeleton(
                      key: ValueKey('adm_usr_loading'),
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
                      key: const ValueKey('adm_usr_error'),
                      message: err.toString(),
                      onRetry: () =>
                          ref.read(adminUsersProvider.notifier).refresh(),
                    ),
                  ),
                ),
              ),
            ],
            data: (users) {
              final filtered = users.where((u) {
                final matchRole = _roleFilter == 'Semua' ||
                    u.role.toLowerCase() == _roleFilter;
                final matchQuery = q.isEmpty ||
                    u.name.toLowerCase().contains(q) ||
                    u.email.toLowerCase().contains(q) ||
                    u.phone.toLowerCase().contains(q);
                return matchRole && matchQuery;
              }).toList();

              if (filtered.isEmpty) {
                return [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                    sliver: SliverToBoxAdapter(
                      child: SwContentSwitcher(
                        child: SwEmptyState(
                          key: ValueKey('adm_usr_empty_$_roleFilter-$q'),
                          icon: Icons.manage_accounts_outlined,
                          title: 'Belum Ada Akun',
                          description:
                              'Tidak ditemukan akun pengguna dengan filter tersebut.',
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
                        final u = filtered[index];
                        return RepaintBoundary(
                          child: FadeSlideEntrance(
                            key: ValueKey('adm_usr_${u.id}_$_roleFilter'),
                            index: index,
                            onceKey: 'adm_usr_${u.id}_$_roleFilter',
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
                                            u.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.titleMd(),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SwStatusBadge.fromRole(u.role),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${u.email} • ${u.phone}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodyMd(
                                        color: AppColors.textSubtle,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        SwStatusBadge(
                                          label: u.isActive
                                              ? 'Aktif'
                                              : 'Nonaktif',
                                          tone: u.isActive
                                              ? SwBadgeTone.success
                                              : SwBadgeTone.error,
                                        ),
                                        SwStatusBadge(
                                          label: '${u.points} Poin',
                                          tone: SwBadgeTone.gold,
                                        ),
                                      ],
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
                                          onPressed: () => _openUserForm(u),
                                        ),
                                        SwButton(
                                          label: 'Hapus',
                                          variant: SwButtonVariant.destructive,
                                          height: 34,
                                          onPressed: () => _deleteUser(u),
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

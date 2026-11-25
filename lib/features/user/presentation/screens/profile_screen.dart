import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/sw_page_transitions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/user_models.dart';
import '../providers/user_catalog_providers.dart';
import '../providers/user_transactions_providers.dart';
import '../widgets/ticket_boarding_pass_modal.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.initialTab});

  final String? initialTab;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _activeTabIndex = 0; // 0: Sewa, 1: E-Tiket, 2: Favorit
  int _previousTabIndex = 0;
  String? _uploadingOrderId;

  static int _tabIndexFromParam(String? tab) {
    return switch (tab?.toLowerCase()) {
      'tickets' || 'eticket' || 'e-tiket' => 1,
      'wishlist' || 'favorit' => 2,
      'orders' || 'sewa' => 0,
      _ => 0,
    };
  }

  void _selectTab(int nextIndex) {
    if (nextIndex == _activeTabIndex) return;
    setState(() {
      _previousTabIndex = _activeTabIndex;
      _activeTabIndex = nextIndex;
    });
  }

  @override
  void initState() {
    super.initState();
    _activeTabIndex = _tabIndexFromParam(widget.initialTab);
    _previousTabIndex = _activeTabIndex;
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab && widget.initialTab != null) {
      _selectTab(_tabIndexFromParam(widget.initialTab));
    }
  }

  Future<void> _handleLogout() async {
    final ok = await SwConfirmDialog.showLogoutModal(context);
    if (!ok || !mounted) return;
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _showEditProfileDialog(
    UserAccountModel user,
    String baseUrl,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    var avatarUrl = user.avatar ?? '';
    var saving = false;
    var uploadingAvatar = false;

    await showDialog<void>(
      context: context,
      barrierColor: AppColors.modalScrim,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickAndUploadAvatar() async {
            final picked = await ImagePicker().pickImage(
              source: ImageSource.gallery,
            );
            if (picked == null) return;
            setDialogState(() => uploadingAvatar = true);
            try {
              final bytes = await picked.readAsBytes();
              final url = await ref
                  .read(userTransactionsRepositoryProvider)
                  .uploadAvatarBytes(bytes: bytes, filename: picked.name);
              setDialogState(() {
                avatarUrl = url;
                uploadingAvatar = false;
              });
            } on ApiException catch (e) {
              setDialogState(() => uploadingAvatar = false);
              if (mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text(e.message)),
                );
              }
            } catch (_) {
              setDialogState(() => uploadingAvatar = false);
            }
          }

          final initial = user.name.trim().isNotEmpty
              ? user.name.trim()[0].toUpperCase()
              : 'S';

          return Dialog(
            backgroundColor: AppColors.parchment,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusModal),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Edit Profil Anda',
                              style: AppTypography.headlineMd(),
                            ),
                          ),
                          IconButton(
                            onPressed: saving || uploadingAvatar
                                ? null
                                : () => Navigator.of(dialogCtx).pop(),
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'Tutup',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Column(
                          children: [
                            _AvatarCircle(
                              avatarUrl: avatarUrl,
                              baseUrl: baseUrl,
                              initial: initial,
                              size: 76,
                              isLoading: uploadingAvatar,
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: uploadingAvatar || saving
                                  ? null
                                  : pickAndUploadAvatar,
                              icon: const Icon(
                                Icons.photo_camera_outlined,
                                size: 16,
                              ),
                              label: Text(
                                uploadingAvatar
                                    ? 'Mengunggah Foto...'
                                    : 'Ganti Foto Profil',
                                style: AppTypography.labelMd(
                                  color: AppColors.brandGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SwInput(
                        controller: nameCtrl,
                        label: 'Nama Lengkap / Sanggar',
                        prefixIcon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: SwInputFormatters.personName,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (v) =>
                            SwValidators.personName(v, 'Nama lengkap'),
                      ),
                      const SizedBox(height: 12),
                      SwInput(
                        controller: phoneCtrl,
                        label: 'Nomor WhatsApp Aktif',
                        prefixIcon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        inputFormatters: SwInputFormatters.phoneDigits,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: SwValidators.phoneId,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: SwButton(
                              label: 'Batal',
                              variant: SwButtonVariant.secondary,
                              onPressed: saving || uploadingAvatar
                                  ? null
                                  : () => Navigator.of(dialogCtx).pop(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SwButton(
                              label: 'Simpan Perubahan',
                              isLoading: saving,
                              onPressed: uploadingAvatar
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      setDialogState(() => saving = true);
                                      try {
                                        final updated = await ref
                                            .read(
                                              userTransactionsRepositoryProvider,
                                            )
                                            .updateProfile(
                                              name: nameCtrl.text.trim(),
                                              phone: phoneCtrl.text.trim(),
                                              avatar: avatarUrl.isNotEmpty
                                                  ? avatarUrl
                                                  : null,
                                            );
                                        ref
                                            .read(authProvider.notifier)
                                            .updateUserAccount(updated);
                                        if (dialogCtx.mounted) {
                                          Navigator.of(dialogCtx).pop();
                                        }
                                        if (mounted) {
                                          ScaffoldMessenger.of(this.context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Profil berhasil diperbarui.',
                                              ),
                                            ),
                                          );
                                        }
                                      } on ApiException catch (e) {
                                        setDialogState(() => saving = false);
                                        if (mounted) {
                                          ScaffoldMessenger.of(this.context)
                                              .showSnackBar(
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
    nameCtrl.dispose();
    phoneCtrl.dispose();
  }

  Future<void> _showSettingsModal({
    required UserAccountModel? user,
    required String displayName,
    required String displayEmail,
    required String baseUrl,
    required bool isSahabatKeraton,
  }) async {
    await showDialog<void>(
      context: context,
      barrierColor: AppColors.modalScrim,
      builder: (dialogCtx) => Dialog(
        backgroundColor: AppColors.parchment,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusModal),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Informasi & Sesi',
                        style: AppTypography.headlineMd(),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      _SettingInfoRow(label: 'Nama', value: displayName),
                      const Divider(height: 16),
                      _SettingInfoRow(label: 'Email', value: displayEmail),
                      const Divider(height: 16),
                      _SettingInfoRow(
                        label: 'WhatsApp',
                        value: (user != null && user.phone.isNotEmpty)
                            ? user.phone
                            : 'Belum diisi',
                      ),
                      const Divider(height: 16),
                      _SettingInfoRow(
                        label: 'Keanggotaan',
                        value:
                            isSahabatKeraton ? 'Sahabat Keraton' : 'Warga Budaya',
                      ),
                      if (user != null) ...[
                        const Divider(height: 16),
                        _SettingInfoRow(
                          label: 'Peran Akun',
                          value: user.role == 'admin' ? 'Kurator' : 'Pengguna',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (user != null) ...[
                  SwButton(
                    label: 'Ubah Data Profil',
                    variant: SwButtonVariant.secondary,
                    leadingIcon: Icons.edit_outlined,
                    fullWidth: true,
                    onPressed: () {
                      Navigator.of(dialogCtx).pop();
                      _showEditProfileDialog(user, baseUrl);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                SwButton(
                  label: 'Keluar Akun',
                  variant: SwButtonVariant.destructive,
                  leadingIcon: Icons.logout_rounded,
                  fullWidth: true,
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    _handleLogout();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showBenefitsModal(int points, bool isSahabatKeraton) async {
    await showDialog<void>(
      context: context,
      barrierColor: AppColors.modalScrim,
      builder: (dialogCtx) => Dialog(
        backgroundColor: AppColors.parchment,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusModal),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.goldDark,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Keuntungan Sahabat Keraton',
                        style: AppTypography.headlineMd(),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isSahabatKeraton
                      ? 'Selamat! Status Sahabat Keraton Anda aktif dengan $points Poin Budaya.'
                      : 'Kumpulkan minimal 500 Poin Budaya untuk membuka seluruh hak istimewa Sahabat Keraton (saat ini: $points poin).',
                  style: AppTypography.bodyMd(color: AppColors.textSubtle),
                ),
                const SizedBox(height: 14),
                const _BenefitDetailTile(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Poin Budaya Otomatis',
                  subtitle:
                      'Setiap penyewaan busana dan pemesanan tiket wayang menambah saldo Poin Budaya Anda.',
                ),
                const SizedBox(height: 10),
                const _BenefitDetailTile(
                  icon: Icons.confirmation_number_outlined,
                  title: 'Kode Kupon Eksklusif',
                  subtitle:
                      'Gunakan kode SRIWEDARI10 (diskon 10%) atau KERATON25 pada formulir sewa busana.',
                ),
                const SizedBox(height: 10),
                const _BenefitDetailTile(
                  icon: Icons.qr_code_2_rounded,
                  title: 'Check-In Cepat E-Tiket Digital',
                  subtitle:
                      'Tunjukkan QR & Barcode boarding pass langsung di Pendopo Sriwedari tanpa antre cetak.',
                ),
                const SizedBox(height: 14),
                SwButton(
                  label: 'Mengerti',
                  fullWidth: true,
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showProofPreviewDialog({
    required String orderId,
    required String proofSource,
    required String baseUrl,
  }) async {
    await showDialog<void>(
      context: context,
      barrierColor: AppColors.modalScrim,
      builder: (dialogCtx) => Dialog(
        backgroundColor: AppColors.parchment,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusModal),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Invoice $orderId',
                        style: AppTypography.headlineMd(),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: SwImage(
                    source: proofSource,
                    baseUrl: baseUrl,
                    width: 380,
                    height: 280,
                    fit: BoxFit.contain,
                    borderRadius: 12,
                  ),
                ),
                const SizedBox(height: 16),
                SwButton(
                  label: 'Tutup',
                  variant: SwButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _uploadProof(String orderId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _uploadingOrderId = orderId);
    try {
      final bytes = await picked.readAsBytes();
      await ref
          .read(userTransactionsRepositoryProvider)
          .uploadAndAttachPaymentProof(
            orderId: orderId,
            bytes: bytes,
            filename: picked.name,
          );
      await ref.read(userOrdersProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bukti transfer berhasil diunggah! Kurator akan memverifikasi.',
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
    } finally {
      if (mounted) setState(() => _uploadingOrderId = null);
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.modalScrim,
      builder: (_) => const SwConfirmDialog(
        title: 'Batalkan pesanan sewa?',
        message: 'Stok busana akan dilepas kembali ke inventaris Galeri Sriwedari.',
        confirmLabel: 'Ya, Batalkan',
        cancelLabel: 'Tutup',
        icon: Icons.cancel_outlined,
        confirmVariant: SwButtonVariant.destructive,
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(userTransactionsRepositoryProvider).cancelOrder(orderId);
      await ref.read(userOrdersProvider.notifier).refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  int _computeProfileCompletion({
    required UserAccountModel? user,
    required String displayName,
    required String displayEmail,
    required int orderCount,
    required int ticketCount,
  }) {
    final hasName = displayName.trim().isNotEmpty;
    final hasEmail = displayEmail.trim().isNotEmpty;
    final hasPhone = (user?.phone.trim().length ?? 0) >= 8;
    final hasActivityOrPhoto =
        ((user?.avatar ?? '').isNotEmpty) || orderCount > 0 || ticketCount > 0;
    final checks = [hasName, hasEmail, hasPhone, hasActivityOrPhoto];
    final done = checks.where((c) => c).length;
    return ((done / checks.length) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final ordersAsync = ref.watch(userOrdersProvider);
    final ticketsAsync = ref.watch(userTicketsProvider);
    final wishlistAsync = ref.watch(userWishlistProvider);
    final galleriesAsync = ref.watch(userGalleriesProvider);
    final costumesAsync = ref.watch(userCostumesProvider);
    final config = ref.watch(appConfigProvider);
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);

    final user = auth.userAccount;
    final orders = ordersAsync.value ?? const <UserOrderModel>[];
    final tickets = ticketsAsync.value ?? const <UserTicketModel>[];
    final wishlistCount = wishlistAsync.value?.length ?? 0;
    final points = user?.points ?? 0;
    final isSahabatKeraton = points >= 500 || user?.role == 'admin';

    final completionPct = _computeProfileCompletion(
      user: user,
      displayName: auth.displayName,
      displayEmail: auth.displayEmail,
      orderCount: orders.length,
      ticketCount: tickets.length,
    );

    final initial = auth.displayName.trim().isNotEmpty
        ? auth.displayName.trim()[0].toUpperCase()
        : 'S';

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(userOrdersProvider.notifier).refresh();
        await ref.read(userTicketsProvider.notifier).refresh();
        ref.invalidate(userWishlistProvider);
      },
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
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Compact Identity Header + Verified Badge + Edit Pill + Gear Settings
                  _buildIdentityHeader(
                    user: user,
                    displayName: auth.displayName,
                    displayEmail: auth.displayEmail,
                    initial: initial,
                    baseUrl: config.baseUrl,
                    isSahabatKeraton: isSahabatKeraton,
                  ),
                  const SizedBox(height: 12),

                  // 2. Location / WhatsApp Status Pill Bar
                  _buildLocationWaBar(
                    user: user,
                    baseUrl: config.baseUrl,
                  ),
                  const SizedBox(height: 12),

                  // 3. Profile Completion Progress Bar
                  _buildCompletionCard(completionPct),
                  const SizedBox(height: 14),

                  // 4. Three Quick Metric & Shortcut Cards with Floating '+' Badges
                  _buildQuickMetricCards(
                    orderCount: orders.length,
                    ticketCount: tickets.length,
                    points: points,
                    wishlistCount: wishlistCount,
                  ),
                  const SizedBox(height: 16),

                  // 5. Privilege & Membership Comparison Card (Warga Budaya vs Sahabat Keraton)
                  _buildMembershipCard(
                    points: points,
                    isSahabatKeraton: isSahabatKeraton,
                  ),
                  const SizedBox(height: 20),

                  // 6. History Tabs (Sewa, E-Tiket, Favorit)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SwFilterChip(
                          key: const ValueKey('profile-tab-orders'),
                          label: 'Sewa (${orders.length})',
                          icon: Icons.receipt_long_outlined,
                          selected: _activeTabIndex == 0,
                          onTap: () => _selectTab(0),
                        ),
                        const SizedBox(width: 8),
                        SwFilterChip(
                          key: const ValueKey('profile-tab-tickets'),
                          label: 'E-Tiket (${tickets.length})',
                          icon: Icons.confirmation_number_outlined,
                          selected: _activeTabIndex == 1,
                          onTap: () => _selectTab(1),
                        ),
                        const SizedBox(width: 8),
                        SwFilterChip(
                          key: const ValueKey('profile-tab-wishlist'),
                          label: 'Favorit ($wishlistCount)',
                          icon: Icons.favorite_border_rounded,
                          selected: _activeTabIndex == 2,
                          onTap: () => _selectTab(2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  SwDirectionalSwitcher(
                    isForward: _activeTabIndex >= _previousTabIndex,
                    child: KeyedSubtree(
                      key: ValueKey('profile-tab-body-$_activeTabIndex'),
                      child: switch (_activeTabIndex) {
                        0 => _buildOrdersTab(ordersAsync, config.baseUrl),
                        1 => _buildTicketsTab(ticketsAsync),
                        _ => _buildWishlistTab(
                            wishlistAsync,
                            galleriesAsync.value ?? const [],
                            costumesAsync.value ?? const [],
                            config.baseUrl,
                          ),
                      },
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

  Widget _buildIdentityHeader({
    required UserAccountModel? user,
    required String displayName,
    required String displayEmail,
    required String initial,
    required String baseUrl,
    required bool isSahabatKeraton,
  }) {
    return SwCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: user != null
                ? () => _showEditProfileDialog(user, baseUrl)
                : null,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _AvatarCircle(
                  avatarUrl: user?.avatar ?? '',
                  baseUrl: baseUrl,
                  initial: initial,
                  size: 62,
                ),
                if (user != null)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.brandGreenDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.ivory, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 12,
                        color: AppColors.goldLight,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headlineMd(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      size: 18,
                      color: AppColors.infoText,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  displayEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd(color: AppColors.textSubtle),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (user != null)
                      InkWell(
                        onTap: () => _showEditProfileDialog(user, baseUrl),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandGreenDark,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.edit_outlined,
                                size: 13,
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Edit profil',
                                style: AppTypography.labelMd(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      InkWell(
                        onTap: () => context.go(AppRoutes.login),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandGreenDark,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Masuk Akun',
                            style: AppTypography.labelMd(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: IconButton(
              key: const ValueKey('profile-settings-btn'),
              onPressed: () => _showSettingsModal(
                user: user,
                displayName: displayName,
                displayEmail: displayEmail,
                baseUrl: baseUrl,
                isSahabatKeraton: isSahabatKeraton,
              ),
              icon: const Icon(
                Icons.settings_outlined,
                size: 20,
                color: AppColors.brandGreenDark,
              ),
              tooltip: 'Pengaturan & Sesi',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationWaBar({
    required UserAccountModel? user,
    required String baseUrl,
  }) {
    final phoneText = (user != null && user.phone.isNotEmpty)
        ? user.phone
        : 'Nomor WA belum diisi';
    return InkWell(
      onTap: user != null ? () => _showEditProfileDialog(user, baseUrl) : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.ivory,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.metricMint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.brandGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Galeri Sriwedari, Surakarta • $phoneText',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMd(color: AppColors.textPrimary),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textSubtle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionCard(int pct) {
    final isComplete = pct >= 100;
    return SwCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.brandGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandGreenDark,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$pct%',
                  style: AppTypography.labelSm(color: AppColors.goldLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isComplete
                    ? Icons.auto_awesome_rounded
                    : Icons.info_outline_rounded,
                size: 15,
                color: isComplete ? AppColors.goldDark : AppColors.textSubtle,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isComplete
                      ? 'Profil lengkap! Siap menjelajahi & menyewa pusaka keraton.'
                      : 'Lengkapi nomor WhatsApp atau unggah foto agar profil mencapai 100%.',
                  style: AppTypography.labelSm(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetricCards({
    required int orderCount,
    required int ticketCount,
    required int points,
    required int wishlistCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _ProfileShortcutMetricCard(
            value: '$orderCount',
            label: 'Sewa',
            subtitle: 'Busana Adat',
            icon: Icons.checkroom_outlined,
            tintBg: AppColors.metricMint,
            onCardTap: () => _selectTab(0),
            onPlusTap: () => context.push(AppRoutes.userBooking),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ProfileShortcutMetricCard(
            value: '$ticketCount',
            label: 'E-Tiket',
            subtitle: 'Pentas Wayang',
            icon: Icons.confirmation_number_outlined,
            tintBg: AppColors.metricPeach,
            onCardTap: () => _selectTab(1),
            onPlusTap: () => context.go(AppRoutes.userSchedule),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ProfileShortcutMetricCard(
            value: '$points',
            label: 'Poin',
            subtitle: '$wishlistCount Favorit',
            icon: Icons.military_tech_outlined,
            tintBg: AppColors.metricLavender,
            onCardTap: () => _selectTab(2),
            onPlusTap: () => context.go(AppRoutes.userGallery),
          ),
        ),
      ],
    );
  }

  Widget _buildMembershipCard({
    required int points,
    required bool isSahabatKeraton,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGreenGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        const Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.gold,
                          size: 20,
                        ),
                        Text(
                          'sriwedari',
                          style: AppTypography.headlineMd(color: Colors.white),
                        ),
                        SwStatusBadge(
                          label: isSahabatKeraton
                              ? 'SAHABAT KERATON'
                              : 'WARGA BUDAYA',
                          tone: SwBadgeTone.gold,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.userBooking),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.goldLight,
                  side: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.5),
                  ),
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Sewa Busana'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        'Hak Istimewa Anggota',
                        style: AppTypography.labelSm(color: AppColors.goldLight),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Warga',
                        textAlign: TextAlign.center,
                        style: AppTypography.labelSm(color: AppColors.canvas),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Sahabat',
                        textAlign: TextAlign.center,
                        style: AppTypography.labelSm(color: AppColors.gold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  color: AppColors.gold.withValues(alpha: 0.18),
                ),
                const SizedBox(height: 8),
                _PrivilegeMatrixRow(
                  label: 'Prioritas Kursi VIP Wayang',
                  wargaUnlocked: isSahabatKeraton,
                  sahabatUnlocked: true,
                ),
                const SizedBox(height: 6),
                _PrivilegeMatrixRow(
                  label: 'Voucher Diskon Sewa Busana',
                  wargaUnlocked: isSahabatKeraton,
                  sahabatUnlocked: true,
                ),
                const SizedBox(height: 6),
                const _PrivilegeMatrixRow(
                  label: 'Check-in Cepat E-Tiket & Galeri',
                  wargaUnlocked: true,
                  sahabatUnlocked: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showBenefitsModal(points, isSahabatKeraton),
              icon: const Icon(
                Icons.card_giftcard_rounded,
                size: 16,
                color: AppColors.goldLight,
              ),
              label: Text(
                'Lihat Semua Keuntungan Anggota',
                style: AppTypography.labelMd(color: AppColors.goldLight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab(
    AsyncValue<List<UserOrderModel>> ordersAsync,
    String baseUrl,
  ) {
    return SwContentSwitcher(
      child: ordersAsync.when(
        loading: () => const SwLoadingSkeleton(
          key: ValueKey('prof_orders_loading'),
          height: 140,
        ),
        error: (err, _) => SwErrorView(
          key: const ValueKey('prof_orders_error'),
          message: err.toString(),
          onRetry: () => ref.read(userOrdersProvider.notifier).refresh(),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return SwEmptyState(
              key: const ValueKey('prof_orders_empty'),
              icon: Icons.shopping_bag_outlined,
              title: 'Belum Ada Pesanan Sewa',
              description:
                  'Anda belum memiliki riwayat penyewaan busana adat keraton.',
              actionLabel: 'Lihat Katalog Kostum',
              onAction: () => context.go(AppRoutes.userCostumes),
            );
          }

          return Column(
            key: ValueKey('prof_orders_${orders.length}'),
            children: orders.asMap().entries.map((entry) {
              final idx = entry.key;
              final order = entry.value;
              final isUploading = _uploadingOrderId == order.id;
              final hasProof =
                  order.paymentProof != null && order.paymentProof!.isNotEmpty;
              final canUploadProof = order.status != 'Selesai' &&
                  order.status != 'Dibatalkan' &&
                  order.status != 'Kedaluwarsa';

              return RepaintBoundary(
                child: FadeSlideEntrance(
                  index: idx,
                  onceKey: 'prof_ord_${order.id}',
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SwCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  order.id,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelMd(
                                    color: AppColors.brandGreen,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SwStatusBadge.fromOrderStatus(order.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(order.costumeName, style: AppTypography.titleMd()),
                          const SizedBox(height: 4),
                          Text(
                            'Mulai ${order.startDate} • ${order.duration} hari • ${order.paymentMethod}',
                            style: AppTypography.bodyMd(
                              color: AppColors.textSubtle,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Deposit Jaminan',
                                  style: AppTypography.labelSm(),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.formatRupiah(
                                    order.depositFee,
                                  ),
                                  style: AppTypography.labelMd(),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Total Bayar',
                                  style: AppTypography.labelSm(),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.formatRupiah(
                                    order.totalPrice,
                                  ),
                                  style: AppTypography.priceText(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (order.qcStatus != null &&
                        order.qcStatus != 'Pending') ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                SwStatusBadge.fromOrderStatus(order.qcStatus!),
                                Text(
                                  'Refund Deposit: ${CurrencyFormatter.formatRupiah(order.refundAmount ?? 0)}',
                                  style: AppTypography.labelMd(
                                    color: AppColors.successText,
                                  ),
                                ),
                              ],
                            ),
                            if (order.deductionNote != null &&
                                order.deductionNote!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Catatan QC: ${order.deductionNote}',
                                style: AppTypography.labelSm(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (hasProof) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.successBg.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.successText.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            SwImage(
                              source: order.paymentProof!,
                              baseUrl: baseUrl,
                              width: 44,
                              height: 44,
                              borderRadius: 8,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bukti Transfer / Slip',
                                    style: AppTypography.labelMd(
                                      color: AppColors.successText,
                                    ),
                                  ),
                                  Text(
                                    'Siap diverifikasi kurator',
                                    style: AppTypography.labelSm(
                                      color: AppColors.textSubtle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showProofPreviewDialog(
                                orderId: order.id,
                                proofSource: order.paymentProof!,
                                baseUrl: baseUrl,
                              ),
                              child: Text(
                                'Lihat',
                                style: AppTypography.labelMd(
                                  color: AppColors.brandGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (canUploadProof) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          SwButton(
                            label: hasProof ? 'Ganti Slip' : 'Unggah Slip',
                            leadingIcon: Icons.upload_file_rounded,
                            height: 38,
                            isLoading: isUploading,
                            onPressed: () => _uploadProof(order.id),
                          ),
                          if (order.status == 'Menunggu')
                            SwButton(
                              label: 'Batalkan',
                              variant: SwButtonVariant.secondary,
                              height: 38,
                              onPressed: () => _cancelOrder(order.id),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
        },
      ),
    );
  }

  Widget _buildTicketsTab(AsyncValue<List<UserTicketModel>> ticketsAsync) {
    return SwContentSwitcher(
      child: ticketsAsync.when(
        loading: () => const SwLoadingSkeleton(
          key: ValueKey('prof_tickets_loading'),
          height: 140,
        ),
        error: (err, _) => SwErrorView(
          key: const ValueKey('prof_tickets_error'),
          message: err.toString(),
          onRetry: () => ref.read(userTicketsProvider.notifier).refresh(),
        ),
        data: (tickets) {
          if (tickets.isEmpty) {
            return SwEmptyState(
              key: const ValueKey('prof_tickets_empty'),
              icon: Icons.confirmation_number_outlined,
              title: 'Belum Ada Tiket Pertunjukan',
              description:
                  'Pesan kursi pagelaran Wayang Orang Sriwedari untuk mendapatkan e-tiket QR pass.',
              actionLabel: 'Lihat Jadwal Pentas',
              onAction: () => context.go(AppRoutes.userSchedule),
            );
          }

          return Column(
            key: ValueKey('prof_tickets_${tickets.length}'),
            children: tickets.asMap().entries.map((entry) {
              final idx = entry.key;
              final ticket = entry.value;
              return RepaintBoundary(
                child: FadeSlideEntrance(
                  index: idx,
                  onceKey: 'prof_tkt_${ticket.id}',
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SwCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SwStatusBadge(
                                label: ticket.bookingCode,
                                tone: SwBadgeTone.gold,
                              ),
                              SwStatusBadge.fromOrderStatus(ticket.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(ticket.eventTitle, style: AppTypography.titleMd()),
                          const SizedBox(height: 4),
                          Text(
                            'Zona ${ticket.zone} • Kursi ${ticket.seats.join(', ')} (${ticket.quantity} tiket)',
                            style: AppTypography.bodyMd(
                              color: AppColors.textSubtle,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Text(
                                  CurrencyFormatter.formatRupiah(
                                    ticket.totalPrice,
                                  ),
                                  style: AppTypography.priceText(fontSize: 15),
                                ),
                                SwButton(
                                  label: 'Lihat E-Tiket QR',
                                  leadingIcon: Icons.qr_code_2_rounded,
                                  height: 38,
                                  onPressed: () => TicketBoardingPassModal.show(
                                    context,
                                    ticket: ticket,
                                  ),
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
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildWishlistTab(
    AsyncValue<List<WishlistItemModel>> wishlistAsync,
    List<UserGalleryModel> galleries,
    List<UserCostumeModel> costumes,
    String baseUrl,
  ) {
    return SwContentSwitcher(
      child: wishlistAsync.when(
        loading: () => const SwLoadingSkeleton(
          key: ValueKey('prof_wish_loading'),
          height: 120,
        ),
        error: (err, _) => SwErrorView(
          key: const ValueKey('prof_wish_error'),
          message: err.toString(),
          onRetry: () => ref.invalidate(userWishlistProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return SwEmptyState(
              key: const ValueKey('prof_wish_empty'),
              icon: Icons.favorite_border_rounded,
              title: 'Daftar Favorit Kosong',
              description:
                  'Tandai karya galeri atau busana adat favorit agar mudah ditemukan kembali.',
              actionLabel: 'Jelajahi Galeri',
              onAction: () => context.go(AppRoutes.userGallery),
            );
          }

          return Column(
            key: ValueKey('prof_wish_${items.length}'),
            children: items.asMap().entries.map((entry) {
              final idx = entry.key;
              final wish = entry.value;
              final gallery = wish.targetType == 'gallery'
                  ? galleries.where((g) => g.id == wish.targetId).firstOrNull
                  : null;
              final costume = wish.targetType == 'costume'
                  ? costumes.where((c) => c.id == wish.targetId).firstOrNull
                  : null;

              final title =
                  gallery?.title ?? costume?.name ?? 'Koleksi #${wish.targetId}';
              final subtitle = gallery != null
                  ? '${gallery.categoryName} • ${gallery.origin}'
                  : costume != null
                      ? '${CurrencyFormatter.formatRupiah(costume.price)} / hari'
                      : wish.targetType;
              final image = gallery?.image ?? costume?.image ?? '';
              final heroTag = wish.targetType == 'costume'
                  ? 'prof-cos-${wish.targetId}'
                  : 'prof-gal-${wish.targetId}';

              return RepaintBoundary(
                child: FadeSlideEntrance(
                  index: idx,
                  onceKey: 'prof_wish_${wish.targetType}_${wish.targetId}',
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SwCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Hero(
                            tag: heroTag,
                            child: SwImage(
                              source: image,
                              baseUrl: baseUrl,
                              width: 64,
                              height: 64,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.titleMd(),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodyMd(
                                    color: AppColors.textSubtle,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        if (wish.targetType == 'costume') {
                                          context.push(
                                            '${AppRoutes.userBooking}?costumeId=${Uri.encodeComponent(wish.targetId)}',
                                          );
                                        } else {
                                          context.push(
                                            '${AppRoutes.galleryDetailPath(wish.targetId)}?heroTag=${Uri.encodeComponent(heroTag)}',
                                          );
                                        }
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            wish.targetType == 'costume'
                                                ? 'Sewa Busana'
                                                : 'Lihat Galeri',
                                            style: AppTypography.labelMd(
                                              color: AppColors.brandGreen,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 14,
                                            color: AppColors.brandGreen,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => ref
                                .read(userWishlistProvider.notifier)
                                .toggleWishlist(
                                  targetId: wish.targetId,
                                  targetType: wish.targetType,
                                ),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.error,
                            ),
                            tooltip: 'Hapus dari Favorit',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.avatarUrl,
    required this.baseUrl,
    required this.initial,
    required this.size,
    this.isLoading = false,
  });

  final String avatarUrl;
  final String baseUrl;
  final String initial;
  final double size;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.gold,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.brandGreenDark.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.brandGreenDark,
                ),
              ),
            )
          : avatarUrl.isNotEmpty
              ? SwImage(
                  source: avatarUrl,
                  baseUrl: baseUrl,
                  width: size,
                  height: size,
                  borderRadius: size / 2,
                )
              : Center(
                  child: Text(
                    initial,
                    style: AppTypography.headlineLg(
                      color: AppColors.brandGreenDark,
                    ),
                  ),
                ),
    );
  }
}

class _ProfileShortcutMetricCard extends StatelessWidget {
  const _ProfileShortcutMetricCard({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.tintBg,
    required this.onCardTap,
    required this.onPlusTap,
  });

  final String value;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color tintBg;
  final VoidCallback onCardTap;
  final VoidCallback onPlusTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: onCardTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
            decoration: BoxDecoration(
              color: AppColors.ivory,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: tintBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.brandGreenDark),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: AppTypography.headlineMd()),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMd(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSm(),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: InkWell(
            onTap: onPlusTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.brandGreenDark,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ivory, width: 1),
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 14,
                color: AppColors.goldLight,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrivilegeMatrixRow extends StatelessWidget {
  const _PrivilegeMatrixRow({
    required this.label,
    required this.wargaUnlocked,
    required this.sahabatUnlocked,
  });

  final String label;
  final bool wargaUnlocked;
  final bool sahabatUnlocked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: AppTypography.labelSm(color: AppColors.canvas),
          ),
        ),
        Expanded(
          flex: 2,
          child: Icon(
            wargaUnlocked
                ? Icons.check_circle_rounded
                : Icons.lock_outline_rounded,
            size: 16,
            color: wargaUnlocked
                ? AppColors.goldLight
                : AppColors.canvas.withValues(alpha: 0.45),
          ),
        ),
        Expanded(
          flex: 2,
          child: Icon(
            sahabatUnlocked
                ? Icons.check_circle_rounded
                : Icons.lock_outline_rounded,
            size: 16,
            color: sahabatUnlocked
                ? AppColors.gold
                : AppColors.canvas.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class _SettingInfoRow extends StatelessWidget {
  const _SettingInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: AppTypography.labelSm(color: AppColors.textSubtle),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.labelMd(),
          ),
        ),
      ],
    );
  }
}

class _BenefitDetailTile extends StatelessWidget {
  const _BenefitDetailTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.brandGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelMd()),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodyMd(color: AppColors.textSubtle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

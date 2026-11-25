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

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _taglineCtrl = TextEditingController();
  final _openHoursCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _holdCtrl = TextEditingController();
  final _refundWindowCtrl = TextEditingController();
  final _lowStockCtrl = TextEditingController();
  final _waAdminCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();

  bool _notifications = true;
  bool _hydrated = false;
  bool _isSaving = false;
  bool _isResetting = false;

  void _hydrateFrom(SystemSettingsModel s) {
    if (_hydrated) return;
    _hydrated = true;
    _nameCtrl.text = s.galleryName;
    _taglineCtrl.text = s.tagline;
    _openHoursCtrl.text = s.openHours;
    _locationCtrl.text = s.location;
    _phoneCtrl.text = s.phone;
    _emailCtrl.text = s.email;
    _depositCtrl.text = s.depositFee.toString();
    _holdCtrl.text = s.holdDurationMinutes.toString();
    _refundWindowCtrl.text = s.refundWindowDays.toString();
    _lowStockCtrl.text = s.lowStockThreshold.toString();
    _waAdminCtrl.text = s.whatsappAdminNumber;
    _termsCtrl.text = s.terms;
    _notifications = s.notifications;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _taglineCtrl.dispose();
    _openHoursCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _depositCtrl.dispose();
    _holdCtrl.dispose();
    _refundWindowCtrl.dispose();
    _lowStockCtrl.dispose();
    _waAdminCtrl.dispose();
    _termsCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(adminOperationsRepositoryProvider).saveSettings(
            SystemSettingsModel(
              galleryName: _nameCtrl.text.trim(),
              tagline: _taglineCtrl.text.trim(),
              openHours: _openHoursCtrl.text.trim(),
              location: _locationCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
              depositFee: int.tryParse(_depositCtrl.text.trim()) ?? 100000,
              terms: _termsCtrl.text.trim(),
              notifications: _notifications,
              holdDurationMinutes:
                  int.tryParse(_holdCtrl.text.trim()) ?? 1440,
              refundWindowDays:
                  int.tryParse(_refundWindowCtrl.text.trim()) ?? 3,
              lowStockThreshold:
                  int.tryParse(_lowStockCtrl.text.trim()) ?? 2,
              whatsappAdminNumber: _waAdminCtrl.text.trim(),
            ),
          );
      _hydrated = false;
      await ref.read(adminSettingsProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan sanggar Sriwedari berhasil disimpan.'),
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmResetDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.modalScrim,
      builder: (_) => const SwConfirmDialog(
        title: 'Reset Seluruh Basis Data?',
        message:
            'Aksi ini mengembalikan sriwedari-user-db.json dan sriwedari-admin-db.json ke data awal bawaan. Perubahan transaksi terakhir akan hilang.',
        confirmLabel: 'Ya, Reset DB',
        cancelLabel: 'Batal',
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.error,
        confirmVariant: SwButtonVariant.destructive,
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isResetting = true);
    try {
      final msg =
          await ref.read(adminOperationsRepositoryProvider).resetDatabase();
      _hydrated = false;
      ref.invalidate(adminSettingsProvider);
      ref.invalidate(adminAnalyticsProvider);
      ref.invalidate(adminGalleriesProvider);
      ref.invalidate(adminCostumesProvider);
      ref.invalidate(adminOrdersProvider);
      ref.invalidate(adminEventsProvider);
      ref.invalidate(adminAuditLogsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(adminSettingsProvider);
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);

    return RefreshIndicator(
      onRefresh: () async {
        _hydrated = false;
        await ref.read(adminSettingsProvider.notifier).refresh();
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
                vertical: AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengaturan Sanggar & Basis Data',
                    style: AppTypography.headlineLg(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Konfigurasi identitas Galeri Sriwedari, deposit jaminan, dan pemeliharaan basis data',
                    style: AppTypography.bodyMd(color: AppColors.textSubtle),
                  ),
                  const SizedBox(height: 16),
                  settingsAsync.when(
                    loading: () => const SwLoadingSkeleton(height: 220),
                    error: (err, _) => SwErrorView(
                      message: err.toString(),
                      onRetry: () {
                        _hydrated = false;
                        ref.read(adminSettingsProvider.notifier).refresh();
                      },
                    ),
                    data: (settings) {
                      _hydrateFrom(settings);
                      return Column(
                        children: [
                          SwCard(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Identitas & Operasional Galeri',
                                    style: AppTypography.titleMd(),
                                  ),
                                  const SizedBox(height: 12),
                                  SwInput(
                                    controller: _nameCtrl,
                                    label: 'Nama Galeri',
                                    validator: (v) =>
                                        SwValidators.requiredField(
                                      v,
                                      'Nama galeri',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SwInput(
                                    controller: _taglineCtrl,
                                    label: 'Tagline',
                                  ),
                                  const SizedBox(height: 10),
                                  SwInput(
                                    controller: _openHoursCtrl,
                                    label: 'Jam Operasional',
                                  ),
                                  const SizedBox(height: 10),
                                  SwInput(
                                    controller: _locationCtrl,
                                    label: 'Alamat Lengkap',
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SwInput(
                                          controller: _phoneCtrl,
                                          label: 'Telepon Loket',
                                          keyboardType: TextInputType.phone,
                                          inputFormatters:
                                              SwInputFormatters.phoneDigits,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: SwInput(
                                          controller: _waAdminCtrl,
                                          label: 'WhatsApp Admin',
                                          keyboardType: TextInputType.phone,
                                          inputFormatters:
                                              SwInputFormatters.phoneDigits,
                                          validator: (v) => v != null &&
                                                  v.trim().isNotEmpty
                                              ? SwValidators.phoneId(v)
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SwInput(
                                    controller: _emailCtrl,
                                    label: 'Email Resmi',
                                    keyboardType: TextInputType.emailAddress,
                                    inputFormatters:
                                        SwInputFormatters.noWhitespace,
                                    validator: (v) =>
                                        v != null && v.trim().isNotEmpty
                                            ? SwValidators.email(v)
                                            : null,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SwInput(
                                          controller: _depositCtrl,
                                          label: 'Deposit Default (Rp)',
                                          keyboardType: TextInputType.number,
                                          inputFormatters:
                                              SwInputFormatters.digitsOnly,
                                          validator: (v) =>
                                              SwValidators.intRange(
                                            v,
                                            fieldName: 'Deposit',
                                            min: 0,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: SwInput(
                                          controller: _lowStockCtrl,
                                          label: 'Ambang Stok Tipis',
                                          keyboardType: TextInputType.number,
                                          inputFormatters:
                                              SwInputFormatters.digitsOnly,
                                          validator: (v) =>
                                              SwValidators.intRange(
                                            v,
                                            fieldName: 'Ambang stok',
                                            min: 0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SwInput(
                                          controller: _holdCtrl,
                                          label: 'Hold Tagihan (Menit)',
                                          keyboardType: TextInputType.number,
                                          inputFormatters:
                                              SwInputFormatters.digitsOnly,
                                          validator: (v) =>
                                              SwValidators.intRange(
                                            v,
                                            fieldName: 'Hold tagihan',
                                            min: 1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: SwInput(
                                          controller: _refundWindowCtrl,
                                          label: 'Batas Refund (Hari)',
                                          keyboardType: TextInputType.number,
                                          inputFormatters:
                                              SwInputFormatters.digitsOnly,
                                          validator: (v) =>
                                              SwValidators.intRange(
                                            v,
                                            fieldName: 'Batas refund',
                                            min: 1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SwInput(
                                    controller: _termsCtrl,
                                    label: 'Syarat & Ketentuan Sewa',
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Aktifkan Notifikasi Kurator',
                                          style: AppTypography.labelMd(),
                                        ),
                                      ),
                                      Switch(
                                        value: _notifications,
                                        onChanged: (v) =>
                                            setState(() => _notifications = v),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SwButton(
                                    label: 'Simpan Pengaturan',
                                    leadingIcon: Icons.save_outlined,
                                    fullWidth: true,
                                    isLoading: _isSaving,
                                    onPressed: _saveSettings,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwCard(
                            backgroundColor: AppColors.errorContainer
                                .withValues(alpha: 0.45),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.dangerous_outlined,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Pemeliharaan & Reset Basis Data',
                                        style: AppTypography.titleMd(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Mengembalikan kedua database terpisah (`sriwedari-user-db.json` dan `sriwedari-admin-db.json`) ke seed awal.',
                                  style: AppTypography.bodyMd(),
                                ),
                                const SizedBox(height: 12),
                                SwButton(
                                  label: 'Reset Database ke Kondisi Awal',
                                  variant: SwButtonVariant.destructive,
                                  leadingIcon: Icons.restart_alt_rounded,
                                  isLoading: _isResetting,
                                  onPressed: _confirmResetDatabase,
                                ),
                              ],
                            ),
                          ),
                        ],
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

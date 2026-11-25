import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/sw_page_transitions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/booking_calculator.dart';
import '../../domain/models/user_models.dart';
import '../providers/user_catalog_providers.dart';
import '../providers/user_transactions_providers.dart';

class BookingFormScreen extends ConsumerStatefulWidget {
  const BookingFormScreen({
    super.key,
    this.initialCostumeId,
    this.initialDays,
    this.initialSize,
  });

  final String? initialCostumeId;
  final int? initialDays;
  final String? initialSize;

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _contactFormKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _startDateController;
  final TextEditingController _couponController = TextEditingController();

  int _currentStep = 0; // 0: Data Diri, 1: Pilih Kostum, 2: Konfirmasi
  int _previousStep = 0;
  DateTime _startDate = DateTime.now().add(const Duration(days: 2));
  String _paymentMethod = 'QRIS';
  final List<BookingCartItemModel> _cartItems = [];
  bool _initializedCart = false;

  int _discountAmount = 0;
  String? _appliedCouponCode;
  String? _couponMessage;
  bool _couponIsError = false;
  bool _isCheckingCoupon = false;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _nameController = TextEditingController(text: auth.userAccount?.name ?? '');
    _phoneController = TextEditingController(text: auth.userAccount?.phone ?? '');
    _emailController = TextEditingController(text: auth.userAccount?.email ?? '');
    _startDateController = TextEditingController(text: _formattedStartDate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _startDateController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  void _ensureInitialCart(List<UserCostumeModel> costumes) {
    if (_initializedCart || costumes.isEmpty) return;
    _initializedCart = true;

    UserCostumeModel? preselected;
    if (widget.initialCostumeId != null) {
      preselected = costumes
          .where((c) => c.id == widget.initialCostumeId)
          .firstOrNull;
    }
    preselected ??= costumes.first;

    final defaultSize = widget.initialSize != null &&
            preselected.sizes.contains(widget.initialSize)
        ? widget.initialSize!
        : (preselected.sizes.isNotEmpty ? preselected.sizes.first : 'All Size');
    final defaultDays = widget.initialDays ?? 3;

    _cartItems.add(
      BookingCartItemModel(
        id: preselected.id,
        name: preselected.name,
        price: preselected.price,
        days: defaultDays,
        size: defaultSize,
      ),
    );
  }

  String get _formattedStartDate =>
      '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}';

  int _activeDepositFee = AppConstants.defaultDepositFee;

  int get _subtotal => BookingCostCalculator.calculateRentalSubtotal(_cartItems);

  int _grandTotalFor(int depositFee) => BookingCostCalculator.calculateGrandTotal(
        subtotal: _subtotal,
        discountAmount: _discountAmount,
        depositFee: depositFee,
      );

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = _startDate.isBefore(today) ? today : _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _startDateController.text = _formattedStartDate;
      });
    }
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _isCheckingCoupon = true;
      _couponMessage = null;
    });

    final res = await ref.read(userTransactionsRepositoryProvider).validateCoupon(
          code: code,
          totalAmount: _subtotal,
        );

    if (mounted) {
      setState(() {
        _isCheckingCoupon = false;
        _discountAmount = res.discountAmount;
        _appliedCouponCode = res.valid ? code.toUpperCase() : null;
        _couponMessage = res.message;
        _couponIsError = !res.valid;
      });
    }
  }

  void _addAdditionalCostume(List<UserCostumeModel> costumes) {
    final available = costumes.where((c) => c.isAvailable).toList();
    if (available.isEmpty) return;
    final next = available.firstWhere(
      (c) => !_cartItems.any((item) => item.id == c.id),
      orElse: () => available.first,
    );
    setState(() {
      _cartItems.add(
        BookingCartItemModel(
          id: next.id,
          name: next.name,
          price: next.price,
          days: 3,
          size: next.sizes.isNotEmpty ? next.sizes.first : 'All Size',
        ),
      );
      _discountAmount = 0;
      _appliedCouponCode = null;
      _couponMessage = null;
    });
  }

  Future<void> _submitOrder() async {
    if (_cartItems.isEmpty) {
      setState(() => _submitError = 'Tambahkan minimal 1 busana untuk disewa.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final order =
          await ref.read(userTransactionsRepositoryProvider).createOrder(
                userName: _nameController.text.trim(),
                userPhone: _phoneController.text.trim(),
                userEmail: _emailController.text.trim(),
                costumes: _cartItems,
                startDate: _formattedStartDate,
                totalPrice: _grandTotalFor(_activeDepositFee),
                depositFee: _activeDepositFee,
                discountAmount: _discountAmount,
                couponCode: _appliedCouponCode,
                paymentMethod: _paymentMethod,
              );

      ref.invalidate(userOrdersProvider);
      ref.invalidate(userCostumesProvider);

      if (mounted) {
        context.go(AppRoutes.bookingSuccessPath(order.id));
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _submitError = e.message;
          _isSubmitting = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitError = 'Gagal mengirim pesanan. Periksa koneksi Anda.';
          _isSubmitting = false;
        });
      }
    }
  }

  void _goToStep(int step) {
    if (step == _currentStep) return;
    setState(() {
      _previousStep = _currentStep;
      _currentStep = step;
    });
  }

  Future<void> _handleBackNavigation() async {
    if (_isSubmitting) return;
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
      return;
    }

    final hasCustomization = _cartItems.length > 1 || _appliedCouponCode != null;
    if (hasCustomization) {
      final leave = await showDialog<bool>(
        context: context,
        barrierColor: AppColors.modalScrim,
        builder: (_) => const SwConfirmDialog(
          title: 'Keluar dari formulir sewa?',
          message:
              'Perubahan tambahan busana atau kupon Anda belum dikirim sebagai pesanan.',
          confirmLabel: 'Ya, Keluar',
          cancelLabel: 'Lanjut Isi',
          icon: Icons.exit_to_app_rounded,
          confirmVariant: SwButtonVariant.destructive,
        ),
      );
      if (leave != true || !mounted) return;
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.userCostumes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final costumesAsync = ref.watch(userCostumesProvider);
    final settingsAsync = ref.watch(publicSettingsProvider);
    _activeDepositFee =
        settingsAsync.value?.depositFee ?? AppConstants.defaultDepositFee;
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.brandGreenDark,
          foregroundColor: AppColors.goldLight,
          leading: IconButton(
            key: const ValueKey('booking-back-btn'),
            onPressed: _handleBackNavigation,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: _currentStep > 0 ? 'Langkah Sebelumnya' : 'Kembali',
          ),
          title: Text(
            'Sewa Busana Keraton',
            style: AppTypography.titleMd(color: AppColors.goldLight),
          ),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: margin,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Form Pemesanan Sewa Busana',
                      style: AppTypography.headlineLg(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reservasi multi-busana adat keraton dengan jaminan kurasi mutu',
                      style: AppTypography.bodyMd(color: AppColors.textSubtle),
                    ),
                    const SizedBox(height: 16),

                    // 3-Step Indicator
                    _StepperHeader(
                      currentStep: _currentStep,
                      onTapStep: (step) {
                        if (step < _currentStep) {
                          _goToStep(step);
                        }
                      },
                    ),
                    const SizedBox(height: 18),

                    costumesAsync.when(
                      loading: () => const SwLoadingSkeleton(height: 220),
                      error: (err, _) => SwErrorView(
                        message: err.toString(),
                        onRetry: () =>
                            ref.read(userCostumesProvider.notifier).refresh(),
                      ),
                      data: (costumes) {
                        _ensureInitialCart(costumes);

                        return SwDirectionalSwitcher(
                          isForward: _currentStep >= _previousStep,
                          child: KeyedSubtree(
                            key: ValueKey('booking-step-$_currentStep'),
                            child: switch (_currentStep) {
                              0 => _buildStep1Contact(),
                              1 => _buildStep2Costumes(costumes),
                              _ => _buildStep3Confirm(),
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Contact() {
    return SwCard(
      child: Form(
        key: _contactFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Informasi Pemesan', style: AppTypography.headlineMd()),
            const SizedBox(height: 14),
            SwInput(
              controller: _nameController,
              label: 'Nama Lengkap / Sanggar',
              hint: 'Masukkan nama lengkap',
              prefixIcon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              inputFormatters: SwInputFormatters.personName,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) => SwValidators.personName(v, 'Nama lengkap'),
            ),
            const SizedBox(height: 12),
            SwInput(
              controller: _phoneController,
              label: 'No. WhatsApp',
              hint: '081234567890',
              prefixIcon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              inputFormatters: SwInputFormatters.phoneDigits,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: SwValidators.phoneId,
            ),
            const SizedBox(height: 12),
            SwInput(
              controller: _emailController,
              label: 'Alamat Email',
              hint: 'nama@example.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              inputFormatters: SwInputFormatters.noWhitespace,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: SwValidators.email,
            ),
            const SizedBox(height: 12),
            SwInput(
              readOnly: true,
              onTap: _pickStartDate,
              label: 'Tanggal Mulai Pemakaian',
              hint: _formattedStartDate,
              controller: _startDateController,
              prefixIcon: Icons.calendar_today_outlined,
              validator: (v) =>
                  SwValidators.isoDate(v, 'Tanggal mulai pemakaian'),
            ),
            const SizedBox(height: 20),
            SwButton(
              label: 'Lanjut ke Pilih Kostum',
              trailingIcon: Icons.arrow_forward_rounded,
              fullWidth: true,
              onPressed: () {
                if (_contactFormKey.currentState!.validate()) {
                  _goToStep(1);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Costumes(List<UserCostumeModel> costumes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '2. Busana Dipilih (${_cartItems.length})',
                      style: AppTypography.headlineMd(),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _addAdditionalCostume(costumes),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tambah Busana'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_cartItems.isEmpty)
                SwEmptyState(
                  icon: Icons.checkroom_outlined,
                  title: 'Keranjang Busana Kosong',
                  description: 'Tambahkan minimal 1 busana adat untuk disewa.',
                  actionLabel: 'Tambah Busana',
                  onAction: () => _addAdditionalCostume(costumes),
                )
              else
                ...List.generate(_cartItems.length, (idx) {
                  final item = _cartItems[idx];
                  final costumeObj = costumes
                          .where((c) => c.id == item.id)
                          .firstOrNull ??
                      costumes.first;
                  final sizes = costumeObj.sizes.isNotEmpty
                      ? costumeObj.sizes
                      : const ['All Size'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.ivory,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SwImage(
                              source: costumeObj.image,
                              width: 54,
                              height: 54,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: costumeObj.id,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                                items: costumes
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c.id,
                                        child: Text(
                                          '${c.name} (${CurrencyFormatter.formatCompactRupiah(c.price)}/hr)',
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.bodyMd(),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (newId) {
                                  if (newId == null) return;
                                  final picked = costumes
                                      .firstWhere((c) => c.id == newId);
                                  setState(() {
                                    _cartItems[idx] = BookingCartItemModel(
                                      id: picked.id,
                                      name: picked.name,
                                      price: picked.price,
                                      days: item.days,
                                      size: picked.sizes.isNotEmpty
                                          ? picked.sizes.first
                                          : 'All Size',
                                    );
                                    _discountAmount = 0;
                                    _appliedCouponCode = null;
                                  });
                                },
                              ),
                            ),
                            if (_cartItems.length > 1)
                              IconButton(
                                onPressed: () =>
                                    setState(() => _cartItems.removeAt(idx)),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.error,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('Ukuran:', style: AppTypography.labelSm()),
                            ...sizes.map(
                              (s) => SwFilterChip(
                                label: s,
                                selected: item.size == s,
                                onTap: () => setState(
                                  () => _cartItems[idx] =
                                      item.copyWith(size: s),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Durasi:', style: AppTypography.labelSm()),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    onPressed: item.days > 1
                                        ? () => setState(
                                              () => _cartItems[idx] = item
                                                  .copyWith(days: item.days - 1),
                                            )
                                        : null,
                                    icon: const Icon(Icons.remove_circle_outline),
                                    iconSize: 20,
                                  ),
                                  Text(
                                    '${item.days} Hari',
                                    style: AppTypography.labelMd(),
                                  ),
                                  IconButton(
                                    onPressed: item.days < 14
                                        ? () => setState(
                                              () => _cartItems[idx] = item
                                                  .copyWith(days: item.days + 1),
                                            )
                                        : null,
                                    icon: const Icon(Icons.add_circle_outline),
                                    iconSize: 20,
                                  ),
                                ],
                              ),
                              Text(
                                CurrencyFormatter.formatRupiah(item.subtotal),
                                style: AppTypography.priceText(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: SwButton(
                label: 'Kembali',
                variant: SwButtonVariant.secondary,
                onPressed: () => _goToStep(0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SwButton(
                label: 'Lanjut ke Konfirmasi',
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: _cartItems.isNotEmpty ? () => _goToStep(2) : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3Confirm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Kupon Promo
        SwCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('3. Kode Kupon Promo Budaya', style: AppTypography.titleMd()),
              const SizedBox(height: 4),
              Text(
                'Coba kode: SRIWEDARI10 (10%), KERATON25 (25%), atau HEMATBUDAYA (Rp 50rb)',
                style: AppTypography.labelSm(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SwInput(
                      controller: _couponController,
                      hint: 'Masukkan kode kupon',
                      prefixIcon: Icons.local_offer_outlined,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: SwInputFormatters.alphaNumCode,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SwButton(
                    label: 'Terapkan',
                    isLoading: _isCheckingCoupon,
                    onPressed: _applyCoupon,
                  ),
                ],
              ),
              SwAnimatedExpand(
                child: _couponMessage != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _couponMessage!,
                          key: ValueKey(_couponMessage),
                          style: AppTypography.bodyMd(
                            color: _couponIsError
                                ? AppColors.error
                                : AppColors.successText,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Metode Pembayaran
        SwCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Metode Pembayaran Resmi', style: AppTypography.titleMd()),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ('QRIS', 'QRIS Dinamis Sriwedari', Icons.qr_code_2_rounded),
                  ('VA', 'Virtual Account BCA', Icons.account_balance_rounded),
                  ('Tunai', 'Tunai di Loket', Icons.payments_outlined),
                ].map((opt) {
                  return ScaleOnTap(
                    pressedScale: 0.95,
                    child: SwFilterChip(
                      label: opt.$2,
                      icon: opt.$3,
                      selected: _paymentMethod == opt.$1,
                      onTap: () => setState(() => _paymentMethod = opt.$1),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Ringkasan Biaya
        SwCard(
          backgroundColor: AppColors.surfaceContainerLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rincian Tagihan', style: AppTypography.titleMd()),
              const SizedBox(height: 10),
              _SummaryRow('Subtotal Sewa (${_cartItems.length} item)', _subtotal),
              const SizedBox(height: 6),
              _SummaryRow(
                'Deposit Jaminan Keamanan (dikembalikan saat QC)',
                _activeDepositFee,
              ),
              SwAnimatedExpand(
                child: _discountAmount > 0
                    ? Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _SummaryRow(
                          'Diskon Kupon (${_appliedCouponCode ?? ""})',
                          -_discountAmount,
                          valueColor: AppColors.successText,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(),
              ),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text('Total Tagihan', style: AppTypography.titleMd()),
                    Text(
                      CurrencyFormatter.formatRupiah(
                        _grandTotalFor(_activeDepositFee),
                      ),
                      style: AppTypography.priceText(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SwAnimatedExpand(
          child: _submitError != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _submitError!,
                      style: AppTypography.bodyMd(color: AppColors.error),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SwButton(
                label: 'Kembali',
                variant: SwButtonVariant.secondary,
                onPressed: () => _goToStep(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SwButton(
                label: 'Konfirmasi & Kirim Pesanan',
                variant: SwButtonVariant.gold,
                trailingIcon: Icons.check_circle_outline_rounded,
                isLoading: _isSubmitting,
                onPressed: _submitOrder,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepperHeader extends StatelessWidget {
  const _StepperHeader({
    required this.currentStep,
    required this.onTapStep,
  });

  final int currentStep;
  final ValueChanged<int> onTapStep;

  @override
  Widget build(BuildContext context) {
    const steps = ['1 Data Diri', '2 Pilih Kostum', '3 Konfirmasi'];

    return Row(
      children: List.generate(steps.length, (i) {
        final active = i == currentStep;
        final done = i < currentStep;
        return Expanded(
          child: InkWell(
            onTap: () => onTapStep(i),
            child: Container(
              margin: EdgeInsets.only(right: i == steps.length - 1 ? 0 : 6),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.brandGreen
                    : done
                        ? AppColors.metricMint
                        : AppColors.parchment,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active || done
                      ? AppColors.brandGreen
                      : AppColors.divider,
                ),
              ),
              child: Text(
                steps[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.labelSm(
                  color: active
                      ? Colors.white
                      : done
                          ? AppColors.brandGreen
                          : AppColors.textSubtle,
                ).copyWith(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.amount, {this.valueColor});

  final String label;
  final int amount;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final prefix = amount < 0 ? '-' : '';
    final formatted = CurrencyFormatter.formatRupiah(amount.abs());
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMd(color: AppColors.textMuted),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$prefix$formatted',
          style: AppTypography.priceText(
            fontSize: 13,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

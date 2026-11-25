import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/sw_page_transitions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../user/domain/booking_calculator.dart';
import '../../data/admin_operations_repository.dart';
import '../../domain/models/admin_models.dart';
import '../providers/admin_providers.dart';

class AdminPosScreen extends ConsumerStatefulWidget {
  const AdminPosScreen({super.key});

  @override
  ConsumerState<AdminPosScreen> createState() => _AdminPosScreenState();
}

class _AdminPosScreenState extends ConsumerState<AdminPosScreen> {
  int _modeIndex = 0; // 0: Kasir Loket POS, 1: Gate Scanner
  int _previousModeIndex = 0;

  // POS Walk-in state
  final _posFormKey = GlobalKey<FormState>();
  final _buyerNameCtrl = TextEditingController();
  final _buyerPhoneCtrl = TextEditingController(text: '081234567890');
  String? _selectedEventId;
  String _selectedZone = 'REGULER';
  final List<String> _selectedSeats = [];
  bool _isIssuing = false;
  AdminTicketGateModel? _issuedTicket;

  // Gate Scanner state
  final _codeCtrl = TextEditingController();
  bool _isScanning = false;
  GateValidationResult? _lastScanResult;
  List<Map<String, dynamic>> _scanHistory = const [];

  @override
  void initState() {
    super.initState();
    _restoreLocalPosState();
  }

  Future<void> _restoreLocalPosState() async {
    final repo = ref.read(adminOperationsRepositoryProvider);
    final savedEvent = await repo.getSavedPosEventId();
    final history = await repo.getLocalScanHistory();
    if (!mounted) return;
    setState(() {
      if (savedEvent != null && savedEvent.isNotEmpty) {
        _selectedEventId = savedEvent;
      }
      _scanHistory = history;
    });
  }

  @override
  void dispose() {
    _buyerNameCtrl.dispose();
    _buyerPhoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  int _priceForZone(AdminEventModel event, String zoneId) {
    if (event.zonePrices != null) {
      return event.zonePrices!.priceForZone(zoneId);
    }
    final cfg = TheaterSeatMapHelper.zones.where((z) => z.id == zoneId).firstOrNull;
    return cfg?.defaultPrice ?? event.price;
  }

  Future<void> _issueTicket(
    AdminEventModel event,
    Set<String> bookedSet,
  ) async {
    final validation = TheaterSeatMapHelper.validateSeatSelection(
      selectedSeats: _selectedSeats,
      bookedSeats: bookedSet,
      maxSeats: 8,
    );
    if (!validation.valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation.error ?? 'Pilih kursi terlebih dahulu.')),
      );
      return;
    }
    if (!_posFormKey.currentState!.validate()) return;

    setState(() => _isIssuing = true);
    try {
      final totalPrice = _priceForZone(event, _selectedZone) * _selectedSeats.length;
      final ticket = await ref.read(adminOperationsRepositoryProvider).issuePosTicket(
            eventId: event.id,
            eventTitle: event.title,
            userName: _buyerNameCtrl.text.trim(),
            userPhone: _buyerPhoneCtrl.text.trim(),
            seats: List<String>.from(_selectedSeats),
            zone: _selectedZone,
            totalPrice: totalPrice,
          );
      _buyerNameCtrl.clear();
      _selectedSeats.clear();
      ref.invalidate(adminEventBookedSeatsProvider(event.id));
      ref.invalidate(adminTicketsProvider);
      ref.invalidate(adminEventsProvider);
      ref.invalidate(adminAnalyticsProvider);
      if (mounted) {
        setState(() {
          _issuedTicket = ticket;
          _isIssuing = false;
        });
      }
    } on ApiException catch (e) {
      ref.invalidate(adminEventBookedSeatsProvider(event.id));
      if (mounted) {
        setState(() => _isIssuing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _validateCode([String? overrideCode]) async {
    final code = (overrideCode ?? _codeCtrl.text).trim();
    if (code.isEmpty) return;
    setState(() => _isScanning = true);
    final result = await ref
        .read(adminOperationsRepositoryProvider)
        .validateGateTicket(code);
    final updatedHistory =
        await ref.read(adminOperationsRepositoryProvider).getLocalScanHistory();
    ref.invalidate(adminTicketsProvider);
    ref.invalidate(adminAnalyticsProvider);
    if (!mounted) return;
    setState(() {
      _lastScanResult = result;
      _scanHistory = updatedHistory;
      _isScanning = false;
      if (result.success) {
        _codeCtrl.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(adminEventsProvider);
    final ticketsAsync = ref.watch(adminTicketsProvider);
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(adminEventsProvider.notifier).refresh();
        await ref.read(adminTicketsProvider.notifier).refresh();
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
                    'Kasir Loket (POS) & Gate Scanner',
                    style: AppTypography.headlineLg(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Penerbitan tiket walk-in loket teater & validasi masuk gerbang Wayang Orang',
                    style: AppTypography.bodyMd(color: AppColors.textSubtle),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SwFilterChip(
                        label: 'Kasir Loket Walk-In',
                        icon: Icons.point_of_sale_rounded,
                        selected: _modeIndex == 0,
                        onTap: () => setState(() {
                          _previousModeIndex = _modeIndex;
                          _modeIndex = 0;
                        }),
                      ),
                      SwFilterChip(
                        label: 'Gate QR Check-In',
                        icon: Icons.qr_code_scanner_rounded,
                        selected: _modeIndex == 1,
                        onTap: () => setState(() {
                          _previousModeIndex = _modeIndex;
                          _modeIndex = 1;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwDirectionalSwitcher(
                    isForward: _modeIndex >= _previousModeIndex,
                    child: KeyedSubtree(
                      key: ValueKey('admin-pos-mode-$_modeIndex'),
                      child: _modeIndex == 0
                          ? _buildPosWalkIn(eventsAsync)
                          : _buildGateScanner(ticketsAsync),
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

  Widget _buildPosWalkIn(AsyncValue<List<AdminEventModel>> eventsAsync) {
    return eventsAsync.when(
      loading: () => const SwLoadingSkeleton(height: 200),
      error: (err, _) => SwErrorView(
        message: err.toString(),
        onRetry: () => ref.read(adminEventsProvider.notifier).refresh(),
      ),
      data: (events) {
        if (events.isEmpty) {
          return const SwEmptyState(
            icon: Icons.event_busy_outlined,
            title: 'Belum Ada Jadwal Pentas',
            description: 'Buat jadwal acara terlebih dahulu di menu Acara.',
          );
        }

        final activeEvent = events
                .where((e) => e.id == _selectedEventId)
                .firstOrNull ??
            events.first;
        final bookedAsync =
            ref.watch(adminEventBookedSeatsProvider(activeEvent.id));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_issuedTicket != null) ...[
              _IssuedPassBanner(
                ticket: _issuedTicket!,
                onDismiss: () => setState(() => _issuedTicket = null),
              ),
              const SizedBox(height: 14),
            ],
            SwCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. Pilih Lakon Pementasan & Zona',
                    style: AppTypography.titleMd(),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: activeEvent.id,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Jadwal Pagelaran',
                    ),
                    items: events
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(
                              '${e.title} (${e.date})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        _selectedEventId = val;
                        _selectedSeats.clear();
                      });
                      ref
                          .read(adminOperationsRepositoryProvider)
                          .savePosEventId(val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TheaterSeatMapHelper.zones.map((z) {
                      final tariff = _priceForZone(activeEvent, z.id);
                      return SwFilterChip(
                        label:
                            '${z.label} (${CurrencyFormatter.formatCompactRupiah(tariff)})',
                        selected: _selectedZone == z.id,
                        onTap: () => setState(() {
                          _selectedZone = z.id;
                          _selectedSeats.clear();
                        }),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            bookedAsync.when(
              loading: () => const SwLoadingSkeleton(height: 150),
              error: (err, _) => SwErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(
                  adminEventBookedSeatsProvider(activeEvent.id),
                ),
              ),
              data: (bookedList) {
                final bookedSet = bookedList.toSet();
                final activeZone = TheaterSeatMapHelper.zones
                    .firstWhere((z) => z.id == _selectedZone);
                final unitPrice = _priceForZone(activeEvent, _selectedZone);

                return SwCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '2. Pilih Kursi & Identitas Pembeli',
                        style: AppTypography.titleMd(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeZone.subtitle,
                        style: AppTypography.labelSm(),
                      ),
                      const SizedBox(height: 10),
                      ...activeZone.rows.map((row) {
                        final seats = TheaterSeatMapHelper.seatsForRow(row);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: seats.map((seatId) {
                              final booked = bookedSet.contains(seatId);
                              final selected = _selectedSeats.contains(seatId);
                              return InkWell(
                                onTap: booked
                                    ? null
                                    : () => setState(() {
                                          if (selected) {
                                            _selectedSeats.remove(seatId);
                                          } else if (_selectedSeats.length < 8) {
                                            _selectedSeats.add(seatId);
                                          }
                                        }),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 54,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: booked
                                        ? AppColors.surfaceDim
                                        : selected
                                            ? AppColors.brandGreen
                                            : AppColors.ivory,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: booked
                                          ? AppColors.warmGray
                                          : selected
                                              ? AppColors.gold
                                              : AppColors.brandGreen
                                                  .withValues(alpha: 0.45),
                                    ),
                                  ),
                                  child: Text(
                                    seatId,
                                    style: AppTypography.labelSm(
                                      color: booked
                                          ? AppColors.warmGray
                                          : selected
                                              ? AppColors.goldLight
                                              : AppColors.brandGreen,
                                    ).copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }),
                      const Divider(height: 22),
                      Form(
                        key: _posFormKey,
                        child: Column(
                          children: [
                            SwInput(
                              controller: _buyerNameCtrl,
                              label: 'Nama Penonton Walk-In',
                              hint: 'Masukkan nama pembeli di loket',
                              prefixIcon: Icons.person_outline_rounded,
                              textCapitalization: TextCapitalization.words,
                              inputFormatters: SwInputFormatters.personName,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (v) =>
                                  SwValidators.personName(v, 'Nama pembeli'),
                            ),
                            const SizedBox(height: 10),
                            SwInput(
                              controller: _buyerPhoneCtrl,
                              label: 'No. WhatsApp Pembeli',
                              hint: '081234567890',
                              prefixIcon: Icons.phone_android_rounded,
                              keyboardType: TextInputType.phone,
                              inputFormatters: SwInputFormatters.phoneDigits,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: SwValidators.phoneId,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Text(
                              _selectedSeats.isEmpty
                                  ? 'Belum ada kursi dipilih'
                                  : 'Kursi: ${_selectedSeats.join(', ')} (${_selectedSeats.length}x)',
                              style: AppTypography.labelMd(),
                            ),
                            Text(
                              CurrencyFormatter.formatRupiah(
                                unitPrice * _selectedSeats.length,
                              ),
                              style: AppTypography.priceText(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwButton(
                        label: 'Terbitkan Tiket Walk-In',
                        leadingIcon: Icons.confirmation_number_outlined,
                        fullWidth: true,
                        isLoading: _isIssuing,
                        onPressed: () => _issueTicket(activeEvent, bookedSet),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildGateScanner(AsyncValue<List<AdminTicketGateModel>> ticketsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pemindai & Validasi Kode Tiket Gerbang',
                style: AppTypography.titleMd(),
              ),
              const SizedBox(height: 4),
              Text(
                'Masukkan kode booking (contoh: SWD-XXXXX atau WO-SRW-100) untuk check-in penonton.',
                style: AppTypography.bodyMd(color: AppColors.textSubtle),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: SwInput(
                      controller: _codeCtrl,
                      label: 'Kode Booking / ID Tiket',
                      hint: 'SWD-12345',
                      prefixIcon: Icons.qr_code_rounded,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: SwInputFormatters.alphaNumCode,
                      onSubmitted: (_) => _validateCode(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SwButton(
                    label: 'Validasi',
                    height: 46,
                    isLoading: _isScanning,
                    onPressed: _validateCode,
                  ),
                ],
              ),
              if (_lastScanResult != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _lastScanResult!.success
                        ? AppColors.successBg
                        : AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _lastScanResult!.message,
                        style: AppTypography.titleMd(
                          color: _lastScanResult!.success
                              ? AppColors.successText
                              : AppColors.error,
                        ),
                      ),
                      if (_lastScanResult!.ticket != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${_lastScanResult!.ticket!.userName} • Zona ${_lastScanResult!.ticket!.zone} • Kursi ${_lastScanResult!.ticket!.seats.join(', ')}',
                          style: AppTypography.bodyMd(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        SwCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Antrean Tiket Siap Check-In',
                style: AppTypography.titleMd(),
              ),
              const SizedBox(height: 10),
              ticketsAsync.when(
                loading: () => const SwLoadingSkeleton(height: 100),
                error: (err, _) => SwErrorView(
                  message: err.toString(),
                  onRetry: () =>
                      ref.read(adminTicketsProvider.notifier).refresh(),
                ),
                data: (tickets) {
                  final active =
                      tickets.where((t) => t.status == 'Aktif').toList();
                  if (active.isEmpty) {
                    return Text(
                      'Tidak ada tiket berstatus Aktif yang menunggu check-in.',
                      style: AppTypography.bodyMd(color: AppColors.textSubtle),
                    );
                  }
                  return Column(
                    children: active.take(8).map((t) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.ivory,
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
                                      '${t.bookingCode} • ${t.userName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.labelMd(),
                                    ),
                                    Text(
                                      'Zona ${t.zone} • Kursi ${t.seats.join(', ')}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.labelSm(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SwButton(
                                label: 'Check-In',
                                height: 34,
                                onPressed: () => _validateCode(t.bookingCode),
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
        if (_scanHistory.isNotEmpty) ...[
          const SizedBox(height: 14),
          SwCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Riwayat Validasi Gerbang (${_scanHistory.length})',
                  style: AppTypography.titleMd(),
                ),
                const SizedBox(height: 8),
                ..._scanHistory.take(6).map((item) {
                  final ok = item['success'] == true;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          ok ? Icons.check_circle_outline : Icons.error_outline,
                          size: 16,
                          color: ok ? AppColors.successText : AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${item['code']} (${item['userName']}) • ${item['message']}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSm(),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _IssuedPassBanner extends StatelessWidget {
  const _IssuedPassBanner({
    required this.ticket,
    required this.onDismiss,
  });

  final AdminTicketGateModel ticket;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return SwCard(
      backgroundColor: AppColors.successBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.successText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tiket Walk-In Diterbitkan: ${ticket.bookingCode}',
                  style: AppTypography.titleMd(color: AppColors.successText),
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${ticket.userName} • ${ticket.eventTitle} • Zona ${ticket.zone} (${ticket.seats.join(', ')})',
            style: AppTypography.bodyMd(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(
                  data: ticket.bookingCode,
                  version: QrVersions.auto,
                  size: 72,
                  backgroundColor: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: BarcodeWidget(
                  barcode: Barcode.code128(),
                  data: ticket.bookingCode,
                  width: 150,
                  height: 36,
                  drawText: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/booking_calculator.dart';
import '../../domain/models/user_models.dart';
import '../providers/user_catalog_providers.dart';
import '../providers/user_transactions_providers.dart';

class TheaterSeatMapSheet extends ConsumerStatefulWidget {
  const TheaterSeatMapSheet({super.key, required this.event});

  final UserEventModel event;

  static Future<void> show(
    BuildContext context, {
    required UserEventModel event,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.parchment,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TheaterSeatMapSheet(event: event),
    );
  }

  @override
  ConsumerState<TheaterSeatMapSheet> createState() =>
      _TheaterSeatMapSheetState();
}

class _TheaterSeatMapSheetState extends ConsumerState<TheaterSeatMapSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  String _selectedZone = 'VIP';
  final List<String> _selectedSeats = [];
  bool _isSubmitting = false;
  String? _errorMessage;
  UserTicketModel? _bookedTicket;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _nameController = TextEditingController(
      text: auth.userAccount?.name ?? '',
    );
    _phoneController = TextEditingController(
      text: auth.userAccount?.phone ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  int _priceForZone(String zoneId) {
    final zp = widget.event.zonePrices;
    if (zp != null) return zp.priceForZone(zoneId);
    final zoneCfg =
        TheaterSeatMapHelper.zones.where((z) => z.id == zoneId).firstOrNull;
    return zoneCfg?.defaultPrice ?? widget.event.price;
  }

  void _toggleSeat(String seatId, Set<String> bookedSet) {
    if (bookedSet.contains(seatId)) return;
    setState(() {
      _errorMessage = null;
      if (_selectedSeats.contains(seatId)) {
        _selectedSeats.remove(seatId);
      } else {
        if (_selectedSeats.length >= AppConstants.maxTicketPerOrder) {
          _errorMessage =
              'Maksimal pemesanan ${AppConstants.maxTicketPerOrder} kursi per transaksi.';
          return;
        }
        _selectedSeats.add(seatId);
      }
    });
  }

  Future<void> _confirmBooking(Set<String> bookedSet) async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      if (mounted) {
        Navigator.of(context).pop();
        context.go(
          '${AppRoutes.login}?redirect=${Uri.encodeComponent(AppRoutes.userSchedule)}',
        );
      }
      return;
    }

    final validation = TheaterSeatMapHelper.validateSeatSelection(
      selectedSeats: _selectedSeats,
      bookedSeats: bookedSet,
      maxSeats: AppConstants.maxTicketPerOrder,
    );
    if (!validation.valid) {
      setState(() => _errorMessage = validation.error);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final unitPrice = _priceForZone(_selectedZone);
      final ticket =
          await ref.read(userTransactionsRepositoryProvider).bookTickets(
                eventId: widget.event.id,
                eventTitle: widget.event.title,
                userName: _nameController.text.trim(),
                userPhone: _phoneController.text.trim(),
                seats: List<String>.from(_selectedSeats),
                zone: _selectedZone,
                totalPrice: unitPrice * _selectedSeats.length,
              );

      ref.invalidate(bookedSeatsProvider(widget.event.id));
      ref.invalidate(userEventsProvider);
      ref.invalidate(userTicketsProvider);

      if (mounted) {
        setState(() {
          _bookedTicket = ticket;
          _isSubmitting = false;
        });
      }
    } on ApiException catch (e) {
      Set<String> freshBooked = const {};
      try {
        final refreshed = await ref.refresh(
          bookedSeatsProvider(widget.event.id).future,
        );
        freshBooked = refreshed.toSet();
      } catch (_) {}
      if (mounted) {
        setState(() {
          if (freshBooked.isNotEmpty) {
            _selectedSeats.removeWhere(freshBooked.contains);
          }
          _errorMessage = e.message;
          _isSubmitting = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memesan tiket. Periksa koneksi server.';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookedAsync = ref.watch(bookedSeatsProvider(widget.event.id));

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: _bookedTicket != null
              ? _BookingSuccessBody(
                  ticket: _bookedTicket!,
                  onGoProfile: () {
                    final router = GoRouter.of(context);
                    Navigator.of(context).pop();
                    router.go(AppRoutes.userProfileWithTab('tickets'));
                  },
                  onClose: () => Navigator.of(context).pop(),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Denah Kursi Wayang Orang',
                                  style: AppTypography.headlineMd(),
                                ),
                                Text(
                                  widget.event.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                      const SizedBox(height: 12),

                      // Stage Representation
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGreenGradient,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'PANGGUNG KELIR & GAMELAN AGENG',
                              style: AppTypography.labelSm(
                                color: AppColors.goldLight,
                              ).copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              'Arah Pandang Penonton',
                              style: AppTypography.labelSm(
                                color: AppColors.canvas.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3 Zone Selector
                      Text('Pilih Zona Kursi', style: AppTypography.labelMd()),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: TheaterSeatMapHelper.zones.map((zone) {
                            final active = _selectedZone == zone.id;
                            final tariff = _priceForZone(zone.id);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: SwFilterChip(
                                label:
                                    '${zone.label} (${CurrencyFormatter.formatCompactRupiah(tariff)})',
                                selected: active,
                                onTap: () => setState(() {
                                  _selectedZone = zone.id;
                                  _selectedSeats.clear();
                                  _errorMessage = null;
                                }),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Seat Legend
                      const Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          _SeatLegendItem(
                            color: AppColors.ivory,
                            borderColor: AppColors.brandGreen,
                            label: 'Tersedia',
                          ),
                          _SeatLegendItem(
                            color: AppColors.brandGreen,
                            borderColor: AppColors.brandGreen,
                            label: 'Dipilih',
                          ),
                          _SeatLegendItem(
                            color: AppColors.surfaceDim,
                            borderColor: AppColors.warmGray,
                            label: 'Terisi',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Live Booked Seats & Grid
                      bookedAsync.when(
                        loading: () => const SwLoadingSkeleton(height: 110),
                        error: (err, _) => SwErrorView(
                          message: err.toString(),
                          onRetry: () => ref.invalidate(
                            bookedSeatsProvider(widget.event.id),
                          ),
                        ),
                        data: (bookedList) {
                          final bookedSet = bookedList.toSet();
                          final activeZoneCfg = TheaterSeatMapHelper.zones
                              .firstWhere((z) => z.id == _selectedZone);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeZoneCfg.subtitle,
                                style: AppTypography.labelSm(),
                              ),
                              const SizedBox(height: 10),
                              ...activeZoneCfg.rows.map((row) {
                                final seats =
                                    TheaterSeatMapHelper.seatsForRow(row);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: seats.map((seatId) {
                                      final isBooked =
                                          bookedSet.contains(seatId);
                                      final isSelected =
                                          _selectedSeats.contains(seatId);
                                      return InkWell(
                                        onTap: isBooked
                                            ? null
                                            : () =>
                                                _toggleSeat(seatId, bookedSet),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 56,
                                          height: 36,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: isBooked
                                                ? AppColors.surfaceDim
                                                : isSelected
                                                    ? AppColors.brandGreen
                                                    : AppColors.ivory,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isBooked
                                                  ? AppColors.warmGray
                                                  : isSelected
                                                      ? AppColors.gold
                                                      : AppColors.brandGreen
                                                          .withValues(
                                                          alpha: 0.45,
                                                        ),
                                            ),
                                          ),
                                          child: Text(
                                            seatId,
                                            style: AppTypography.labelSm(
                                              color: isBooked
                                                  ? AppColors.warmGray
                                                  : isSelected
                                                      ? AppColors.goldLight
                                                      : AppColors.brandGreen,
                                            ).copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              }),
                              const SizedBox(height: 12),
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    SwInput(
                                      controller: _nameController,
                                      label: 'Nama Pemesan',
                                      hint: 'Nama lengkap sesuai identitas',
                                      prefixIcon: Icons.person_outline_rounded,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      inputFormatters:
                                          SwInputFormatters.personName,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      validator: (v) =>
                                          SwValidators.personName(
                                        v,
                                        'Nama pemesan',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SwInput(
                                      controller: _phoneController,
                                      label: 'No. WhatsApp',
                                      hint: '081234567890',
                                      prefixIcon: Icons.phone_android_rounded,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters:
                                          SwInputFormatters.phoneDigits,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      validator: SwValidators.phoneId,
                                    ),
                                  ],
                                ),
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTypography.bodyMd(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              SwCard(
                                backgroundColor: AppColors.surfaceContainerLow,
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedSeats.isEmpty
                                                ? 'Belum ada kursi dipilih'
                                                : 'Kursi: ${_selectedSeats.join(', ')}',
                                            style: AppTypography.labelMd(),
                                          ),
                                          Text(
                                            '${_selectedSeats.length} tiket × ${CurrencyFormatter.formatRupiah(_priceForZone(_selectedZone))}',
                                            style: AppTypography.labelSm(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.formatRupiah(
                                        _priceForZone(_selectedZone) *
                                            _selectedSeats.length,
                                      ),
                                      style: AppTypography.priceText(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              SwButton(
                                label: 'Konfirmasi Pemesanan Tiket',
                                trailingIcon: Icons.confirmation_number_outlined,
                                fullWidth: true,
                                isLoading: _isSubmitting,
                                onPressed: () => _confirmBooking(bookedSet),
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
    );
  }
}

class _SeatLegendItem extends StatelessWidget {
  const _SeatLegendItem({
    required this.color,
    required this.borderColor,
    required this.label,
  });

  final Color color;
  final Color borderColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTypography.labelSm()),
      ],
    );
  }
}

class _BookingSuccessBody extends StatelessWidget {
  const _BookingSuccessBody({
    required this.ticket,
    required this.onGoProfile,
    required this.onClose,
  });

  final UserTicketModel ticket;
  final VoidCallback onGoProfile;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: AppColors.successBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 32,
            color: AppColors.successText,
          ),
        ),
        const SizedBox(height: 14),
        Text('Tiket Berhasil Dipesan!', style: AppTypography.headlineMd()),
        const SizedBox(height: 6),
        Text(
          'Kode Booking: ${ticket.bookingCode}\nKursi ${ticket.seats.join(', ')} (Zona ${ticket.zone})',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMd(color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: SwButton(
                label: 'Tutup',
                variant: SwButtonVariant.secondary,
                onPressed: onClose,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SwButton(
                label: 'Lihat E-Tiket',
                onPressed: onGoProfile,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

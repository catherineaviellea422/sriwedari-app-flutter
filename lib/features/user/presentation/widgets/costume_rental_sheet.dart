import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/models/user_models.dart';
import '../providers/user_catalog_providers.dart';
import '../providers/user_transactions_providers.dart';

class CostumeRentalSheet extends ConsumerStatefulWidget {
  const CostumeRentalSheet({super.key, required this.costume});

  final UserCostumeModel costume;

  static Future<void> show(
    BuildContext context, {
    required UserCostumeModel costume,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.parchment,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CostumeRentalSheet(costume: costume),
    );
  }

  @override
  ConsumerState<CostumeRentalSheet> createState() => _CostumeRentalSheetState();
}

class _CostumeRentalSheetState extends ConsumerState<CostumeRentalSheet> {
  int _selectedDays = 3;
  late String _selectedSize;

  @override
  void initState() {
    super.initState();
    _selectedSize =
        widget.costume.sizes.isNotEmpty ? widget.costume.sizes.first : 'All Size';
  }

  Future<void> _proceedToBooking() async {
    final selection = BookingCartItemModel(
      id: widget.costume.id,
      name: widget.costume.name,
      price: widget.costume.price,
      days: _selectedDays,
      size: _selectedSize,
    );
    await ref
        .read(userCatalogRepositoryProvider)
        .saveCostumeBookingDraft(selection);

    if (!mounted) return;
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(
      '${AppRoutes.userBooking}?costumeId=${Uri.encodeComponent(widget.costume.id)}&days=$_selectedDays&size=${Uri.encodeComponent(_selectedSize)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final costume = widget.costume;
    final settingsAsync = ref.watch(publicSettingsProvider);
    final depositFee =
        settingsAsync.value?.depositFee ?? AppConstants.defaultDepositFee;
    final rentalSubtotal = costume.price * _selectedDays;
    final sizes = costume.sizes.isNotEmpty ? costume.sizes : const ['All Size'];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SwImage(source: costume.image, width: 68, height: 68),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          costume.name,
                          style: AppTypography.cardTitleSerif(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${CurrencyFormatter.formatRupiah(costume.price)} / hari',
                          style: AppTypography.priceText(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text('Pilih Ukuran Busana', style: AppTypography.labelMd()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sizes.map((size) {
                  final sizeStock = costume.sizeStocks[size];
                  final label = sizeStock != null ? '$size ($sizeStock)' : size;
                  return SwFilterChip(
                    label: label,
                    selected: _selectedSize == size,
                    onTap: () => setState(() => _selectedSize = size),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Pilih Durasi Sewa', style: AppTypography.labelMd()),
              const SizedBox(height: 8),
              Row(
                children: [1, 3, 7].map((days) {
                  final active = _selectedDays == days;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: days == 7 ? 0 : 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedDays = days),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.brandGreen
                                : AppColors.ivory,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusButton,
                            ),
                            border: Border.all(
                              color: active
                                  ? AppColors.brandGreen
                                  : AppColors.divider,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$days Hari',
                                style: AppTypography.labelMd(
                                  color: active
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormatter.formatCompactRupiah(
                                  costume.price * days,
                                ),
                                style: AppTypography.labelSm(
                                  color: active
                                      ? AppColors.goldLight
                                      : AppColors.textSubtle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              SwCard(
                backgroundColor: AppColors.surfaceContainerLow,
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal Sewa', style: AppTypography.bodyMd()),
                        Text(
                          CurrencyFormatter.formatRupiah(rentalSubtotal),
                          style: AppTypography.priceText(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Deposit Jaminan (dikembalikan)',
                          style: AppTypography.bodyMd(),
                        ),
                        Text(
                          CurrencyFormatter.formatRupiah(depositFee),
                          style: AppTypography.priceText(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SwButton(
                label: 'Lanjutkan ke Reservasi',
                trailingIcon: Icons.arrow_forward_rounded,
                fullWidth: true,
                onPressed: costume.isAvailable ? _proceedToBooking : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

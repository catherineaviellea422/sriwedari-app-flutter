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
import '../../../user/domain/models/user_event_ticket_model.dart';
import '../../domain/models/admin_models.dart';
import '../providers/admin_providers.dart';

class AdminEventsScreen extends ConsumerStatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  ConsumerState<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends ConsumerState<AdminEventsScreen> {
  Future<void> _openEventForm([AdminEventModel? existing]) async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final dateCtrl = TextEditingController(
      text: existing?.date ??
          DateTime.now().add(const Duration(days: 7)).toIso8601String().substring(0, 10),
    );
    final timeCtrl = TextEditingController(text: existing?.time ?? '19:30 WIB');
    final locationCtrl = TextEditingController(
      text: existing?.location ?? 'Gedung Wayang Orang Sriwedari',
    );
    final quotaCtrl = TextEditingController(
      text: existing != null ? existing.quota.toString() : '48',
    );
    final vipCtrl = TextEditingController(
      text: (existing?.zonePrices?.vip ?? 50000).toString(),
    );
    final regCtrl = TextEditingController(
      text: (existing?.zonePrices?.reguler ?? existing?.price ?? 35000).toString(),
    );
    final balkonCtrl = TextEditingController(
      text: (existing?.zonePrices?.balkon ?? 25000).toString(),
    );
    final imageCtrl = TextEditingController(
      text: existing?.image ?? '/images/tari-jawa-dramatic-stage.png',
    );
    final descCtrl = TextEditingController(text: existing?.description ?? '');
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
                            ? 'Tambah Jadwal Pagelaran'
                            : 'Ubah Jadwal Pagelaran',
                        style: AppTypography.headlineMd(),
                      ),
                      const SizedBox(height: 14),
                      SwInput(
                        controller: titleCtrl,
                        label: 'Judul Lakon / Acara',
                        validator: (v) =>
                            SwValidators.requiredField(v, 'Judul acara'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SwInput(
                              controller: dateCtrl,
                              label: 'Tanggal (YYYY-MM-DD)',
                              keyboardType: TextInputType.datetime,
                              inputFormatters: SwInputFormatters.isoDate,
                              validator: (v) =>
                                  SwValidators.isoDate(v, 'Tanggal'),
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
                                    firstDate: DateTime(2020),
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
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SwInput(
                              controller: timeCtrl,
                              label: 'Jam Pentas',
                              validator: (v) =>
                                  SwValidators.requiredField(v, 'Jam pentas'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: SwInput(
                              controller: locationCtrl,
                              label: 'Lokasi Gedung',
                              validator: (v) =>
                                  SwValidators.requiredField(v, 'Lokasi'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SwInput(
                              controller: quotaCtrl,
                              label: 'Kuota Kursi',
                              keyboardType: TextInputType.number,
                              inputFormatters: SwInputFormatters.digitsOnly,
                              validator: (v) => SwValidators.intRange(
                                v,
                                fieldName: 'Kuota',
                                min: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tarif Tiket 3 Zona Teater (Rp)',
                        style: AppTypography.labelMd(),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: SwInput(
                              controller: vipCtrl,
                              label: 'VIP',
                              keyboardType: TextInputType.number,
                              inputFormatters: SwInputFormatters.digitsOnly,
                              validator: (v) => SwValidators.intRange(
                                v,
                                fieldName: 'Tarif VIP',
                                min: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SwInput(
                              controller: regCtrl,
                              label: 'Reguler',
                              keyboardType: TextInputType.number,
                              inputFormatters: SwInputFormatters.digitsOnly,
                              validator: (v) => SwValidators.intRange(
                                v,
                                fieldName: 'Tarif Reguler',
                                min: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SwInput(
                              controller: balkonCtrl,
                              label: 'Balkon',
                              keyboardType: TextInputType.number,
                              inputFormatters: SwInputFormatters.digitsOnly,
                              validator: (v) => SwValidators.intRange(
                                v,
                                fieldName: 'Tarif Balkon',
                                min: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: SwInput(
                              controller: imageCtrl,
                              label: 'URL Poster Acara',
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
                                      prefix: 'event',
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
                        label: 'Sinopsis / Deskripsi Lakon',
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
                              label: 'Simpan Jadwal',
                              isLoading: isSaving,
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                setDialogState(() => isSaving = true);
                                try {
                                  final vip =
                                      int.tryParse(vipCtrl.text.trim()) ?? 50000;
                                  final reg =
                                      int.tryParse(regCtrl.text.trim()) ?? 35000;
                                  final balkon =
                                      int.tryParse(balkonCtrl.text.trim()) ??
                                          25000;
                                  final model = AdminEventModel(
                                    id: existing?.id ?? '',
                                    title: titleCtrl.text.trim(),
                                    date: dateCtrl.text.trim(),
                                    time: timeCtrl.text.trim(),
                                    location: locationCtrl.text.trim(),
                                    price: reg,
                                    quota:
                                        int.tryParse(quotaCtrl.text.trim()) ??
                                            48,
                                    booked: existing?.booked ?? 0,
                                    image: imageCtrl.text.trim(),
                                    description: descCtrl.text.trim(),
                                    zonePrices: EventZonePrices(
                                      vip: vip,
                                      reguler: reg,
                                      balkon: balkon,
                                    ),
                                  );
                                  await ref
                                      .read(adminCatalogRepositoryProvider)
                                      .saveEvent(model);
                                  await ref
                                      .read(adminEventsProvider.notifier)
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

  Future<void> _deleteEvent(AdminEventModel evt) async {
    final confirm = await SwConfirmDialog.showDeleteModal(
      context,
      itemName: evt.title,
    );
    if (!confirm || !mounted) return;
    try {
      await ref.read(adminCatalogRepositoryProvider).deleteEvent(evt.id);
      await ref.read(adminEventsProvider.notifier).refresh();
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
    final eventsAsync = ref.watch(adminEventsProvider);
    final config = ref.watch(appConfigProvider);
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);
    final hPad = centeredSliverHorizontalPadding(
      width,
      horizontalMargin: margin,
      maxContentWidth: AppSpacing.maxContentWidth,
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(adminEventsProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        scrollCacheExtent: const ScrollCacheExtent.pixels(600),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, AppSpacing.xl, hPad, 16),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
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
                          'Kelola Jadwal & Acara',
                          style: AppTypography.headlineLg(),
                        ),
                        Text(
                          'Manajemen agenda pentas Wayang Orang, kuota, & tarif 3 zona',
                          style: AppTypography.bodyMd(
                            color: AppColors.textSubtle,
                          ),
                        ),
                      ],
                    ),
                    SwButton(
                      label: 'Tambah Acara',
                      leadingIcon: Icons.add_rounded,
                      onPressed: () => _openEventForm(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ...eventsAsync.when(
            loading: () => [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                sliver: const SliverToBoxAdapter(
                  child: SwContentSwitcher(
                    child: SwLoadingSkeleton(
                      key: ValueKey('adm_evt_loading'),
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
                      key: const ValueKey('adm_evt_error'),
                      message: err.toString(),
                      onRetry: () =>
                          ref.read(adminEventsProvider.notifier).refresh(),
                    ),
                  ),
                ),
              ),
            ],
            data: (events) {
              if (events.isEmpty) {
                return [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                    sliver: SliverToBoxAdapter(
                      child: SwContentSwitcher(
                        child: SwEmptyState(
                          key: const ValueKey('adm_evt_empty'),
                          icon: Icons.theater_comedy_outlined,
                          title: 'Belum Ada Jadwal Pentas',
                          description:
                              'Tambahkan jadwal pertunjukan Wayang Orang Sriwedari.',
                          actionLabel: 'Tambah Acara',
                          onAction: () => _openEventForm(),
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
                        final evt = events[index];
                        final vip = evt.zonePrices?.vip ?? 50000;
                        final reg = evt.zonePrices?.reguler ?? evt.price;
                        final bal = evt.zonePrices?.balkon ?? 25000;

                        return RepaintBoundary(
                          child: FadeSlideEntrance(
                            key: ValueKey('adm_evt_${evt.id}'),
                            index: index,
                            onceKey: 'adm_evt_${evt.id}',
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SwCard(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SwImage(
                                      source: evt.image,
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
                                            evt.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.titleMd(),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${evt.date} • ${evt.time} • ${evt.location}',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.labelSm(),
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              SwStatusBadge(
                                                label:
                                                    'Terisi ${evt.booked}/${evt.quota}',
                                                tone: evt.booked >= evt.quota
                                                    ? SwBadgeTone.warning
                                                    : SwBadgeTone.info,
                                              ),
                                              SwStatusBadge(
                                                label:
                                                    'VIP ${CurrencyFormatter.formatCompactRupiah(vip)} • Reg ${CurrencyFormatter.formatCompactRupiah(reg)} • Bal ${CurrencyFormatter.formatCompactRupiah(bal)}',
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
                                                variant:
                                                    SwButtonVariant.secondary,
                                                height: 34,
                                                onPressed: () =>
                                                    _openEventForm(evt),
                                              ),
                                              SwButton(
                                                label: 'Hapus',
                                                variant:
                                                    SwButtonVariant.destructive,
                                                height: 34,
                                                onPressed: () =>
                                                    _deleteEvent(evt),
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
                      childCount: events.length,
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

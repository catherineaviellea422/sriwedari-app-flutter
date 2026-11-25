import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../providers/admin_providers.dart';

class AdminAuditScreen extends ConsumerStatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  ConsumerState<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends ConsumerState<AdminAuditScreen> {
  final _searchCtrl = TextEditingController();
  String _severityFilter = 'Semua';
  bool _isExporting = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      final csvContent = await ref
          .read(adminOperationsRepositoryProvider)
          .exportAuditCsvRaw();
      var savedMessage = 'CSV audit trail berhasil disalin ke clipboard.';
      try {
        final saveCsv = ref.read(csvFileSaverProvider);
        await saveCsv(
          'sriwedari-audit-${DateTime.now().millisecondsSinceEpoch}',
          Uint8List.fromList(utf8.encode(csvContent)),
        );
        savedMessage = 'Berkas CSV audit trail berhasil diekspor.';
      } catch (_) {
        await Clipboard.setData(ClipboardData(text: csvContent));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(savedMessage)),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(adminAuditLogsProvider);
    final width = MediaQuery.sizeOf(context).width;
    final margin = ResponsiveHelper.horizontalMarginForWidth(width);
    final q = _searchCtrl.text.trim().toLowerCase();
    final hPad = centeredSliverHorizontalPadding(
      width,
      horizontalMargin: margin,
      maxContentWidth: AppSpacing.maxContentWidth,
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(adminAuditLogsProvider.notifier).refresh(),
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
                              'Audit Trail Keamanan',
                              style: AppTypography.headlineLg(),
                            ),
                            Text(
                              'Rekam jejak seluruh transaksi, QC retur, gate check-in, & pengaturan',
                              style: AppTypography.bodyMd(
                                color: AppColors.textSubtle,
                              ),
                            ),
                          ],
                        ),
                        SwButton(
                          label: 'Ekspor CSV',
                          leadingIcon: Icons.download_rounded,
                          isLoading: _isExporting,
                          onPressed: _exportCsv,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SwInput(
                    controller: _searchCtrl,
                    hint: 'Cari aksi, aktor, atau rincian kejadian...',
                    prefixIcon: Icons.search_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Semua', 'info', 'warning', 'critical'].map((s) {
                      return SwFilterChip(
                        label: s == 'Semua' ? 'Semua Level' : s.toUpperCase(),
                        selected: _severityFilter == s,
                        onTap: () => setState(() => _severityFilter = s),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          ...logsAsync.when(
            loading: () => [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                sliver: const SliverToBoxAdapter(
                  child: SwContentSwitcher(
                    child: SwLoadingSkeleton(
                      key: ValueKey('adm_aud_loading'),
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
                      key: const ValueKey('adm_aud_error'),
                      message: err.toString(),
                      onRetry: () =>
                          ref.read(adminAuditLogsProvider.notifier).refresh(),
                    ),
                  ),
                ),
              ),
            ],
            data: (logs) {
              final filtered = logs.where((l) {
                final matchSev =
                    _severityFilter == 'Semua' || l.severity == _severityFilter;
                final matchQuery = q.isEmpty ||
                    l.action.toLowerCase().contains(q) ||
                    l.actorName.toLowerCase().contains(q) ||
                    l.details.toLowerCase().contains(q);
                return matchSev && matchQuery;
              }).toList();

              if (filtered.isEmpty) {
                return [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xl),
                    sliver: SliverToBoxAdapter(
                      child: SwContentSwitcher(
                        child: SwEmptyState(
                          key: ValueKey('adm_aud_empty_$_severityFilter-$q'),
                          icon: Icons.security_outlined,
                          title: 'Tidak Ada Log Audit',
                          description:
                              'Belum ada log aktivitas yang sesuai dengan filter.',
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
                        final log = filtered[index];
                        final tone = log.severity == 'critical'
                            ? SwBadgeTone.error
                            : log.severity == 'warning'
                                ? SwBadgeTone.warning
                                : SwBadgeTone.info;
                        return RepaintBoundary(
                          child: FadeSlideEntrance(
                            key: ValueKey('adm_aud_${log.id}_$_severityFilter'),
                            index: index,
                            onceKey: 'adm_aud_${log.id}_$_severityFilter',
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
                                            log.action,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.labelMd(
                                              color: AppColors.brandGreen,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SwStatusBadge(
                                          label: log.severity.toUpperCase(),
                                          tone: tone,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      log.details,
                                      style: AppTypography.bodyMd(),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${log.actorName} (${log.actorRole}) • ${log.ipAddress} • ${log.timestamp}',
                                      style: AppTypography.labelSm(),
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

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AdminShortcutItem {
  const AdminShortcutItem({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.category,
  });

  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final String category;
}

const List<AdminShortcutItem> adminCommandShortcuts = [
  AdminShortcutItem(
    title: 'Dashboard Analitik',
    subtitle: 'Omzet bruto, metrik kunjungan, dan kanal pembayaran',
    route: AppRoutes.adminDashboard,
    icon: Icons.dashboard_outlined,
    category: 'Operasional',
  ),
  AdminShortcutItem(
    title: 'Pesanan Sewa & QC Retur',
    subtitle: 'Verifikasi slip transfer dan inspeksi mutu Grade A–D',
    route: AppRoutes.adminOrders,
    icon: Icons.receipt_long_outlined,
    category: 'Operasional',
  ),
  AdminShortcutItem(
    title: 'Kasir POS & Gate Scanner',
    subtitle: 'Penjualan tiket walk-in & pemindai QR pintu teater',
    route: AppRoutes.adminPos,
    icon: Icons.qr_code_scanner_rounded,
    category: 'Operasional',
  ),
  AdminShortcutItem(
    title: 'Rekap Pengunjung',
    subtitle: 'Pantauan presensi penonton harian dan hari ini',
    route: AppRoutes.adminVisitors,
    icon: Icons.groups_outlined,
    category: 'Operasional',
  ),
  AdminShortcutItem(
    title: 'Koleksi Galeri Seni',
    subtitle: 'Kurasi katalog karya seni tari & foto pusaka',
    route: AppRoutes.adminGallery,
    icon: Icons.photo_library_outlined,
    category: 'Katalog',
  ),
  AdminShortcutItem(
    title: 'Kategori Galeri',
    subtitle: 'Kelola rumpun seni tari Nusantara',
    route: AppRoutes.adminCategories,
    icon: Icons.category_outlined,
    category: 'Katalog',
  ),
  AdminShortcutItem(
    title: 'Katalog Kostum & Stok',
    subtitle: 'Inventaris busana keraton & buku besar mutasi stok',
    route: AppRoutes.adminCostumes,
    icon: Icons.checkroom_outlined,
    category: 'Katalog',
  ),
  AdminShortcutItem(
    title: 'Jadwal Pentas Wayang',
    subtitle: 'Atur lakon, kuota kursi, dan tarif zona teater',
    route: AppRoutes.adminEvents,
    icon: Icons.theater_comedy_outlined,
    category: 'Katalog',
  ),
  AdminShortcutItem(
    title: 'Kupon Diskon Budaya',
    subtitle: 'Buat dan aktifkan voucher promo sewa',
    route: AppRoutes.adminCoupons,
    icon: Icons.local_offer_outlined,
    category: 'Promosi',
  ),
  AdminShortcutItem(
    title: 'Moderasi Ulasan',
    subtitle: 'Tinjau dan moderasi ulasan pengunjung',
    route: AppRoutes.adminReviews,
    icon: Icons.rate_review_outlined,
    category: 'Promosi',
  ),
  AdminShortcutItem(
    title: 'Kelola Pengguna',
    subtitle: 'Manajemen akun pengunjung dan staf kurator',
    route: AppRoutes.adminUsers,
    icon: Icons.manage_accounts_outlined,
    category: 'Sistem',
  ),
  AdminShortcutItem(
    title: 'Audit Trail Keamanan',
    subtitle: 'Rekam jejak transaksi dan ekspor CSV UTF-8 BOM',
    route: AppRoutes.adminAudit,
    icon: Icons.security_outlined,
    category: 'Sistem',
  ),
  AdminShortcutItem(
    title: 'Pengaturan Sanggar & Reset DB',
    subtitle: 'Profil sanggar, jam buka, dan reset database uji',
    route: AppRoutes.adminSettings,
    icon: Icons.settings_outlined,
    category: 'Sistem',
  ),
  AdminShortcutItem(
    title: 'Dokumentasi Alur Sistem',
    subtitle: 'Panduan operasional standar untuk staf loket & kurator',
    route: AppRoutes.adminDocs,
    icon: Icons.menu_book_outlined,
    category: 'Sistem',
  ),
];

class CommandPaletteDialog extends StatefulWidget {
  const CommandPaletteDialog({super.key, required this.onNavigate});

  final ValueChanged<String> onNavigate;

  static const Set<String> _adminRootTabs = {
    AppRoutes.adminDashboard,
    AppRoutes.adminGallery,
    AppRoutes.adminOrders,
    AppRoutes.adminUsers,
    AppRoutes.adminSettings,
  };

  static Future<void> show(BuildContext context) async {
    final router = GoRouter.of(context);
    await showDialog<void>(
      context: context,
      barrierColor: AppColors.modalScrim,
      builder: (dialogContext) => CommandPaletteDialog(
        onNavigate: (route) {
          Navigator.of(dialogContext).pop();
          if (_adminRootTabs.contains(route)) {
            router.go(route);
          } else {
            router.push(route);
          }
        },
      ),
    );
  }

  @override
  State<CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<CommandPaletteDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cleanQuery = _query.trim().toLowerCase();
    final filtered = adminCommandShortcuts.where((item) {
      if (cleanQuery.isEmpty) return true;
      return item.title.toLowerCase().contains(cleanQuery) ||
          item.subtitle.toLowerCase().contains(cleanQuery) ||
          item.category.toLowerCase().contains(cleanQuery);
    }).toList();

    return Dialog(
      backgroundColor: AppColors.parchment,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusModal),
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                onSubmitted: (_) {
                  if (filtered.isNotEmpty) {
                    widget.onNavigate(filtered.first.route);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Cari modul admin (mis. QC, Loket, Audit, Kupon)...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.brandGreen,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Tidak ada pintasan yang cocok untuk "$_query".',
                        style: AppTypography.bodyMd(color: AppColors.textSubtle),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.metricMint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              item.icon,
                              size: 18,
                              color: AppColors.brandGreen,
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: AppTypography.titleMd(),
                          ),
                          subtitle: Text(
                            item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMd(color: AppColors.textSubtle),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              item.category,
                              style: AppTypography.labelSm(),
                            ),
                          ),
                          onTap: () => widget.onNavigate(item.route),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

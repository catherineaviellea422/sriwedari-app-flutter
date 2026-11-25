import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../config/app_config.dart';
import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/sw_modal_dialog.dart';
import 'command_palette_dialog.dart';

class _AdminNavEntry {
  const _AdminNavEntry({
    required this.label,
    required this.route,
    required this.icon,
    this.badge,
  });

  final String label;
  final String route;
  final IconData icon;
  final String? badge;
}

class _AdminNavGroup {
  const _AdminNavGroup({required this.title, required this.items});

  final String title;
  final List<_AdminNavEntry> items;
}

class _AdminTopContext {
  const _AdminTopContext({
    required this.title,
    this.fallbackBackRoute,
  });

  final String title;
  final String? fallbackBackRoute;

  bool get showBack => fallbackBackRoute != null;
}

const List<_AdminNavEntry> _adminBottomTabs = [
  _AdminNavEntry(label: 'Dashboard', route: AppRoutes.adminDashboard, icon: Icons.dashboard_rounded),
  _AdminNavEntry(label: 'Galeri', route: AppRoutes.adminGallery, icon: Icons.photo_library_rounded),
  _AdminNavEntry(label: 'Pesanan', route: AppRoutes.adminOrders, icon: Icons.receipt_long_rounded),
  _AdminNavEntry(label: 'Pengguna', route: AppRoutes.adminUsers, icon: Icons.people_rounded),
  _AdminNavEntry(label: 'Pengaturan', route: AppRoutes.adminSettings, icon: Icons.settings_rounded),
];

const List<_AdminNavGroup> _adminSidebarGroups = [
  _AdminNavGroup(
    title: 'OPERASIONAL',
    items: [
      _AdminNavEntry(label: 'Dashboard Analitik', route: AppRoutes.adminDashboard, icon: Icons.dashboard_outlined),
      _AdminNavEntry(label: 'Pesanan & QC Sewa', route: AppRoutes.adminOrders, icon: Icons.receipt_long_outlined),
      _AdminNavEntry(label: 'Kasir POS & Gate', route: AppRoutes.adminPos, icon: Icons.qr_code_scanner_rounded, badge: 'Loket'),
      _AdminNavEntry(label: 'Rekap Pengunjung', route: AppRoutes.adminVisitors, icon: Icons.groups_outlined),
    ],
  ),
  _AdminNavGroup(
    title: 'KATALOG & PENTAS',
    items: [
      _AdminNavEntry(label: 'Koleksi Galeri Seni', route: AppRoutes.adminGallery, icon: Icons.photo_library_outlined),
      _AdminNavEntry(label: 'Kategori Galeri', route: AppRoutes.adminCategories, icon: Icons.category_outlined),
      _AdminNavEntry(label: 'Kostum & Mutasi Stok', route: AppRoutes.adminCostumes, icon: Icons.checkroom_outlined),
      _AdminNavEntry(label: 'Jadwal Pentas Wayang', route: AppRoutes.adminEvents, icon: Icons.theater_comedy_outlined),
      _AdminNavEntry(label: 'Kupon Diskon', route: AppRoutes.adminCoupons, icon: Icons.local_offer_outlined),
      _AdminNavEntry(label: 'Moderasi Ulasan', route: AppRoutes.adminReviews, icon: Icons.rate_review_outlined),
    ],
  ),
  _AdminNavGroup(
    title: 'SISTEM & PENGAWASAN',
    items: [
      _AdminNavEntry(label: 'Kelola Pengguna', route: AppRoutes.adminUsers, icon: Icons.manage_accounts_outlined),
      _AdminNavEntry(label: 'Audit Trail Keamanan', route: AppRoutes.adminAudit, icon: Icons.security_outlined),
      _AdminNavEntry(label: 'Pengaturan Sanggar', route: AppRoutes.adminSettings, icon: Icons.settings_outlined),
      _AdminNavEntry(label: 'Dokumentasi Alur', route: AppRoutes.adminDocs, icon: Icons.menu_book_outlined),
    ],
  ),
];

class _OpenPaletteIntent extends Intent {
  const _OpenPaletteIntent();
}

class AdminAppShell extends ConsumerStatefulWidget {
  const AdminAppShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AdminAppShell> createState() => _AdminAppShellState();
}

class _AdminAppShellState extends ConsumerState<AdminAppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const Set<String> _adminRootRoutes = {
    AppRoutes.adminDashboard,
    AppRoutes.adminGallery,
    AppRoutes.adminOrders,
    AppRoutes.adminUsers,
    AppRoutes.adminSettings,
  };

  static _AdminTopContext _resolveTopContext(String currentLocation) {
    return switch (currentLocation) {
      AppRoutes.adminPos => const _AdminTopContext(
          title: 'Kasir & Gate',
          fallbackBackRoute: AppRoutes.adminDashboard,
        ),
      AppRoutes.adminVisitors => const _AdminTopContext(
          title: 'Kunjungan',
          fallbackBackRoute: AppRoutes.adminDashboard,
        ),
      AppRoutes.adminEvents => const _AdminTopContext(
          title: 'Agenda Pentas',
          fallbackBackRoute: AppRoutes.adminDashboard,
        ),
      AppRoutes.adminCoupons => const _AdminTopContext(
          title: 'Voucher Promo',
          fallbackBackRoute: AppRoutes.adminDashboard,
        ),
      AppRoutes.adminReviews => const _AdminTopContext(
          title: 'Ulasan Pengunjung',
          fallbackBackRoute: AppRoutes.adminDashboard,
        ),
      AppRoutes.adminAudit => const _AdminTopContext(
          title: 'Audit Trail',
          fallbackBackRoute: AppRoutes.adminDashboard,
        ),
      AppRoutes.adminDocs => const _AdminTopContext(
          title: 'Panduan SOP',
          fallbackBackRoute: AppRoutes.adminDashboard,
        ),
      AppRoutes.adminGalleryCreate => const _AdminTopContext(
          title: 'Karya Baru',
          fallbackBackRoute: AppRoutes.adminGallery,
        ),
      AppRoutes.adminCategories => const _AdminTopContext(
          title: 'Kategori Tari',
          fallbackBackRoute: AppRoutes.adminGallery,
        ),
      AppRoutes.adminCostumes => const _AdminTopContext(
          title: 'Inventaris Kostum',
          fallbackBackRoute: AppRoutes.adminGallery,
        ),
      AppRoutes.adminGallery => const _AdminTopContext(
          title: 'Galeri Kurasi',
        ),
      AppRoutes.adminOrders => const _AdminTopContext(
          title: 'Pesanan & QC',
        ),
      AppRoutes.adminUsers => const _AdminTopContext(
          title: 'Akun Pengguna',
        ),
      AppRoutes.adminSettings => const _AdminTopContext(
          title: 'Setelan Sanggar',
        ),
      _ => const _AdminTopContext(
          title: 'Panel Kurator Sriwedari',
        ),
    };
  }

  void _handleContextualBack(BuildContext context, _AdminTopContext topContext) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final fallback = topContext.fallbackBackRoute;
    if (fallback != null) {
      context.go(fallback);
    }
  }

  void _navigateToRoute(BuildContext context, String route) {
    if (_adminRootRoutes.contains(route)) {
      context.go(route);
    } else {
      context.push(route);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await SwConfirmDialog.showLogoutModal(
      context,
      subtitle: 'Sesi administrator akan diakhiri dan Anda kembali ke gerbang login.',
    );
    if (!confirmed || !mounted) return;
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go(AppRoutes.adminLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final sizeClass = ResponsiveHelper.of(context);
    final currentLocation = GoRouterState.of(context).uri.path;
    final topContext = _resolveTopContext(currentLocation);
    final isDrawerOpen = _scaffoldKey.currentState?.isDrawerOpen ?? false;
    final canExitApp =
        !topContext.showBack && widget.navigationShell.currentIndex == 0 && !isDrawerOpen;

    return PopScope(
      canPop: canExitApp,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          Navigator.of(context).pop();
          return;
        }
        if (topContext.showBack) {
          _handleContextualBack(context, topContext);
          return;
        }
        if (widget.navigationShell.currentIndex != 0) {
          widget.navigationShell.goBranch(0);
        }
      },
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.keyK, control: true): _OpenPaletteIntent(),
          SingleActivator(LogicalKeyboardKey.keyK, meta: true): _OpenPaletteIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _OpenPaletteIntent: CallbackAction<_OpenPaletteIntent>(
              onInvoke: (_) {
                CommandPaletteDialog.show(context);
                return null;
              },
            ),
          },
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.canvas,
            drawer: sizeClass == WindowSizeClass.expanded
                ? null
                : _AdminSidebarPanel(
                    currentLocation: currentLocation,
                    isDrawer: true,
                    onNavigate: (route) {
                      Navigator.of(context).pop();
                      _navigateToRoute(context, route);
                    },
                    onLogout: () {
                      Navigator.of(context).pop();
                      _handleLogout();
                    },
                  ),
            body: Row(
              children: [
                if (sizeClass == WindowSizeClass.medium)
                  NavigationRail(
                    backgroundColor: AppColors.brandGreenDark,
                    selectedIndex: widget.navigationShell.currentIndex,
                    onDestinationSelected: (idx) => widget.navigationShell.goBranch(
                      idx,
                      initialLocation: idx == widget.navigationShell.currentIndex,
                    ),
                    labelType: NavigationRailLabelType.all,
                    selectedIconTheme: const IconThemeData(color: AppColors.gold),
                    unselectedIconTheme: IconThemeData(
                      color: AppColors.canvas.withValues(alpha: 0.78),
                    ),
                    selectedLabelTextStyle: AppTypography.labelSm(color: AppColors.gold)
                        .copyWith(fontWeight: FontWeight.w700),
                    unselectedLabelTextStyle: AppTypography.labelSm(
                      color: AppColors.canvas.withValues(alpha: 0.78),
                    ),
                    indicatorColor: AppColors.gold.withValues(alpha: 0.16),
                    destinations: _adminBottomTabs
                        .map(
                          (tab) => NavigationRailDestination(
                            icon: Icon(tab.icon),
                            label: Text(tab.label),
                          ),
                        )
                        .toList(),
                  ),
                if (sizeClass == WindowSizeClass.expanded)
                  SizedBox(
                    width: 268,
                    child: _AdminSidebarPanel(
                      currentLocation: currentLocation,
                      isDrawer: false,
                      onNavigate: (route) => _navigateToRoute(context, route),
                      onLogout: _handleLogout,
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      _AdminTopBar(
                        showMenuButton: sizeClass != WindowSizeClass.expanded,
                        showSearchPill: sizeClass != WindowSizeClass.compact,
                        topContext: topContext,
                        authState: authState,
                        onBackTap: () => _handleContextualBack(context, topContext),
                        onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
                        onOpenPalette: () => CommandPaletteDialog.show(context),
                        onLogout: _handleLogout,
                      ),
                      Expanded(child: widget.navigationShell),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: sizeClass == WindowSizeClass.compact
                ? NavigationBar(
                    backgroundColor: AppColors.parchment,
                    indicatorColor: AppColors.metricMint,
                    selectedIndex: widget.navigationShell.currentIndex,
                    onDestinationSelected: (idx) => widget.navigationShell.goBranch(
                      idx,
                      initialLocation: idx == widget.navigationShell.currentIndex,
                    ),
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: _adminBottomTabs
                        .map(
                          (tab) => NavigationDestination(
                            icon: Icon(tab.icon, color: AppColors.textSubtle),
                            selectedIcon: Icon(tab.icon, color: AppColors.brandGreen),
                            label: tab.label,
                          ),
                        )
                        .toList(),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.showMenuButton,
    required this.showSearchPill,
    required this.topContext,
    required this.authState,
    required this.onBackTap,
    required this.onOpenMenu,
    required this.onOpenPalette,
    required this.onLogout,
  });

  final bool showMenuButton;
  final bool showSearchPill;
  final _AdminTopContext topContext;
  final AuthState authState;
  final VoidCallback onBackTap;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenPalette;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.parchment,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.cardBorder),
            ),
          ),
          child: Row(
            children: [
              if (topContext.showBack)
                IconButton(
                  key: const ValueKey('admin-shell-back-btn'),
                  onPressed: onBackTap,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.brandGreen,
                  ),
                  tooltip: 'Kembali',
                )
              else if (showMenuButton)
                IconButton(
                  onPressed: onOpenMenu,
                  icon: const Icon(Icons.menu_rounded, color: AppColors.brandGreen),
                  tooltip: 'Menu Operasional Admin',
                ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topContext.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMd(color: AppColors.brandGreen),
                    ),
                    Text(
                      'Admin: ${authState.displayName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSm(color: AppColors.textSubtle),
                    ),
                  ],
                ),
              ),
              if (showSearchPill)
                InkWell(
                  onTap: onOpenPalette,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          size: 16,
                          color: AppColors.brandGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Pintasan Cepat (Ctrl+K)',
                          style: AppTypography.labelMd(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: onOpenPalette,
                  icon: const Icon(Icons.search_rounded, color: AppColors.brandGreen),
                  tooltip: 'Pintasan Cepat',
                ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                tooltip: 'Keluar Admin',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminSidebarPanel extends StatelessWidget {
  const _AdminSidebarPanel({
    required this.currentLocation,
    required this.isDrawer,
    required this.onNavigate,
    required this.onLogout,
  });

  final String currentLocation;
  final bool isDrawer;
  final ValueChanged<String> onNavigate;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      color: AppColors.brandGreenDark,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Image.asset(
                      AppConstants.heritageLogoAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.temple_buddhist_rounded,
                        color: AppColors.gold,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SRIWEDARI ADMIN',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelMd(color: AppColors.goldLight),
                        ),
                        Text(
                          'Panel Kurator Keraton',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSm(
                            color: AppColors.canvas.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: _adminSidebarGroups
                    .map(
                      (group) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 10, bottom: 6),
                              child: Text(
                                group.title,
                                style: AppTypography.labelSm(
                                  color: AppColors.gold.withValues(alpha: 0.84),
                                ).copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            ...group.items.map((item) {
                              final active = currentLocation == item.route ||
                                  (item.route != AppRoutes.adminDashboard &&
                                      currentLocation.startsWith(item.route));
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Material(
                                  color: active ? AppColors.gold : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  child: InkWell(
                                    onTap: () => onNavigate(item.route),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 9,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            item.icon,
                                            size: 18,
                                            color: active
                                                ? AppColors.brandGreenDark
                                                : AppColors.canvas.withValues(alpha: 0.84),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              item.label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.labelMd(
                                                color: active
                                                    ? AppColors.brandGreenDark
                                                    : AppColors.canvas.withValues(alpha: 0.9),
                                              ),
                                            ),
                                          ),
                                          if (item.badge != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: active
                                                    ? AppColors.brandGreenDark
                                                    : AppColors.gold.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                item.badge!,
                                                style: AppTypography.labelSm(
                                                  color: active ? AppColors.gold : AppColors.goldLight,
                                                ).copyWith(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.deepForest,
                border: Border(
                  top: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: onLogout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFCA5A5),
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.45),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Keluar Sesi'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isDrawer) {
      return Drawer(
        width: 292,
        backgroundColor: AppColors.brandGreenDark,
        child: content,
      );
    }
    return content;
  }
}

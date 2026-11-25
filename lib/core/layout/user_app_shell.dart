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

class _UserNavItem {
  const _UserNavItem({
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

class _UserTopContext {
  const _UserTopContext({
    required this.title,
    required this.subtitle,
    this.fallbackBackRoute,
  });

  final String title;
  final String subtitle;
  final String? fallbackBackRoute;

  bool get showBack => fallbackBackRoute != null;
}

const List<_UserNavItem> _userPrimaryTabs = [
  _UserNavItem(label: 'Beranda', route: AppRoutes.userDashboard, icon: Icons.home_rounded),
  _UserNavItem(label: 'Galeri', route: AppRoutes.userGallery, icon: Icons.photo_library_rounded),
  _UserNavItem(label: 'Kostum', route: AppRoutes.userCostumes, icon: Icons.checkroom_rounded),
  _UserNavItem(label: 'Jadwal', route: AppRoutes.userSchedule, icon: Icons.calendar_month_rounded),
  _UserNavItem(label: 'Profil', route: AppRoutes.userProfile, icon: Icons.person_rounded),
];

const List<_UserNavItem> _userDrawerMain = [
  _UserNavItem(label: 'Beranda Utama', route: AppRoutes.userDashboard, icon: Icons.home_outlined),
  _UserNavItem(label: 'Koleksi Galeri Seni', route: AppRoutes.userGallery, icon: Icons.photo_library_outlined),
  _UserNavItem(label: 'Sewa Busana Keraton', route: AppRoutes.userCostumes, icon: Icons.checkroom_outlined, badge: 'Populer'),
  _UserNavItem(label: 'Formulir Sewa Busana', route: AppRoutes.userBooking, icon: Icons.shopping_bag_outlined),
  _UserNavItem(label: 'Jadwal Pagelaran Wayang', route: AppRoutes.userSchedule, icon: Icons.theater_comedy_outlined),
  _UserNavItem(label: 'Pentas Hari Ini', route: AppRoutes.userScheduleToday, icon: Icons.today_outlined, badge: 'Live'),
  _UserNavItem(label: 'Pesanan & E-Tiket Saya', route: AppRoutes.userProfile, icon: Icons.receipt_long_outlined),
];

const List<_UserNavItem> _userDrawerHeritage = [
  _UserNavItem(label: 'Tentang Sriwedari', route: AppRoutes.about, icon: Icons.info_outline),
  _UserNavItem(label: 'Kronik Sejarah 1899', route: AppRoutes.aboutHistory, icon: Icons.history_edu_outlined),
  _UserNavItem(label: 'Dewan Kurator & Maestro', route: AppRoutes.aboutCurators, icon: Icons.groups_outlined),
  _UserNavItem(label: 'Warta & Artikel Budaya', route: AppRoutes.blog, icon: Icons.menu_book_outlined),
];

class UserAppShell extends ConsumerStatefulWidget {
  const UserAppShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<UserAppShell> createState() => _UserAppShellState();
}

class _UserAppShellState extends ConsumerState<UserAppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static _UserTopContext _resolveTopContext(String currentLocation) {
    if (currentLocation == AppRoutes.aboutHistory) {
      return const _UserTopContext(
        title: 'Sejarah 1899',
        subtitle: 'KRONIK TAMAN SRIWEDARI',
        fallbackBackRoute: AppRoutes.about,
      );
    }
    if (currentLocation == AppRoutes.aboutCurators) {
      return const _UserTopContext(
        title: 'Dewan Kurator',
        subtitle: 'EMPU & MAESTRO SENI',
        fallbackBackRoute: AppRoutes.about,
      );
    }
    if (currentLocation == AppRoutes.about) {
      return const _UserTopContext(
        title: 'Tentang Sriwedari',
        subtitle: 'WARISAN KERATON SURAKARTA',
        fallbackBackRoute: AppRoutes.userDashboard,
      );
    }
    if (currentLocation.startsWith('${AppRoutes.blog}/')) {
      return const _UserTopContext(
        title: 'Artikel Budaya',
        subtitle: 'WARTA SRIWEDARI',
        fallbackBackRoute: AppRoutes.blog,
      );
    }
    if (currentLocation == AppRoutes.blog) {
      return const _UserTopContext(
        title: 'Warta Budaya',
        subtitle: 'ARTIKEL & TELAAH TARI',
        fallbackBackRoute: AppRoutes.userDashboard,
      );
    }
    if (currentLocation == AppRoutes.userScheduleToday) {
      return const _UserTopContext(
        title: 'Pentas Hari Ini',
        subtitle: 'JADWAL PAGELARAN',
        fallbackBackRoute: AppRoutes.userSchedule,
      );
    }
    if (currentLocation == AppRoutes.userScheduleDaily) {
      return const _UserTopContext(
        title: 'Jadwal Harian',
        subtitle: 'JADWAL PAGELARAN',
        fallbackBackRoute: AppRoutes.userSchedule,
      );
    }
    return const _UserTopContext(
      title: 'Galeri Sriwedari',
      subtitle: 'PUSAKA SENI KERATON',
    );
  }

  void _handleContextualBack(BuildContext context, _UserTopContext topContext) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final fallback = topContext.fallbackBackRoute;
    if (fallback != null) {
      context.go(fallback);
    }
  }

  void _navigateFromSidebar(BuildContext context, String route) {
    if (route == AppRoutes.userBooking) {
      context.push(route);
      return;
    }
    context.go(route);
  }

  Future<void> _handleLogout() async {
    final confirmed = await SwConfirmDialog.showLogoutModal(
      context,
      subtitle: 'Sesi pengguna akan ditutup dan Anda kembali ke halaman login.',
    );
    if (!confirmed || !mounted) return;
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go(AppRoutes.login);
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
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.canvas,
        drawer: sizeClass == WindowSizeClass.expanded
            ? null
            : _UserSidebarPanel(
                currentLocation: currentLocation,
                authState: authState,
                isDrawer: true,
                onNavigate: (route) {
                  Navigator.of(context).pop();
                  _navigateFromSidebar(context, route);
                },
                onLogout: () {
                  Navigator.of(context).pop();
                  _handleLogout();
                },
              ),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: _UserTopNavbar(
            showMenuButton: sizeClass != WindowSizeClass.expanded,
            topContext: topContext,
            authState: authState,
            onBackTap: () => _handleContextualBack(context, topContext),
            onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
            onAvatarTap: () {
              if (authState.isAuthenticated) {
                context.go(AppRoutes.userProfile);
              } else {
                context.go(AppRoutes.login);
              }
            },
          ),
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
                destinations: _userPrimaryTabs
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
                child: _UserSidebarPanel(
                  currentLocation: currentLocation,
                  authState: authState,
                  isDrawer: false,
                  onNavigate: (route) => _navigateFromSidebar(context, route),
                  onLogout: _handleLogout,
                ),
              ),
            Expanded(child: widget.navigationShell),
          ],
        ),
        bottomNavigationBar: sizeClass == WindowSizeClass.compact
            ? NavigationBarTheme(
                data: NavigationBarThemeData(
                  backgroundColor: AppColors.brandGreenDark,
                  indicatorColor: AppColors.gold.withValues(alpha: 0.2),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return AppTypography.labelSm(
                      color: selected
                          ? AppColors.goldLight
                          : AppColors.canvas.withValues(alpha: 0.78),
                    ).copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 11,
                    );
                  }),
                ),
                child: NavigationBar(
                  backgroundColor: AppColors.brandGreenDark,
                  selectedIndex: widget.navigationShell.currentIndex,
                  onDestinationSelected: (idx) => widget.navigationShell.goBranch(
                    idx,
                    initialLocation: idx == widget.navigationShell.currentIndex,
                  ),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: _userPrimaryTabs
                      .map(
                        (tab) => NavigationDestination(
                          icon: Icon(
                            tab.icon,
                            color: AppColors.canvas.withValues(alpha: 0.78),
                          ),
                          selectedIcon: Icon(tab.icon, color: AppColors.gold),
                          label: tab.label,
                        ),
                      )
                      .toList(),
                ),
              )
            : null,
      ),
    );
  }
}

class _UserTopNavbar extends StatelessWidget {
  const _UserTopNavbar({
    required this.showMenuButton,
    required this.topContext,
    required this.authState,
    required this.onBackTap,
    required this.onOpenMenu,
    required this.onAvatarTap,
  });

  final bool showMenuButton;
  final _UserTopContext topContext;
  final AuthState authState;
  final VoidCallback onBackTap;
  final VoidCallback onOpenMenu;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final initial = authState.displayName.isNotEmpty
        ? authState.displayName[0].toUpperCase()
        : 'T';

    return Material(
      color: AppColors.brandGreenDark,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.gold.withValues(alpha: 0.2)),
            ),
          ),
          child: Row(
            children: [
              if (topContext.showBack) ...[
                IconButton(
                  key: const ValueKey('user-shell-back-btn'),
                  onPressed: onBackTap,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.goldLight,
                  ),
                  tooltip: 'Kembali',
                ),
              ] else if (showMenuButton)
                IconButton(
                  onPressed: onOpenMenu,
                  icon: const Icon(Icons.menu_rounded, color: AppColors.gold),
                  tooltip: 'Buka menu navigasi',
                ),
              if (!topContext.showBack) ...[
                Container(
                  width: 32,
                  height: 32,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen,
                    borderRadius: BorderRadius.circular(8),
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
              ],
              Expanded(
                child: InkWell(
                  onTap: topContext.showBack
                      ? onBackTap
                      : () => context.go(AppRoutes.userDashboard),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topContext.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMd(color: AppColors.goldLight),
                      ),
                      Text(
                        topContext.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSm(
                          color: AppColors.canvas.withValues(alpha: 0.78),
                        ).copyWith(fontSize: 9, letterSpacing: 1.0),
                      ),
                    ],
                  ),
                ),
              ),
              if (authState.isAdmin)
                IconButton(
                  onPressed: () => context.go(AppRoutes.adminDashboard),
                  icon: const Icon(
                    Icons.shield_outlined,
                    color: AppColors.gold,
                  ),
                  tooltip: 'Buka Panel Kurator',
                ),
              InkWell(
                onTap: onAvatarTap,
                borderRadius: BorderRadius.circular(999),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.gold,
                  child: authState.isAuthenticated
                      ? Text(
                          initial,
                          style: AppTypography.labelMd(
                            color: AppColors.brandGreenDark,
                          ),
                        )
                      : const Icon(
                          Icons.person_outline_rounded,
                          size: 18,
                          color: AppColors.brandGreenDark,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserSidebarPanel extends StatelessWidget {
  const _UserSidebarPanel({
    required this.currentLocation,
    required this.authState,
    required this.isDrawer,
    required this.onNavigate,
    required this.onLogout,
  });

  final String currentLocation;
  final AuthState authState;
  final bool isDrawer;
  final ValueChanged<String> onNavigate;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      color: AppColors.deepForest,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.brandGreenDark,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.gold,
                    child: Text(
                      authState.displayName.isNotEmpty
                          ? authState.displayName[0].toUpperCase()
                          : 'T',
                      style: AppTypography.titleMd(
                        color: AppColors.brandGreenDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelMd(color: Colors.white),
                        ),
                        Text(
                          authState.displayEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSm(color: AppColors.goldLight),
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
                children: [
                  const _SidebarSectionTitle('MENU UTAMA'),
                  ..._userDrawerMain.map(
                    (item) => _SidebarNavTile(
                      item: item,
                      active: currentLocation == item.route,
                      onTap: () => onNavigate(item.route),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _SidebarSectionTitle('EKSPLORASI BUDAYA'),
                  ..._userDrawerHeritage.map(
                    (item) => _SidebarNavTile(
                      item: item,
                      active: currentLocation == item.route,
                      onTap: () => onNavigate(item.route),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (authState.isAuthenticated)
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
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () => onNavigate(AppRoutes.login),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.brandGreenDark,
                      ),
                      icon: const Icon(Icons.login_rounded, size: 16),
                      label: const Text('Masuk Akun'),
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
        backgroundColor: AppColors.deepForest,
        child: content,
      );
    }
    return content;
  }
}

class _SidebarSectionTitle extends StatelessWidget {
  const _SidebarSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 6, top: 4),
      child: Text(
        title,
        style: AppTypography.labelSm(color: AppColors.gold.withValues(alpha: 0.84))
            .copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.0),
      ),
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  const _SidebarNavTile({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _UserNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: active ? AppColors.gold : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.brandGreenDark
                          : AppColors.gold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.badge!,
                      style: AppTypography.labelSm(
                        color: active ? AppColors.gold : AppColors.goldLight,
                      ).copyWith(fontSize: 9, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

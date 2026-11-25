import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../features/about_blog/presentation/screens/about_curators_screen.dart';
import '../../features/about_blog/presentation/screens/about_history_screen.dart';
import '../../features/about_blog/presentation/screens/about_screen.dart';
import '../../features/about_blog/presentation/screens/blog_detail_screen.dart';
import '../../features/about_blog/presentation/screens/blog_list_screen.dart';
import '../../features/admin/presentation/screens/admin_audit_screen.dart';
import '../../features/admin/presentation/screens/admin_categories_screen.dart';
import '../../features/admin/presentation/screens/admin_costumes_screen.dart';
import '../../features/admin/presentation/screens/admin_coupons_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_docs_screen.dart';
import '../../features/admin/presentation/screens/admin_events_screen.dart';
import '../../features/admin/presentation/screens/admin_gallery_screen.dart';
import '../../features/admin/presentation/screens/admin_orders_screen.dart';
import '../../features/admin/presentation/screens/admin_pos_screen.dart';
import '../../features/admin/presentation/screens/admin_reviews_screen.dart';
import '../../features/admin/presentation/screens/admin_settings_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/admin_visitors_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/admin_login_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/user/presentation/screens/booking_form_screen.dart';
import '../../features/user/presentation/screens/booking_success_screen.dart';
import '../../features/user/presentation/screens/costume_catalog_screen.dart';
import '../../features/user/presentation/screens/costume_detail_screen.dart';
import '../../features/user/presentation/screens/gallery_detail_screen.dart';
import '../../features/user/presentation/screens/gallery_list_screen.dart';
import '../../features/user/presentation/screens/profile_screen.dart';
import '../../features/user/presentation/screens/schedule_screen.dart';
import '../../features/user/presentation/screens/user_dashboard_screen.dart';
import '../layout/admin_app_shell.dart';
import '../layout/user_app_shell.dart';
import '../theme/app_colors.dart';
import 'app_routes.dart';
import 'sw_page_transitions.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(authRouterRefreshProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.login,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final location = state.uri.path;

      final isAuthPage = location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.forgotPassword;
      final isAdminLoginPage = location == AppRoutes.adminLogin;
      final isAdminRoute =
          location.startsWith('/admin') && !isAdminLoginPage;

      if (location == AppRoutes.root) {
        if (authState.isAdmin) return AppRoutes.adminDashboard;
        if (authState.isUser) return AppRoutes.userDashboard;
        return AppRoutes.login;
      }

      // Role Guard Ketat: Admin routes hanya untuk role admin
      if (isAdminRoute) {
        if (!authState.isAuthenticated) {
          return '${AppRoutes.adminLogin}?redirect=${Uri.encodeComponent(location)}';
        }
        if (!authState.isAdmin) {
          return AppRoutes.userDashboard;
        }
      }

      // Route transaksi & profil User butuh sesi autentikasi
      if (AppRoutes.isAuthRequiredForUser(location) &&
          !authState.isAuthenticated) {
        return '${AppRoutes.login}?redirect=${Uri.encodeComponent(location)}';
      }

      // Jika sudah login sebagai Admin, arahkan keluar dari halaman login
      if (authState.isAdmin && (isAuthPage || isAdminLoginPage)) {
        return AppRoutes.adminDashboard;
      }

      // Jika sudah login sebagai User, arahkan keluar dari halaman login user
      if (authState.isUser && isAuthPage) {
        return AppRoutes.userDashboard;
      }

      return null;
    },
    routes: [
      // ==========================================
      // AUTH ROUTES
      // ==========================================
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginScreen(
          redirectTo: state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(
        path: AppRoutes.adminLogin,
        pageBuilder: (context, state) => SwPageTransitions.slideHorizontal(
          key: state.pageKey,
          child: AdminLoginScreen(
            redirectTo: state.uri.queryParameters['redirect'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => SwPageTransitions.slideHorizontal(
          key: state.pageKey,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) => SwPageTransitions.slideHorizontal(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
        ),
      ),

      // ==========================================
      // STANDALONE TRANSACTION FLOWS (ROOT NAVIGATOR)
      // ==========================================
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.userBooking,
        pageBuilder: (context, state) {
          final qp = state.uri.queryParameters;
          final parsedDays = int.tryParse(qp['days'] ?? '');
          return SwPageTransitions.slideHorizontal(
            key: state.pageKey,
            child: Material(
              color: AppColors.canvas,
              child: BookingFormScreen(
                initialCostumeId: qp['costumeId'],
                initialDays: parsedDays,
                initialSize: qp['size'],
              ),
            ),
          );
        },
        routes: [
          GoRoute(
            parentNavigatorKey: rootNavigatorKey,
            path: 'sukses/:id',
            pageBuilder: (context, state) => SwPageTransitions.slideUpFade(
              key: state.pageKey,
              child: Material(
                color: AppColors.canvas,
                child: BookingSuccessScreen(
                  orderId: state.pathParameters['id'] ?? '',
                ),
              ),
            ),
          ),
        ],
      ),

      // ==========================================
      // USER & PUBLIC ADAPTIVE SHELL
      // ==========================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return UserAppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.userDashboard,
                builder: (context, state) => const UserDashboardScreen(),
              ),
              GoRoute(
                path: AppRoutes.about,
                pageBuilder: (context, state) =>
                    SwPageTransitions.slideHorizontal(
                  key: state.pageKey,
                  child: const AboutScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutes.aboutHistory,
                pageBuilder: (context, state) =>
                    SwPageTransitions.slideHorizontal(
                  key: state.pageKey,
                  child: const AboutHistoryScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutes.aboutCurators,
                pageBuilder: (context, state) =>
                    SwPageTransitions.slideHorizontal(
                  key: state.pageKey,
                  child: const AboutCuratorsScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutes.blog,
                pageBuilder: (context, state) =>
                    SwPageTransitions.slideHorizontal(
                  key: state.pageKey,
                  child: const BlogListScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutes.blogDetail,
                pageBuilder: (context, state) =>
                    SwPageTransitions.slideHorizontal(
                  key: state.pageKey,
                  child: BlogDetailScreen(
                    slug: state.pathParameters['slug'] ?? '',
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.userGallery,
                builder: (context, state) => GalleryListScreen(
                  initialQuery: state.uri.queryParameters['q'],
                ),
                routes: [
                  GoRoute(
                    parentNavigatorKey: rootNavigatorKey,
                    path: ':id',
                    pageBuilder: (context, state) =>
                        SwPageTransitions.slideHorizontal(
                      key: state.pageKey,
                      child: GalleryDetailScreen(
                        galleryId: state.pathParameters['id'] ?? '',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.userCostumes,
                builder: (context, state) => const CostumeCatalogScreen(),
                routes: [
                  GoRoute(
                    parentNavigatorKey: rootNavigatorKey,
                    path: ':id',
                    pageBuilder: (context, state) =>
                        SwPageTransitions.slideHorizontal(
                      key: state.pageKey,
                      child: CostumeDetailScreen(
                        costumeId: state.pathParameters['id'] ?? '',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.userSchedule,
                builder: (context, state) => const ScheduleScreen(
                  viewMode: ScheduleViewMode.all,
                ),
                routes: [
                  GoRoute(
                    path: 'harian',
                    pageBuilder: (context, state) =>
                        SwPageTransitions.slideHorizontal(
                      key: state.pageKey,
                      child: const ScheduleScreen(
                        viewMode: ScheduleViewMode.daily,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'hari-ini',
                    pageBuilder: (context, state) =>
                        SwPageTransitions.slideHorizontal(
                      key: state.pageKey,
                      child: const ScheduleScreen(
                        viewMode: ScheduleViewMode.today,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.userProfile,
                builder: (context, state) => ProfileScreen(
                  initialTab: state.uri.queryParameters['tab'],
                ),
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // ADMIN / CURATOR ADAPTIVE SHELL
      // ==========================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminAppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminDashboard,
                builder: (context, state) => const AdminDashboardScreen(),
              ),
              GoRoute(
                path: AppRoutes.adminPos,
                pageBuilder: (context, state) =>
                    SwPageTransitions.slideHorizontal(
                  key: state.pageKey,
                  child: const AdminPosScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutes.adminVisitors,
                pageBuilder: (context, state) =>
                    SwPageTransitions.slideHorizontal(
                  key: state.pageKey,
                  child: const AdminVisitorsScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutes.adminEvents,
                pageBuilder: (context, state) =>
                    SwPageTransitions.slideHorizontal(
                  key: state.pageKey,
                  child: const AdminEventsScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutes.adminCoupons,
                pageBuilder: (context, state) =>
                    SwPageTransitions.slideHorizontal(
                  key: state.pageKey,
                  child: const AdminCouponsScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutes.adminReviews,
                pageBuilder: (context, state) =>
                    SwPageTransitions.slideHorizontal(
                  key: state.pageKey,
                  child: const AdminReviewsScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutes.adminAudit,
                pageBuilder: (context, state) =>
                    SwPageTransitions.slideHorizontal(
                  key: state.pageKey,
                  child: const AdminAuditScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutes.adminDocs,
                pageBuilder: (context, state) =>
                    SwPageTransitions.slideHorizontal(
                  key: state.pageKey,
                  child: const AdminDocsScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminGallery,
                builder: (context, state) => const AdminGalleryScreen(),
                routes: [
                  GoRoute(
                    path: 'baru',
                    pageBuilder: (context, state) =>
                        SwPageTransitions.slideHorizontal(
                      key: state.pageKey,
                      child: const AdminGalleryScreen(
                        openCreateOnLoad: true,
                      ),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: AppRoutes.adminCategories,
                pageBuilder: (context, state) =>
                    SwPageTransitions.slideHorizontal(
                  key: state.pageKey,
                  child: const AdminCategoriesScreen(),
                ),
              ),
              GoRoute(
                path: AppRoutes.adminCostumes,
                pageBuilder: (context, state) =>
                    SwPageTransitions.slideHorizontal(
                  key: state.pageKey,
                  child: const AdminCostumesScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminOrders,
                builder: (context, state) => const AdminOrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminUsers,
                builder: (context, state) => const AdminUsersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminSettings,
                builder: (context, state) => const AdminSettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

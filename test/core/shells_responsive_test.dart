import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sriwedari_app/app.dart';
import 'package:sriwedari_app/core/network/api_client.dart';
import 'package:sriwedari_app/core/providers/core_providers.dart';
import 'package:sriwedari_app/core/router/app_router.dart';
import 'package:sriwedari_app/core/router/app_routes.dart';
import 'package:sriwedari_app/features/admin/domain/models/admin_account_model.dart';
import 'package:sriwedari_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sriwedari_app/features/user/domain/models/user_account_model.dart';

class _ShellMockAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final payload = options.path.endsWith('/admin/analytics')
        ? {'success': true, 'data': <String, dynamic>{}}
        : {'success': true, 'data': <dynamic>[]};
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _TestUserAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
        status: AuthStatus.authenticatedUser,
        userAccount: UserAccountModel(
          id: 'usr-user-1',
          name: 'Oliv Satoro',
          email: 'oliv@example.com',
          phone: '081234567890',
        ),
        isInitialized: true,
      );
}

class _TestAdminAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
        status: AuthStatus.authenticatedAdmin,
        adminAccount: AdminAccountModel(
          id: 'usr-admin-1',
          name: 'Kanjeng Raden Mas Kurator',
          email: 'admin@galerisriwedari.id',
          phone: '081122334455',
        ),
        isInitialized: true,
      );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  ApiClient buildStubClient(ApiScope scope) {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000/api'))
      ..httpClientAdapter = _ShellMockAdapter();
    return ApiClient(
      baseUrl: 'http://localhost:5000',
      scope: scope,
      readToken: () async => 'test-token',
      dioOverride: dio,
    );
  }

  group('Responsivitas UserAppShell & AdminAppShell', () {
    testWidgets('UserAppShell adaptif di Mobile (390x844), Tablet (768x1024), dan Desktop (1280x800)', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final userClient = buildStubClient(ApiScope.user);

      // Mobile
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(_TestUserAuthNotifier.new),
            userApiClientProvider.overrideWithValue(userClient),
          ],
          child: const SriwedariApp(autoRestoreSession: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      // Tablet
      tester.view.physicalSize = const Size(768, 1024);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      // Desktop
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('MENU UTAMA'), findsOneWidget);
      expect(find.text('EKSPLORASI BUDAYA'), findsOneWidget);
    });

    testWidgets('AdminAppShell adaptif di Mobile (390x844) dan Desktop (1280x800) + Command Palette', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final adminClient = buildStubClient(ApiScope.admin);

      // Mobile
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(_TestAdminAuthNotifier.new),
            adminApiClientProvider.overrideWithValue(adminClient),
          ],
          child: const SriwedariApp(autoRestoreSession: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Pengaturan'), findsOneWidget);

      // Desktop + Command Palette
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_TestAdminAuthNotifier.new),
          adminApiClientProvider.overrideWithValue(adminClient),
        ],
      );
      addTearDown(container.dispose);

      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SriwedariApp(autoRestoreSession: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SRIWEDARI ADMIN'), findsOneWidget);
      expect(find.text('Pintasan Cepat (Ctrl+K)'), findsOneWidget);

      await tester.tap(find.text('Pintasan Cepat (Ctrl+K)'));
      await tester.pumpAndSettle();
      expect(find.text('Kasir POS & Gate Scanner'), findsAtLeastNWidgets(1));

      await tester.tap(find.text('Kasir POS & Gate Scanner').last);
      await tester.pumpAndSettle();
      expect(
        container.read(appRouterProvider).routeInformationProvider.value.uri.path,
        AppRoutes.adminPos,
      );

      // Tombol Back kontekstual AdminAppShell mengembalikan ke Dashboard
      final adminBackBtn = find.byKey(const ValueKey('admin-shell-back-btn'));
      expect(adminBackBtn, findsOneWidget);
      await tester.tap(adminBackBtn);
      await tester.pumpAndSettle();
      expect(
        container.read(appRouterProvider).routeInformationProvider.value.uri.path,
        AppRoutes.adminDashboard,
      );
    });

    testWidgets('UserAppShell menampilkan Back button kontekstual pada sub-halaman non-tab dan kembali dengan benar', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final userClient = buildStubClient(ApiScope.user);
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_TestUserAuthNotifier.new),
          userApiClientProvider.overrideWithValue(userClient),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SriwedariApp(autoRestoreSession: false),
        ),
      );
      await tester.pumpAndSettle();

      container.read(appRouterProvider).push(AppRoutes.aboutHistory);
      await tester.pumpAndSettle();

      expect(find.text('Sejarah 1899'), findsWidgets);
      final backBtn = find.byKey(const ValueKey('user-shell-back-btn'));
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(
        container.read(appRouterProvider).routeInformationProvider.value.uri.path,
        AppRoutes.userDashboard,
      );
    });
  });
}

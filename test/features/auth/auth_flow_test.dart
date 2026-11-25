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
import 'package:sriwedari_app/core/storage/admin_local_storage.dart';
import 'package:sriwedari_app/core/storage/storage_backend.dart';
import 'package:sriwedari_app/core/storage/user_local_storage.dart';

class _AuthMockAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    final body = options.data is Map
        ? options.data as Map
        : <String, dynamic>{};

    if (path.endsWith('/user/auth/login')) {
      if (body['email'] == 'oliv@example.com' &&
          body['password'] == 'rahasia123') {
        return _jsonResponse({
          'success': true,
          'token': 'user-token-xyz',
          'user': {
            'id': 'usr-user-1',
            'name': 'Oliv Satoro',
            'email': 'oliv@example.com',
            'phone': '081234567890',
            'role': 'user',
            'status': 'active',
            'points': 420,
            'registeredAt': '2025-06-15',
          },
        });
      }
      return _jsonResponse({
        'success': false,
        'error': 'Kredensial user salah',
      }, status: 401);
    }

    if (path.endsWith('/admin/auth/login')) {
      if (body['email'] == 'admin@galerisriwedari.id' &&
          body['password'] == 'rahasia123') {
        return _jsonResponse({
          'success': true,
          'token': 'admin-token-xyz',
          'user': {
            'id': 'usr-admin-1',
            'name': 'Kanjeng Raden Mas Kurator',
            'email': 'admin@galerisriwedari.id',
            'phone': '081122334455',
            'role': 'admin',
            'status': 'active',
            'points': 1500,
            'registeredAt': '2024-01-01',
          },
        });
      }
      return _jsonResponse({
        'success': false,
        'error': 'Kredensial admin salah',
      }, status: 401);
    }

    if (path.endsWith('/user/auth/register')) {
      return _jsonResponse({
        'success': true,
        'token': 'user-reg-token',
        'user': {
          'id': 'usr-new-1',
          'name': body['name'],
          'email': body['email'],
          'phone': body['phone'],
          'role': 'user',
          'status': 'active',
          'points': 50,
          'registeredAt': '2026-11-16',
        },
      }, status: 201);
    }

    if (path.endsWith('/admin/analytics')) {
      return _jsonResponse({'success': true, 'data': <String, dynamic>{}});
    }

    if (path.endsWith('/user/galleries') ||
        path.endsWith('/user/categories') ||
        path.endsWith('/user/costumes') ||
        path.endsWith('/user/events') ||
        path.endsWith('/user/wishlist')) {
      return _jsonResponse({'success': true, 'data': []});
    }

    return _jsonResponse({'success': true});
  }

  ResponseBody _jsonResponse(Map<String, dynamic> data, {int status = 200}) {
    return ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Autentikasi Multi-Peran & GoRouter Role Guard', () {
    late InMemoryKeyValueStore kv;
    late InMemorySecureStore secure;
    late UserLocalStorage userStorage;
    late AdminLocalStorage adminStorage;
    late ApiClient userApi;
    late ApiClient adminApi;

    setUp(() {
      kv = InMemoryKeyValueStore();
      secure = InMemorySecureStore();
      userStorage = UserLocalStorage(kvStore: kv, secureStore: secure);
      adminStorage = AdminLocalStorage(kvStore: kv, secureStore: secure);

      final userDio = Dio(BaseOptions(baseUrl: 'http://localhost:5000/api'))
        ..httpClientAdapter = _AuthMockAdapter();
      final adminDio = Dio(BaseOptions(baseUrl: 'http://localhost:5000/api'))
        ..httpClientAdapter = _AuthMockAdapter();

      userApi = ApiClient(
        baseUrl: 'http://localhost:5000',
        scope: ApiScope.user,
        readToken: userStorage.getToken,
        dioOverride: userDio,
      );
      adminApi = ApiClient(
        baseUrl: 'http://localhost:5000',
        scope: ApiScope.admin,
        readToken: adminStorage.getToken,
        dioOverride: adminDio,
      );
    });

    Widget createTestApp({ProviderContainer? container}) {
      if (container != null) {
        return UncontrolledProviderScope(
          container: container,
          child: const SriwedariApp(autoRestoreSession: false),
        );
      }
      return ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(kv),
          secureStoreProvider.overrideWithValue(secure),
          userApiClientProvider.overrideWithValue(userApi),
          adminApiClientProvider.overrideWithValue(adminApi),
        ],
        child: const SriwedariApp(autoRestoreSession: false),
      );
    }

    testWidgets(
      'Login User berhasil menyimpan ke UserLocalStorage dan masuk ke Beranda User',
      (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1280, 800);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('GALERI SRIWEDARI'), findsOneWidget);
        await tester.tap(find.text('Demo 1-Klik Pengguna (Dev)'));
        await tester.pumpAndSettle();

        expect(find.text('Selamat datang di Galeri Sriwedari'), findsOneWidget);
        expect(await userStorage.getToken(), 'user-token-xyz');
        expect(await adminStorage.getToken(), isNull);
      },
    );

    testWidgets(
      'Role Guard memblokir User saat mencoba membuka /admin/dashboard',
      (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1280, 800);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer(
          overrides: [
            keyValueStoreProvider.overrideWithValue(kv),
            secureStoreProvider.overrideWithValue(secure),
            userApiClientProvider.overrideWithValue(userApi),
            adminApiClientProvider.overrideWithValue(adminApi),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(createTestApp(container: container));
        await tester.pumpAndSettle();

        // Login sebagai User lewat UI tombol Demo 1-Klik
        await tester.tap(find.text('Demo 1-Klik Pengguna (Dev)'));
        await tester.pumpAndSettle();
        expect(find.text('Selamat datang di Galeri Sriwedari'), findsOneWidget);

        // User mencoba membuka rute admin -> harus ditolak dan dialihkan ke /dashboard
        container.read(appRouterProvider).go(AppRoutes.adminDashboard);
        await tester.pumpAndSettle();

        expect(find.text('Selamat datang di Galeri Sriwedari'), findsOneWidget);
        expect(find.text('Dasbor Operasional Galeri Sriwedari'), findsNothing);
      },
    );

    testWidgets(
      'Login Admin lewat /admin/login masuk ke AdminShell & Logout via Modal',
      (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1280, 800);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer(
          overrides: [
            keyValueStoreProvider.overrideWithValue(kv),
            secureStoreProvider.overrideWithValue(secure),
            userApiClientProvider.overrideWithValue(userApi),
            adminApiClientProvider.overrideWithValue(adminApi),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(createTestApp(container: container));
        await tester.pumpAndSettle();

        // Pengunjung belum login buka /admin/dashboard -> dialihkan ke /admin/login
        container.read(appRouterProvider).go(AppRoutes.adminDashboard);
        await tester.pumpAndSettle();
        expect(find.text('Login sebagai Admin'), findsOneWidget);

        // Login Demo Kurator
        await tester.tap(find.text('Demo 1-Klik Kurator (Dev)'));
        await tester.pumpAndSettle();

        expect(
          find.text('Dasbor Operasional Galeri Sriwedari'),
          findsOneWidget,
        );
        expect(find.text('SRIWEDARI ADMIN'), findsOneWidget);
        expect(await adminStorage.getToken(), 'admin-token-xyz');
        expect(await userStorage.getToken(), isNull);

        // Klik Keluar Sesi -> konfirmasi modal logout
        await tester.tap(find.text('Keluar Sesi'));
        await tester.pumpAndSettle();
        expect(find.text('Keluar dari akun?'), findsOneWidget);

        await tester.tap(find.text('Ya, Keluar'));
        await tester.pumpAndSettle();

        expect(await adminStorage.getToken(), isNull);
        expect(find.text('Login sebagai Admin'), findsOneWidget);
      },
    );

    testWidgets(
      'LoginScreen menyediakan CTA Jelajahi sebagai Tamu tanpa duplikasi Gerbang Admin dan RegisterScreen punya tombol Back',
      (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Gerbang Admin'), findsNothing);
        final guestCta = find.byKey(const ValueKey('login-guest-cta'));
        expect(guestCta, findsOneWidget);

        // Cek tombol Back di RegisterScreen
        final daftarLink = find.text('Daftar di sini');
        await tester.ensureVisible(daftarLink);
        await tester.tap(daftarLink);
        await tester.pumpAndSettle();
        expect(find.text('Daftar Akun Baru'), findsOneWidget);
        expect(find.byKey(const ValueKey('auth-back-btn')), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('auth-back-btn')));
        await tester.pumpAndSettle();

        // Masuk sebagai tamu
        await tester.ensureVisible(guestCta);
        await tester.tap(guestCta);
        await tester.pumpAndSettle();
        expect(find.text('Selamat datang di Galeri Sriwedari'), findsOneWidget);
      },
    );
  });
}

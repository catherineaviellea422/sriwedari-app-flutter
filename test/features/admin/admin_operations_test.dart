import 'dart:convert';
import 'dart:typed_data';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sriwedari_app/app.dart';
import 'package:sriwedari_app/core/network/api_client.dart';
import 'package:sriwedari_app/core/providers/core_providers.dart';
import 'package:sriwedari_app/core/router/app_router.dart';
import 'package:sriwedari_app/core/router/app_routes.dart';
import 'package:sriwedari_app/core/storage/admin_local_storage.dart';
import 'package:sriwedari_app/core/storage/storage_backend.dart';
import 'package:sriwedari_app/features/admin/data/admin_operations_repository.dart';
import 'package:sriwedari_app/features/admin/domain/models/admin_models.dart';
import 'package:sriwedari_app/features/admin/presentation/providers/admin_providers.dart';
import 'package:sriwedari_app/features/auth/presentation/providers/auth_provider.dart';

class _AdminOpsFakeBackendAdapter implements HttpClientAdapter {
  int seq = 1;
  bool resetCalled = false;

  final List<Map<String, dynamic>> events = [
    {
      'id': 'evt-1',
      'title': 'Wayang Orang Lakon Anoman Duta',
      'date': '2026-12-25',
      'time': '19:30 WIB',
      'location': 'Gedung Wayang Orang Sriwedari',
      'price': 35000,
      'quota': 48,
      'booked': 2,
      'image': '/images/tari-jawa-dramatic-stage.png',
      'description': 'Pagelaran Wayang Orang spesial.',
      'zonePrices': {'VIP': 50000, 'REGULER': 35000, 'BALKON': 25000},
    },
  ];

  final List<Map<String, dynamic>> tickets = [
    {
      'id': 'TCK-2026-101',
      'eventId': 'evt-1',
      'eventTitle': 'Wayang Orang Lakon Anoman Duta',
      'userName': 'Bima Pratama',
      'userPhone': '081299988877',
      'quantity': 1,
      'seats': ['A-01'],
      'zone': 'VIP',
      'totalPrice': 50000,
      'status': 'Aktif',
      'bookingCode': 'SWD-101AA',
      'createdAt': '2026-11-18 09:00',
    },
  ];

  final List<Map<String, dynamic>> coupons = [
    {
      'id': 'coup-1',
      'code': 'SRIWEDARI10',
      'type': 'PERCENTAGE',
      'value': 10,
      'minOrder': 150000,
      'maxUses': 100,
      'usedCount': 5,
      'isActive': true,
      'expiresAt': '2026-12-31',
      'description': 'Diskon khusus pelestari budaya.',
    },
  ];

  final List<Map<String, dynamic>> reviews = [
    {
      'id': 'rev-1',
      'targetId': 'gal-1',
      'targetType': 'gallery',
      'userName': 'Dewi Anggraini',
      'rating': 5,
      'comment': 'Koleksi busana sangat terawat dan bersejarah.',
      'createdAt': '2026-11-12',
      'verified': true,
      'status': 'tampil',
    },
  ];

  final List<Map<String, dynamic>> users = [
    {
      'id': 'adm-1',
      'name': 'Kurator Utama',
      'email': 'kurator@sriwedari.id',
      'phone': '081111111111',
      'role': 'admin',
      'status': 'active',
      'points': 500,
      'registeredAt': '2025-01-01',
    },
    {
      'id': 'usr-1',
      'name': 'Siti Rahma',
      'email': 'siti@example.com',
      'phone': '081234567890',
      'role': 'user',
      'status': 'active',
      'points': 120,
      'registeredAt': '2026-02-10',
    },
  ];

  final List<Map<String, dynamic>> auditLogs = [
    {
      'id': 'aud-1',
      'timestamp': '2026-11-18 10:00:00',
      'action': 'VERIFY_PAYMENT',
      'actorName': 'Kurator Utama',
      'actorRole': 'Admin',
      'details': 'Konfirmasi transfer pesanan ORD-201',
      'ipAddress': '127.0.0.1',
      'severity': 'info',
    },
    {
      'id': 'aud-2',
      'timestamp': '2026-11-18 10:15:00',
      'action': 'RESET_DB',
      'actorName': 'Admin',
      'actorRole': 'Admin',
      'details': 'Simulasi peringatan keamanan',
      'ipAddress': '127.0.0.1',
      'severity': 'warning',
    },
  ];

  Map<String, dynamic> settings = {
    'galleryName': 'Galeri Pusaka Seni Sriwedari',
    'tagline': 'Pelestarian Seni Tari & Busana Keraton',
    'openHours': '09:00 - 21:00 WIB',
    'location': 'Jl. Slamet Riyadi No. 275, Surakarta',
    'phone': '0271-712345',
    'email': 'info@sriwedari.id',
    'depositFee': 100000,
    'terms': 'Busana wajib dikembalikan sesuai jadwal.',
    'notifications': true,
    'holdDurationMinutes': 1440,
    'refundWindowDays': 3,
    'lowStockThreshold': 2,
    'whatsappAdminNumber': '6281234567890',
  };

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    final method = options.method.toUpperCase();
    final body = options.data is Map<String, dynamic>
        ? options.data as Map<String, dynamic>
        : <String, dynamic>{};

    if (path == '/admin/events') {
      return _json(200, {'success': true, 'data': events});
    }

    if (path == '/admin/tickets') {
      final eventIdParam = options.queryParameters['eventId']?.toString();
      if (method == 'GET' && eventIdParam != null) {
        final booked = tickets
            .where((t) => t['eventId'] == eventIdParam)
            .expand((t) => List<String>.from(t['seats'] as List))
            .toList();
        return _json(200, {'success': true, 'bookedSeats': booked});
      }
      if (method == 'GET') {
        return _json(200, {'success': true, 'data': tickets});
      }
      if (method == 'POST') {
        seq++;
        final newTicket = {
          'id': 'TCK-2026-${200 + seq}',
          ...body,
          'bookingCode': 'SWD-POS$seq',
          'status': 'Aktif',
          'createdAt': '2026-11-18 11:00',
        };
        tickets.insert(0, newTicket);
        return _json(201, {'success': true, 'ticket': newTicket});
      }
      if (method == 'PATCH') {
        final code = (body['ticketCode'] ?? '').toString().toUpperCase();
        final idx = tickets.indexWhere(
          (t) =>
              t['bookingCode'].toString().toUpperCase() == code ||
              t['id'].toString().toUpperCase() == code,
        );
        if (idx < 0) {
          return _json(400, {
            'success': false,
            'message': 'Tiket tidak ditemukan di sistem loket Sriwedari!',
          });
        }
        if (tickets[idx]['status'] == 'Check-in') {
          return _json(400, {
            'success': false,
            'message':
                'Tiket ${tickets[idx]['bookingCode']} sudah pernah digunakan check-in!',
          });
        }
        tickets[idx] = {...tickets[idx], 'status': 'Check-in'};
        return _json(200, {
          'success': true,
          'message': 'Check-in Berhasil! Silakan masuk pintu pementasan.',
          'ticket': tickets[idx],
        });
      }
    }

    if (path == '/admin/coupons') {
      if (method == 'GET') return _json(200, {'success': true, 'data': coupons});
      if (method == 'POST') {
        seq++;
        final item = {
          ...body,
          'id': (body['id'] ?? '').toString().isEmpty ? 'coup-$seq' : body['id'],
        };
        final idx = coupons.indexWhere((c) => c['id'] == item['id']);
        if (idx >= 0) {
          coupons[idx] = item;
        } else {
          coupons.add(item);
        }
        return _json(201, {'success': true, 'data': item});
      }
      if (method == 'DELETE') {
        final id = options.queryParameters['id']?.toString();
        coupons.removeWhere((c) => c['id'] == id);
        return _json(200, {'success': true});
      }
    }

    if (path == '/admin/reviews') {
      if (method == 'GET') return _json(200, {'success': true, 'data': reviews});
      if (method == 'PATCH') {
        final id = body['id'];
        final idx = reviews.indexWhere((r) => r['id'] == id);
        if (idx >= 0) {
          reviews[idx] = {...reviews[idx], 'status': body['status']};
          return _json(200, {'success': true, 'data': reviews[idx]});
        }
        return _json(404, {'success': false, 'message': 'Ulasan tidak ada'});
      }
      if (method == 'DELETE') {
        final id = options.queryParameters['id']?.toString();
        reviews.removeWhere((r) => r['id'] == id);
        return _json(200, {'success': true});
      }
    }

    if (path == '/admin/users') {
      if (method == 'GET') return _json(200, {'success': true, 'data': users});
      if (method == 'POST') {
        seq++;
        final item = {
          ...body,
          'id': (body['id'] ?? '').toString().isEmpty ? 'usr-$seq' : body['id'],
        };
        item.remove('password');
        final idx = users.indexWhere((u) => u['id'] == item['id']);
        if (idx >= 0) {
          users[idx] = item;
        } else {
          users.add(item);
        }
        return _json(201, {'success': true, 'data': item});
      }
      if (method == 'DELETE') {
        final id = options.queryParameters['id']?.toString();
        users.removeWhere((u) => u['id'] == id);
        return _json(200, {'success': true});
      }
    }

    if (path == '/admin/audit') {
      if (options.queryParameters['format'] == 'csv') {
        return ResponseBody.fromString(
          'ID,Waktu,Aksi,Aktor\naud-1,2026-11-18,VERIFY_PAYMENT,Kurator Utama\n',
          200,
          headers: {
            Headers.contentTypeHeader: ['text/csv; charset=utf-8'],
          },
        );
      }
      return _json(200, {'success': true, 'data': auditLogs});
    }

    if (path == '/admin/settings') {
      if (method == 'GET') return _json(200, {'success': true, 'data': settings});
      if (method == 'POST') {
        settings = {...settings, ...body};
        return _json(200, {'success': true, 'data': settings});
      }
      if (method == 'PUT') {
        resetCalled = true;
        return _json(200, {
          'success': true,
          'message': 'Database User & Admin berhasil direset ke state bawaan.',
        });
      }
    }

    return _json(404, {'success': false, 'message': 'Route tidak ditemukan'});
  }

  ResponseBody _json(int status, Map<String, dynamic> data) {
    return ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _LoggedInAdminNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
        status: AuthStatus.authenticatedAdmin,
        adminAccount: AdminAccountModel(
          id: 'adm-1',
          name: 'Kurator Utama',
          email: 'kurator@sriwedari.id',
          phone: '081111111111',
        ),
        isInitialized: true,
      );
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AdminOperationsRepository Unit Tests', () {
    late InMemoryKeyValueStore kv;
    late InMemorySecureStore secure;
    late AdminLocalStorage storage;
    late _AdminOpsFakeBackendAdapter adapter;
    late AdminOperationsRepository repo;

    setUp(() async {
      kv = InMemoryKeyValueStore();
      secure = InMemorySecureStore();
      storage = AdminLocalStorage(kvStore: kv, secureStore: secure);
      await storage.saveToken('admin-jwt');

      adapter = _AdminOpsFakeBackendAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3001/api'))
        ..httpClientAdapter = adapter;
      final client = ApiClient(
        baseUrl: 'http://localhost:3001',
        scope: ApiScope.admin,
        readToken: storage.getToken,
        dioOverride: dio,
      );
      repo = AdminOperationsRepository(
        adminApiClient: client,
        adminStorage: storage,
      );
    });

    test('issues POS ticket, validates gate check-in & stores scan history in AdminLocalStorage', () async {
      final issued = await repo.issuePosTicket(
        eventId: 'evt-1',
        eventTitle: 'Wayang Orang Lakon Anoman Duta',
        userName: 'Tamu Walk-in',
        userPhone: '081234567890',
        seats: const ['C-01'],
        zone: 'REGULER',
        totalPrice: 35000,
      );
      expect(issued.bookingCode, 'SWD-POS2');

      final firstCheck = await repo.validateGateTicket(issued.bookingCode);
      expect(firstCheck.success, isTrue);
      expect(firstCheck.ticket?.status, 'Check-in');

      final duplicateCheck = await repo.validateGateTicket(issued.bookingCode);
      expect(duplicateCheck.success, isFalse);

      final history = await repo.getLocalScanHistory();
      expect(history.length, 2);
      expect(history.first['success'], isFalse);
    });

    test('manages coupons, review moderation, users, audit CSV & settings/reset', () async {
      final savedCoup = await repo.saveCoupon(
        const AdminCouponModel(
          id: '',
          code: 'BATIK20',
          type: 'PERCENTAGE',
          value: 20,
          minOrder: 100000,
          maxUses: 50,
          usedCount: 0,
          isActive: true,
          expiresAt: '2026-12-31',
        ),
      );
      expect(savedCoup.code, 'BATIK20');
      await repo.deleteCoupon(savedCoup.id);

      final hiddenRev = await repo.updateReviewStatus(
        id: 'rev-1',
        status: 'disembunyikan',
      );
      expect(hiddenRev.status, 'disembunyikan');

      final savedUser = await repo.saveUser(
        const AdminAccountModel(
          id: '',
          name: 'Kurator Baru',
          email: 'baru@sriwedari.id',
          phone: '081999888777',
          role: 'admin',
        ),
        password: 'password123',
      );
      expect(savedUser.id, isNotEmpty);
      await repo.deleteUser(savedUser.id);

      final csv = await repo.exportAuditCsvRaw();
      expect(csv, contains('VERIFY_PAYMENT'));

      final currentSettings = await repo.fetchSettings();
      final updatedSettings = await repo.saveSettings(
        SystemSettingsModel.fromJson({
          ...currentSettings.toJson(),
          'depositFee': 125000,
        }),
      );
      expect(updatedSettings.depositFee, 125000);

      final resetMsg = await repo.resetDatabase();
      expect(resetMsg, contains('direset'));
      expect(adapter.resetCalled, isTrue);
    });
  });

  group('Fase 6 Admin Operations Widget Tests (390x844 & 1280x800)', () {
    String? lastSavedCsv;

    Future<ProviderContainer> pumpAdminApp(
      WidgetTester tester, {
      required Size viewport,
      required _AdminOpsFakeBackendAdapter adapter,
      required String initialRoute,
    }) async {
      lastSavedCsv = null;
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = viewport;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final kv = InMemoryKeyValueStore();
      final secure = InMemorySecureStore();
      final storage = AdminLocalStorage(kvStore: kv, secureStore: secure);
      await storage.saveToken('admin-jwt');

      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3001/api'))
        ..httpClientAdapter = adapter;
      final client = ApiClient(
        baseUrl: 'http://localhost:3001',
        scope: ApiScope.admin,
        readToken: storage.getToken,
        dioOverride: dio,
      );

      final container = ProviderContainer(
        overrides: [
          keyValueStoreProvider.overrideWithValue(kv),
          secureStoreProvider.overrideWithValue(secure),
          adminApiClientProvider.overrideWithValue(client),
          authProvider.overrideWith(_LoggedInAdminNotifier.new),
          csvFileSaverProvider.overrideWithValue((name, bytes) async {
            lastSavedCsv = utf8.decode(bytes);
          }),
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

      container.read(appRouterProvider).go(initialRoute);
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets(
      'AdminPosScreen issues walk-in ticket with QR/Barcode and validates Gate Check-In on Desktop (1280x800)',
      (tester) async {
        final adapter = _AdminOpsFakeBackendAdapter();
        await pumpAdminApp(
          tester,
          viewport: const Size(1280, 800),
          adapter: adapter,
          initialRoute: AppRoutes.adminPos,
        );

        expect(find.text('Kasir Loket (POS) & Gate Scanner'), findsOneWidget);

        // Pilih kursi C-02 & isi nama pembeli
        await tester.tap(find.text('C-02'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Masukkan nama pembeli di loket'),
          'Raden Mas Panji',
        );

        final issueBtn = find.text('Terbitkan Tiket Walk-In');
        await tester.ensureVisible(issueBtn);
        await tester.tap(issueBtn);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Tiket Walk-In Diterbitkan: SWD-POS2'),
          findsOneWidget,
        );
        expect(find.byType(QrImageView), findsOneWidget);
        expect(find.byType(BarcodeWidget), findsOneWidget);

        // Pindah ke Gate QR Check-In
        final gateTab = find.text('Gate QR Check-In');
        await tester.ensureVisible(gateTab);
        await tester.tap(gateTab);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'SWD-12345'),
          'SWD-POS2',
        );
        await tester.tap(find.text('Validasi'));
        await tester.pumpAndSettle();

        expect(
          find.text('Check-in Berhasil! Silakan masuk pintu pementasan.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AdminVisitorsScreen, AdminCouponsScreen, AdminReviewsScreen & AdminUsersScreen render cleanly on Mobile (390x844)',
      (tester) async {
        final adapter = _AdminOpsFakeBackendAdapter();
        final container = await pumpAdminApp(
          tester,
          viewport: const Size(390, 844),
          adapter: adapter,
          initialRoute: AppRoutes.adminVisitors,
        );

        expect(find.text('Rekap & Presensi Kunjungan'), findsOneWidget);
        expect(find.textContaining('SWD-101AA'), findsOneWidget);

        container.read(appRouterProvider).go(AppRoutes.adminCoupons);
        await tester.pumpAndSettle();
        expect(find.text('Manajemen Kupon Diskon'), findsOneWidget);
        expect(find.text('SRIWEDARI10'), findsOneWidget);

        container.read(appRouterProvider).go(AppRoutes.adminReviews);
        await tester.pumpAndSettle();
        expect(find.text('Moderasi Ulasan Budaya'), findsOneWidget);
        await tester.tap(find.text('Sembunyikan'));
        await tester.pumpAndSettle();
        expect(find.text('Tampilkan Kembali'), findsOneWidget);

        container.read(appRouterProvider).go(AppRoutes.adminUsers);
        await tester.pumpAndSettle();
        expect(find.text('Kelola Pengguna & Kurator'), findsOneWidget);
        expect(find.text('Siti Rahma'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AdminAuditScreen (CSV), AdminSettingsScreen (Reset DB), and AdminDocsScreen work on Mobile (390x844)',
      (tester) async {
        final adapter = _AdminOpsFakeBackendAdapter();
        final container = await pumpAdminApp(
          tester,
          viewport: const Size(390, 844),
          adapter: adapter,
          initialRoute: AppRoutes.adminAudit,
        );

        expect(find.text('Audit Trail Keamanan'), findsOneWidget);
        expect(find.text('VERIFY_PAYMENT'), findsOneWidget);
        await tester.tap(find.text('Ekspor CSV'));
        await tester.pumpAndSettle();
        expect(lastSavedCsv, contains('VERIFY_PAYMENT'));
        expect(
          find.text('Berkas CSV audit trail berhasil diekspor.'),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        container.read(appRouterProvider).go(AppRoutes.adminSettings);
        await tester.pumpAndSettle();
        expect(find.text('Pengaturan Sanggar & Basis Data'), findsOneWidget);

        final resetBtn = find.text('Reset Database ke Kondisi Awal');
        await tester.ensureVisible(resetBtn);
        await tester.tap(resetBtn);
        await tester.pumpAndSettle();

        expect(find.text('Reset Seluruh Basis Data?'), findsOneWidget);
        await tester.tap(find.text('Ya, Reset DB'));
        await tester.pumpAndSettle();
        expect(adapter.resetCalled, isTrue);

        container.read(appRouterProvider).go(AppRoutes.adminDocs);
        await tester.pumpAndSettle();
        expect(find.text('Dokumentasi Alur Operasional'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

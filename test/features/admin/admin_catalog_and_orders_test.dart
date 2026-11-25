import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
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
import 'package:sriwedari_app/features/admin/data/admin_catalog_repository.dart';
import 'package:sriwedari_app/features/admin/domain/models/admin_models.dart';
import 'package:sriwedari_app/features/auth/presentation/providers/auth_provider.dart';

class _AdminFakeBackendAdapter implements HttpClientAdapter {
  bool simulateAnalyticsNetworkError = false;
  int seq = 1;

  final List<Map<String, dynamic>> categories = [
    {
      'id': 'cat-1',
      'name': 'Tari Tradisional',
      'icon': 'theater_comedy',
      'description': 'Pakem tari klasik keraton.',
      'count': 2,
    },
  ];

  final List<Map<String, dynamic>> galleries = [
    {
      'id': 'gal-1',
      'title': 'Tari Bedhaya Ketawang',
      'category': 'tari-tradisional',
      'categoryName': 'Tari Tradisional',
      'type': 'foto',
      'date': '2026-01-10',
      'description': 'Tarian sakral pusaka Surakarta.',
      'image': '/images/tari-bedhaya-ketawang.png',
      'views': 2450,
      'likes': 510,
      'origin': 'Keraton Surakarta',
      'costumeId': 'costume-1',
    },
  ];

  final List<Map<String, dynamic>> costumes = [
    {
      'id': 'costume-1',
      'name': 'Busana Ksatria Topeng Malangan',
      'category': 'Jawa Timuran',
      'price': 250000,
      'rating': 4.9,
      'reviewCount': 18,
      'stock': 3,
      'sizes': ['S', 'M', 'L'],
      'image': '/images/tari-topeng-malangan.png',
      'description': 'Busana tari lengkap dengan jamang.',
      'origin': 'Malang',
    },
  ];

  final List<Map<String, dynamic>> stockMovements = [
    {
      'id': 'sm-1',
      'costumeId': 'costume-1',
      'costumeName': 'Busana Ksatria Topeng Malangan',
      'size': 'M',
      'delta': 3,
      'stockAfter': 3,
      'reason': 'restock',
      'note': 'Stok awal inventaris.',
      'actorName': 'Kurator Utama',
      'createdAt': '2026-11-01 09:00:00',
    },
  ];

  final List<Map<String, dynamic>> events = [
    {
      'id': 'evt-1',
      'title': 'Wayang Orang Lakon Gatotkaca Gandrung',
      'date': '2026-12-20',
      'time': '19:30 WIB',
      'location': 'Gedung Wayang Orang Sriwedari',
      'price': 35000,
      'quota': 48,
      'booked': 12,
      'image': '/images/tari-jawa-dramatic-stage.png',
      'description': 'Pentas malam kolosal.',
      'zonePrices': {'VIP': 50000, 'REGULER': 35000, 'BALKON': 25000},
    },
  ];

  final List<Map<String, dynamic>> orders = [
    {
      'id': 'ORD-301',
      'userId': 'user-1',
      'userName': 'Raden Ayu Sekar',
      'userPhone': '081234567890',
      'userEmail': 'sekar@keraton.id',
      'costumeId': 'costume-1',
      'costumeName': 'Busana Ksatria Topeng Malangan',
      'costumes': [
        {
          'id': 'costume-1',
          'name': 'Busana Ksatria Topeng Malangan',
          'price': 250000,
          'days': 2,
          'size': 'M',
        },
      ],
      'startDate': '2026-12-05',
      'duration': 2,
      'totalPrice': 600000,
      'depositFee': 100000,
      'discountAmount': 0,
      'status': 'Menunggu',
      'paymentMethod': 'QRIS',
      'paymentProof': '/uploads/proof-1.png',
      'createdAt': '2026-11-15T10:00:00Z',
    },
  ];

  final List<Map<String, dynamic>> auditLogs = [
    {
      'id': 'log-1',
      'timestamp': '2026-11-17 09:15:00',
      'action': 'VERIFY_PAYMENT',
      'actorName': 'Kurator Utama',
      'actorRole': 'Admin',
      'details': 'Sinkronisasi data inventaris pagi.',
      'ipAddress': '127.0.0.1',
      'severity': 'info',
    },
  ];

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

    if (path == '/admin/analytics' && method == 'GET') {
      if (simulateAnalyticsNetworkError) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'Offline',
        );
      }
      return _json(200, {
        'success': true,
        'data': {
          'totalRevenue': 1850000,
          'revenueRental': 1350000,
          'revenueTickets': 500000,
          'escrowDeposit': 300000,
          'qcDeductions': 25000,
          'paymentChannels': {'QRIS': 950000, 'VA': 400000, 'Tunai': 500000},
          'totalOrders': orders.length,
          'activeOrders': orders.where((o) => o['status'] != 'Selesai').length,
          'completedOrders': orders.where((o) => o['status'] == 'Selesai').length,
          'totalUsers': 14,
          'totalTicketsSold': 24,
          'gateCheckinCount': 12,
          'occupancyRate': 25,
          'totalCostumes': costumes.length,
          'totalGalleries': galleries.length,
          'totalEvents': events.length,
          'topGalleries': galleries,
          'recentActivities': auditLogs,
          'weeklyVisitors': [
            {
              'date': '2026-11-11',
              'visitors': 42,
              'revenue': 400000,
              'ordersCount': 2,
              'ticketsCount': 10,
            },
            {
              'date': '2026-11-12',
              'visitors': 58,
              'revenue': 650000,
              'ordersCount': 3,
              'ticketsCount': 14,
            },
          ],
        },
      });
    }

    if (path == '/admin/galleries') {
      if (method == 'GET') return _json(200, {'success': true, 'data': galleries});
      if (method == 'POST') {
        seq++;
        final item = {
          ...body,
          'id': (body['id'] ?? '').toString().isEmpty
              ? 'gal-$seq'
              : body['id'],
        };
        final idx = galleries.indexWhere((g) => g['id'] == item['id']);
        if (idx >= 0) {
          galleries[idx] = item;
        } else {
          galleries.insert(0, item);
        }
        return _json(201, {'success': true, 'data': item});
      }
      if (method == 'DELETE') {
        final id = options.queryParameters['id']?.toString();
        galleries.removeWhere((g) => g['id'] == id);
        return _json(200, {'success': true});
      }
    }

    if (path == '/admin/categories') {
      if (method == 'GET') return _json(200, {'success': true, 'data': categories});
      if (method == 'POST') {
        seq++;
        final item = {
          ...body,
          'id': (body['id'] ?? '').toString().isEmpty
              ? 'cat-$seq'
              : body['id'],
        };
        final idx = categories.indexWhere((c) => c['id'] == item['id']);
        if (idx >= 0) {
          categories[idx] = item;
        } else {
          categories.add(item);
        }
        return _json(201, {'success': true, 'data': item});
      }
      if (method == 'DELETE') {
        final id = options.queryParameters['id']?.toString();
        categories.removeWhere((c) => c['id'] == id);
        return _json(200, {'success': true});
      }
    }

    if (path == '/admin/costumes') {
      if (method == 'GET') return _json(200, {'success': true, 'data': costumes});
      if (method == 'POST') {
        seq++;
        final item = {
          ...body,
          'id': (body['id'] ?? '').toString().isEmpty
              ? 'costume-$seq'
              : body['id'],
        };
        final idx = costumes.indexWhere((c) => c['id'] == item['id']);
        if (idx >= 0) {
          costumes[idx] = item;
        } else {
          costumes.insert(0, item);
        }
        return _json(201, {'success': true, 'data': item});
      }
      if (method == 'DELETE') {
        final id = options.queryParameters['id']?.toString();
        costumes.removeWhere((c) => c['id'] == id);
        return _json(200, {'success': true});
      }
    }

    if (path == '/admin/stock-movements') {
      if (method == 'GET') {
        final cid = options.queryParameters['costumeId']?.toString();
        final filtered = cid == null
            ? stockMovements
            : stockMovements.where((m) => m['costumeId'] == cid).toList();
        return _json(200, {'success': true, 'data': filtered});
      }
      if (method == 'POST') {
        seq++;
        final movement = {
          ...body,
          'id': 'sm-$seq',
          'actorName': 'Kurator Utama',
          'createdAt': '2026-11-17 12:00:00',
        };
        stockMovements.insert(0, movement);
        final cIdx = costumes.indexWhere((c) => c['id'] == body['costumeId']);
        if (cIdx >= 0) {
          costumes[cIdx] = {
            ...costumes[cIdx],
            'stock': body['stockAfter'],
          };
        }
        return _json(201, {'success': true, 'data': movement});
      }
    }

    if (path == '/admin/events') {
      if (method == 'GET') return _json(200, {'success': true, 'data': events});
      if (method == 'POST') {
        seq++;
        final item = {
          ...body,
          'id': (body['id'] ?? '').toString().isEmpty
              ? 'evt-$seq'
              : body['id'],
        };
        final idx = events.indexWhere((e) => e['id'] == item['id']);
        if (idx >= 0) {
          events[idx] = item;
        } else {
          events.insert(0, item);
        }
        return _json(201, {'success': true, 'data': item});
      }
      if (method == 'DELETE') {
        final id = options.queryParameters['id']?.toString();
        events.removeWhere((e) => e['id'] == id);
        return _json(200, {'success': true});
      }
    }

    if (path == '/admin/orders') {
      if (method == 'GET') return _json(200, {'success': true, 'data': orders});
      if (method == 'PATCH') {
        final orderId = body['orderId'];
        final idx = orders.indexWhere((o) => o['id'] == orderId);
        if (idx < 0) {
          return _json(404, {'success': false, 'message': 'Pesanan tidak ada'});
        }
        final updated = {...orders[idx], ...body};
        if (body['qcStatus'] != null && body['qcStatus'] != 'Pending') {
          updated['status'] = 'Selesai';
        }
        orders[idx] = updated;
        return _json(200, {'success': true, 'data': updated});
      }
    }

    if (path == '/upload' && method == 'POST') {
      return _json(200, {'success': true, 'url': '/uploads/admin-media.png'});
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

  group('AdminCatalogRepository Unit Tests', () {
    late InMemoryKeyValueStore kv;
    late InMemorySecureStore secure;
    late AdminLocalStorage adminStorage;
    late _AdminFakeBackendAdapter adapter;
    late ApiClient adminClient;
    late AdminCatalogRepository repo;

    setUp(() async {
      kv = InMemoryKeyValueStore();
      secure = InMemorySecureStore();
      adminStorage = AdminLocalStorage(kvStore: kv, secureStore: secure);
      await adminStorage.saveToken('admin-jwt');

      adapter = _AdminFakeBackendAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3001/api'))
        ..httpClientAdapter = adapter;
      adminClient = ApiClient(
        baseUrl: 'http://localhost:3001',
        scope: ApiScope.admin,
        readToken: adminStorage.getToken,
        dioOverride: dio,
      );
      repo = AdminCatalogRepository(
        adminApiClient: adminClient,
        adminStorage: adminStorage,
      );
    });

    test('fetches analytics & falls back to AdminLocalStorage offline cache', () async {
      final online = await repo.fetchAnalytics();
      expect(online.totalRevenue, 1850000);
      expect(online.weeklyVisitors.length, 2);

      adapter.simulateAnalyticsNetworkError = true;
      final offline = await repo.fetchAnalytics();
      expect(offline.totalRevenue, 1850000);
      expect(offline.occupancyRate, 25);
    });

    test('performs Gallery, Category, Costume & StockMovement, Event & Order QC mutations', () async {
      final savedGal = await repo.saveGallery(
        const AdminGalleryModel(
          id: '',
          title: 'Tari Gambyong Pareanom',
          category: 'tari-tradisional',
          categoryName: 'Tari Tradisional',
          type: 'foto',
          date: '2026-11-17',
          description: 'Tari penyambutan tamu keraton.',
          image: '/images/tari-gambyong.png',
        ),
      );
      expect(savedGal.id, isNotEmpty);
      await repo.deleteGallery(savedGal.id);
      expect((await repo.fetchGalleries()).length, 1);

      final cat = await repo.saveCategory(
        const AdminCategoryModel(
          id: '',
          name: 'Karawitan',
          icon: 'music_note',
          description: 'Gamelan pelog & slendro.',
        ),
      );
      expect(cat.name, 'Karawitan');
      await repo.deleteCategory(cat.id);

      final movement = await repo.recordStockMovement(
        costumeId: 'costume-1',
        costumeName: 'Busana Ksatria Topeng Malangan',
        size: 'M',
        delta: 2,
        stockAfter: 5,
        reason: 'restock',
        note: 'Penambahan unit baru',
      );
      expect(movement.stockAfter, 5);
      final updatedCostume = (await repo.fetchCostumes()).first;
      expect(updatedCostume.stock, 5);

      final confirmed = await repo.updateOrderStatus(
        orderId: 'ORD-301',
        status: 'Dikonfirmasi',
      );
      expect(confirmed.status, 'Dikonfirmasi');

      final qcRes = await repo.submitOrderQc(
        orderId: 'ORD-301',
        qcStatus: 'Grade B',
        refundAmount: 75000,
        deductionNote: 'Noda ringan di selendang',
      );
      expect(qcRes.status, 'Selesai');
      expect(qcRes.qcStatus, 'Grade B');
      expect(qcRes.refundAmount, 75000);
    });
  });

  group('Fase 5 Admin Screens Widget Tests (390x844 & 1280x800)', () {
    Future<ProviderContainer> pumpAdminApp(
      WidgetTester tester, {
      required Size viewport,
      required _AdminFakeBackendAdapter adapter,
      String initialRoute = AppRoutes.adminDashboard,
    }) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = viewport;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final kv = InMemoryKeyValueStore();
      final secure = InMemorySecureStore();
      final adminStorage = AdminLocalStorage(kvStore: kv, secureStore: secure);
      await adminStorage.saveToken('admin-jwt');

      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3001/api'))
        ..httpClientAdapter = adapter;
      final adminClient = ApiClient(
        baseUrl: 'http://localhost:3001',
        scope: ApiScope.admin,
        readToken: adminStorage.getToken,
        dioOverride: dio,
      );

      final container = ProviderContainer(
        overrides: [
          keyValueStoreProvider.overrideWithValue(kv),
          secureStoreProvider.overrideWithValue(secure),
          adminApiClientProvider.overrideWithValue(adminClient),
          authProvider.overrideWith(_LoggedInAdminNotifier.new),
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
      'AdminDashboardScreen renders KPIs, fl_chart BarChart, channels & top galleries on Desktop (1280x800)',
      (tester) async {
        final adapter = _AdminFakeBackendAdapter();
        await pumpAdminApp(
          tester,
          viewport: const Size(1280, 800),
          adapter: adapter,
          initialRoute: AppRoutes.adminDashboard,
        );

        expect(
          find.text('Dasbor Operasional Galeri Sriwedari'),
          findsOneWidget,
        );
        expect(find.text('Total Pendapatan'), findsOneWidget);
        expect(find.byType(BarChart), findsOneWidget);
        expect(find.text('Tari Bedhaya Ketawang'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AdminCostumesScreen records stock movement in Ledger sheet on Mobile (390x844)',
      (tester) async {
        final adapter = _AdminFakeBackendAdapter();
        await pumpAdminApp(
          tester,
          viewport: const Size(390, 844),
          adapter: adapter,
          initialRoute: AppRoutes.adminCostumes,
        );

        expect(find.text('Busana Ksatria Topeng Malangan'), findsOneWidget);
        expect(find.text('Stok: 3'), findsOneWidget);

        await tester.tap(find.text('Mutasi Stok'));
        await tester.pumpAndSettle();

        expect(find.text('Ledger Mutasi Stok'), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextFormField, '+2 atau -1'),
          '2',
        );
        await tester.tap(find.text('Simpan Mutasi Stok'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Stok Saat Ini: 5'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AdminOrdersScreen confirms payment and runs QC Grade B calculation (Rp 75.000 refund) on Mobile (390x844)',
      (tester) async {
        final adapter = _AdminFakeBackendAdapter();
        await pumpAdminApp(
          tester,
          viewport: const Size(390, 844),
          adapter: adapter,
          initialRoute: AppRoutes.adminOrders,
        );

        expect(find.text('Busana Ksatria Topeng Malangan'), findsOneWidget);
        expect(find.text('Bukti transfer tersedia'), findsOneWidget);

        // Konfirmasi Bayar
        final confirmPayBtn = find.text('Konfirmasi Bayar');
        await tester.ensureVisible(confirmPayBtn);
        await tester.tap(confirmPayBtn);
        await tester.pumpAndSettle();

        expect(find.text('Dikonfirmasi'), findsWidgets);

        // Buka Dialog Inspeksi QC Retur
        final qcBtn = find.text('Inspeksi QC Retur');
        await tester.ensureVisible(qcBtn);
        await tester.tap(qcBtn);
        await tester.pumpAndSettle();

        expect(find.text('Inspeksi QC Retur Busana'), findsOneWidget);

        // Pilih Grade B (Potongan Rp 25.000 -> Refund Rp 75.000)
        final gradeB = find.text('Grade B');
        await tester.ensureVisible(gradeB);
        await tester.tap(gradeB);
        await tester.pumpAndSettle();
        expect(find.text('Rp 75.000'), findsOneWidget);

        final submitQcBtn = find.text('Selesaikan QC');
        await tester.ensureVisible(submitQcBtn);
        await tester.tap(submitQcBtn);
        await tester.pumpAndSettle();

        expect(find.text('Grade B'), findsOneWidget);
        expect(find.text('Refund: Rp 75.000'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AdminGalleryScreen, AdminCategoriesScreen, and AdminEventsScreen render cleanly without overflow (390x844)',
      (tester) async {
        final adapter = _AdminFakeBackendAdapter();
        final container = await pumpAdminApp(
          tester,
          viewport: const Size(390, 844),
          adapter: adapter,
          initialRoute: AppRoutes.adminGallery,
        );

        expect(find.text('Kelola Koleksi Galeri'), findsOneWidget);
        expect(find.text('Tari Bedhaya Ketawang'), findsOneWidget);

        container.read(appRouterProvider).go(AppRoutes.adminCategories);
        await tester.pumpAndSettle();
        expect(find.text('Kategori Galeri Seni'), findsOneWidget);
        expect(find.text('Tari Tradisional'), findsOneWidget);

        container.read(appRouterProvider).go(AppRoutes.adminEvents);
        await tester.pumpAndSettle();
        expect(find.text('Kelola Jadwal & Acara'), findsOneWidget);
        expect(
          find.text('Wayang Orang Lakon Gatotkaca Gandrung'),
          findsOneWidget,
        );

        await tester.tap(find.text('Tambah Acara'));
        await tester.pumpAndSettle();
        expect(find.text('Tambah Jadwal Pagelaran'), findsOneWidget);
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}

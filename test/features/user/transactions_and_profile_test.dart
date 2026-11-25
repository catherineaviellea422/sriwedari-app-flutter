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
import 'package:sriwedari_app/core/storage/storage_backend.dart';
import 'package:sriwedari_app/core/storage/user_local_storage.dart';
import 'package:sriwedari_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sriwedari_app/features/user/data/user_transactions_repository.dart';
import 'package:sriwedari_app/features/user/domain/booking_calculator.dart';
import 'package:sriwedari_app/features/user/domain/models/user_models.dart';
import 'package:sriwedari_app/features/user/presentation/widgets/theater_seat_map_sheet.dart';
import 'package:sriwedari_app/features/user/presentation/widgets/ticket_boarding_pass_modal.dart';

class _TransactionsFakeBackendAdapter implements HttpClientAdapter {
  bool simulateSeatConflictOnce = false;
  bool simulateNetworkErrorOnTickets = false;
  int customDepositFee = 100000;
  int orderSeq = 1;
  int ticketSeq = 1;

  Map<String, dynamic> userAccount = {
    'id': 'user-1',
    'name': 'Raden Ayu Sekar',
    'email': 'sekar@keraton.id',
    'phone': '081234567890',
    'points': 120,
    'role': 'user',
    'createdAt': '2025-01-01T00:00:00Z',
  };

  final List<Map<String, dynamic>> costumes = [
    {
      'id': 'costume-topeng',
      'name': 'Busana Ksatria Topeng Malangan',
      'category': 'Jawa Timuran',
      'price': 250000,
      'rating': 4.9,
      'reviewCount': 38,
      'stock': 4,
      'sizes': ['S', 'M', 'L'],
      'description': 'Kostum pentas Topeng Malangan lengkap.',
      'image': '/images/tari-topeng-malangan.png',
      'available': true,
      'includes': ['Jamang', 'Baju Bludru'],
    },
    {
      'id': 'costume-ramayana',
      'name': 'Busana Sinta Sendratari',
      'category': 'Klasik Keraton',
      'price': 180000,
      'rating': 4.8,
      'reviewCount': 22,
      'stock': 3,
      'sizes': ['S', 'M'],
      'description': 'Busana tari Ramayana klasik.',
      'image': '/images/tari-jawa-dramatic-stage.png',
      'available': true,
      'includes': ['Siger', 'Selendang'],
    },
  ];

  final List<Map<String, dynamic>> events = [
    {
      'id': 'evt-1',
      'title': 'Wayang Orang Lakon Gatotkaca Gandrung',
      'category': 'Pagelaran Utama',
      'date': '2026-12-20',
      'time': '19:30 WIB',
      'location': 'Gedung Wayang Orang Sriwedari',
      'description': 'Pagelaran malam kolosal penari senior Sriwedari.',
      'image': '/images/tari-jawa-dramatic-stage.png',
      'price': 35000,
      'zonePrices': {'VIP': 50000, 'REGULER': 35000, 'BALKON': 25000},
      'quota': 48,
      'bookedSeats': ['A-01', 'A-02'],
      'status': 'Mendatang',
    },
    {
      'id': 'evt-2',
      'title': 'Pentas Ramayana Klasik',
      'category': 'Arsip Pementasan',
      'date': '2024-11-10',
      'time': '19:30 WIB',
      'location': 'Pendopo Sriwedari',
      'description': 'Dokumentasi pementasan bulan lalu.',
      'image': '/images/tari-bedhaya-ketawang.png',
      'price': 35000,
      'quota': 48,
      'bookedSeats': [],
      'status': 'Selesai',
    },
  ];

  final List<Map<String, dynamic>> orders = [
    {
      'id': 'ORD-100',
      'userId': 'user-1',
      'userName': 'Raden Ayu Sekar',
      'userPhone': '081234567890',
      'userEmail': 'sekar@keraton.id',
      'costumeId': 'costume-ramayana',
      'costumeName': 'Busana Sinta Sendratari',
      'costumes': [
        {
          'id': 'costume-ramayana',
          'name': 'Busana Sinta Sendratari',
          'price': 180000,
          'days': 2,
          'size': 'M',
        },
      ],
      'startDate': '2026-12-01',
      'duration': 2,
      'totalPrice': 460000,
      'depositFee': 100000,
      'discountAmount': 0,
      'status': 'Selesai',
      'qcStatus': 'Lolos',
      'deductionFee': 0,
      'refundAmount': 100000,
      'deductionNote': 'Kondisi kain songket sangat terawat.',
      'paymentMethod': 'QRIS',
      'createdAt': '2026-11-01T10:00:00Z',
    },
  ];

  final List<Map<String, dynamic>> tickets = [
    {
      'id': 'TKT-100',
      'eventId': 'evt-1',
      'eventTitle': 'Wayang Orang Lakon Gatotkaca Gandrung',
      'userId': 'user-1',
      'userName': 'Raden Ayu Sekar',
      'userPhone': '081234567890',
      'quantity': 2,
      'seats': ['A-01', 'A-02'],
      'zone': 'VIP',
      'totalPrice': 100000,
      'bookingCode': 'WO-SRW-100',
      'status': 'Aktif',
      'createdAt': '2026-11-01T12:00:00Z',
    },
  ];

  final List<Map<String, dynamic>> wishlists = [
    {
      'id': 'wish-1',
      'userId': 'user-1',
      'targetType': 'costume',
      'targetId': 'costume-topeng',
      'createdAt': '2026-11-02T09:00:00Z',
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
    final rawData = options.data;
    final body = rawData is Map<String, dynamic>
        ? rawData
        : <String, dynamic>{};

    if (path == '/user/costumes') {
      return _json(200, {'success': true, 'data': costumes});
    }
    if (path == '/user/events') {
      return _json(200, {'success': true, 'data': events});
    }
    if (path == '/user/galleries') {
      return _json(200, {'success': true, 'data': []});
    }
    if (path == '/user/categories') {
      return _json(200, {'success': true, 'data': []});
    }
    if (path == '/user/articles') {
      return _json(200, {'success': true, 'data': []});
    }
    if (path == '/user/testimonials') {
      return _json(200, {'success': true, 'data': []});
    }
    if (path == '/user/settings') {
      return _json(200, {
        'success': true,
        'data': {
          'galleryName': 'Galeri Sriwedari',
          'contactPhone': '0271-712345',
          'depositFee': customDepositFee,
        },
      });
    }

    if (path == '/user/coupons/validate' && method == 'POST') {
      final code = (body['code'] ?? '').toString().toUpperCase();
      final totalAmount = (body['totalAmount'] as num?)?.toInt() ?? 0;
      if (code == 'SRIWEDARI10') {
        final discount = (totalAmount * 0.1).round();
        return _json(200, {
          'success': true,
          'discountAmount': discount,
          'message': 'Kupon SRIWEDARI10 (10%) berhasil diterapkan.',
          'coupon': {
            'code': 'SRIWEDARI10',
            'type': 'PERCENTAGE',
            'value': 10,
            'minOrder': 0,
            'active': true,
          },
        });
      }
      return _json(400, {'success': false, 'message': 'Kupon tidak ditemukan.'});
    }

    if (path == '/user/orders') {
      if (method == 'GET') {
        return _json(200, {'success': true, 'data': orders});
      }
      if (method == 'POST') {
        orderSeq++;
        final newOrder = {
          'id': 'ORD-${200 + orderSeq}',
          'userId': 'user-1',
          ...body,
          'createdAt': '2026-11-17T10:00:00Z',
        };
        orders.insert(0, newOrder);
        return _json(201, {'success': true, 'data': newOrder});
      }
      if (method == 'PATCH') {
        final orderId = body['orderId'];
        final idx = orders.indexWhere((o) => o['id'] == orderId);
        if (idx >= 0) {
          orders[idx] = {...orders[idx], ...body};
          return _json(200, {'success': true, 'data': orders[idx]});
        }
        return _json(404, {'success': false, 'message': 'Pesanan tidak ada.'});
      }
    }

    if (path == '/upload' && method == 'POST') {
      return _json(200, {
        'success': true,
        'url': '/uploads/proof-test-123.png',
      });
    }

    if (path == '/user/tickets') {
      final eventIdParam = options.queryParameters['eventId']?.toString();
      if (method == 'GET' && eventIdParam != null) {
        final evt = events.firstWhere(
          (e) => e['id'] == eventIdParam,
          orElse: () => {'bookedSeats': <String>[]},
        );
        return _json(200, {
          'success': true,
          'bookedSeats': evt['bookedSeats'] ?? <String>[],
        });
      }
      if (method == 'GET') {
        if (simulateNetworkErrorOnTickets) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            message: 'Offline mode',
          );
        }
        return _json(200, {'success': true, 'data': tickets});
      }
      if (method == 'POST') {
        if (simulateSeatConflictOnce) {
          simulateSeatConflictOnce = false;
          final evt = events.firstWhere((e) => e['id'] == body['eventId']);
          final booked = List<String>.from(evt['bookedSeats'] as List);
          if (!booked.contains('A-03')) booked.add('A-03');
          evt['bookedSeats'] = booked;
          return _json(409, {
            'success': false,
            'message': 'Kursi [A-03] baru saja dipesan oleh penonton lain.',
          });
        }
        ticketSeq++;
        final seats = List<String>.from(body['seats'] as List);
        final evt = events.firstWhere((e) => e['id'] == body['eventId']);
        final booked = List<String>.from(evt['bookedSeats'] as List);
        booked.addAll(seats);
        evt['bookedSeats'] = booked;

        final newTicket = {
          'id': 'TKT-${200 + ticketSeq}',
          ...body,
          'userId': 'user-1',
          'bookingCode': 'WO-SRW-${200 + ticketSeq}',
          'status': 'Aktif',
          'createdAt': '2026-11-17T11:00:00Z',
        };
        tickets.insert(0, newTicket);
        return _json(201, {'success': true, 'ticket': newTicket});
      }
    }

    if (path == '/user/wishlist') {
      if (method == 'GET') {
        return _json(200, {'success': true, 'data': wishlists});
      }
      if (method == 'DELETE') {
        final targetId = options.queryParameters['targetId']?.toString();
        wishlists.removeWhere((w) => w['targetId'] == targetId);
        return _json(200, {'success': true, 'data': wishlists});
      }
    }

    if (path == '/user/profile' && method == 'PATCH') {
      userAccount = {
        ...userAccount,
        'name': body['name'] ?? userAccount['name'],
        'phone': body['phone'] ?? userAccount['phone'],
      };
      return _json(200, {'success': true, 'data': userAccount});
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

class _LoggedInUserNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
        status: AuthStatus.authenticatedUser,
        userAccount: UserAccountModel(
          id: 'user-1',
          name: 'Raden Ayu Sekar',
          email: 'sekar@keraton.id',
          phone: '081234567890',
          points: 120,
        ),
        isInitialized: true,
      );
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('BookingCostCalculator & TheaterSeatMapHelper Unit Tests', () {
    test('calculates multi-costume subtotal, percentage/fixed discount, minOrder & deposit', () {
      const items = [
        BookingCartItemModel(
          id: 'c1',
          name: 'Topeng Malangan',
          price: 250000,
          days: 2,
          size: 'L',
        ),
        BookingCartItemModel(
          id: 'c2',
          name: 'Sinta Sendratari',
          price: 180000,
          days: 1,
          size: 'M',
        ),
      ];

      final subtotal = BookingCostCalculator.calculateRentalSubtotal(items);
      expect(subtotal, 680000);

      final pctDiscount = BookingCostCalculator.calculateCouponDiscount(
        subtotal: subtotal,
        couponType: 'PERCENTAGE',
        couponValue: 10,
        minOrder: 200000,
      );
      expect(pctDiscount, 68000);

      final belowMinOrder = BookingCostCalculator.calculateCouponDiscount(
        subtotal: subtotal,
        couponType: 'FIXED',
        couponValue: 50000,
        minOrder: 900000,
      );
      expect(belowMinOrder, 0);

      final grandTotal = BookingCostCalculator.calculateGrandTotal(
        subtotal: subtotal,
        discountAmount: pctDiscount,
        depositFee: 100000,
      );
      expect(grandTotal, 712000);
    });

    test('validates 3-zone seat map & detects empty, overflow, and booked collision', () {
      expect(TheaterSeatMapHelper.zones.length, 3);
      expect(TheaterSeatMapHelper.seatsForRow('A').length, 8);
      expect(TheaterSeatMapHelper.seatsForRow('A').first, 'A-01');

      final emptyRes = TheaterSeatMapHelper.validateSeatSelection(
        selectedSeats: const [],
        bookedSeats: const {'A-01'},
      );
      expect(emptyRes.valid, isFalse);

      final tooManyRes = TheaterSeatMapHelper.validateSeatSelection(
        selectedSeats: const ['C-01', 'C-02', 'C-03', 'C-04', 'C-05', 'C-06'],
        bookedSeats: const {},
      );
      expect(tooManyRes.valid, isFalse);

      final conflictRes = TheaterSeatMapHelper.validateSeatSelection(
        selectedSeats: const ['A-01', 'A-04'],
        bookedSeats: const {'A-01', 'A-02'},
      );
      expect(conflictRes.valid, isFalse);
      expect(conflictRes.error, contains('A-01'));

      final okRes = TheaterSeatMapHelper.validateSeatSelection(
        selectedSeats: const ['A-03', 'A-04'],
        bookedSeats: const {'A-01', 'A-02'},
      );
      expect(okRes.valid, isTrue);
    });
  });

  group('UserTransactionsRepository Unit Tests', () {
    late InMemoryKeyValueStore kv;
    late InMemorySecureStore secure;
    late UserLocalStorage storage;
    late _TransactionsFakeBackendAdapter adapter;
    late ApiClient apiClient;
    late UserTransactionsRepository repo;

    setUp(() async {
      kv = InMemoryKeyValueStore();
      secure = InMemorySecureStore();
      storage = UserLocalStorage(kvStore: kv, secureStore: secure);
      await storage.saveToken('user-token');

      adapter = _TransactionsFakeBackendAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3001/api'))
        ..httpClientAdapter = adapter;
      apiClient = ApiClient(
        baseUrl: 'http://localhost:3001',
        scope: ApiScope.user,
        readToken: storage.getToken,
        dioOverride: dio,
      );
      repo = UserTransactionsRepository(
        userApiClient: apiClient,
        userStorage: storage,
      );
    });

    test('creates order, clears draft, uploads payment proof, and cancels order', () async {
      await storage.saveBookingDraftJson({'step': 2});
      expect(await storage.getBookingDraftJson(), isNotNull);

      final order = await repo.createOrder(
        userName: 'Sekar',
        userPhone: '081234567890',
        userEmail: 'sekar@keraton.id',
        costumes: const [
          BookingCartItemModel(
            id: 'costume-topeng',
            name: 'Busana Ksatria Topeng Malangan',
            price: 250000,
            days: 2,
            size: 'L',
          ),
        ],
        startDate: '2026-12-10',
        totalPrice: 600000,
        depositFee: 100000,
        discountAmount: 0,
        paymentMethod: 'QRIS',
      );
      expect(order.id, 'ORD-202');
      expect(await storage.getBookingDraftJson(), isNull);

      final proofUrl = await repo.uploadAndAttachPaymentProof(
        orderId: order.id,
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        filename: 'bukti.png',
      );
      expect(proofUrl, '/uploads/proof-test-123.png');

      await repo.cancelOrder(order.id);
      final list = await repo.fetchMyOrders();
      final cancelled = list.firstWhere((o) => o.id == order.id);
      expect(cancelled.status, 'Dibatalkan');
    });

    test('caches booked tickets and falls back to offline cache on network error', () async {
      final onlineTickets = await repo.fetchMyTickets();
      expect(onlineTickets.length, 1);
      expect(onlineTickets.first.bookingCode, 'WO-SRW-100');

      adapter.simulateNetworkErrorOnTickets = true;
      final offlineTickets = await repo.fetchMyTickets();
      expect(offlineTickets.length, 1);
      expect(offlineTickets.first.bookingCode, 'WO-SRW-100');

      adapter.simulateNetworkErrorOnTickets = false;
      final newTicket = await repo.bookTickets(
        eventId: 'evt-1',
        eventTitle: 'Wayang Orang Lakon Gatotkaca Gandrung',
        userName: 'Sekar',
        userPhone: '081234567890',
        seats: const ['C-01', 'C-02'],
        zone: 'REGULER',
        totalPrice: 70000,
      );
      expect(newTicket.bookingCode, 'WO-SRW-202');

      adapter.simulateNetworkErrorOnTickets = true;
      final updatedOffline = await repo.fetchMyTickets();
      expect(updatedOffline.length, 2);
      expect(updatedOffline.first.bookingCode, 'WO-SRW-202');
    });

    test('validates coupons and updates profile into UserLocalStorage', () async {
      final validCoupon = await repo.validateCoupon(
        code: 'SRIWEDARI10',
        totalAmount: 500000,
      );
      expect(validCoupon.valid, isTrue);
      expect(validCoupon.discountAmount, 50000);

      final invalidCoupon = await repo.validateCoupon(
        code: 'SALAH',
        totalAmount: 500000,
      );
      expect(invalidCoupon.valid, isFalse);

      final updated = await repo.updateProfile(
        name: 'Sekar Wangi',
        phone: '089999888777',
      );
      expect(updated.name, 'Sekar Wangi');
      final cachedProfile = await storage.getUserProfileJson();
      expect(cachedProfile?['name'], 'Sekar Wangi');
    });
  });

  group('Fase 4 UI Flows (390x844 Mobile & 1280x800 Desktop)', () {
    Future<void> pumpApp(
      WidgetTester tester, {
      required Size viewport,
      required _TransactionsFakeBackendAdapter adapter,
      String initialRoute = AppRoutes.userBooking,
    }) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = viewport;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final kv = InMemoryKeyValueStore();
      final secure = InMemorySecureStore();
      final userStorage = UserLocalStorage(kvStore: kv, secureStore: secure);
      await userStorage.saveToken('user-jwt');
      await userStorage.saveUserProfileJson(adapter.userAccount);

      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3001/api'))
        ..httpClientAdapter = adapter;
      final userClient = ApiClient(
        baseUrl: 'http://localhost:3001',
        scope: ApiScope.user,
        readToken: userStorage.getToken,
        dioOverride: dio,
      );

      final container = ProviderContainer(
        overrides: [
          keyValueStoreProvider.overrideWithValue(kv),
          secureStoreProvider.overrideWithValue(secure),
          userApiClientProvider.overrideWithValue(userClient),
          authProvider.overrideWith(_LoggedInUserNotifier.new),
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
    }

    testWidgets(
      'BookingFormScreen 3-step checkout with multi-costume & SRIWEDARI10 coupon reaches BookingSuccessScreen (mobile 390x844)',
      (tester) async {
        final adapter = _TransactionsFakeBackendAdapter();
        await pumpApp(
          tester,
          viewport: const Size(390, 844),
          adapter: adapter,
          initialRoute:
              '${AppRoutes.userBooking}?costumeId=costume-topeng&days=2&size=L',
        );

        expect(find.text('Form Pemesanan Sewa Busana'), findsOneWidget);
        expect(find.text('1. Informasi Pemesan'), findsOneWidget);

        // Step 1 -> Step 2
        final toStep2 = find.text('Lanjut ke Pilih Kostum');
        await tester.ensureVisible(toStep2);
        await tester.tap(toStep2);
        await tester.pumpAndSettle();

        expect(find.text('2. Busana Dipilih (1)'), findsOneWidget);

        // Tambah busana kedua (multi-costume cart)
        final addSecondBtn = find.text('Tambah Busana');
        await tester.ensureVisible(addSecondBtn);
        await tester.tap(addSecondBtn);
        await tester.pumpAndSettle();
        expect(find.text('2. Busana Dipilih (2)'), findsOneWidget);

        // Step 2 -> Step 3
        final toStep3 = find.text('Lanjut ke Konfirmasi');
        await tester.ensureVisible(toStep3);
        await tester.tap(toStep3);
        await tester.pumpAndSettle();

        // Terapkan kupon SRIWEDARI10
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Masukkan kode kupon'),
          'SRIWEDARI10',
        );
        await tester.tap(find.text('Terapkan'));
        await tester.pumpAndSettle();
        expect(find.textContaining('SRIWEDARI10'), findsWidgets);

        // Submit pesanan
        final submitBtn = find.text('Konfirmasi & Kirim Pesanan');
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(find.text('Pesanan Sewa Berhasil Dibuat!'), findsOneWidget);
        expect(find.textContaining('ORD-202'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ScheduleScreen opens TheaterSeatMapSheet, handles 409 double-booking conflict, and completes ticket booking (desktop 1280x800)',
      (tester) async {
        final adapter = _TransactionsFakeBackendAdapter()
          ..simulateSeatConflictOnce = true;

        await pumpApp(
          tester,
          viewport: const Size(1280, 800),
          adapter: adapter,
          initialRoute: AppRoutes.userSchedule,
        );

        expect(find.text('Wayang Orang Lakon Gatotkaca Gandrung'), findsOneWidget);

        // Buka denah kursi
        await tester.tap(find.text('Pilih Kursi & Pesan Tiket'));
        await tester.pumpAndSettle();

        expect(find.byType(TheaterSeatMapSheet), findsOneWidget);
        expect(find.text('PANGGUNG KELIR & GAMELAN AGENG'), findsOneWidget);

        // Pilih kursi A-03
        await tester.tap(find.text('A-03'));
        await tester.pumpAndSettle();

        // Percobaan pertama -> 409 Conflict
        final bookBtn = find.text('Konfirmasi Pemesanan Tiket');
        await tester.ensureVisible(bookBtn);
        await tester.tap(bookBtn);
        await tester.pumpAndSettle();

        expect(find.textContaining('baru saja dipesan'), findsOneWidget);

        // Pilih kursi kosong berikutnya A-04 setelah conflict clear
        await tester.tap(find.text('A-04'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(bookBtn);
        await tester.tap(bookBtn);
        await tester.pumpAndSettle();

        expect(find.text('Tiket Berhasil Dipesan!'), findsOneWidget);
        expect(find.textContaining('WO-SRW-202'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ProfileScreen renders SRIWEDARI REVISI layout, modals, QC refund, QR Boarding Pass, and wishlist on mobile (390x844)',
      (tester) async {
        final adapter = _TransactionsFakeBackendAdapter();
        await pumpApp(
          tester,
          viewport: const Size(390, 844),
          adapter: adapter,
          initialRoute: AppRoutes.userProfile,
        );

        // Header, WA pill, completion bar & membership card
        expect(find.text('Edit profil'), findsOneWidget);
        expect(
          find.text('Galeri Sriwedari, Surakarta • 081234567890'),
          findsOneWidget,
        );
        expect(find.text('100%'), findsOneWidget);
        expect(find.text('WARGA BUDAYA'), findsOneWidget);

        // Modal Keuntungan Anggota
        final benefitsBtn = find.text('Lihat Semua Keuntungan Anggota');
        await tester.ensureVisible(benefitsBtn);
        await tester.tap(benefitsBtn);
        await tester.pumpAndSettle();
        expect(find.text('Keuntungan Sahabat Keraton'), findsOneWidget);
        final closeBenefitsBtn = find.text('Mengerti');
        await tester.ensureVisible(closeBenefitsBtn);
        await tester.tap(closeBenefitsBtn);
        await tester.pumpAndSettle();

        // Modal Informasi & Sesi (gear button)
        final settingsBtn = find.byKey(const ValueKey('profile-settings-btn'));
        await tester.ensureVisible(settingsBtn);
        await tester.tap(settingsBtn);
        await tester.pumpAndSettle();
        expect(find.text('Informasi & Sesi'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        // Tab 0: Sewa & QC Refund
        expect(find.text('Busana Sinta Sendratari'), findsOneWidget);
        expect(find.textContaining('Refund Deposit: Rp 100.000'), findsOneWidget);
        expect(
          find.text('Catatan QC: Kondisi kain songket sangat terawat.'),
          findsOneWidget,
        );

        // Tab 1: E-Tiket & QR Boarding Pass
        final ticketTab = find.byKey(const ValueKey('profile-tab-tickets'));
        await tester.ensureVisible(ticketTab);
        await tester.tap(ticketTab);
        await tester.pumpAndSettle();

        expect(find.text('WO-SRW-100'), findsOneWidget);
        final openQr = find.text('Lihat E-Tiket QR');
        await tester.ensureVisible(openQr);
        await tester.tap(openQr);
        await tester.pumpAndSettle();

        expect(find.byType(TicketBoardingPassModal), findsOneWidget);
        expect(find.byType(QrImageView), findsOneWidget);
        expect(find.byType(BarcodeWidget), findsOneWidget);

        await tester.tap(find.text('Tutup'));
        await tester.pumpAndSettle();

        // Tab 2: Favorit & hapus wishlist
        final wishlistTab = find.byKey(const ValueKey('profile-tab-wishlist'));
        await tester.ensureVisible(wishlistTab);
        await tester.tap(wishlistTab);
        await tester.pumpAndSettle();

        expect(find.text('Busana Ksatria Topeng Malangan'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Daftar Favorit Kosong'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    test('SessionExpiredSignalNotifier resets authenticated AuthNotifier state to unauthenticated', () async {
      final kv = InMemoryKeyValueStore();
      final secure = InMemorySecureStore();
      final userStorage = UserLocalStorage(kvStore: kv, secureStore: secure);
      await userStorage.saveToken('user-jwt');
      await userStorage.saveUserProfileJson({
        'id': 'u-1',
        'name': 'Sekar',
        'email': 'sekar@keraton.id',
        'phone': '081234567890',
        'points': 120,
        'role': 'user',
        'createdAt': '2025-01-01T00:00:00Z',
      });

      final container = ProviderContainer(
        overrides: [
          keyValueStoreProvider.overrideWithValue(kv),
          secureStoreProvider.overrideWithValue(secure),
        ],
      );
      addTearDown(container.dispose);

      // Pulihkan sesi user asli agar AuthNotifier berada di status authenticatedUser
      await container.read(authProvider.notifier).restoreSession();
      expect(container.read(authProvider).status, AuthStatus.authenticatedUser);

      // Picu sinyal 401
      container.read(sessionExpiredSignalProvider.notifier).trigger();

      final updatedAuth = container.read(authProvider);
      expect(updatedAuth.status, AuthStatus.unauthenticated);
      expect(updatedAuth.userAccount, isNull);
      expect(updatedAuth.errorMessage, contains('Sesi Anda telah berakhir'));
    });

    testWidgets(
      'BookingFormScreen uses dynamic depositFee from publicSettingsProvider on Step 3',
      (tester) async {
        final adapter = _TransactionsFakeBackendAdapter()
          ..customDepositFee = 150000;
        await pumpApp(
          tester,
          viewport: const Size(1280, 800),
          adapter: adapter,
          initialRoute: '${AppRoutes.userBooking}?costumeId=costume-topeng',
        );

        // Step 1 -> Step 2
        final next1 = find.text('Lanjut ke Pilih Kostum');
        await tester.ensureVisible(next1);
        await tester.tap(next1);
        await tester.pumpAndSettle();

        // Step 2 -> Step 3
        final next2 = find.text('Lanjut ke Konfirmasi');
        await tester.ensureVisible(next2);
        await tester.tap(next2);
        await tester.pumpAndSettle();

        // Subtotal (250.000 x 3 hari = 750.000) + Deposit dinamis 150.000 = Total 900.000
        expect(find.text('Rp 150.000'), findsWidgets);
        expect(find.text('Rp 900.000'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'BookingFormScreen AppBar Back steps backward 2 -> 1 -> 0 and ProfileScreen respects ?tab=tickets',
      (tester) async {
        final adapter = _TransactionsFakeBackendAdapter();
        await pumpApp(
          tester,
          viewport: const Size(390, 844),
          adapter: adapter,
          initialRoute: '${AppRoutes.userBooking}?costumeId=costume-topeng',
        );

        // Step 1 -> Step 2
        final toStep2 = find.text('Lanjut ke Pilih Kostum');
        await tester.ensureVisible(toStep2);
        await tester.tap(toStep2);
        await tester.pumpAndSettle();
        expect(find.text('2. Busana Dipilih (1)'), findsOneWidget);

        // Tekan tombol Back di AppBar -> kembali ke Step 1
        await tester.tap(find.byKey(const ValueKey('booking-back-btn')));
        await tester.pumpAndSettle();
        expect(find.text('1. Informasi Pemesan'), findsOneWidget);

        // Cek /profil?tab=tickets langsung membuka tab E-Tiket
        await pumpApp(
          tester,
          viewport: const Size(390, 844),
          adapter: adapter,
          initialRoute: AppRoutes.userProfileWithTab('tickets'),
        );
        expect(find.text('WO-SRW-100'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'BookingFormScreen memblokir angka di Nama, huruf di WhatsApp, dan mode ketik tanggal bebas',
      (tester) async {
        final adapter = _TransactionsFakeBackendAdapter();
        await pumpApp(
          tester,
          viewport: const Size(390, 844),
          adapter: adapter,
          initialRoute: '${AppRoutes.userBooking}?costumeId=costume-topeng',
        );

        // 1. Kolom Nama menolak angka & simbol ilegal lewat inputFormatters
        final nameFieldFinder = find.byType(TextFormField).at(0);
        await tester.tap(nameFieldFinder);
        await tester.pump();
        tester.testTextInput.enterText('Raden 12345!');
        await tester.pump();
        final nameField = tester.widget<TextFormField>(nameFieldFinder);
        expect(nameField.controller!.text, 'Raden ');

        // 2. Kolom No. WhatsApp hanya menerima digit angka
        final waFieldFinder = find.byType(TextFormField).at(1);
        await tester.tap(waFieldFinder);
        await tester.pump();
        tester.testTextInput.enterText('0812abc3456xy78');
        await tester.pump();
        final waField = tester.widget<TextFormField>(waFieldFinder);
        expect(waField.controller!.text, '0812345678');

        // 3. Kolom Tanggal membuka DatePicker mode calendarOnly (tanpa ikon pensil ketik manual)
        final dateFieldFinder = find.byIcon(Icons.calendar_today_outlined);
        await tester.ensureVisible(dateFieldFinder);
        await tester.tap(dateFieldFinder);
        await tester.pumpAndSettle();

        expect(find.byType(DatePickerDialog), findsOneWidget);
        expect(find.byIcon(Icons.edit_outlined), findsNothing);
        expect(find.byIcon(Icons.edit), findsNothing);

        await tester.tap(
          find
              .descendant(
                of: find.byType(DatePickerDialog),
                matching: find.byType(TextButton),
              )
              .last,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}

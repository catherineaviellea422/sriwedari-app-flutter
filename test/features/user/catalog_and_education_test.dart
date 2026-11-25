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
import 'package:sriwedari_app/core/storage/storage_backend.dart';
import 'package:sriwedari_app/core/storage/user_local_storage.dart';
import 'package:sriwedari_app/core/widgets/core_widgets.dart';
import 'package:sriwedari_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sriwedari_app/features/user/data/user_catalog_repository.dart';
import 'package:sriwedari_app/features/user/domain/models/user_models.dart';

class _CatalogFakeBackendAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> galleries = [
    {
      'id': 'gal-1',
      'title': 'Tari Topeng Malangan',
      'category': 'tari-tradisional',
      'categoryName': 'Tari Tradisional',
      'type': 'foto',
      'date': '2025-01-10',
      'description': 'Seni pertunjukan wayang topeng khas Jawa Timur.',
      'image': '/images/tari-topeng-malangan.png',
      'views': 1420,
      'likes': 358,
      'isLiked': false,
      'origin': 'Malang, Jawa Timur',
      'costumeId': 'costume-topeng',
    },
    {
      'id': 'gal-5',
      'title': 'Drama Tari Jawa Teatrikal',
      'category': 'tari-kreasi',
      'categoryName': 'Tari Kreasi',
      'type': 'video',
      'date': '2024-12-28',
      'description': 'Kisah kepahlawanan Prabu Rama di panggung Sriwedari.',
      'image': '/images/tari-jawa-dramatic-stage.png',
      'views': 3120,
      'likes': 890,
      'isLiked': false,
      'origin': 'Taman Sriwedari, Surakarta',
      'costumeId': 'costume-ramayana',
    },
  ];

  final List<Map<String, dynamic>> categories = [
    {
      'id': 'cat-1',
      'name': 'Tari Tradisional',
      'icon': 'theater_comedy',
      'description': 'Pakem keraton',
      'count': 1,
    },
    {
      'id': 'cat-2',
      'name': 'Tari Kreasi',
      'icon': 'auto_awesome',
      'description': 'Kontemporer Nusantara',
      'count': 1,
    },
  ];

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
      'sizeStocks': {'S': 1, 'M': 2, 'L': 1},
      'image': '/images/tari-topeng-malangan.png',
      'description': 'Satu set lengkap topeng kayu ukir dan kain parang.',
      'origin': 'Malang, Jawa Timur',
    },
    {
      'id': 'costume-bedhaya',
      'name': 'Busana Dodot Ageng Bedhaya Surakarta',
      'category': 'Keraton Solo',
      'price': 450000,
      'rating': 5.0,
      'reviewCount': 64,
      'stock': 2,
      'sizes': ['All Size'],
      'image': '/images/tari-jawa-stage.png',
      'description': 'Kain dodot kampuh prada emas asli keraton.',
      'origin': 'Keraton Surakarta',
    },
  ];

  final List<Map<String, dynamic>> events = [
    {
      'id': 'evt-1',
      'title': 'Pagelaran Wayang Orang Sriwedari',
      'date': '2026-10-31',
      'time': '20:00 WIB',
      'location': 'GWO Sriwedari',
      'price': 50000,
      'quota': 200,
      'booked': 142,
      'image': '/images/tari-jawa-dramatic-stage.png',
      'description': 'Lakon Ramayana Tambak',
    },
  ];

  final List<Map<String, dynamic>> reviews = [
    {
      'id': 'rev-1',
      'targetId': 'gal-1',
      'targetType': 'gallery',
      'userName': 'Bagus Wicaksono',
      'rating': 5,
      'comment': 'Penjelasan narasi filosofis topeng Panji sangat mendalam.',
      'createdAt': '2026-10-23',
      'verified': true,
      'status': 'tampil',
    },
  ];

  final List<Map<String, dynamic>> wishlist = [];

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
    final body = options.data is Map ? options.data as Map : <String, dynamic>{};

    if (path.endsWith('/user/galleries')) {
      return _json({'success': true, 'data': galleries});
    }
    if (path.endsWith('/user/galleries/like') && method == 'PATCH') {
      final id = body['id'];
      final g = galleries.firstWhere((e) => e['id'] == id);
      g['isLiked'] = !(g['isLiked'] == true);
      g['likes'] = (g['likes'] as int) + (g['isLiked'] == true ? 1 : -1);
      return _json({'success': true, 'isLiked': g['isLiked'], 'likes': g['likes']});
    }
    if (path.endsWith('/user/categories')) {
      return _json({'success': true, 'data': categories});
    }
    if (path.endsWith('/user/costumes')) {
      return _json({'success': true, 'data': costumes});
    }
    if (path.endsWith('/user/events')) {
      return _json({'success': true, 'data': events});
    }
    if (path.endsWith('/user/reviews') && method == 'GET') {
      final targetId = options.queryParameters['targetId'];
      final list = targetId == null
          ? reviews
          : reviews.where((r) => r['targetId'] == targetId).toList();
      return _json({'success': true, 'data': list});
    }
    if (path.endsWith('/user/reviews') && method == 'POST') {
      final created = {
        'id': 'rev-${reviews.length + 1}',
        'targetId': body['targetId'],
        'targetType': body['targetType'],
        'userName': 'Oliv Satoro',
        'rating': body['rating'],
        'comment': body['comment'],
        'createdAt': '2026-11-17',
        'verified': true,
        'status': 'tampil',
      };
      reviews.insert(0, created);
      return _json({'success': true, 'data': created}, status: 201);
    }
    if (path.endsWith('/user/wishlist') && method == 'GET') {
      return _json({'success': true, 'data': wishlist});
    }
    if (path.endsWith('/user/wishlist') && method == 'POST') {
      wishlist.insert(0, {
        'id': 'wl-${wishlist.length + 1}',
        'userId': 'usr-user-1',
        'targetId': body['targetId'],
        'targetType': body['targetType'],
        'createdAt': '2026-11-17',
      });
      return _json({'success': true, 'data': wishlist}, status: 201);
    }
    if (path.endsWith('/user/wishlist') && method == 'DELETE') {
      final targetId = options.queryParameters['targetId'];
      wishlist.removeWhere((w) => w['targetId'] == targetId);
      return _json({'success': true, 'data': wishlist});
    }
    return _json({'success': true, 'data': []});
  }

  ResponseBody _json(Map<String, dynamic> data, {int status = 200}) {
    return ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _LoggedInUserNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
        status: AuthStatus.authenticatedUser,
        userAccount: UserAccountModel(
          id: 'usr-user-1',
          name: 'Oliv Satoro',
          email: 'oliv@example.com',
          phone: '081234567890',
          points: 420,
        ),
        isInitialized: true,
      );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('UserCatalogRepository Unit Tests', () {
    late _CatalogFakeBackendAdapter adapter;
    late UserLocalStorage userStorage;
    late UserCatalogRepository repo;

    setUp(() async {
      adapter = _CatalogFakeBackendAdapter();
      userStorage = UserLocalStorage(
        kvStore: InMemoryKeyValueStore(),
        secureStore: InMemorySecureStore(),
      );
      await userStorage.saveToken('user-jwt-123');

      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000/api'))
        ..httpClientAdapter = adapter;
      final client = ApiClient(
        baseUrl: 'http://localhost:5000',
        scope: ApiScope.user,
        readToken: userStorage.getToken,
        dioOverride: dio,
      );
      repo = UserCatalogRepository(
        userApiClient: client,
        userStorage: userStorage,
      );
    });

    test('mengambil galeri, kategori, kostum, toggle like, wishlist, dan ulasan', () async {
      final galleries = await repo.fetchGalleries();
      expect(galleries, hasLength(2));
      expect(galleries.first.costumeId, 'costume-topeng');

      final likeResult = await repo.toggleGalleryLike('gal-1');
      expect(likeResult.isLiked, isTrue);
      expect(likeResult.likes, 359);

      final added = await repo.addToWishlist(
        targetId: 'gal-1',
        targetType: 'gallery',
      );
      expect(added, hasLength(1));
      expect(await userStorage.getWishlistIds(), ['gal-1']);

      final removed = await repo.removeFromWishlist('gal-1');
      expect(removed, isEmpty);
      expect(await userStorage.getWishlistIds(), isEmpty);

      final rev = await repo.submitReview(
        targetId: 'gal-1',
        targetType: 'gallery',
        rating: 5,
        comment: 'Sangat menginspirasi!',
      );
      expect(rev.comment, 'Sangat menginspirasi!');
    });
  });

  group('Fase 3 Screens & Flows Widget Tests', () {
    late _CatalogFakeBackendAdapter adapter;
    late InMemoryKeyValueStore kv;
    late InMemorySecureStore secure;
    late UserLocalStorage userStorage;
    late ApiClient userClient;

    setUp(() async {
      adapter = _CatalogFakeBackendAdapter();
      kv = InMemoryKeyValueStore();
      secure = InMemorySecureStore();
      userStorage = UserLocalStorage(kvStore: kv, secureStore: secure);
      await userStorage.saveToken('user-jwt-123');

      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000/api'))
        ..httpClientAdapter = adapter;
      userClient = ApiClient(
        baseUrl: 'http://localhost:5000',
        scope: ApiScope.user,
        readToken: userStorage.getToken,
        dioOverride: dio,
      );
    });

    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          keyValueStoreProvider.overrideWithValue(kv),
          secureStoreProvider.overrideWithValue(secure),
          userApiClientProvider.overrideWithValue(userClient),
          authProvider.overrideWith(_LoggedInUserNotifier.new),
        ],
      );
    }

    testWidgets('Beranda, Galeri (filter & detail), Ulasan, dan tombol Sewa Kostum Terkait meneruskan costumeId', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final container = createContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SriwedariApp(autoRestoreSession: false),
        ),
      );
      await tester.pumpAndSettle();

      // Beranda tampil personal
      expect(find.text('Halo, Oliv'), findsOneWidget);
      expect(find.text('420 Poin Budaya'), findsOneWidget);
      expect(find.text('Lestarikan Budaya Melalui Seni Tari'), findsOneWidget);

      // Navigasi ke Galeri
      container.read(appRouterProvider).go(AppRoutes.userGallery);
      await tester.pumpAndSettle();
      expect(find.text('Tari Topeng Malangan'), findsOneWidget);
      expect(find.text('Drama Tari Jawa Teatrikal'), findsOneWidget);

      // Filter Tari Kreasi
      final kreasiChip = find.widgetWithText(SwFilterChip, 'Tari Kreasi');
      await tester.ensureVisible(kreasiChip);
      await tester.tap(kreasiChip);
      await tester.pumpAndSettle();
      expect(find.text('Drama Tari Jawa Teatrikal'), findsOneWidget);
      expect(find.text('Tari Topeng Malangan'), findsNothing);

      // Kembalikan filter ke Semua lalu buka detail Tari Topeng Malangan
      final semuaChip = find.widgetWithText(SwFilterChip, 'Semua');
      await tester.ensureVisible(semuaChip);
      await tester.tap(semuaChip);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tari Topeng Malangan'));
      await tester.pumpAndSettle();

      expect(find.text('Informasi Galeri'), findsOneWidget);
      expect(find.text('Ulasan Budaya (1)'), findsOneWidget);
      expect(find.text('Sewa Kostum Terkait'), findsOneWidget);

      // Ketuk Sewa Kostum Terkait -> meneruskan costumeId=costume-topeng
      await tester.tap(find.text('Sewa Kostum Terkait'));
      await tester.pumpAndSettle();
      final uri = container.read(appRouterProvider).routeInformationProvider.value.uri;
      expect(uri.path, AppRoutes.userBooking);
      expect(uri.queryParameters['costumeId'], 'costume-topeng');
    });

    testWidgets('Katalog Kostum, Bottom Sheet Sewa, dan Halaman Edukasi (Tentang & Warta)', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final container = createContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SriwedariApp(autoRestoreSession: false),
        ),
      );
      await tester.pumpAndSettle();

      // Buka Katalog Kostum
      container.read(appRouterProvider).go(AppRoutes.userCostumes);
      await tester.pumpAndSettle();
      expect(find.text('Busana Ksatria Topeng Malangan'), findsOneWidget);
      expect(find.text('Busana Dodot Ageng Bedhaya Surakarta'), findsOneWidget);

      // Klik tombol Sewa pada kostum pertama -> buka CostumeRentalSheet
      await tester.tap(find.text('Sewa').first);
      await tester.pumpAndSettle();
      expect(find.text('Pilih Ukuran Busana'), findsOneWidget);
      expect(find.text('Pilih Durasi Sewa'), findsOneWidget);

      // Pilih 7 Hari lalu Lanjutkan ke Reservasi
      await tester.tap(find.text('7 Hari'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjutkan ke Reservasi'));
      await tester.pumpAndSettle();

      final uri = container.read(appRouterProvider).routeInformationProvider.value.uri;
      expect(uri.path, AppRoutes.userBooking);
      expect(uri.queryParameters['costumeId'], 'costume-topeng');
      expect(uri.queryParameters['days'], '7');

      // Buka Halaman Tentang, Sejarah, Kurator, dan Blog
      container.read(appRouterProvider).go(AppRoutes.about);
      await tester.pumpAndSettle();
      expect(find.text('Menjaga Napas Kebudayaan Keraton Surakarta'), findsOneWidget);

      container.read(appRouterProvider).go(AppRoutes.aboutHistory);
      await tester.pumpAndSettle();
      expect(find.text('Sejarah Panjang Taman Sriwedari (1899 – Sekarang)'), findsOneWidget);

      container.read(appRouterProvider).go(AppRoutes.aboutCurators);
      await tester.pumpAndSettle();
      expect(find.text('K.R.M. Sasangka Hadiningrat'), findsOneWidget);

      container.read(appRouterProvider).go(AppRoutes.blog);
      await tester.pumpAndSettle();
      expect(find.text('Filosofi Sembilan Penari dalam Sakralitas Tari Bedhaya Ketawang'), findsOneWidget);

      await tester.tap(find.text('Filosofi Sembilan Penari dalam Sakralitas Tari Bedhaya Ketawang'));
      await tester.pumpAndSettle();
      expect(find.text('Reservasi Sewa Busana'), findsOneWidget);
    });
  });
}

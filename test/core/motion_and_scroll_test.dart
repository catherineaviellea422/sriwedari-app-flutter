import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sriwedari_app/app.dart';
import 'package:sriwedari_app/core/motion/motion.dart';
import 'package:sriwedari_app/core/network/api_client.dart';
import 'package:sriwedari_app/core/providers/core_providers.dart';
import 'package:sriwedari_app/core/router/app_router.dart';
import 'package:sriwedari_app/core/router/app_routes.dart';
import 'package:sriwedari_app/core/storage/storage_backend.dart';
import 'package:sriwedari_app/core/storage/user_local_storage.dart';
import 'package:sriwedari_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sriwedari_app/features/user/domain/models/user_models.dart';

class _MotionHeroFakeBackendAdapter implements HttpClientAdapter {
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
  ];

  final List<Map<String, dynamic>> categories = [
    {
      'id': 'cat-1',
      'name': 'Tari Tradisional',
      'icon': 'theater_comedy',
      'description': 'Pakem keraton',
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

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    if (path.endsWith('/user/galleries')) {
      return _json({'success': true, 'data': galleries});
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

class _MotionUserAuthNotifier extends AuthNotifier {
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

  group('Motion Kit & Smooth Scroll Unit/Widget Tests', () {
    test('SwScrollBehavior mendukung perangkat drag Web/Mobile & padding sliver', () {
      const behavior = SwScrollBehavior();
      expect(
        behavior.dragDevices,
        containsAll([
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        ]),
      );

      expect(
        centeredSliverHorizontalPadding(
          390,
          horizontalMargin: 16,
          maxContentWidth: 1200,
        ),
        16,
      );
      expect(
        centeredSliverHorizontalPadding(
          1280,
          horizontalMargin: 32,
          maxContentWidth: 1200,
        ),
        72,
      );
    });

    testWidgets(
      'ScaleOnTap menekan tanpa memblokir tap callback & hormati disableAnimations',
      (tester) async {
        var tapped = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: false),
              child: Scaffold(
                body: Center(
                  child: ScaleOnTap(
                    child: ElevatedButton(
                      onPressed: () => tapped++,
                      child: const Text('Tekan Saya'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.text('Tekan Saya')),
        );
        await tester.pump(const Duration(milliseconds: 80));

        final scaleWidget = tester.widget<AnimatedScale>(
          find.byType(AnimatedScale),
        );
        expect(scaleWidget.scale, lessThan(1.0));

        await gesture.up();
        await tester.pumpAndSettle();

        expect(tapped, 1);
        final restored = tester.widget<AnimatedScale>(
          find.byType(AnimatedScale),
        );
        expect(restored.scale, 1.0);
      },
    );

    testWidgets(
      'FadeSlideEntrance hormati disableAnimations=true dan tidak replay saat onceKey tersimpan',
      (tester) async {
        // 1. Mode disableAnimations=true langsung muncul penuh tanpa jeda
        await tester.pumpWidget(
          const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: FadeSlideEntrance(
                  index: 4,
                  child: Text('Aksesibilitas Aktif'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Aksesibilitas Aktif'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(FadeSlideEntrance),
            matching: find.byType(Opacity),
          ),
          findsNothing,
        );

        // 2. Dengan onceKey & PageStorage: animasi aktif saat pertama kali muncul,
        // lalu remount berikutnya di bucket yang sama langsung render final tanpa replay.
        final bucket = PageStorageBucket();
        await tester.pumpWidget(
          MaterialApp(
            home: PageStorage(
              bucket: bucket,
              child: const Scaffold(
                body: FadeSlideEntrance(
                  onceKey: 'card_once_1',
                  child: Text('Kartu Pertama'),
                ),
              ),
            ),
          ),
        );
        expect(
          find.descendant(
            of: find.byType(FadeSlideEntrance),
            matching: find.byType(Opacity),
          ),
          findsOneWidget,
        );
        await tester.pumpAndSettle();

        // Unmount lalu mount ulang pada bucket PageStorage yang sama
        await tester.pumpWidget(
          MaterialApp(
            home: PageStorage(
              bucket: bucket,
              child: const Scaffold(body: SizedBox.shrink()),
            ),
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: PageStorage(
              bucket: bucket,
              child: const Scaffold(
                body: FadeSlideEntrance(
                  key: ValueKey('remounted'),
                  onceKey: 'card_once_1',
                  child: Text('Kartu Pertama'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Kartu Pertama'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(FadeSlideEntrance),
            matching: find.byType(Opacity),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('SwAnimatedExpand menganimasikan tinggi konten dengan halus', (
      tester,
    ) async {
      var expanded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Column(
                children: [
                  TextButton(
                    onPressed: () => setState(() => expanded = !expanded),
                    child: const Text('Toggle'),
                  ),
                  SwAnimatedExpand(
                    child: expanded
                        ? const SizedBox(key: ValueKey('box'), height: 80)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(SwAnimatedExpand)).height, 0);

      await tester.tap(find.text('Toggle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final midHeight = tester.getSize(find.byType(SwAnimatedExpand)).height;
      expect(midHeight, greaterThan(0));
      expect(midHeight, lessThan(80));

      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(SwAnimatedExpand)).height, 80);
    });

    testWidgets(
      'Navigasi Hero Dashboard -> GaleriDetail, GaleriList -> GaleriDetail, dan Kostum -> KostumDetail bebas tag collision (390x844 & 1280x800)',
      (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        final adapter = _MotionHeroFakeBackendAdapter();
        final kv = InMemoryKeyValueStore();
        final secure = InMemorySecureStore();
        final userStorage = UserLocalStorage(kvStore: kv, secureStore: secure);
        await userStorage.saveToken('user-jwt-123');

        final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000/api'))
          ..httpClientAdapter = adapter;
        final client = ApiClient(
          baseUrl: 'http://localhost:5000',
          scope: ApiScope.user,
          readToken: userStorage.getToken,
          dioOverride: dio,
        );

        final container = ProviderContainer(
          overrides: [
            keyValueStoreProvider.overrideWithValue(kv),
            secureStoreProvider.overrideWithValue(secure),
            userApiClientProvider.overrideWithValue(client),
            authProvider.overrideWith(_MotionUserAuthNotifier.new),
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

        // Pastikan Dashboard sudah ter-render sebelum uji navigasi Hero
        expect(find.text('Halo, Oliv'), findsOneWidget);

        // 1. Dashboard -> GalleryDetail (Hero dash-gal-gal-1)
        final galFinder = find.text('Tari Topeng Malangan');
        await tester.scrollUntilVisible(
          galFinder,
          250,
          scrollable: find
              .descendant(
                of: find.byType(CustomScrollView).first,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(galFinder.first);
        await tester.pumpAndSettle();
        expect(find.text('Informasi Galeri'), findsOneWidget);
        expect(find.byType(Hero), findsWidgets);
        expect(tester.takeException(), isNull);

        // Kembali ke shell
        container.read(appRouterProvider).pop();
        await tester.pumpAndSettle();

        // 2. Pindah tab Galeri sementara Dashboard tetap hidup di IndexedStack -> tap Hero list-gal-gal-1
        container.read(appRouterProvider).go(AppRoutes.userGallery);
        await tester.pumpAndSettle();
        await tester.tap(galFinder.last);
        await tester.pumpAndSettle();
        expect(find.text('Informasi Galeri'), findsOneWidget);
        expect(find.byType(Hero), findsWidgets);
        expect(tester.takeException(), isNull);

        container.read(appRouterProvider).pop();
        await tester.pumpAndSettle();

        // 3. Resize ke Desktop 1280x800 lalu KostumCatalog -> CostumeDetail (Hero list-cos-costume-topeng)
        tester.view.physicalSize = const Size(1280, 800);
        container.read(appRouterProvider).go(AppRoutes.userCostumes);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Busana Ksatria Topeng Malangan').last);
        await tester.pumpAndSettle();
        expect(find.text('Pilih Ukuran & Sewa Sekarang'), findsOneWidget);
        expect(find.byType(Hero), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

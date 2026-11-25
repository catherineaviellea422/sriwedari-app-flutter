import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sriwedari_app/core/config/app_config.dart';
import 'package:sriwedari_app/core/network/api_client.dart';
import 'package:sriwedari_app/core/network/api_exception.dart';
import 'package:sriwedari_app/core/theme/app_spacing.dart';
import 'package:sriwedari_app/core/utils/currency_formatter.dart';
import 'package:sriwedari_app/core/utils/date_formatter.dart';
import 'package:sriwedari_app/core/utils/validators.dart';

class _StubHttpAdapter implements HttpClientAdapter {
  _StubHttpAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  RequestOptions? lastRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return handler(options);
  }
}

void main() {
  group('ApiClient & Scope Isolation', () {
    test('menyisipkan Bearer token dan header scope sesuai peran', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000/api'));
      final adapter = _StubHttpAdapter((_) {
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'data': []}),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });
      dio.httpClientAdapter = adapter;

      final userClient = ApiClient(
        baseUrl: 'http://localhost:5000',
        scope: ApiScope.user,
        readToken: () async => 'token-user-abc',
        dioOverride: dio,
      );

      final res = await userClient.get('/user/galleries');
      expect(res['success'], isTrue);
      expect(adapter.lastRequest?.headers['Authorization'], 'Bearer token-user-abc');
      expect(adapter.lastRequest?.headers['X-Sriwedari-Scope'], 'user');
      expect(userClient.scopePrefix, '/user');
    });

    test('memicu callback onUnauthorized saat menerima HTTP 401', () async {
      var unauthorizedCalled = false;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000/api'));
      dio.httpClientAdapter = _StubHttpAdapter((_) {
        return ResponseBody.fromString(
          jsonEncode({'success': false, 'error': 'Sesi kedaluwarsa'}),
          401,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      final adminClient = ApiClient(
        baseUrl: 'http://localhost:5000',
        scope: ApiScope.admin,
        readToken: () async => 'expired-admin-token',
        onUnauthorized: () async {
          unauthorizedCalled = true;
        },
        dioOverride: dio,
      );

      await expectLater(
        adminClient.get('/admin/analytics'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', 'Sesi kedaluwarsa'),
        ),
      );
      expect(unauthorizedCalled, isTrue);
    });
  });

  group('Formatters, Validators, AssetResolver & ResponsiveHelper', () {
    test('CurrencyFormatter memformat rupiah dengan benar', () {
      expect(CurrencyFormatter.formatRupiah(100000), 'Rp 100.000');
      expect(CurrencyFormatter.formatRupiah(300000), 'Rp 300.000');
      expect(CurrencyFormatter.formatCompactRupiah(2500000), 'Rp 2.5 Jt');
    });

    test('DateFormatter memformat tanggal Indonesia', () {
      expect(DateFormatter.formatShortDate('2026-10-31'), '31 Okt 2026');
      expect(DateFormatter.formatFullDate('2026-01-05'), '5 Januari 2026');
      final badge = DateFormatter.splitBadgeDate('2026-09-26');
      expect(badge.day, '26');
      expect(badge.month, 'Sep');
      expect(badge.year, '2026');
    });

    test('SwValidators & SwInputFormatters memvalidasi nama, tanggal, angka, email, telepon, dan password', () {
      expect(SwValidators.email('oliv@example.com'), isNull);
      expect(SwValidators.email('bukan-email'), isNotNull);
      expect(SwValidators.phoneId('081234567890'), isNull);
      expect(SwValidators.phoneId('12345'), isNotNull);
      expect(SwValidators.phoneId('0812abcd90'), isNotNull);
      expect(SwValidators.password('123456'), isNull);
      expect(SwValidators.password('123'), isNotNull);

      expect(SwValidators.personName('Oliv Satoro'), isNull);
      expect(SwValidators.personName('K.R.M. Sasangka'), isNull);
      expect(SwValidators.personName('Oliv 123'), isNotNull);
      expect(SwValidators.personName('123456'), isNotNull);
      expect(SwValidators.personName('A'), isNotNull);

      expect(SwValidators.isoDate('2026-11-30'), isNull);
      expect(SwValidators.isoDate('abcdef'), isNotNull);
      expect(SwValidators.isoDate('2026-02-31'), isNotNull);

      expect(SwValidators.otpCode('123456'), isNull);
      expect(SwValidators.otpCode('12ab56'), isNotNull);

      expect(SwValidators.intRange('50', fieldName: 'Diskon', min: 1, max: 100), isNull);
      expect(SwValidators.intRange('150', fieldName: 'Diskon', min: 1, max: 100), isNotNull);
    });

    test('AssetResolver mengenali aset gambar lokal vs upload server', () {
      expect(
        AssetResolver.resolveLocalAsset('/images/tari-gandrung-banyuwangi.png'),
        'assets/images/tari-gandrung-banyuwangi.png',
      );
      expect(AssetResolver.resolveLocalAsset('/uploads/slip-123.png'), isNull);
      expect(
        AssetResolver.resolveNetworkUrl('/uploads/slip-123.png', 'http://localhost:5000/'),
        'http://localhost:5000/uploads/slip-123.png',
      );
    });

    test('ResponsiveHelper mengklasifikasikan breakpoint dengan benar', () {
      expect(ResponsiveHelper.classifyWidth(390), WindowSizeClass.compact);
      expect(ResponsiveHelper.classifyWidth(768), WindowSizeClass.medium);
      expect(ResponsiveHelper.classifyWidth(1280), WindowSizeClass.expanded);
      expect(ResponsiveHelper.galleryColumnsForWidth(390), 2);
      expect(ResponsiveHelper.galleryColumnsForWidth(800), 3);
      expect(ResponsiveHelper.galleryColumnsForWidth(1280), 4);
    });
  });
}

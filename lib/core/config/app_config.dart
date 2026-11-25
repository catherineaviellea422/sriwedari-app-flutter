import 'package:flutter/foundation.dart';

enum AppFlavor { dev, staging, prod }

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.baseUrl,
    required this.appName,
  });

  final AppFlavor flavor;
  final String baseUrl;
  final String appName;

  bool get isDev => flavor == AppFlavor.dev;
  bool get showDemoShortcuts => flavor != AppFlavor.prod;

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _envFlavor = String.fromEnvironment('APP_FLAVOR', defaultValue: 'dev');

  factory AppConfig.fromEnvironment() {
    final flavor = switch (_envFlavor.toLowerCase()) {
      'prod' || 'production' => AppFlavor.prod,
      'staging' => AppFlavor.staging,
      _ => AppFlavor.dev,
    };

    final resolvedBaseUrl = _envBaseUrl.isNotEmpty
        ? _envBaseUrl
        : _defaultBaseUrlForPlatform(flavor);

    return AppConfig(
      flavor: flavor,
      baseUrl: resolvedBaseUrl,
      appName: 'Galeri Sriwedari',
    );
  }

  static String _defaultBaseUrlForPlatform(AppFlavor flavor) {
    if (flavor == AppFlavor.prod) {
      return 'https://api.galerisriwedari.id';
    }
    if (flavor == AppFlavor.staging) {
      return 'https://staging-api.galerisriwedari.id';
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }
}

class AppConstants {
  const AppConstants._();

  static const int defaultDepositFee = 100000;
  static const int maxTicketPerOrder = 5;
  static const int defaultHoldDurationMinutes = 1440;
  static const String heritageLogoAsset = 'assets/images/logo-sriwedari.png';
  static const String defaultReceiptAsset = 'assets/images/sample-receipt.png';
}

class AssetResolver {
  const AssetResolver._();

  static const Set<String> _bundledImageNames = {
    'logo-sriwedari.png',
    'reog-ponorogo.png',
    'sample-receipt.png',
    'tari-gandrung-banyuwangi.png',
    'tari-jawa-dramatic-stage.png',
    'tari-jawa-stage.png',
    'tari-kecak.png',
    'tari-ketubun-ritual-1.png',
    'tari-ketubun-ritual-2.png',
    'tari-kipas.png',
    'tari-topeng-malangan.png',
  };

  /// Mengembalikan path asset lokal jika cocok dengan gambar bawaan,
  /// atau null jika harus dimuat sebagai URL jaringan.
  static String? resolveLocalAsset(String rawPath) {
    if (rawPath.isEmpty) return null;
    if (rawPath.startsWith('assets/')) return rawPath;
    final clean = rawPath.split('?').first;
    final fileName = clean.split('/').last;
    if (_bundledImageNames.contains(fileName)) {
      return 'assets/images/$fileName';
    }
    return null;
  }

  /// Mengubah path relatif `/uploads/...` menjadi URL penuh backend.
  static String resolveNetworkUrl(String rawPath, String baseUrl) {
    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return rawPath;
    }
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = rawPath.startsWith('/') ? rawPath : '/$rawPath';
    return '$normalizedBase$normalizedPath';
  }
}

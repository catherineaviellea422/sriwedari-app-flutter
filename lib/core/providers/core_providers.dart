import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../storage/admin_local_storage.dart';
import '../storage/storage_backend.dart';
import '../storage/user_local_storage.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

/// Di-override pada `main.dart` menggunakan `SharedPrefsKeyValueStore(prefs)`.
/// Default in-memory aman untuk widget test tanpa setup SharedPreferences manual.
final keyValueStoreProvider = Provider<KeyValueStore>((ref) {
  return InMemoryKeyValueStore();
});

final secureStoreProvider = Provider<SecureStore>((ref) {
  return FlutterSecureStoreAdapter(
    const FlutterSecureStorage(),
    ref.watch(keyValueStoreProvider),
  );
});

final userLocalStorageProvider = Provider<UserLocalStorage>((ref) {
  return UserLocalStorage(
    kvStore: ref.watch(keyValueStoreProvider),
    secureStore: ref.watch(secureStoreProvider),
  );
});

final adminLocalStorageProvider = Provider<AdminLocalStorage>((ref) {
  return AdminLocalStorage(
    kvStore: ref.watch(keyValueStoreProvider),
    secureStore: ref.watch(secureStoreProvider),
  );
});

/// Counter event ketika menerima HTTP 401 dari server agar [AuthNotifier]
/// otomatis membersihkan sesi dan mengarahkan pengguna ke halaman login.
class SessionExpiredSignalNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void trigger() {
    state = state + 1;
  }
}

final sessionExpiredSignalProvider =
    NotifierProvider<SessionExpiredSignalNotifier, int>(
  SessionExpiredSignalNotifier.new,
);

final userApiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final userStorage = ref.watch(userLocalStorageProvider);
  return ApiClient(
    baseUrl: config.baseUrl,
    scope: ApiScope.user,
    readToken: userStorage.getToken,
    onUnauthorized: () async {
      await userStorage.clearSession();
      ref.read(sessionExpiredSignalProvider.notifier).trigger();
    },
  );
});

final adminApiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final adminStorage = ref.watch(adminLocalStorageProvider);
  return ApiClient(
    baseUrl: config.baseUrl,
    scope: ApiScope.admin,
    readToken: adminStorage.getToken,
    onUnauthorized: () async {
      await adminStorage.clearSession();
      ref.read(sessionExpiredSignalProvider.notifier).trigger();
    },
  );
});

import 'dart:convert';
import 'storage_backend.dart';

/// Penyimpanan lokal TERISOLASI khusus untuk sisi Pengguna (role: user).
/// Seluruh key memakai prefix `sriwedari_user_store::` agar tidak pernah
/// bercampur dengan `AdminLocalStorage`.
class UserLocalStorage {
  UserLocalStorage({
    required KeyValueStore kvStore,
    required SecureStore secureStore,
  })  : _kv = kvStore,
        _secure = secureStore;

  static const String namespace = 'sriwedari_user_store::';

  static const String _keyToken = '${namespace}auth_token';
  static const String _keyProfileJson = '${namespace}user_profile_json';
  static const String _keyWishlistIds = '${namespace}wishlist_ids';
  static const String _keyBookingDraftJson = '${namespace}booking_draft_json';
  static const String _keyOfflineTicketsJson = '${namespace}offline_tickets_json';
  static const String _keyRecentSearches = '${namespace}recent_searches';
  static const String _keyRememberMe = '${namespace}remember_me';
  static const String _keyLastSyncAt = '${namespace}last_sync_at';

  final KeyValueStore _kv;
  final SecureStore _secure;

  Future<String?> getToken() => _secure.read(_keyToken);

  Future<void> saveToken(String token) => _secure.write(_keyToken, token);

  Future<void> deleteToken() => _secure.delete(_keyToken);

  Future<Map<String, dynamic>?> getUserProfileJson() async {
    final raw = await _kv.getString(_keyProfileJson);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<void> saveUserProfileJson(Map<String, dynamic> profile) {
    return _kv.setString(_keyProfileJson, jsonEncode(profile));
  }

  Future<List<String>> getWishlistIds() async {
    return (await _kv.getStringList(_keyWishlistIds)) ?? const [];
  }

  Future<void> saveWishlistIds(List<String> ids) {
    return _kv.setStringList(_keyWishlistIds, ids.toSet().toList());
  }

  Future<Map<String, dynamic>?> getBookingDraftJson() async {
    final raw = await _kv.getString(_keyBookingDraftJson);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<void> saveBookingDraftJson(Map<String, dynamic> draft) {
    return _kv.setString(_keyBookingDraftJson, jsonEncode(draft));
  }

  Future<void> clearBookingDraft() => _kv.remove(_keyBookingDraftJson);

  Future<List<Map<String, dynamic>>> getOfflineTicketsJson() async {
    final raw = await _kv.getString(_keyOfflineTicketsJson);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  Future<void> saveOfflineTicketsJson(List<Map<String, dynamic>> tickets) {
    return _kv.setString(_keyOfflineTicketsJson, jsonEncode(tickets));
  }

  Future<List<String>> getRecentSearches() async {
    return (await _kv.getStringList(_keyRecentSearches)) ?? const [];
  }

  Future<void> addRecentSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;
    final existing = await getRecentSearches();
    final updated = [clean, ...existing.where((e) => e != clean)].take(8).toList();
    await _kv.setStringList(_keyRecentSearches, updated);
  }

  Future<bool> getRememberMe() async => (await _kv.getBool(_keyRememberMe)) ?? false;

  Future<void> setRememberMe(bool value) => _kv.setBool(_keyRememberMe, value);

  Future<String?> getLastSyncAt() => _kv.getString(_keyLastSyncAt);

  Future<void> setLastSyncAt(String isoTimestamp) =>
      _kv.setString(_keyLastSyncAt, isoTimestamp);

  Future<void> clearSession() async {
    await deleteToken();
    await _kv.remove(_keyProfileJson);
  }

  /// Menghapus seluruh data di namespace User tanpa menyentuh namespace Admin.
  Future<void> clearAll() async {
    await deleteToken();
    final keys = await _kv.getKeys();
    for (final key in keys) {
      if (key.startsWith(namespace)) {
        await _kv.remove(key);
      }
    }
  }
}

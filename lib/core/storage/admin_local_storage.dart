import 'dart:convert';
import 'storage_backend.dart';

/// Penyimpanan lokal TERISOLASI khusus untuk sisi Kurator/Admin (role: admin).
/// Seluruh key memakai prefix `sriwedari_admin_store::` agar terpisah total
/// dari `UserLocalStorage`.
class AdminLocalStorage {
  AdminLocalStorage({
    required KeyValueStore kvStore,
    required SecureStore secureStore,
  })  : _kv = kvStore,
        _secure = secureStore;

  static const String namespace = 'sriwedari_admin_store::';

  static const String _keyToken = '${namespace}auth_token';
  static const String _keyProfileJson = '${namespace}admin_profile_json';
  static const String _keyAnalyticsCacheJson = '${namespace}analytics_cache_json';
  static const String _keyOrderFilterStatus = '${namespace}order_filter_status';
  static const String _keySelectedPosEventId = '${namespace}selected_pos_event_id';
  static const String _keyGateScanHistoryJson = '${namespace}gate_scan_history_json';
  static const String _keyLastSyncAt = '${namespace}last_sync_at';

  final KeyValueStore _kv;
  final SecureStore _secure;

  Future<String?> getToken() => _secure.read(_keyToken);

  Future<void> saveToken(String token) => _secure.write(_keyToken, token);

  Future<void> deleteToken() => _secure.delete(_keyToken);

  Future<Map<String, dynamic>?> getAdminProfileJson() async {
    final raw = await _kv.getString(_keyProfileJson);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<void> saveAdminProfileJson(Map<String, dynamic> profile) {
    return _kv.setString(_keyProfileJson, jsonEncode(profile));
  }

  Future<Map<String, dynamic>?> getAnalyticsCacheJson() async {
    final raw = await _kv.getString(_keyAnalyticsCacheJson);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<void> saveAnalyticsCacheJson(Map<String, dynamic> analytics) {
    return _kv.setString(_keyAnalyticsCacheJson, jsonEncode(analytics));
  }

  Future<String?> getOrderFilterStatus() => _kv.getString(_keyOrderFilterStatus);

  Future<void> setOrderFilterStatus(String status) =>
      _kv.setString(_keyOrderFilterStatus, status);

  Future<String?> getSelectedPosEventId() => _kv.getString(_keySelectedPosEventId);

  Future<void> setSelectedPosEventId(String eventId) =>
      _kv.setString(_keySelectedPosEventId, eventId);

  Future<List<Map<String, dynamic>>> getGateScanHistoryJson() async {
    final raw = await _kv.getString(_keyGateScanHistoryJson);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  Future<void> appendGateScanHistoryJson(Map<String, dynamic> entry) async {
    final existing = await getGateScanHistoryJson();
    final updated = [entry, ...existing].take(30).toList();
    await _kv.setString(_keyGateScanHistoryJson, jsonEncode(updated));
  }

  Future<String?> getLastSyncAt() => _kv.getString(_keyLastSyncAt);

  Future<void> setLastSyncAt(String isoTimestamp) =>
      _kv.setString(_keyLastSyncAt, isoTimestamp);

  Future<void> clearSession() async {
    await deleteToken();
    await _kv.remove(_keyProfileJson);
  }

  /// Menghapus seluruh data di namespace Admin tanpa menyentuh namespace User.
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

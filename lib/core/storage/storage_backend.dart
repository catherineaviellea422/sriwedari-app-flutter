import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class KeyValueStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<List<String>?> getStringList(String key);
  Future<void> setStringList(String key, List<String> value);
  Future<bool?> getBool(String key);
  Future<void> setBool(String key, bool value);
  Future<void> remove(String key);
  Future<Set<String>> getKeys();
}

abstract class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SharedPrefsKeyValueStore implements KeyValueStore {
  SharedPrefsKeyValueStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<bool?> getBool(String key) async => _prefs.getBool(key);

  @override
  Future<Set<String>> getKeys() async => _prefs.getKeys();

  @override
  Future<String?> getString(String key) async => _prefs.getString(key);

  @override
  Future<List<String>?> getStringList(String key) async =>
      _prefs.getStringList(key);

  @override
  Future<void> remove(String key) async => _prefs.remove(key);

  @override
  Future<void> setBool(String key, bool value) async =>
      _prefs.setBool(key, value);

  @override
  Future<void> setString(String key, String value) async =>
      _prefs.setString(key, value);

  @override
  Future<void> setStringList(String key, List<String> value) async =>
      _prefs.setStringList(key, value);
}

class FlutterSecureStoreAdapter implements SecureStore {
  FlutterSecureStoreAdapter([
    this._storage = const FlutterSecureStorage(),
    this._fallbackKv,
  ]);

  final FlutterSecureStorage _storage;
  final KeyValueStore? _fallbackKv;
  final Map<String, String> _memoryFallback = {};

  static const String _fallbackPrefix = 'sw_web_fallback::';

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      _memoryFallback.remove(key);
      await _fallbackKv?.remove('$_fallbackPrefix$key');
    }
  }

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return _memoryFallback[key] ??
          await _fallbackKv?.getString('$_fallbackPrefix$key');
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      _memoryFallback[key] = value;
      await _fallbackKv?.setString('$_fallbackPrefix$key', value);
    }
  }
}

/// Implementasi in-memory untuk keperluan unit test & fallback.
class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, Object> _data = {};

  @override
  Future<bool?> getBool(String key) async {
    final val = _data[key];
    return val is bool ? val : null;
  }

  @override
  Future<Set<String>> getKeys() async => _data.keys.toSet();

  @override
  Future<String?> getString(String key) async {
    final val = _data[key];
    return val is String ? val : null;
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    final val = _data[key];
    return val is List<String> ? List<String>.from(val) : null;
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    _data[key] = value;
  }

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    _data[key] = List<String>.from(value);
  }
}

class InMemorySecureStore implements SecureStore {
  final Map<String, String> _data = {};

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }
}

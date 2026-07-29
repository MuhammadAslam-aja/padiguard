import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> write(String key, String value) async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sec_$key', value);
      } catch (e) {
        debugPrint('SharedPreferences write error: $e');
      }
    }
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('SecureStorage write error: $e');
    }
  }

  Future<String?> read(String key) async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final val = prefs.getString('sec_$key');
        if (val != null && val.isNotEmpty) return val;
      } catch (_) {}
    }
    try {
      final val = await _storage.read(key: key);
      if (val != null) return val;
    } catch (e) {
      debugPrint('SecureStorage read error: $e');
    }
    return null;
  }

  Future<void> delete(String key) async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('sec_$key');
      } catch (_) {}
    }
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  Future<void> deleteAll() async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys().where((k) => k.startsWith('sec_')).toList();
        for (final k in keys) {
          await prefs.remove(k);
        }
      } catch (_) {}
    }
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}

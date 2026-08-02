import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight key-value persistence (prefs): cart cache, onboarding flags,
/// last-known role, etc. Distinct from [TokenStorage] — nothing sensitive here.
class LocalStore {
  final SharedPreferences _prefs;

  LocalStore(this._prefs);

  static Future<LocalStore> init() async => LocalStore(await SharedPreferences.getInstance());

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  bool getBool(String key, {bool defaultValue = false}) => _prefs.getBool(key) ?? defaultValue;
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  String? getStringListKey(String key) => _prefs.getString(key);
}

final localStoreProvider = FutureProvider<LocalStore>((ref) => LocalStore.init());

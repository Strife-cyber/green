import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';

/// Current app locale, persisted across restarts. Defaults to the device
/// locale when it is en/fr, otherwise English.
final localeControllerProvider =
    NotifierProvider<LocaleController, AppLocale>(LocaleController.new);

class LocaleController extends Notifier<AppLocale> {
  static const _kPrefKey = 'app.locale';

  @override
  AppLocale build() {
    final device = _deviceLocale();
    LocaleSettings.setLocale(device);
    _applySavedPreference();
    return device;
  }

  void setLocale(AppLocale locale) {
    state = locale;
    LocaleSettings.setLocale(locale);
    _persist(locale.languageCode);
  }

  /// Applies a previously saved preference once SharedPreferences is ready
  /// (cached instance from `main()`), so the app bootstraps on the device
  /// locale and then switches to the user's choice.
  Future<void> _applySavedPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kPrefKey);
      if (saved == null) return;
      final locale = L10n.fromLanguageCode(saved);
      if (locale != state) {
        state = locale;
        LocaleSettings.setLocale(locale);
      }
    } catch (_) {
      // Best-effort; fall back to the device locale.
    }
  }

  AppLocale _deviceLocale() {
    final code = PlatformDispatcher.instance.locale.languageCode;
    return L10n.fromLanguageCode(code);
  }

  Future<void> _persist(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefKey, code);
    } catch (_) {
      // Persistence is best-effort.
    }
  }
}

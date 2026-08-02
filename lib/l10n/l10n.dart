import 'package:flutter/material.dart';

import 'generated/strings.g.dart';

export 'generated/strings.g.dart';

/// Supported locales for the app.
///
/// Used by `MaterialApp.supportedLocales`. Slang (see `slang.yaml`) generates
/// the [AppLocale] enum + [Translations] from `lib/l10n/app_*.arb`.
class L10n {
  /// Locale files available (en, fr).
  static const List<AppLocale> supportedLocales = AppLocale.values;

  /// Flutter [Locale] objects for `MaterialApp.supportedLocales`.
  static List<Locale> get flutterLocales =>
      AppLocale.values.map((e) => e.flutterLocale).toList();

  /// Resolves a raw language code to an [AppLocale], defaulting to English.
  static AppLocale fromLanguageCode(String? code) => AppLocale.values.firstWhere(
        (l) => l.languageCode == code,
        orElse: () => AppLocale.en,
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/i18n/locale_controller.dart';
import 'core/router/app_router.dart';
import 'l10n/l10n.dart';
import 'theme/app_theme.dart';

/// Root widget: wires the brand themes, the go_router instance and slang
/// localization (English + French).
class GreenApp extends ConsumerWidget {
  const GreenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeControllerProvider);
    return TranslationProvider(
      child: MaterialApp.router(
        title: 'Trendy Green',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        locale: locale.flutterLocale,
        supportedLocales: L10n.flutterLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
  }
}

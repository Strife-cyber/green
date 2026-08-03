import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/i18n/locale_controller.dart';
import 'core/notifications/push_service.dart';
import 'core/router/app_router.dart';
import 'data/models/enums.dart';
import 'data/repositories/providers.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'l10n/l10n.dart';
import 'theme/app_theme.dart';

/// Root widget: wires the brand themes, the go_router instance, slang
/// localization (English + French) and the FCM push bridge.
class GreenApp extends ConsumerWidget {
  const GreenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeControllerProvider);

    // Push wiring (idempotent; no-ops unless Firebase was initialized in main).
    PushService.instance
      ..attach(ref.read(deviceTokenRepositoryProvider))
      ..onDeepLink = () => _onDeepLink(ref);

    // Register the FCM token once the session is restored / logged in, and
    // dispatch any deep link that arrived before auth was known.
    ref.listen<AsyncValue<AuthState>>(authControllerProvider, (_, next) {
      final user = next.valueOrNull?.user;
      if (user == null) return;
      PushService.instance.registerToken();
      _dispatchPendingDeepLink(ref, user.role);
    });

    return TranslationProvider(
      child: MaterialApp.router(
        title: 'Trendy Green',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: PushService.instance.scaffoldMessengerKey,
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

  /// A notification was tapped (banner, background open or cold start). The
  /// payload is buffered in [PushService]; only dispatch once auth is known.
  void _onDeepLink(WidgetRef ref) {
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    if (user == null) return;
    _dispatchPendingDeepLink(ref, user.role);
  }

  void _dispatchPendingDeepLink(WidgetRef ref, UserRole role) {
    final path = PushService.instance.pendingDeepLink(role);
    if (path == null) return;
    // The router may not have built its first frame yet — navigate post-frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routerProvider).push(path);
    });
  }
}

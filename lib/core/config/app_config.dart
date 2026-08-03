import 'package:flutter/foundation.dart';

/// Which backend the app talks to. Selected at compile/run time with
/// `--dart-define=APP_ENV=local|staging|production` (defaults to `local`).
enum AppEnvironment { local, staging, production }

/// Central app configuration — the Green equivalent of the reference app's
/// `AppConfig`: one place that resolves the API/socket base URLs and feature
/// flags per environment.
///
/// Usage:
/// - `flutter run`                                → local (platform-aware host)
/// - `flutter run --dart-define=APP_ENV=staging`  → staging
/// - `flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000` → any
///   backend (e.g. a physical device talking to your machine's LAN IP)
abstract final class AppConfig {
  static const String _envName = String.fromEnvironment('APP_ENV', defaultValue: 'local');

  /// Selected environment (compile-time, via `--dart-define=APP_ENV=…`).
  static AppEnvironment get environment => switch (_envName) {
        'production' => AppEnvironment.production,
        'staging' => AppEnvironment.staging,
        _ => AppEnvironment.local,
      };

  /// Base URL of the API. An explicit `--dart-define=API_BASE_URL=…` always
  /// wins; otherwise each environment has its own URL, and `local` is
  /// platform-aware so a phone/emulator can reach your dev machine.
  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    return switch (environment) {
      AppEnvironment.production => 'https://api.greenish.cm',
      AppEnvironment.staging => 'https://api-staging.greenish.cm',
      AppEnvironment.local => localHost,
    };
  }

  /// WebSocket / socket.io base — the same host as the API (no extra path).
  static String get wsBaseUrl => apiBaseUrl;

  /// The local backend host: the Android emulator reaches the host machine via
  /// `10.0.2.2`; the iOS simulator, desktop and web all use `localhost`. A
  /// physical device must set `API_BASE_URL` to the machine's LAN IP.
  static String get localHost {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  static bool get isLocal => environment == AppEnvironment.local;
  static bool get isStaging => environment == AppEnvironment.staging;
  static bool get isProduction => environment == AppEnvironment.production;
}

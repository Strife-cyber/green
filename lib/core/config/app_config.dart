import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Which backend the app talks to. Selected at runtime from the `.env` file
/// (`APP_ENV=local|staging|production`, auto-loaded by flutter_dotenv), or
/// overridable at build time with `--dart-define=APP_ENV=…` which wins.
enum AppEnvironment { local, staging, production }

/// Central app configuration — the Green equivalent of the reference app's
/// `AppConfig`: one place that resolves the API/socket base URLs and feature
/// flags per environment.
///
/// Precedence for every value: an explicit `--dart-define` first, then the
/// `.env` file (loaded in `main()` via `dotenv.load`), then the default.
/// - `flutter run`                                → reads `.env` (default `local`)
/// - `--dart-define=APP_ENV=staging`              → staging, ignoring `.env`
/// - `--dart-define=API_BASE_URL=http://192.168.1.20:3000` → any backend
abstract final class AppConfig {
  /// `APP_ENV`: dart-define > `.env` > `local`.
  static String get _envName {
    const fromDefine = String.fromEnvironment('APP_ENV', defaultValue: '');
    if (fromDefine.isNotEmpty) return fromDefine;
    final fromDotEnv = dotenv.maybeGet('APP_ENV');
    return (fromDotEnv == null || fromDotEnv.isEmpty) ? 'local' : fromDotEnv;
  }

  /// Selected environment (from `.env`, or `--dart-define=APP_ENV=…`).
  static AppEnvironment get environment => switch (_envName) {
        'production' => AppEnvironment.production,
        'staging' => AppEnvironment.staging,
        _ => AppEnvironment.local,
      };

  /// Base URL of the API. An explicit `--dart-define=API_BASE_URL=…` or the
  /// `.env` `API_BASE_URL` always wins; otherwise each environment has its own
  /// URL, and `local` is platform-aware so a phone/emulator can reach your dev
  /// machine.
  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    final fromDotEnv = dotenv.maybeGet('API_BASE_URL');
    final explicit = override.isNotEmpty
        ? override
        : (fromDotEnv?.isNotEmpty ?? false ? fromDotEnv! : '');
    if (explicit.isNotEmpty) return explicit;
    return switch (environment) {
      AppEnvironment.production => 'https://api.greenish.cm',
      AppEnvironment.staging => 'https://green.strife-cyber.org',
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

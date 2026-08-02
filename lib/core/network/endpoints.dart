/// Central endpoint registry — the frontend mirror of the backend Swagger.
///
/// Each phase adds the endpoints for the modules it touches. This file is the
/// main thing updated during the Swagger hand-off (see
/// `docs/FRONTEND_IMPLEMENTATION_PLAN.md` §10).
abstract final class Endpoints {
  /// Base URL of the live backend (the API is served at the ROOT; the Swagger
  /// UI is mounted at `/api`). For an Android emulator use
  /// `--dart-define=API_BASE_URL=http://10.0.2.2:3000`.
  static const String base = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  // ---- auth (Phase 0) ----
  static const String login = '$base/auth/login';
  static const String signup = '$base/auth/signup';
  static const String refresh = '$base/auth/refresh';
  static const String logout = '$base/auth/logout';
  static const String me = '$base/auth/me';
  static const String forgotPassword = '$base/auth/forgot-password';
  static const String resetPassword = '$base/auth/reset-password';
  static const String verifyEmail = '$base/auth/verify-email';
}

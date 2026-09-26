import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/auth.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'endpoints.dart';

/// Broadcast when a mid-session 401 could not be recovered by a token refresh
/// (refresh token missing, expired or rejected). App-level code ([GreenApp])
/// listens and signs the user out, so the router returns to login.
final sessionExpiredProvider =
    NotifierProvider<SessionExpiredNotifier, int>(SessionExpiredNotifier.new);

class SessionExpiredNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void signal() => state++;
}

/// Shared Dio instance for the Api…Repository implementations.
final apiClientProvider = Provider<Dio>((ref) {
  return createApiClient(
    ref.watch(tokenStorageProvider),
    onSessionExpired: () => ref.read(sessionExpiredProvider.notifier).signal(),
  );
});

/// Builds the app's Dio client: base URL, timeouts, auth header interceptor
/// (with transparent 401 → refresh → retry), and request/response logging (see
/// [_LoggingInterceptor]).
Dio createApiClient(TokenStorage tokens, {void Function()? onSessionExpired}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Endpoints.base,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      // The backend wraps every response in { data, meta, error }.
      responseType: ResponseType.json,
    ),
  );
  dio.interceptors
    ..add(_AuthInterceptor(tokens, dio, onSessionExpired))
    ..add(_LoggingInterceptor());
  return dio;
}

/// Attaches `Authorization: Bearer <token>` to every request, and transparently
/// recovers from a mid-session 401 (~6h access-token expiry) by refreshing the
/// token pair — single-flight, so concurrent 401s share one refresh — then
/// retrying the original request once with the new token. If the refresh fails
/// the session is cleared and [onSessionExpired] is signalled so the app can
/// redirect to login.
class _AuthInterceptor extends Interceptor {
  final TokenStorage _tokens;
  final Dio _dio;
  final void Function()? _onSessionExpired;

  /// One shared refresh future across all concurrent 401s; dropped once the
  /// refresh settles so a later expiry can refresh again.
  Future<AuthSession>? _refreshFuture;

  _AuthInterceptor(this._tokens, this._dio, this._onSessionExpired);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // The refresh call authenticates with the refresh token in the body — a
    // stale access-token header would only make the backend reject it.
    if (!options.uri.toString().startsWith(Endpoints.refresh)) {
      final token = await _tokens.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final uri = err.requestOptions.uri.toString();
    final alreadyRetried = err.requestOptions.extra[extraRetried] == true;

    if (status != 401 || alreadyRetried || _isNoRefreshUri(uri)) {
      handler.next(err);
      return;
    }

    // No refresh token left to recover with — the session is dead.
    String? refreshToken;
    try {
      refreshToken = await _tokens.readRefreshToken();
    } catch (_) {
      refreshToken = null;
    }
    if (refreshToken == null || refreshToken.isEmpty) {
      await _safeClear();
      handler.next(err);
      return;
    }

    try {
      final session = await _refreshOnce(refreshToken);
      await _tokens.saveSession(session);
      // Replay the original request with the fresh token. The flag prevents an
      // endless 401 → refresh → retry loop if the retry is rejected too.
      err.requestOptions.extra[extraRetried] = true;
      final retry = await _dio.fetch(err.requestOptions);
      handler.resolve(retry);
    } catch (_) {
      // Refresh rejected — the session can't be salvaged.
      await _safeClear();
      handler.next(err);
    }
  }

  static const String extraRetried = '__authRetried';

  /// Auth calls whose 401 means bad credentials (or a bad refresh token), not
  /// an expired session — never trigger a refresh.
  static bool _isNoRefreshUri(String uri) =>
      uri.startsWith(Endpoints.refresh) ||
      uri.startsWith(Endpoints.login) ||
      uri.startsWith(Endpoints.signup) ||
      uri.startsWith(Endpoints.otpRequest) ||
      uri.startsWith(Endpoints.otpVerify) ||
      uri.startsWith(Endpoints.forgotPassword) ||
      uri.startsWith(Endpoints.resetPassword) ||
      uri.startsWith(Endpoints.verifyEmail) ||
      uri.startsWith(Endpoints.resendVerification);

  /// Single-flight refresh: the first 401 starts the refresh and everyone else
  /// awaits the same future.
  Future<AuthSession> _refreshOnce(String refreshToken) {
    final active = _refreshFuture;
    if (active != null) return active;
    final future = _dio
        .post(Endpoints.refresh, data: {'refreshToken': refreshToken})
        .then((res) => AuthSession.fromJson(
            ApiEnvelope.unwrap(res.data) as Map<String, dynamic>))
        .whenComplete(() => _refreshFuture = null);
    _refreshFuture = future;
    return future;
  }

  Future<void> _safeClear() async {
    try {
      await _tokens.clearSession();
    } catch (_) {
      // Secure storage teardown — nothing else to fall back on.
    }
    try {
      _onSessionExpired?.call();
    } catch (_) {
      // The listener (GreenApp → logout) must not prevent the error surfacing.
    }
  }
}

/// Logs every request made to the API: method + URL + query/body on the way
/// out, status + response data on success, and the error details on failure.
///
/// Headers are never logged (no token leakage), and sensitive body fields
/// (passwords, tokens, OTP codes) are redacted. Enabled by default; disable
/// with `--dart-define=API_LOGGING=false`.
class _LoggingInterceptor extends Interceptor {
  static const bool _enabled = bool.fromEnvironment('API_LOGGING', defaultValue: true);
  static const int _maxChars = 2000;

  /// Body keys whose values are never echoed into logs.
  static const Set<String> _sensitiveKeys = {
    'password',
    'refreshToken',
    'accessToken',
    'token',
    'code',
    'otp',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_enabled) {
      debugPrint(' API → ${options.method.toUpperCase()} ${options.uri}');
      if (options.queryParameters.isNotEmpty) {
        debugPrint('   query: ${_redact(options.queryParameters)}');
      }
      if (options.data != null) {
        debugPrint('   body: ${_redact(options.data)}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (_enabled) {
      final req = response.requestOptions;
      debugPrint(' API ← ${response.statusCode} ${req.method.toUpperCase()} ${req.uri}');
      final data = _truncate(response.data);
      if (data != null) debugPrint('   data: $data');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_enabled) {
      final req = err.requestOptions;
      final res = err.response;
      debugPrint(
          '❌ API ✗ ${err.type.name} ${res?.statusCode} ${req.method.toUpperCase()} ${req.uri}');
      debugPrint('   error: ${err.message}');
      if (req.data != null) debugPrint('   sent: ${_redact(req.data)}');
      final body = res != null ? _truncate(res.data) : null;
      if (body != null) debugPrint('   response: $body');
    }
    handler.next(err);
  }

  /// Replaces values of sensitive keys with `***` (recursively).
  static Object? _redact(Object? data) {
    if (data is Map) {
      return data.map(
        (key, value) => MapEntry(
          key,
          _sensitiveKeys.contains(key) ? '***' : _redact(value),
        ),
      );
    }
    if (data is List) return data.map(_redact).toList();
    return data;
  }

  static String? _truncate(Object? data) {
    if (data == null) return null;
    final s = data.toString();
    return s.length <= _maxChars ? s : '${s.substring(0, _maxChars)}… (${s.length} chars)';
  }
}

/// Maps a Dio failure to a typed [ApiException] with a friendly message.
ApiException apiExceptionFromDio(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.transformTimeout:
      return const ApiException(kind: ApiErrorKind.timeout, message: 'The request timed out. Please try again.');
    case DioExceptionType.connectionError:
      return const ApiException(kind: ApiErrorKind.network, message: 'No internet connection.');
    case DioExceptionType.badResponse:
      final status = error.response?.statusCode;
      final body = error.response?.data;
      if (body is Map<String, dynamic>) {
        return ApiEnvelope.fromMap(statusCode: status, map: body);
      }
      return ApiException(
        kind: ApiEnvelope.kindForStatus(status),
        statusCode: status,
        message: 'Request failed (${status ?? 'unknown'}).',
      );
    case DioExceptionType.cancel:
      return const ApiException(kind: ApiErrorKind.network, message: 'Request cancelled.');
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return const ApiException(kind: ApiErrorKind.unknown, message: 'Something went wrong. Please try again.');
  }
}

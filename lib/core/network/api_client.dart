import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'endpoints.dart';

/// Shared Dio instance for the Api…Repository implementations.
final apiClientProvider = Provider<Dio>((ref) {
  return createApiClient(ref.watch(tokenStorageProvider));
});

/// Builds the app's Dio client: base URL, timeouts, auth header interceptor,
/// and request/response logging (see [_LoggingInterceptor]).
Dio createApiClient(TokenStorage tokens) {
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
    ..add(_AuthInterceptor(tokens))
    ..add(_LoggingInterceptor());
  return dio;
}

/// Attaches `Authorization: Bearer <token>` to every request.
class _AuthInterceptor extends Interceptor {
  final TokenStorage _tokens;

  _AuthInterceptor(this._tokens);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokens.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
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

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared Dio instance for the Api…Repository implementations (used once the
/// backend is live — everything currently runs against mocks).
final apiClientProvider = Provider<Dio>((ref) {
  return createApiClient(ref.watch(tokenStorageProvider));
});

/// Builds the app's Dio client: base URL, timeouts, auth header interceptor.
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
  dio.interceptors.add(_AuthInterceptor(tokens));
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

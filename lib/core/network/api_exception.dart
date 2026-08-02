/// Typed API errors matching the backend envelope `{ data, meta, error }`
/// (backend plan §2.3) and the `PrismaExceptionFilter` status mapping.
class ApiException implements Exception {
  final ApiErrorKind kind;
  final int? statusCode;
  final String message;

  /// Field → messages, for inline form errors (backend `error.fields`).
  final Map<String, List<String>>? fieldErrors;

  const ApiException({
    required this.kind,
    this.statusCode,
    required this.message,
    this.fieldErrors,
  });

  @override
  String toString() => 'ApiException($kind, status: $statusCode): $message';
}

enum ApiErrorKind { network, timeout, unauthorized, forbidden, notFound, conflict, validation, server, unknown }

/// Parses the backend response envelope.
///
/// Successes are wrapped by the NestJS TransformInterceptor in `{ data: … }`;
/// failures use the NestJS error body `{ message, error, statusCode }`.
class ApiEnvelope {
  static const _data = 'data';

  ApiEnvelope._();

  /// Extracts `data` from a decoded success body. Non-envelope payloads (raw
  /// lists, plain maps) pass through unchanged.
  static dynamic unwrap(dynamic body, {int? statusCode}) {
    if (body is! Map<String, dynamic>) return body;
    if (body.containsKey(_data)) return body[_data];
    return body;
  }

  static ApiException fromMap({int? statusCode, required Map<String, dynamic> map}) {
    // NestJS validation errors surface `message` as a list of messages.
    final message = switch (map['message']) {
      String s => s,
      List l => l.map((e) => '$e').join('\n'),
      _ => map['error'] as String? ?? 'Request failed.',
    };

    return ApiException(
      kind: kindForStatus(statusCode),
      statusCode: statusCode,
      message: message,
    );
  }

  static ApiErrorKind kindForStatus(int? status) => switch (status) {
        401 => ApiErrorKind.unauthorized,
        403 => ApiErrorKind.forbidden,
        404 => ApiErrorKind.notFound,
        409 => ApiErrorKind.conflict,
        422 => ApiErrorKind.validation,
        final s? => s >= 500 ? ApiErrorKind.server : ApiErrorKind.unknown,
        null => ApiErrorKind.unknown,
      };
}

import '../config/app_config.dart';

/// Resolves a media URL returned by the API into an absolute URL usable by
/// `Image.network`.
///
/// Uploaded files come back **relative** (e.g. `/uploads/products/….jpg`) and
/// are served from the same backend host, so the API base is prepended
/// (`http://localhost:3000/uploads/products/….jpg`). Absolute URLs (`https://…`,
/// CDN links like loremflickr) pass through unchanged.
String resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return url ?? '';
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
  return '$base${url.startsWith('/') ? url : '/$url'}';
}

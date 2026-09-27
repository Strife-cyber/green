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

/// True when [path] refers to a client-side file (a just-picked camera/gallery
/// or microphone artifact), false for anything the API serves. Server paths are
/// relative (`/uploads/…`) or absolute `http(s)`; a leading `/` alone is NOT a
/// local signal — `/uploads/x.jpg` is remote.
bool isLocalMediaPath(String path) =>
    path.startsWith('blob:') ||
    path.startsWith('data:') ||
    path.startsWith('file:') ||
    RegExp(r'^[A-Za-z]:').hasMatch(path) ||
    (path.startsWith('/') && !path.startsWith('/uploads/'));

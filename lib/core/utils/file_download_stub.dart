/// Fallback when neither `dart:io` nor the web library is available.
Future<void> downloadFile({
  required List<int> bytes,
  required String filename,
  required String mimeType,
}) =>
    throw UnsupportedError('Downloads are not supported on this platform');

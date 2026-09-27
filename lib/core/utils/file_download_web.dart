import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Triggers a browser "Save as" via a Blob + temporary anchor (PAY-07 export,
/// REC-04 receipt PDF). Nothing touches the filesystem.
Future<void> downloadFile({
  required List<int> bytes,
  required String filename,
  required String mimeType,
}) async {
  final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  final blob = web.Blob(
    [data.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

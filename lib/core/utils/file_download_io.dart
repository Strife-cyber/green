import 'dart:io';

import 'package:share_plus/share_plus.dart';

/// Native side of [downloadFile]: writes to the temp dir then hands the file
/// to the system share sheet so the user can save/share it — there is no
/// public Downloads-folder contract on mobile.
Future<void> downloadFile({
  required List<int> bytes,
  required String filename,
  required String mimeType,
}) async {
  final file = File('${Directory.systemTemp.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path, mimeType: mimeType)]),
  );
}

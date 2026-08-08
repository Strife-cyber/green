import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';

/// Renders an image from a locally-picked file. Reads the bytes via [XFile] so
/// it works on native (a filesystem path) and web (a blob URL) — unlike
/// `Image.file`, which does not render on the web platform.
class LocalFileImage extends StatefulWidget {
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;

  const LocalFileImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  State<LocalFileImage> createState() => _LocalFileImageState();
}

class _LocalFileImageState extends State<LocalFileImage> {
  late Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = XFile(widget.path).readAsBytes();
  }

  @override
  void didUpdateWidget(LocalFileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _bytes = XFile(widget.path).readAsBytes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return SizedBox(width: widget.width, height: widget.height);
        }
        return Image.memory(
          bytes,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        );
      },
    );
  }
}

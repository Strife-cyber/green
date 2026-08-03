import 'package:flutter/material.dart';

import '../../core/network/media_url.dart';
import '../../theme/app_colors.dart';

/// Network image with a branded placeholder/error fallback.
///
/// Relative API URLs (e.g. `/uploads/products/….jpg`) are resolved against the
/// backend base before loading, so uploaded images work out of the box.
/// [headers] forwards to `Image.network` — needed for endpoints that require
/// an `Authorization` header (e.g. the decrypt-on-read KYC document routes).
class ImageNetwork extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Map<String, String>? headers;

  const ImageNetwork({
    super.key,
    this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.headers,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: AppColors.backgroundElevated,
      alignment: Alignment.center,
      child: const Icon(Icons.eco_outlined, color: AppColors.tanDark),
    );

    Widget image;
    if (url == null || url!.isEmpty) {
      image = placeholder;
    } else {
      image = Image.network(
        resolveMediaUrl(url),
        width: width,
        height: height,
        fit: fit,
        headers: headers,
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholder,
      );
    }

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}

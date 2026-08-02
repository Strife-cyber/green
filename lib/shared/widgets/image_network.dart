import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Network image with a branded placeholder/error fallback.
class ImageNetwork extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ImageNetwork({
    super.key,
    this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
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
        url!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholder,
      );
    }

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}

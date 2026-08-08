import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_colors.dart';
import 'image_network.dart';
import 'local_file_image.dart';

/// A tappable image that opens the gallery and returns the picked file path.
/// Used for product photos and chat images.
class PhotoPicker extends StatelessWidget {
  final String? imagePath;
  final String? imageUrl;
  final double size;
  final ValueChanged<String> onPicked;

  const PhotoPicker({
    super.key,
    this.imagePath,
    this.imageUrl,
    this.size = 96,
    required this.onPicked,
  });

  Future<void> _pick(BuildContext context) async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) onPicked(picked.path);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the gallery.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = imagePath != null && imagePath!.isNotEmpty;
    final hasUrl = imageUrl != null && imageUrl!.isNotEmpty;
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.tan),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasFile
            ? LocalFileImage(path: imagePath!)
            : hasUrl
                ? ImageNetwork(url: imageUrl)
                : const Center(child: Icon(Icons.add_photo_alternate_outlined, color: AppColors.tanDark)),
      ),
    );
  }
}

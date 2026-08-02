import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Initials-based avatar with a deterministic brand colour per name.
class UserAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const UserAvatar({super.key, required this.name, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return CircleAvatar(
      radius: radius,
      backgroundColor: _colorFor(name),
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: radius * 0.8),
      ),
    );
  }

  Color _colorFor(String name) {
    const palette = [AppColors.green, AppColors.orange, AppColors.tanDark, Color(0xFF4A7CBE)];
    var hash = 0;
    for (final c in name.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    return palette[hash % palette.length];
  }
}

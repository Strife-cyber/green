import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';
import '../../theme/app_colors.dart';

/// Visual password-strength meter (AUTH-01). Shows a segmented bar plus a
/// short hint of what's still missing.
class PasswordStrengthBar extends StatelessWidget {
  final String password;

  const PasswordStrengthBar({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = passwordStrength(password);
    final segments = List.generate(4, (i) => i < strength.score);

    Color colorFor(int score) => switch (score) {
          <= 1 => AppColors.orange,
          2 || 3 => AppColors.tanDark,
          _ => AppColors.green,
        };

    final color = colorFor(strength.score);
    final label = strength.valid ? 'Strong password' : strength.failed.join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 4,
                  margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: segments[i] ? color : AppColors.tan.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: strength.valid ? AppColors.green : AppColors.tanDark,
              ),
        ),
      ],
    );
  }
}

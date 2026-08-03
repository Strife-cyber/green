import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A tappable quick action on a dashboard/home tab.
class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickAction({required this.icon, required this.label, required this.onTap});
}

/// A compact row of **icon-only** quick actions (the BraidsBook pattern, but
/// small): one line, just the icons, label shown on long-press/tooltip so the
/// header stays out of the way and the content below has room.
class QuickActionsSection extends StatelessWidget {
  final List<QuickAction> actions;
  final String? title;

  const QuickActionsSection({super.key, required this.actions, this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.tanDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [for (final action in actions) _QuickActionIcon(action: action)],
        ),
      ],
    );
  }
}

class _QuickActionIcon extends StatelessWidget {
  final QuickAction action;
  const _QuickActionIcon({required this.action});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: action.label,
      child: InkWell(
        onTap: action.onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(action.icon, color: AppColors.greenDark, size: 22),
        ),
      ),
    );
  }
}

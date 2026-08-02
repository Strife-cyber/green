import 'package:flutter/material.dart';

import '../../l10n/l10n_ext.dart';

/// A tappable quick action on a dashboard/home tab.
class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickAction({required this.icon, required this.label, required this.onTap});
}

/// A titled grid of card-style quick actions (the BraidsBook pattern): each
/// action is a bordered card tile with an icon above its label.
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
        Text(
          title ?? context.t.quickActions,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [for (final action in actions) _QuickActionTile(action: action)],
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 108,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, color: theme.colorScheme.primary, size: 26),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

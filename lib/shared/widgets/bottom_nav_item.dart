import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A single item in the floating [CustomBottomNavBar]. The selected item
/// renders as a filled pill with its label; others show just the icon.
class BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool isSelected;
  final VoidCallback onTap;
  final double iconSize;
  final double horizontalPadding;
  final double verticalPadding;
  final bool showLabel;
  final int? badge;
  final bool hapticFeedback;

  const BottomNavItem({
    super.key,
    required this.icon,
    this.label,
    required this.isSelected,
    required this.onTap,
    required this.iconSize,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.showLabel,
    this.badge,
    this.hapticFeedback = true,
  });

  void _handleTap() {
    if (hapticFeedback) HapticFeedback.lightImpact();
    onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final iconColor = isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant;
    final pillColor = isSelected ? theme.colorScheme.primary : Colors.transparent;
    const pillRadius = BorderRadius.all(Radius.circular(100));

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: iconSize, color: iconColor),
            if (badge != null && badge! > 0)
              Positioned(top: -4, right: -4, child: _Badge(count: badge!)),
          ],
        ),
        Flexible(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: showLabel && isSelected && label != null
                ? Padding(
                    padding: EdgeInsets.only(left: horizontalPadding * 0.5),
                    child: Text(
                      label!,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: iconSize * 0.55,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );

    final pillWrapper = isSelected
        ? AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
            decoration: BoxDecoration(color: pillColor, borderRadius: pillRadius),
            child: content,
          )
        : Container(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
            child: content,
          );

    return Semantics(
      label: label ?? icon.toString(),
      selected: isSelected,
      button: true,
      child: Tooltip(
        message: (!showLabel || !isSelected) ? (label ?? '') : '',
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: _handleTap,
            borderRadius: pillRadius,
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            highlightColor: theme.colorScheme.primary.withValues(alpha: 0.08),
            child: pillWrapper,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(color: theme.colorScheme.onError, fontSize: 9, fontWeight: FontWeight.bold, height: 1),
        textAlign: TextAlign.center,
      ),
    );
  }
}

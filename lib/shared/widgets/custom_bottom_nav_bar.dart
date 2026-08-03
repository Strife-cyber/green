import 'package:flutter/material.dart';

import 'bottom_nav_item.dart';

/// Describes one destination of the [CustomBottomNavBar].
class CustomNavItemData {
  final IconData icon;
  final String? label;
  final int? badge;

  const CustomNavItemData({required this.icon, this.label, this.badge});
}

const int _kSelectedFlex = 2;
const double _kMinLabelSlack = 24.0;

/// A floating, pill-shaped bottom navigation bar (the BraidsBook pattern):
/// the selected item expands into a filled pill with its label; all items sit
/// inside one rounded floating container with a soft shadow.
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<CustomNavItemData> items;
  final ValueChanged<int> onTap;
  final bool hapticFeedback;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.hapticFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;

    final pillMinWidth = screenWidth * 0.80;
    final pillMaxWidth = screenWidth * 0.90;

    const innerH = 10.0;
    const innerV = 14.0;
    const bottomLift = 10.0;

    final isVerySmall = screenWidth < 340;
    final isSmall = screenWidth < 360;
    final iconSize = isSmall ? (isVerySmall ? 16.0 : 18.0) : 22.0;
    final hPad = isSmall ? (isVerySmall ? 6.0 : 8.0) : 14.0;
    final vPad = isSmall ? 8.0 : 12.0;

    final totalFlex = _kSelectedFlex + (items.length - 1);
    final selectedSlotW = pillMinWidth * _kSelectedFlex / totalFlex;
    final labelSlack = selectedSlotW - hPad * 2 - iconSize;
    final showLabel = !isVerySmall && labelSlack >= _kMinLabelSlack;

    final pillDecoration = BoxDecoration(
      color: theme.colorScheme.surface,
      border: Border.all(color: Colors.black.withValues(alpha: 0.8), width: 1),
      borderRadius: BorderRadius.circular(100),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );

    // Anchored to the bottom (not vertically centered in the nav slot), so the
    // pill hugs the bottom edge with a small float.
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: pillMinWidth, maxWidth: pillMaxWidth),
        child: Container(
          margin: const EdgeInsets.only(bottom: bottomLift),
          padding: const EdgeInsets.symmetric(horizontal: innerH, vertical: innerV),
          decoration: pillDecoration,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final unitWidth = constraints.maxWidth / totalFlex;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(items.length, (index) {
                  final isSelected = currentIndex == index;
                  final itemWidth = isSelected ? unitWidth * _kSelectedFlex : unitWidth;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    width: itemWidth,
                    child: BottomNavItem(
                      key: ValueKey(index),
                      icon: items[index].icon,
                      label: items[index].label,
                      isSelected: isSelected,
                      onTap: () => onTap(index),
                      iconSize: iconSize,
                      horizontalPadding: hPad,
                      verticalPadding: vPad,
                      showLabel: showLabel,
                      badge: items[index].badge,
                      hapticFeedback: hapticFeedback,
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}

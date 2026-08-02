import 'package:flutter/material.dart';

import '../../data/models/category.dart';

/// Horizontally scrolling category filter chips (BUY-03).
class CategoryChips extends StatelessWidget {
  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: selectedId == null,
            onSelected: (_) => onSelected(null),
          ),
          for (final category in categories) ...[
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(category.name),
              selected: selectedId == category.id,
              onSelected: (_) => onSelected(category.id),
            ),
          ],
        ],
      ),
    );
  }
}

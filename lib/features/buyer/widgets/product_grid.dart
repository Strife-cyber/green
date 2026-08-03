import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/product.dart';
import '../../../shared/widgets/product_card.dart';
import 'product_sheet.dart';

/// A two-column grid of [ProductCard]s. Tapping a card opens the product in a
/// draggable bottom sheet (see [showProductSheet]); pass [onTap] to override.
class ProductGrid extends ConsumerWidget {
  final List<Product> products;
  final void Function(Product)? onTap;

  const ProductGrid({super.key, required this.products, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: onTap == null
              ? () => showProductSheet(context, ref, product)
              : () => onTap!(product),
        );
      },
    );
  }
}

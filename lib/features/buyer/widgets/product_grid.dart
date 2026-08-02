import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/product.dart';
import '../../../shared/widgets/product_card.dart';

/// A two-column grid of [ProductCard]s. Tapping a card pushes the product
/// detail route by default; pass [onTap] to override.
class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final void Function(Product)? onTap;

  const ProductGrid({super.key, required this.products, this.onTap});

  @override
  Widget build(BuildContext context) {
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
              ? () => context.push(AppRoutes.productDetail(product.id))
              : () => onTap!(product),
        );
      },
    );
  }
}

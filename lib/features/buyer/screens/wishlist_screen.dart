import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/product.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../theme/app_colors.dart';
import '../controllers/product_list_controller.dart';
import '../controllers/wishlist_controller.dart';

/// The buyer's wishlist (BUY-05): a grid of saved products with a tap-to-remove
/// heart overlay, each tile opening the product detail.
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(wishlistControllerProvider);
    final catalog = ref.watch(productCatalogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: AsyncView<Set<String>>(
        value: saved,
        onRetry: () => ref.invalidate(wishlistControllerProvider),
        builder: (savedIds) => AsyncView<List<Product>>(
          value: catalog,
          onRetry: () => ref.invalidate(productCatalogProvider),
          builder: (products) {
            final items = [
              for (final product in products)
                if (savedIds.contains(product.id)) product,
            ];
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.favorite_border,
                title: 'Your wishlist is empty',
                message: 'Tap the heart on any product to save it here.',
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final product = items[index];
                return Stack(
                  children: [
                    ProductCard(
                      product: product,
                      onTap: () =>
                          context.push(AppRoutes.productDetail(product.id)),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        tooltip: 'Remove from wishlist',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.backgroundElevated,
                        ),
                        icon: const Icon(
                          Icons.favorite,
                          color: AppColors.orange,
                          size: 20,
                        ),
                        onPressed: () => ref
                            .read(wishlistControllerProvider.notifier)
                            .toggle(product.id),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

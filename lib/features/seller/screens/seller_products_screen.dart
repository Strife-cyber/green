import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/image_network.dart';
import '../../../theme/app_colors.dart';
import '../controllers/seller_product_list_controller.dart';

/// The seller's catalog with create / edit / delete (SELL-01).
class SellerProductsScreen extends ConsumerWidget {
  const SellerProductsScreen({super.key});

  Future<void> _openNew(BuildContext context, WidgetRef ref) async {
    await context.push('/seller/products/new');
    ref.invalidate(sellerProductListControllerProvider);
  }

  Future<void> _openEdit(BuildContext context, WidgetRef ref, Product product) async {
    await context.push(AppRoutes.sellerProductEdit(product.id));
    ref.invalidate(sellerProductListControllerProvider);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Remove "${product.name}" from your catalog?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(sellerProductListControllerProvider.notifier).deleteProduct(product.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(sellerProductListControllerProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('My Products')),
      body: Stack(
        children: [
          RefreshableAsyncView<List<Product>>(
            value: products,
            onRefresh: () => ref.read(sellerProductListControllerProvider.notifier).refresh(),
            onRetry: () => ref.invalidate(sellerProductListControllerProvider),
            empty: const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No products yet',
              message: 'Tap + to add your first product.',
            ),
            builder: (items) => ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _ProductTile(
                product: items[index],
                onTap: () => _openEdit(context, ref, items[index]),
                onDelete: () => _confirmDelete(context, ref, items[index]),
              ),
            ),
          ),
          Positioned(
            bottom: 92,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => _openNew(context, ref),
              tooltip: 'Add product',
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProductTile({required this.product, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: ImageNetwork(url: product.imageUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    AmountText(product.pricePerKg, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(formatKg(product.quantityKg), style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => value == 'delete' ? onDelete() : onTap(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

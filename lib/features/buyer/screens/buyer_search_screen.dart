import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/product.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/debounced_search_bar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../controllers/product_list_controller.dart';
import '../widgets/product_grid.dart';

/// Buyer search (BUY-02): a debounced query field over the shared catalog
/// grid.
class BuyerSearchScreen extends ConsumerWidget {
  const BuyerSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(productListControllerProvider.notifier);
    final products = ref.watch(productListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: DebouncedSearchBar(
              hint: 'Search products, farms…',
              onChanged: (text) => controller.setQuery(search: text),
            ),
          ),
          Expanded(
            child: AsyncView<List<Product>>(
              value: products,
              onRetry: () => ref.invalidate(productListControllerProvider),
              builder: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'No results',
                    message: 'Try a different keyword.',
                  );
                }
                return ProductGrid(products: items);
              },
            ),
          ),
        ],
      ),
    );
  }
}

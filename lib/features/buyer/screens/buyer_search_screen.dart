import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/product.dart';
import '../../../data/models/seller_profile.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/debounced_search_bar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../theme/app_colors.dart';
import '../controllers/farm_search_controller.dart';
import '../controllers/product_list_controller.dart';
import '../widgets/product_grid.dart';

/// Buyer search (BUY-02): a debounced query producing two sections —
/// Farms (name · region · ★rating) then Products.
class BuyerSearchScreen extends ConsumerWidget {
  const BuyerSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(productListControllerProvider.notifier);
    final products = ref.watch(productListControllerProvider);
    final query = ref.watch(farmSearchQueryProvider);
    final farms = ref.watch(farmSearchProvider(query));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(context.t.search)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: DebouncedSearchBar(
              hint: context.t.searchFarmsProducts,
              onChanged: (text) {
                ref.read(farmSearchQueryProvider.notifier).state = text;
                controller.setQuery(search: text);
              },
            ),
          ),
          Expanded(
            child: AsyncView<List<Product>>(
              value: products,
              onRetry: () => ref.invalidate(productListControllerProvider),
              builder: (items) {
                if (items.isEmpty && query.trim().isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    title: context.t.noResults,
                    message: context.t.tryDifferentKeyword,
                  );
                }
                return ListView(
                  children: [
                    if (query.trim().isNotEmpty)
                      farms.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (list) => _FarmSection(farms: list),
                      ),
                    _ProductSection(items: items),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Farms" result block — tappable rows that open the farm's catalog.
class _FarmSection extends StatelessWidget {
  final List<SellerSearchItem> farms;

  const _FarmSection({required this.farms});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (farms.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(context.t.farmsSection, style: theme.textTheme.titleSmall),
        ),
        for (final farm in farms)
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.greenPale,
              child: Icon(Icons.storefront_outlined, color: AppColors.green),
            ),
            title: Text(farm.farmName),
            subtitle: Text(farm.region ?? ''),
            trailing: farm.ratingCount == 0
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 16, color: AppColors.orange),
                      const SizedBox(width: 2),
                      Text(farm.rating.toStringAsFixed(1)),
                    ],
                  ),
            onTap: () {},
          ),
      ],
    );
  }
}

/// The "Products" result block.
class _ProductSection extends StatelessWidget {
  final List<Product> items;

  const _ProductSection({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: context.t.noResults,
        message: context.t.tryDifferentKeyword,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(context.t.productsSection,
              style: theme.textTheme.titleSmall),
        ),
        // The grid is shrink-wrapped inside the outer ListView — the two
        // sections scroll as one.
        ProductGrid(products: items, shrinkWrap: true),
      ],
    );
  }
}

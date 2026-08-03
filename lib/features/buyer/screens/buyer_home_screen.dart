import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/nav_providers.dart';
import '../../../data/models/product.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/category_chips.dart';
import '../../../shared/widgets/debounced_search_bar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../controllers/buyer_order_list_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/product_list_controller.dart';
import '../widgets/product_grid.dart';
import 'buyer_orders_screen.dart';
import 'buyer_profile_screen.dart';
import 'cart_screen.dart';

/// The buyer's landing shell: a BraidsBook-style [AppShell] over four core
/// tabs — Home feed, Cart (with live badge), Orders, Profile. Search lives on
/// the Home feed (search bar + quick action), so the bar stays at 4 items.
class BuyerHomeScreen extends ConsumerWidget {
  const BuyerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cartCount = ref.watch(cartControllerProvider).itemCount;
    // Auto-refresh the active tab's data whenever the user switches tabs.
    ref.listen(buyerTabProvider, (previous, next) {
      if (previous == next) return;
      switch (next) {
        case 0: ref.invalidate(productListControllerProvider); break;
        case 2: ref.invalidate(buyerOrderListControllerProvider); break;
        // 1 = Cart (local state), 3 = Profile — nothing to refetch.
      }
    });
    return AppShell(
      tabProvider: buyerTabProvider,
      persistKey: 'buyer',
      tabs: [
        AppShellTab(label: t.navHome, icon: Icons.home_outlined, page: const _HomeFeed()),
        AppShellTab(
          label: t.navCart,
          icon: Icons.shopping_cart_outlined,
          badge: cartCount,
          page: const CartScreen(),
        ),
        AppShellTab(label: t.navOrders, icon: Icons.receipt_long_outlined, page: const BuyerOrdersScreen()),
        AppShellTab(label: t.navProfile, icon: Icons.person_outline, page: const BuyerProfileScreen()),
      ],
    );
  }
}

/// The Home feed tab: quick actions + debounced search + category chips +
/// product grid (BUY-01/02/03).
class _HomeFeed extends ConsumerWidget {
  const _HomeFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final controller = ref.read(productListControllerProvider.notifier);
    final products = ref.watch(productListControllerProvider);
    final categories = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(t.appTitle)
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: DebouncedSearchBar(
              onChanged: (text) => controller.setQuery(search: text),
            ),
          ),
          categories.when(
            data: (list) => CategoryChips(
              categories: list,
              selectedId: controller.categoryId,
              onSelected: (id) {
                if (id == null) {
                  controller.clearCategory();
                } else {
                  controller.setQuery(categoryId: id);
                }
              },
            ),
            loading: () => const SizedBox(height: 40),
            error: (_, _) => const SizedBox(height: 40),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: RefreshableAsyncView<List<Product>>(
              value: products,
              onRefresh: () => ref.read(productListControllerProvider.notifier).refresh(),
              onRetry: () => ref.invalidate(productListControllerProvider),
              empty: EmptyState(icon: Icons.search_off, title: t.search, message: t.empty),
              builder: (items) => ProductGrid(products: items),
            ),
          ),
        ],
      ),
    );
  }
}

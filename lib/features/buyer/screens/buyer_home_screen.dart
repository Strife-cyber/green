import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/nav_providers.dart';
import '../../../data/models/product.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/category_chips.dart';
import '../../../shared/widgets/debounced_search_bar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../theme/app_colors.dart';
import '../../wallet/screens/wallet_screen.dart';
import '../controllers/buyer_order_list_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/product_list_controller.dart';
import '../widgets/product_grid.dart';
import 'buyer_orders_screen.dart';
import 'buyer_profile_screen.dart';
import 'wishlist_screen.dart';

/// The buyer's landing shell: [AppShell] over the five design-doc tabs —
/// Market (home feed), Wishlist, Orders, Wallet (read-only), Me. The cart is
/// a badge on the Market app bar and lives at `/buyer/cart`; chat threads open
/// from order/product contexts.
class BuyerHomeScreen extends ConsumerWidget {
  const BuyerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    // Auto-refresh the active tab's data whenever the user switches tabs.
    ref.listen(buyerTabProvider, (previous, next) {
      if (previous == next) return;
      switch (next) {
        case 0:
          ref.invalidate(productListControllerProvider);
          break;
        case 2:
          ref.invalidate(buyerOrderListControllerProvider);
          break;
        // 1 = Wishlist (self-refreshing), 3 = Wallet (self-managing),
        // 4 = Me.
      }
    });
    return AppShell(
      tabProvider: buyerTabProvider,
      persistKey: 'buyer',
      tabs: [
        AppShellTab(label: t.navMarket, icon: Icons.storefront_outlined, page: const _HomeFeed()),
        AppShellTab(label: t.navWishlist, icon: Icons.favorite_border, page: const WishlistScreen()),
        AppShellTab(label: t.navOrders, icon: Icons.receipt_long_outlined, page: const BuyerOrdersScreen()),
        AppShellTab(label: t.navWallet, icon: Icons.account_balance_wallet_outlined, page: const WalletScreen(readOnly: true)),
        AppShellTab(label: t.navMe, icon: Icons.person_outline, page: const BuyerProfileScreen()),
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

    final cartCount = ref.watch(cartControllerProvider).itemCount;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(t.appTitle),
        actions: [
          IconButton(
            tooltip: t.navChat,
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push(AppRoutes.chatThreads),
          ),
          IconButton(
            tooltip: t.navCart,
            onPressed: () => context.push(AppRoutes.cart),
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
        ],
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
            loading: () => const _CategoryChipsSkeleton(),
            error: (_, _) => Row(
              children: [
                const SizedBox(width: 16),
                const Icon(Icons.error_outline,
                    size: 18, color: AppColors.orangeDark),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Could not load categories',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(categoryListProvider),
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 8),
              ],
            ),
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

/// Lightweight placeholder for the category chip row while it loads — cream
/// pills at the same height as the real [CategoryChips] (40px).
class _CategoryChipsSkeleton extends StatelessWidget {
  const _CategoryChipsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, _) => Container(
          width: 76,
          decoration: BoxDecoration(
            color: AppColors.tan.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

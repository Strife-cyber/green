import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/money.dart';
import '../../../data/repositories/providers.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../theme/app_colors.dart';
import '../controllers/cart_controller.dart';
import '../widgets/cart_line_tile.dart';

/// The buyer's cart (BUY-06): line items with kg steppers, remove + clear, the
/// running subtotal and a button to proceed to checkout.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  /// Asks before wiping the cart and offers an undo snackbar afterwards.
  Future<void> _confirmClearCart(BuildContext context, WidgetRef ref) async {
    final cart = ref.read(cartControllerProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear your cart?'),
        content: Text(
          'This removes ${cart.lines.length} product '
          'line${cart.lines.length == 1 ? '' : 's'} · '
          '${_trimKg(cart.totalKg)} kg from your cart. '
          'You can add them again any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep cart'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final snapshot = cart.lines;
    ref.read(cartControllerProvider.notifier).clear();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cart cleared'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () =>
              ref.read(cartControllerProvider.notifier).restore(snapshot),
        ),
      ),
    );
  }

  String _trimKg(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cart = ref.watch(cartControllerProvider);
    final controller = ref.read(cartControllerProvider.notifier);
    final groups = cart.sellerGroups;
    // Per-order flat delivery fee — from platform config `delivery_fee_flat`
    // with the app-wide default while config isn't loaded (design 13/14).
    final feeConfig = ref.watch(platformConfigProvider('delivery_fee_flat'));
    final deliveryFee =
        int.tryParse(feeConfig.valueOrNull ?? '') ?? kDefaultDeliveryFee;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Cart'),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () => _confirmClearCart(context, ref),
              child: const Text('Clear'),
            ),
        ],
      ),
      body: cart.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              message: 'Browse the catalogue and add some fresh produce.',
              action: FilledButton(
                onPressed: () => context.go(AppRoutes.buyerHome),
                child: const Text('Browse products'),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Multi-farm explainer: each farm checks out as its own
                      // order with its own flat delivery fee (design 13).
                      if (groups.length > 1)
                        Card(
                          color: AppColors.greenPale,
                          child: ListTile(
                            leading: const Icon(
                              Icons.storefront_outlined,
                              color: AppColors.green,
                            ),
                            title: Text(
                              context.t.multiFarmExplainer(
                                  count: groups.length),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      for (final group in groups) ...[
                        if (groups.length > 1)
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(4, 12, 4, 4),
                            child: Text(
                              group.sellerName ?? context.t.roleSeller,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                        for (final line in group.lines)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CartLineTile(
                              line: line,
                              onQuantityChanged: (quantity) => controller
                                  .adjust(line.product.id, quantity),
                              onRemove: () =>
                                  controller.remove(line.product.id),
                            ),
                          ),
                        if (groups.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.t.orderSubtotal,
                                  style: theme.textTheme.bodySmall,
                                ),
                                AmountText(
                                  group.subtotal,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // The flat delivery fee applies per order (per farm).
                        Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined,
                                size: 16, color: AppColors.tanDark),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                context.t.deliveryFeeLabel,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: AppColors.tanDark),
                              ),
                            ),
                            AmountText(
                              deliveryFee,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.tanDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${cart.lines.length} '
                              'product${cart.lines.length == 1 ? '' : 's'} · '
                              '${_trimKg(cart.totalKg)} kg',
                              style: theme.textTheme.bodyMedium,
                            ),
                            AmountText(
                              cart.subtotal,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.greenDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => context.push(AppRoutes.checkout),
                          icon: const Icon(Icons.lock_outline),
                          label: const Text('Proceed to checkout'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

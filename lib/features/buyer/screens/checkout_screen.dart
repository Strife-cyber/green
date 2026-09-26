import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/address.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/address_controller.dart';
import '../controllers/buyer_order_list_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/checkout_controller.dart';

/// Checkout (BUY-07): presents the whole cart as ONE order — a single summary
/// card, a single delivery fee, one total and one "Place order" button. The
/// per-seller splitting still happens server-side, but nothing here lets it
/// leak: the buyer never sees "order 1 of 2". On success they land on payment.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  /// Per-seller delivery fee sent on order creation. The backend currently
  /// persists `delivery_fee: 0` and charges the subtotal only (the fee rule
  /// isn't decided yet), so the summary shows "set at order" instead of a
  /// phantom amount and the displayed total always equals the charge.
  static const int deliveryFee = 0;

  String? _selectedAddressId;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartControllerProvider);
    final checkout = ref.watch(checkoutControllerProvider);
    final addresses = ref.watch(addressControllerProvider);

    ref.listen(checkoutControllerProvider, (previous, next) {
      if (previous != null &&
          previous.submitting &&
          !next.submitting &&
          next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: ${next.error}')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(context.t.checkout)),
      body: cart.isEmpty
          ? EmptyState(
              icon: Icons.receipt_long_outlined,
              title: context.t.nothingToCheckout,
              message: context.t.emptyCart,
            )
          : AsyncView<List<Address>>(
              value: addresses,
              onRetry: () => ref.invalidate(addressControllerProvider),
              builder: (addressList) {
                final selected = _resolveSelected(addressList);
                final groups = _groupBySeller(cart.lines);
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _AddressCard(
                      addresses: addressList,
                      selected: selected,
                      onChanged: (address) =>
                          setState(() => _selectedAddressId = address.id),
                    ),
                    const SizedBox(height: 16),
                    _CheckoutSummaryCard(
                      groups: groups,
                      deliveryFee: deliveryFee,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: (checkout.submitting || addressList.isEmpty)
                          ? null
                          : () => _placeOrder(groups, selected),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: checkout.submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(context.t.placeOrder),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Address _resolveSelected(List<Address> addresses) {
    if (addresses.isEmpty) return const Address(id: '', label: '', recipientName: '', phone: '', region: '', addressLine: '');
    return addresses.firstWhere(
      (a) => a.id == _selectedAddressId,
      orElse: () => addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addresses.first,
      ),
    );
  }

  Map<String, List<CartLine>> _groupBySeller(List<CartLine> lines) {
    final groups = <String, List<CartLine>>{};
    for (final line in lines) {
      groups.putIfAbsent(line.product.sellerId, () => []).add(line);
    }
    return groups;
  }

  Future<void> _placeOrder(
    Map<String, List<CartLine>> groups,
    Address address,
  ) async {
    // D7: browsing is free for unverified accounts, but placing an order is
    // the one action that requires a verified email — the banner's Resend /
    // check-status affordances live above the app shell.
    if (ref.read(authControllerProvider).valueOrNull?.user?.emailVerified ==
        false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.verifyToOrderHint)),
      );
      return;
    }
    final result = await ref
        .read(checkoutControllerProvider.notifier)
        .submit(
          sellerGroups: groups,
          address: address,
          deliveryFee: deliveryFee,
        );
    if (!mounted) return;

    final placed = result.placedOrders;
    if (placed.isEmpty) return; // Full failure — snackbar via ref.listen below.

    final cartController = ref.read(cartControllerProvider.notifier);
    if (result.allSucceeded) {
      // Every order placed — only now is the cart safe to clear.
      cartController.clear();
    } else {
      // Partial checkout: drop only the lines that became orders, keep the
      // rest so the buyer can retry the failed seller groups.
      final succeededSellerIds = {for (final p in placed) p.sellerId};
      cartController.removeLinesWhere(
        (line) => succeededSellerIds.contains(line.product.sellerId),
      );
    }

    // The new orders won't show on the Orders tab unless the list refetches —
    // the payment screen reads it to continue through the remaining orders.
    ref.invalidate(buyerOrderListControllerProvider);

    if (result.partial) {
      await _showPartialCheckoutDialog(result);
      return;
    }
    if (!mounted) return;
    context.pushReplacement(AppRoutes.payment(placed.first.orderId));
  }

  Future<void> _showPartialCheckoutDialog(CheckoutResult result) async {
    final placed = result.placedOrders;
    final total = placed.length + result.failedGroups;
    final action = await showDialog<_PartialAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Some orders were placed'),
        content: Text(
          'You had $total order${total == 1 ? '' : 's'} but only '
          '${placed.length} could be placed. The placed '
          'order${placed.length == 1 ? '' : 's'} '
          '${placed.length == 1 ? 'is' : 'are'} ready to pay. '
          'What would you like to do?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _PartialAction.dismiss),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _PartialAction.retry),
            child: const Text('Retry the rest'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _PartialAction.payPlaced),
            child: Text(
              'Pay ${placed.length == 1 ? 'placed order' : 'placed orders'}',
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == _PartialAction.payPlaced) {
      context.pushReplacement(AppRoutes.payment(placed.first.orderId));
    } else if (action == _PartialAction.retry) {
      // The cart now holds only the failed groups' lines — resubmit those.
      final remainingAddress = _resolveSelected(
        ref.read(addressControllerProvider).valueOrNull ?? const <Address>[],
      );
      final remainingGroups = _groupBySeller(
        ref.read(cartControllerProvider).lines,
      );
      if (remainingGroups.isNotEmpty && remainingAddress.id.isNotEmpty) {
        await _placeOrder(remainingGroups, remainingAddress);
      }
    }
    // _PartialAction.dismiss (or a barrier tap) leaves the cart as-is.
  }
}

/// What the buyer chose in the partial-checkout dialog.
enum _PartialAction { payPlaced, retry, dismiss }

/// Delivery-address picker card; empty state links out to manage addresses.
class _AddressCard extends StatelessWidget {
  final List<Address> addresses;
  final Address selected;
  final ValueChanged<Address> onChanged;

  const _AddressCard({
    required this.addresses,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.t.deliveryAddress, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (addresses.isEmpty)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'No saved address yet.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.addresses),
                    child: const Text('Add address'),
                  ),
                ],
              )
            else
              DropdownButtonFormField<Address>(
                initialValue: selected,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Saved address'),
                items: [
                  for (final address in addresses)
                    DropdownMenuItem(
                      value: address,
                      child: Text('${address.label} — ${address.addressLine}'),
                    ),
                ],
                onChanged: (address) {
                  if (address != null) onChanged(address);
                },
              ),
            if (addresses.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.addresses),
                  child: const Text('Manage addresses'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A single order-style summary of the whole cart: every line item, one
/// subtotal, one delivery line, one total. The seller grouping is only used to
/// charge the correct flat fee per seller — the buyer never sees the split.
/// Until the backend computes a fee, the delivery line reads "set at order"
/// and the total is exactly what payment charges.
class _CheckoutSummaryCard extends StatelessWidget {
  final Map<String, List<CartLine>> groups;
  final int deliveryFee;

  const _CheckoutSummaryCard({required this.groups, required this.deliveryFee});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.t;

    var subtotal = 0;
    for (final entry in groups.entries) {
      for (final line in entry.value) {
        subtotal += line.lineTotal;
      }
    }
    final deliveryTotal = deliveryFee * groups.length;
    final total = subtotal + deliveryTotal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.items, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            for (final entry in groups.entries)
              for (final line in entry.value) ...[
                _LineRow(
                  line: line,
                  sellerName: line.product.sellerName,
                ),
                const SizedBox(height: 4),
              ],
            const Divider(),
            _priceRow(context, t.subtotal, subtotal),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t.delivery, style: theme.textTheme.bodyMedium),
                  Text(
                    'Set at order',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.tanDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.total, style: theme.textTheme.titleSmall),
                AmountText(
                  total,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(BuildContext context, String label, int amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          AmountText(amount, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  final CartLine line;
  final String? sellerName;

  const _LineRow({required this.line, this.sellerName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.product.name, style: Theme.of(context).textTheme.bodyMedium),
              Text(
                sellerName == null
                    ? '${_trimKg(line.quantityKg)} kg'
                    : '$sellerName · ${_trimKg(line.quantityKg)} kg',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.tanDark),
              ),
            ],
          ),
        ),
        AmountText(line.lineTotal, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  String _trimKg(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';
}

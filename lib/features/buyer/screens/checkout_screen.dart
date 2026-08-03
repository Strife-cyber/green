import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/address.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../theme/app_colors.dart';
import '../controllers/address_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/checkout_controller.dart';

/// Checkout (BUY-07): groups the cart by seller into one order per seller,
/// lets the buyer pick a saved delivery address (or add one) and places every
/// order through `orderRepository`. On success the buyer lands on payment.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  /// Flat per-order delivery fee in FCFA.
  static const int deliveryFee = 500;

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
        title: const Text('Checkout')),
      body: cart.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Nothing to checkout',
              message: 'Your cart is empty.',
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
                    for (final entry in groups.entries) ...[
                      _SellerOrderCard(
                        sellerId: entry.key,
                        lines: entry.value,
                        deliveryFee: deliveryFee,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _GrandTotal(
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
                          : const Text('Place order'),
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
    final orderId = await ref
        .read(checkoutControllerProvider.notifier)
        .submit(
          sellerGroups: groups,
          address: address,
          deliveryFee: deliveryFee,
        );
    if (orderId == null || !mounted) return;
    ref.read(cartControllerProvider.notifier).clear();
    context.pushReplacement(AppRoutes.payment(orderId));
  }
}

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
            Text('Delivery address', style: theme.textTheme.titleSmall),
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

/// Per-seller order summary: items, subtotal, delivery and total.
class _SellerOrderCard extends StatelessWidget {
  final String sellerId;
  final List<CartLine> lines;
  final int deliveryFee;

  const _SellerOrderCard({
    required this.sellerId,
    required this.lines,
    required this.deliveryFee,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sellerName = lines.first.product.sellerName ?? 'Seller';
    final subtotal = lines.fold(0, (sum, line) => sum + line.lineTotal);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront_outlined, color: AppColors.green),
                const SizedBox(width: 8),
                Text(sellerName, style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            for (final line in lines) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${line.product.name} × ${_trimKg(line.quantityKg)} kg',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  AmountText(line.lineTotal, style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 4),
            ],
            const Divider(),
            _priceRow(context, 'Subtotal', subtotal),
            _priceRow(context, 'Delivery', deliveryFee),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: theme.textTheme.titleSmall),
                AmountText(
                  subtotal + deliveryFee,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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

  String _trimKg(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';
}

/// Overall checkout total across every per-seller order.
class _GrandTotal extends StatelessWidget {
  final Map<String, List<CartLine>> groups;
  final int deliveryFee;

  const _GrandTotal({required this.groups, required this.deliveryFee});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var grandTotal = 0;
    var itemCount = 0;
    for (final entry in groups.entries) {
      for (final line in entry.value) {
        grandTotal += line.lineTotal;
        itemCount++;
      }
      grandTotal += deliveryFee;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$itemCount item${itemCount == 1 ? '' : 's'} · '
          '${groups.length} order${groups.length == 1 ? '' : 's'}',
          style: theme.textTheme.bodyMedium,
        ),
        AmountText(
          grandTotal,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.greenDark,
          ),
        ),
      ],
    );
  }
}

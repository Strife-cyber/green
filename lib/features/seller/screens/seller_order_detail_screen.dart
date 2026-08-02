import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/order.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/order_timeline.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../theme/app_colors.dart';
import '../controllers/seller_order_detail_controller.dart';

/// Order detail with status actions and chat (SELL-03).
class SellerOrderDetailScreen extends ConsumerWidget {
  final String id;

  const SellerOrderDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(sellerOrderDetailControllerProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: AsyncView<Order>(
        value: orderAsync,
        onRetry: () => ref.invalidate(sellerOrderDetailControllerProvider(id)),
        builder: (order) => _OrderDetailContent(
          order: order,
          onStatus: (status) => _updateStatus(context, ref, status),
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, OrderStatus status) async {
    if (status == OrderStatus.cancelled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cancel order?'),
          content: const Text('This will cancel the order for the buyer.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
              child: const Text('Yes, cancel'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    try {
      await ref.read(sellerOrderDetailControllerProvider(id).notifier).updateStatus(status);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update the order.')),
        );
      }
    }
  }
}

class _OrderDetailContent extends StatelessWidget {
  final Order order;
  final void Function(OrderStatus status) onStatus;

  const _OrderDetailContent({required this.order, required this.onStatus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('#${order.id}', style: theme.textTheme.titleMedium),
                    StatusBadge.order(order.status),
                  ],
                ),
                if (order.placedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    formatDateTime(order.placedAt!),
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
                  ),
                ],
                if (order.deliveryAddressLabel != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.tanDark),
                      const SizedBox(width: 4),
                      Text(order.deliveryAddressLabel!, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Items', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final item in order.items) _ItemRow(item: item),
                const Divider(),
                _TotalRow(label: 'Subtotal', amount: order.subtotal),
                _TotalRow(label: 'Delivery', amount: order.deliveryFee),
                _TotalRow(label: 'Total', amount: order.totalAmount, bold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progress', style: theme.textTheme.titleSmall),
                const SizedBox(height: 12),
                OrderTimeline(status: order.status),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ..._actionButtons(context),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutes.chat(order.id)),
          icon: const Icon(Icons.chat_outlined),
          label: const Text('Chat with buyer'),
        ),
      ],
    );
  }

  List<Widget> _actionButtons(BuildContext context) {
    final buttons = <Widget>[];
    switch (order.status) {
      case OrderStatus.pending:
        buttons
          ..add(FilledButton(onPressed: () => onStatus(OrderStatus.confirmed), child: const Text('Confirm order')))
          ..add(const SizedBox(height: 8))
          ..add(OutlinedButton.icon(
            onPressed: () => onStatus(OrderStatus.cancelled),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel order'),
          ));
        break;
      case OrderStatus.confirmed:
        buttons
          ..add(FilledButton(onPressed: () => onStatus(OrderStatus.shipped), child: const Text('Mark as shipped')))
          ..add(const SizedBox(height: 8))
          ..add(OutlinedButton.icon(
            onPressed: () => onStatus(OrderStatus.cancelled),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel order'),
          ));
        break;
      case OrderStatus.shipped:
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        break;
    }
    return buttons;
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItem item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '${item.productName} × ${formatKg(item.quantityKg)}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          AmountText(item.lineTotal, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final int amount;
  final bool bold;

  const _TotalRow({required this.label, required this.amount, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = bold
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          AmountText(amount, style: style),
        ],
      ),
    );
  }
}

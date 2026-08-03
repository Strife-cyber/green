import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../chat/chat_actions.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/providers.dart';
import '../../../data/repositories/rating_repository.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/order_timeline.dart';
import '../../../shared/widgets/report_dialog.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../theme/app_colors.dart';
import '../controllers/order_detail_controller.dart';

/// Order detail (BUY-10): itemised breakdown, lifecycle timeline, status
/// badges and contextual actions (pay, track, receipt, chat, rate seller).
class OrderDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const OrderDetailScreen({super.key, required this.id});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(orderDetailControllerProvider.notifier).load(widget.id);
  }

  @override
  void didUpdateWidget(OrderDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      ref.read(orderDetailControllerProvider.notifier).load(widget.id);
    }
  }

  Future<void> _rateSeller(Order order) async {
    final rating = await showDialog<int>(
      context: context,
      builder: (context) => _RateSellerDialog(order: order),
    );
    if (rating == null || !mounted) return;
    try {
      await ref.read(ratingRepositoryProvider).create(CreateRatingInput(
            orderId: order.id,
            sellerId: order.sellerId,
            rating: rating,
          ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for rating this seller!')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit your rating.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderDetailControllerProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Order Details')),
      body: AsyncView<Order>(
        value: order,
        onRetry: () =>
            ref.read(orderDetailControllerProvider.notifier).load(widget.id),
        builder: (o) => _buildOrder(context, o),
      ),
    );
  }

  Widget _buildOrder(BuildContext context, Order order) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                order.sellerName ?? 'Order ${orderReference(order.id)}',
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Report seller',
              icon: const Icon(Icons.flag_outlined, size: 20),
              onPressed: () => showReportDialog(
                context,
                ref,
                reportedId: order.sellerId,
                targetType: ReportTargetType.profile,
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                StatusBadge.order(order.status),
                StatusBadge.payment(order.paymentStatus),
              ],
            ),
          ],
        ),
        if (order.placedAt != null) ...[
          const SizedBox(height: 4),
          Text(
            DateFormat('d MMM yyyy · HH:mm').format(order.placedAt!),
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
          ),
        ],
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: OrderTimeline(status: order.status),
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
                for (final item in order.items) ...[
                  _itemRow(item),
                  const SizedBox(height: 8),
                ],
                const Divider(),
                _priceRow('Subtotal', order.subtotal),
                _priceRow('Delivery', order.deliveryFee),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: theme.textTheme.titleSmall),
                    AmountText(
                      order.totalAmount,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _actions(order),
      ],
    );
  }

  Widget _itemRow(OrderItem item) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.productName, style: theme.textTheme.bodyMedium),
              Text(
                '${_trimKg(item.quantityKg)} kg · ${formatMoney(item.unitPrice)}/kg',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
              ),
            ],
          ),
        ),
        AmountText(item.lineTotal, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _priceRow(String label, int amount) {
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

  Widget _actions(Order order) {
    final unpaid = order.paymentStatus == PaymentStatus.unpaid;
    final shipped = order.status == OrderStatus.shipped;
    final delivered = order.status == OrderStatus.delivered;

    final buttons = <Widget>[];
    if (unpaid) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.payment(order.id)),
          icon: const Icon(Icons.payment),
          label: const Text('Pay now'),
        ),
      );
    }
    if (shipped) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutes.deliveryTracking(order.id)),
          icon: const Icon(Icons.local_shipping_outlined),
          label: const Text('Track delivery'),
        ),
      );
    }
    if (delivered) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutes.receipt(order.id)),
          icon: const Icon(Icons.receipt_long_outlined),
          label: const Text('View receipt'),
        ),
      );
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _rateSeller(order),
          icon: const Icon(Icons.star_outline),
          label: const Text('Rate seller'),
        ),
      );
    }
    buttons.add(
      OutlinedButton.icon(
        onPressed: () => openChatForOrder(context, ref, order.id),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Chat with seller'),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final button in buttons) ...[button, const SizedBox(height: 10)],
      ],
    );
  }

  String _trimKg(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';
}

/// Star + optional-review rating dialog (one rating per delivered order).
class _RateSellerDialog extends ConsumerStatefulWidget {
  final Order order;

  const _RateSellerDialog({required this.order});

  @override
  ConsumerState<_RateSellerDialog> createState() => _RateSellerDialogState();
}

class _RateSellerDialogState extends ConsumerState<_RateSellerDialog> {
  int _rating = 5;
  final _review = TextEditingController();

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rate ${widget.order.sellerName ?? 'seller'}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  icon: Icon(
                    i <= _rating ? Icons.star : Icons.star_border,
                    color: AppColors.orange,
                  ),
                  onPressed: () => setState(() => _rating = i),
                ),
            ],
          ),
          TextField(
            controller: _review,
            maxLines: 3,
            maxLength: 240,
            decoration: const InputDecoration(labelText: 'Review (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _rating),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

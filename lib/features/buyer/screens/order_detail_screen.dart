import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/delivery.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/providers.dart';
import '../../../data/repositories/rating_repository.dart';
import '../../../l10n/l10n_ext.dart';
import '../../chat/chat_actions.dart';
import '../../delivery/controllers/delivery_tracking_controller.dart';
import '../../delivery/widgets/live_delivery_map.dart';
import '../../order/order_status_text.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/report_dialog.dart';
import '../../../theme/app_colors.dart';
import '../../wallet/controllers/ledger_controller.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../controllers/buyer_order_list_controller.dart';
import '../controllers/order_detail_controller.dart';

/// Order detail (BUY-10): a single plain-language status line, the itemised
/// breakdown, delivery address with a Chat pill and — once the driver is on
/// the way — a live map plus a "Got it" confirm. Confirming is a one-tap when
/// the order is below the code-required threshold, otherwise the buyer enters
/// the 6-digit code emailed to them.
class OrderDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const OrderDetailScreen({super.key, required this.id});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  final _codeController = TextEditingController();
  bool _confirming = false;

  DeliveryTrackingRequest get _trackingRequest =>
      DeliveryTrackingRequest(orderId: widget.id);

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
      _codeController.clear();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
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

  /// Buyer-initiated cancel. The backend only allows this while the order is
  /// PENDING — the button is hidden otherwise (see [_actions]).
  Future<void> _cancelOrder(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text(
          'The order will be cancelled and you will not be charged. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(orderRepositoryProvider)
          .updateStatus(order.id, OrderStatus.cancelled);
      if (!mounted) return;
      ref.invalidate(orderDetailControllerProvider);
      ref.invalidate(buyerOrderListControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not cancel this order right now.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderDetailControllerProvider);
    // The delivery (live position + codeRequired + pickup/delivered flags)
    // comes from the shared tracking controller — reused, not rebuilt.
    final tracking = ref.watch(deliveryTrackingControllerProvider(_trackingRequest));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(context.t.orderDetails)),
      body: AsyncView<Order>(
        value: order,
        onRetry: () =>
            ref.read(orderDetailControllerProvider.notifier).load(widget.id),
        builder: (o) => _buildOrder(context, o, tracking.delivery),
      ),
    );
  }

  Widget _buildOrder(BuildContext context, Order order, Delivery? delivery) {
    final theme = Theme.of(context);
    final shipped = order.status == OrderStatus.shipped;
    final canGotIt = shipped && delivery != null && delivery.isAwaitingBuyer;

    final addressLabel = order.deliveryAddressLabel ??
        delivery?.deliveryAddress?.label ??
        delivery?.deliveryAddress?.addressLine ??
        context.t.deliveryAddress;

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
              tooltip: context.t.report,
              icon: const Icon(Icons.flag_outlined, size: 20),
              onPressed: () => showReportDialog(
                context,
                ref,
                reportedId: order.sellerId,
                targetType: ReportTargetType.profile,
              ),
            ),
          ],
        ),
        Text(
          orderStatusPhrase(context, order.status),
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (order.placedAt != null) ...[
          const SizedBox(height: 4),
          Text(
            DateFormat('d MMM yyyy · HH:mm').format(order.placedAt!),
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
          ),
        ],
        if (canGotIt) ...[
          const SizedBox(height: 16),
          _gotItCard(context, delivery),
        ],
        if (shipped && delivery != null) ...[
          const SizedBox(height: 16),
          LiveDeliveryMap(
            delivery: delivery,
            height: 220,
            onTap: () => context.push(AppRoutes.liveMap(widget.id)),
          ),
        ],
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.t.items, style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final item in order.items) ...[
                  _itemRow(item),
                  const SizedBox(height: 8),
                ],
                const Divider(),
                _priceRow(context.t.subtotal, order.subtotal),
                _priceRow(context.t.delivery, order.deliveryFee),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.t.total, style: theme.textTheme.titleSmall),
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.t.deliveryAddress, style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18, color: AppColors.tanDark),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        addressLabel,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    _ChatPill(order: order),
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

  /// The "Got it" card — shown once the driver has picked up (order SHIPPED)
  /// but the buyer hasn't confirmed yet. The 6-digit input appears while the
  /// order is code-required or a code has been issued (backend sends
  /// `codeRequired`/`confirmationCodeIssued`); below the threshold the card
  /// stays a one-tap confirm.
  Widget _gotItCard(BuildContext context, Delivery delivery) {
    final theme = Theme.of(context);
    final t = context.t;
    final needsCode = delivery.codeRequired || delivery.confirmationCodeIssued;
    final code = _codeController.text.trim();
    return Card(
      color: AppColors.greenContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.greenDark, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(t.driverArrivedTitle, style: theme.textTheme.titleSmall),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              t.driverArrivedBody,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
            ),
            if (needsCode) ...[
              const SizedBox(height: 12),
              Text(
                t.gotItCodeHint,
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.greenDark),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: t.confirmationCode,
                  prefixIcon: const Icon(Icons.pin_outlined),
                  counterText: '',
                ),
                onChanged: (_) {
                  setState(() {});
                  // Auto-submit on the 6th digit — one fewer tap.
                  if (_codeController.text.trim().length == 6 && !_confirming) {
                    _confirmGotIt(delivery);
                  }
                },
                onSubmitted: (_) {
                  if (code.length == 6) _confirmGotIt(delivery);
                },
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: (!needsCode || code.length == 6) && !_confirming
                  ? () => _confirmGotIt(delivery)
                  : null,
              icon: const Icon(Icons.check),
              label: Text(t.gotIt),
              style: FilledButton.styleFrom(backgroundColor: AppColors.greenDark),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmGotIt(Delivery delivery) async {
    final needsCode = delivery.codeRequired || delivery.confirmationCodeIssued;
    final code = _codeController.text.trim();
    if (needsCode && code.length != 6) return;
    setState(() => _confirming = true);
    try {
      await ref
          .read(deliveryRepositoryProvider)
          .confirm(delivery.id, code: needsCode ? code : null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.deliveryConfirmed)),
      );
      ref.invalidate(orderDetailControllerProvider);
      ref.invalidate(buyerOrderListControllerProvider);
      // Confirming releases escrow — refresh the wallet surfaces too.
      ref.invalidate(walletControllerProvider);
      ref.invalidate(ledgerControllerProvider);
      await ref
          .read(deliveryTrackingControllerProvider(_trackingRequest).notifier)
          .refreshNow();
    } catch (error) {
      // API errors verbatim — e.g. a wrong code's "attempts left" message.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(error, context))),
        );
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
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
    final t = context.t;
    final unpaid = order.paymentStatus == PaymentStatus.unpaid;
    final pending = order.status == OrderStatus.pending;
    final shipped = order.status == OrderStatus.shipped;
    final delivered = order.status == OrderStatus.delivered;

    final buttons = <Widget>[];
    if (pending) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _cancelOrder(order),
          icon: const Icon(Icons.cancel_outlined),
          label: Text(t.cancelOrder),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.orangeDark,
            side: BorderSide(color: AppColors.orangeDark),
          ),
        ),
      );
    }
    if (unpaid) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.payment(order.id)),
          icon: const Icon(Icons.payment),
          label: Text(t.payNow),
        ),
      );
    }
    if (shipped) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutes.deliveryTracking(order.id)),
          icon: const Icon(Icons.local_shipping_outlined),
          label: Text(t.qaTrackDelivery),
        ),
      );
    }
    if (delivered) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutes.receipt(order.id)),
          icon: const Icon(Icons.receipt_long_outlined),
          label: Text(t.viewReceipt),
        ),
      );
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _rateSeller(order),
          icon: const Icon(Icons.star_outline),
          label: Text(t.rateSeller),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final button in buttons) ...[button, const SizedBox(height: 10)],
      ],
    );
  }

  String _trimKg(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';
}

/// Pill-styled "Chat with seller" affordance (CHAT-01), matching the app's
/// rounded-badge language.
class _ChatPill extends ConsumerWidget {
  final Order order;

  const _ChatPill({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => openChatForOrder(context, ref, order.id),
      icon: const Icon(Icons.chat_bubble_outline, size: 18),
      label: Text(context.t.chatWithSeller),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        foregroundColor: AppColors.greenDark,
        side: BorderSide(color: AppColors.green.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
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

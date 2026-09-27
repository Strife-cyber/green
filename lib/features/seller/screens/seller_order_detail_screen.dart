import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../chat/chat_actions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/order.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/providers.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/order_timeline.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';
import '../../order/order_status_text.dart';
import '../controllers/seller_order_detail_controller.dart';
import '../controllers/seller_queue_controller.dart';

/// Seller order detail (SELL-03): status, items, progress — and the actions
/// that advance a paid order through its lifecycle: Confirm (PENDING +
/// ESCROW_HELD) → Assign driver (CONFIRMED, `POST /deliveries`) → Mark as
/// shipped (delivery assigned). Pickup/delivery completion stays with the
/// driver and the buyer.
class SellerOrderDetailScreen extends ConsumerWidget {
  final String id;

  const SellerOrderDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(sellerOrderDetailControllerProvider(id));
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(context.t.orderDetails)),
      body: AsyncView<Order>(
        value: orderAsync,
        onRetry: () => ref.invalidate(sellerOrderDetailControllerProvider(id)),
        builder: (order) => _OrderDetailContent(
          order: order,
          onStatus: (status) => _updateStatus(context, ref, order, status),
          onAssignDriver: () => _assignDriver(context, ref, order),
          onCancel: () => _cancelOrder(context, ref, order),
        ),
      ),
    );
  }

  /// `PATCH /orders/{id}/status` — API errors surface verbatim in a snackbar.
  Future<void> _updateStatus(
      BuildContext context, WidgetRef ref, Order order, OrderStatus status) async {
    try {
      await ref
          .read(sellerOrderDetailControllerProvider(order.id).notifier)
          .updateStatus(status);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(error, context))),
        );
      }
    }
  }

  /// Picks a DRIVER user and assigns them via `POST /deliveries`
  /// (`GET /deliveries/drivers` powers the picker). The returned delivery is
  /// merged into the order — it's the record that unlocks "Mark as shipped".
  Future<void> _assignDriver(
      BuildContext context, WidgetRef ref, Order order) async {
    final driver = await showModalBottomSheet<User>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _DriverPickerSheet(),
    );
    if (driver == null || !context.mounted) return;
    try {
      final delivery =
          await ref.read(deliveryRepositoryProvider).assign(order.id, driver.id);
      ref
          .read(sellerOrderDetailControllerProvider(order.id).notifier)
          .deliveryAssigned(delivery);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(error, context))),
        );
      }
    }
  }

  /// Buyer-initiated cancellation is gone (no confirm buttons). The seller can
  /// still cancel a PENDING order; paid orders are only cancelled by support.
  Future<void> _cancelOrder(
      BuildContext context, WidgetRef ref, Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel order?'),
        content: const Text('This will cancel the order for the buyer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(sellerOrderDetailControllerProvider(order.id).notifier)
          .updateStatus(OrderStatus.cancelled);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(error, context))),
        );
      }
    }
  }
}

class _OrderDetailContent extends ConsumerWidget {
  final Order order;
  final ValueChanged<OrderStatus> onStatus;
  final VoidCallback onAssignDriver;
  final VoidCallback onCancel;

  const _OrderDetailContent({
    required this.order,
    required this.onStatus,
    required this.onAssignDriver,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = context.t;
    final prepared = ref.watch(sellerPreparedProvider).contains(order.id);
    final pending = order.status == OrderStatus.pending;
    final confirmed = order.status == OrderStatus.confirmed;
    final shipped = order.status == OrderStatus.shipped;
    // The escrow must be held before the seller commits stock.
    final confirmable = pending && order.paymentStatus == PaymentStatus.escrowHeld;
    final assigned = order.deliveryId != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(orderReference(order.id), style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  orderStatusPhrase(context, order.status),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.greenDark,
                    fontWeight: FontWeight.w600,
                  ),
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
                Text(t.items, style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final item in order.items) _ItemRow(item: item),
                const Divider(),
                _TotalRow(label: t.subtotal, amount: order.subtotal),
                _TotalRow(label: t.delivery, amount: order.deliveryFee),
                _TotalRow(label: t.total, amount: order.totalAmount, bold: true),
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
                Text(t.orderDetails, style: theme.textTheme.titleSmall),
                const SizedBox(height: 12),
                OrderTimeline(status: order.status),
              ],
            ),
          ),
        ),
        if (confirmed) ...[
          const SizedBox(height: 16),
          _prepareCard(context, ref, prepared),
          const SizedBox(height: 16),
          _driverCard(context),
        ],
        const SizedBox(height: 16),
        if (confirmable) ...[
          FilledButton.icon(
            onPressed: () => onStatus(OrderStatus.confirmed),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirm order'),
          ),
          const SizedBox(height: 12),
        ],
        if (confirmed && assigned) ...[
          FilledButton.icon(
            onPressed: () => onStatus(OrderStatus.shipped),
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Mark as shipped'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.greenDark),
          ),
          const SizedBox(height: 12),
        ],
        if (pending) ...[
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel_outlined),
            label: Text(t.cancelOrder),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.orangeDark,
              side: BorderSide(color: AppColors.orangeDark),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (shipped) ...[
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.deliveryTracking(order.id)),
            icon: const Icon(Icons.local_shipping_outlined),
            label: Text(t.qaTrackDelivery),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: () => openChatForOrder(context, ref, order.id),
          icon: const Icon(Icons.chat_outlined),
          label: Text(t.chatWithBuyer),
        ),
      ],
    );
  }

  /// Delivery status + the Assign-driver affordance. The delivery record
  /// (created on assign) is what unlocks "Mark as shipped" — shipping an
  /// order with no driver would leave the code flow unstartable.
  Widget _driverCard(BuildContext context) {
    final theme = Theme.of(context);
    final assigned = order.deliveryId != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              assigned ? Icons.local_shipping : Icons.local_shipping_outlined,
              color: assigned ? AppColors.green : AppColors.tanDark,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assigned
                        ? 'Assigned to ${order.deliveryDriverName ?? 'a driver'}'
                        : 'No driver assigned yet',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    assigned
                        ? 'Mark the order as shipped once the goods leave.'
                        : 'Assign a driver before marking this order as shipped.',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
                  ),
                ],
              ),
            ),
            if (!assigned)
              TextButton(
                onPressed: onAssignDriver,
                child: const Text('Assign driver'),
              ),
          ],
        ),
      ),
    );
  }

  /// Soft "Done": a local marking that this order is prepared and now awaits
  /// the driver's pickup. No backend write — the driver's pickup flips the
  /// order SHIPPED.
  Widget _prepareCard(BuildContext context, WidgetRef ref, bool prepared) {
    final theme = Theme.of(context);
    final t = context.t;
    return Card(
      color: prepared ? AppColors.greenContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.toPrepare, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              t.noQueueHint,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
            ),
            const SizedBox(height: 12),
            if (!prepared)
              FilledButton.icon(
                onPressed: () => ref
                    .read(sellerPreparedProvider.notifier)
                    .update((set) => {...set, order.id}),
                icon: const Icon(Icons.check),
                label: Text(t.done),
                style: FilledButton.styleFrom(backgroundColor: AppColors.greenDark),
              )
            else
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.greenDark, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    t.prepared,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.greenDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
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

/// Bottom sheet: pick one of the available DRIVER users to assign to the order
/// (DEL-02). `GET /deliveries/drivers` powers the list — the admin-console
/// driver endpoint is admin-only.
class _DriverPickerSheet extends ConsumerStatefulWidget {
  const _DriverPickerSheet();

  @override
  ConsumerState<_DriverPickerSheet> createState() => _DriverPickerSheetState();
}

class _DriverPickerSheetState extends ConsumerState<_DriverPickerSheet> {
  late Future<List<User>> _driversFuture;

  @override
  void initState() {
    super.initState();
    _driversFuture = ref.read(deliveryRepositoryProvider).availableDrivers();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('Assign a driver', style: theme.textTheme.titleMedium),
            ),
            Expanded(
              child: FutureBuilder<List<User>>(
                future: _driversFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ErrorView(
                      message: friendlyErrorMessage(snapshot.error!, context),
                      onRetry: () => setState(() {
                        _driversFuture = ref
                            .read(deliveryRepositoryProvider)
                            .availableDrivers();
                      }),
                    );
                  }
                  final drivers = snapshot.data ?? const <User>[];
                  if (drivers.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No drivers available yet.'),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: drivers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final driver = drivers[index];
                      return Card(
                        child: ListTile(
                          leading: UserAvatar(name: driver.fullName),
                          title: Text(
                            driver.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${driver.region ?? 'Region unknown'} · ${driver.phone ?? driver.email}',
                          ),
                          onTap: () => Navigator.of(context).pop(driver),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

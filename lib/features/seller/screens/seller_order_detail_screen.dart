import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/chat_actions.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/order.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/providers.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/order_timeline.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/user_avatar.dart';
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Order')),
      body: AsyncView<Order>(
        value: orderAsync,
        onRetry: () => ref.invalidate(sellerOrderDetailControllerProvider(id)),
        builder: (order) => _OrderDetailContent(
          order: order,
          onStatus: (status) => _updateStatus(context, ref, status),
          onAssignDriver: () => _assignDriver(context, ref, order.id),
        ),
      ),
    );
  }

  /// Picks a DRIVER user and assigns them to the order via `POST /deliveries`
  /// (DEL-02). The delivery record is what unlocks "Mark as shipped".
  Future<void> _assignDriver(
      BuildContext context, WidgetRef ref, String orderId) async {
    final driver = await showModalBottomSheet<User>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _DriverPickerSheet(),
    );
    if (driver == null || !context.mounted) return;
    try {
      final delivery =
          await ref.read(deliveryRepositoryProvider).assign(orderId, driver.id);
      if (context.mounted) {
        ref
            .read(sellerOrderDetailControllerProvider(orderId).notifier)
            .deliveryAssigned(delivery);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${driver.fullName} assigned to this order')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not assign — the order may already have a driver.'),
          ),
        );
      }
    }
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

class _OrderDetailContent extends ConsumerWidget {
  final Order order;
  final void Function(OrderStatus status) onStatus;
  final VoidCallback onAssignDriver;

  const _OrderDetailContent({
    required this.order,
    required this.onStatus,
    required this.onAssignDriver,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    Text(orderReference(order.id), style: theme.textTheme.titleMedium),
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
        _driverCard(context),
        const SizedBox(height: 16),
        ..._actionButtons(context),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => openChatForOrder(context, ref, order.id),
          icon: const Icon(Icons.chat_outlined),
          label: const Text('Chat with buyer'),
        ),
      ],
    );
  }

  /// Delivery/assignment status. The delivery record (created by [assign])
  /// is the gate that unlocks "Mark as shipped" — without it the order would
  /// end up SHIPPED with no driver and the code flow can never start.
  Widget _driverCard(BuildContext context) {
    final theme = Theme.of(context);
    final assigned = order.deliveryId != null;
    final canAssign = !assigned &&
        (order.status == OrderStatus.pending ||
            order.status == OrderStatus.confirmed);
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
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.tanDark),
                  ),
                ],
              ),
            ),
            if (canAssign)
              TextButton(
                onPressed: onAssignDriver,
                child: const Text('Assign driver'),
              ),
          ],
        ),
      ),
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
        final canShip = order.deliveryId != null;
        buttons.add(FilledButton(
          onPressed: canShip ? () => onStatus(OrderStatus.shipped) : null,
          child: const Text('Mark as shipped'),
        ));
        if (!canShip) {
          buttons
            ..add(const SizedBox(height: 4))
            ..add(Text(
              'Assign a driver to enable shipping.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.tanDark),
            ));
        }
        buttons
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

/// Bottom sheet: pick one of the available DRIVER users to assign to an order
/// (DEL-02). The driver list is fetched through the delivery repository because
/// the admin-console driver endpoint is admin-only.
class _DriverPickerSheet extends ConsumerStatefulWidget {
  const _DriverPickerSheet();

  @override
  ConsumerState<_DriverPickerSheet> createState() => _DriverPickerSheetState();
}

class _DriverPickerSheetState extends ConsumerState<_DriverPickerSheet> {
  late final Future<List<User>> _driversFuture;

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
                    return const Center(child: Text('Could not load drivers.'));
                  }
                  final drivers = snapshot.data ?? const <User>[];
                  if (drivers.isEmpty) {
                    return const Center(child: Text('No drivers available yet.'));
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/delivery.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../controllers/admin_deliveries_controller.dart';

/// In-flight deliveries (assigned but not yet delivered) for admin oversight
/// (ADM-05, DEL-02/03).
class AdminDeliveriesScreen extends StatelessWidget {
  const AdminDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deliveries')),
      body: const AdminDeliveriesBody(),
    );
  }
}

/// Reusable list body — also embedded as the "Deliveries" tab of the admin shell.
class AdminDeliveriesBody extends ConsumerWidget {
  const AdminDeliveriesBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveries = ref.watch(adminDeliveriesControllerProvider);
    return AsyncView<List<Delivery>>(
      value: deliveries,
      onRetry: () => ref.invalidate(adminDeliveriesControllerProvider),
      builder: (list) => list.isEmpty
          ? const EmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'No active deliveries',
              message: 'Deliveries on the road will appear here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _DeliveryCard(delivery: list[index]),
            ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final Delivery delivery;

  const _DeliveryCard({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(name: delivery.driverName ?? delivery.driverId ?? 'Driver'),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery.driverName ?? 'Unassigned driver',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text('Order ${delivery.orderId}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Chip(
                  label: delivery.isPickupConfirmed ? 'Pickup confirmed' : 'Pending pickup',
                  active: delivery.isPickupConfirmed,
                ),
                if (delivery.assignedAt != null) ...[
                  const Spacer(),
                  Text(formatDate(delivery.assignedAt!), style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;

  const _Chip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF2E7D32) : const Color(0xFFC94F1F);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

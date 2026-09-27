import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/delivery.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../controllers/admin_deliveries_controller.dart';

/// In-flight deliveries (assigned but not yet delivered) for admin oversight
/// (ADM-05, DEL-02/03).
class AdminDeliveriesScreen extends StatelessWidget {
  const AdminDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Deliveries')),
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
    return RefreshableAsyncView<List<Delivery>>(
      value: deliveries,
      onRefresh: () => ref.read(adminDeliveriesControllerProvider.notifier).refresh(),
      onRetry: () => ref.invalidate(adminDeliveriesControllerProvider),
      empty: const EmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'No active deliveries',
        message: 'Deliveries on the road will appear here.',
      ),
      builder: (list) => ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        // The live map sits above the cards (design 40) — one marker per
        // delivery that has a reported position.
        itemCount: list.length + 2,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) return _LiveMap(deliveries: list);
          if (index == 1) {
            return Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push(AppRoutes.adminChat),
                icon: const Icon(Icons.forum_outlined, size: 18),
                label: Text(context.t.openChatAudit),
              ),
            );
          }
          return _DeliveryCard(delivery: list[index - 2]);
        },
      ),
    );
  }
}

/// Map of every active delivery's latest reported position (design 40).
/// Douala-centred with fallback zoom until a driver posts a fix.
class _LiveMap extends StatelessWidget {
  final List<Delivery> deliveries;

  const _LiveMap({required this.deliveries});

  static const _fallback = LatLng(4.0511, 9.7679); // Douala
  static const _tileTemplate =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

  @override
  Widget build(BuildContext context) {
    final points = [
      for (final d in deliveries)
        if (d.currentLatitude != null && d.currentLongitude != null)
          LatLng(d.currentLatitude!, d.currentLongitude!),
    ];
    final center = points.isNotEmpty
        ? LatLng(
            points.map((p) => p.latitude).reduce((a, b) => a + b) /
                points.length,
            points.map((p) => p.longitude).reduce((a, b) => a + b) /
                points.length,
          )
        : _fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: points.isEmpty ? 11 : 12,
          ),
          children: [
            TileLayer(
              urlTemplate: _tileTemplate,
              subdomains: const ['a', 'b', 'c', 'd'],
              retinaMode: true,
              userAgentPackageName: 'com.example.green',
            ),
            MarkerLayer(
              markers: [
                for (final d in deliveries)
                  if (d.currentLatitude != null &&
                      d.currentLongitude != null)
                    Marker(
                      point: LatLng(
                          d.currentLatitude!, d.currentLongitude!),
                      width: 40,
                      height: 40,
                      child: Tooltip(
                        message: d.driverName ??
                            'Order ${orderReference(d.orderId)}',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.green,
                            border: Border.all(
                                color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.local_shipping,
                              color: Colors.white, size: 16),
                        ),
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
                      Text('Order ${orderReference(delivery.orderId)}', style: theme.textTheme.bodySmall),
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

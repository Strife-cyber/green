import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/delivery.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/providers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/order_timeline.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../theme/app_colors.dart';
import '../controllers/delivery_tracking_controller.dart';
import '../widgets/live_delivery_map.dart';

/// Loads the order so the buyer can see its delivery confirmation code.
final deliveryOrderProvider = FutureProvider.family<Order, String>(
  (ref, orderId) => ref.watch(orderRepositoryProvider).get(orderId),
);

/// Buyer/seller view: live map with the moving driver marker plus the order
/// timeline and a link to contact the driver (DEL-04).
class DeliveryTrackingScreen extends ConsumerWidget {
  final String orderId;

  const DeliveryTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = DeliveryTrackingRequest(orderId: orderId);
    final state = ref.watch(deliveryTrackingControllerProvider(request));
    return Scaffold(
      appBar: AppBar(title: const Text('Live Tracking')),
      body: _body(context, ref, request, state),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    DeliveryTrackingRequest request,
    DeliveryTrackingState state,
  ) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.delivery == null) {
      return ErrorView(
        message: state.error!,
        onRetry: () =>
            ref.read(deliveryTrackingControllerProvider(request).notifier).refreshNow(),
      );
    }
    final delivery = state.delivery;
    if (delivery == null) {
      return const EmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'No delivery for this order',
        message: 'This order has not been assigned to a driver yet.',
      );
    }
    final code = ref.watch(deliveryOrderProvider(orderId)).valueOrNull?.confirmationCode;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiveDeliveryMap(delivery: delivery, height: 280),
        const SizedBox(height: 16),
        _statusRow(context, delivery),
        if (code != null) ...[
          const SizedBox(height: 16),
          _confirmationCard(context, code),
        ],
        const SizedBox(height: 24),
        OrderTimeline(status: _orderStatusFor(delivery)),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutes.chat(delivery.orderId)),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Contact driver'),
        ),
      ],
    );
  }

  /// Prominent delivery confirmation code the buyer shares with the driver
  /// (DEL-07).
  Widget _confirmationCard(BuildContext context, String code) {
    final theme = Theme.of(context);
    return Card(
      color: AppColors.greenContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.qr_code_2, color: AppColors.greenDark, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Give this code to your driver',
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    code,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.greenDark,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(BuildContext context, Delivery delivery) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Order #${delivery.orderId}',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        _statusBadge(delivery),
      ],
    );
  }

  Widget _statusBadge(Delivery delivery) {
    if (delivery.isDelivered) {
      return const StatusBadge(label: 'Delivered', color: AppColors.green);
    }
    if (delivery.isPickupConfirmed) {
      return const StatusBadge(label: 'En route', color: AppColors.orange);
    }
    return const StatusBadge(label: 'Assigned', color: AppColors.tanDark);
  }

  OrderStatus _orderStatusFor(Delivery delivery) {
    if (delivery.isDelivered) return OrderStatus.delivered;
    if (delivery.isPickupConfirmed) return OrderStatus.shipped;
    return OrderStatus.confirmed;
  }
}

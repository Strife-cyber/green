import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/chat_actions.dart';
import '../../../data/models/delivery.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/providers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/order_timeline.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../theme/app_colors.dart';
import '../controllers/delivery_tracking_controller.dart';
import '../widgets/live_delivery_map.dart';

/// Buyer/seller view: live map with the moving driver marker, the delivery
/// confirmation-code entry (DEL-07) and a link to contact the driver (DEL-04).
class DeliveryTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const DeliveryTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<DeliveryTrackingScreen> createState() =>
      _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends ConsumerState<DeliveryTrackingScreen> {
  final _codeController = TextEditingController();
  bool _confirming = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = DeliveryTrackingRequest(orderId: widget.orderId);
    final state = ref.watch(deliveryTrackingControllerProvider(request));
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Live Tracking')),
      body: _body(context, request, state),
    );
  }

  Widget _body(
    BuildContext context,
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiveDeliveryMap(delivery: delivery, height: 280),
        const SizedBox(height: 16),
        _statusRow(context, delivery),
        if (delivery.isPickupConfirmed && !delivery.isDelivered) ...[
          const SizedBox(height: 16),
          _confirmationInput(context, delivery, request),
        ],
        const SizedBox(height: 24),
        OrderTimeline(status: _orderStatusFor(delivery)),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => openChatForOrder(context, ref, delivery.orderId),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Contact driver'),
        ),
      ],
    );
  }

  /// Buyer enters the 6-digit code issued to them by the driver's hand-off
  /// (DEL-07). Only the buyer can confirm — the order becomes DELIVERED and
  /// escrow is released on success.
  Widget _confirmationInput(
    BuildContext context,
    Delivery delivery,
    DeliveryTrackingRequest request,
  ) {
    final theme = Theme.of(context);
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
                const Icon(Icons.qr_code_2, color: AppColors.greenDark, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Confirm your delivery',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code your driver shared with you to confirm the hand-off.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Confirmation code',
                prefixIcon: Icon(Icons.pin_outlined),
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (code.length == 6) _confirmDelivery(delivery, request);
              },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: code.length == 6 && !_confirming
                  ? () => _confirmDelivery(delivery, request)
                  : null,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Confirm delivery'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelivery(
    Delivery delivery,
    DeliveryTrackingRequest request,
  ) async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;
    setState(() => _confirming = true);
    try {
      await ref.read(deliveryRepositoryProvider).confirm(delivery.id, code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery confirmed — thank you!')),
      );
      await ref.read(deliveryTrackingControllerProvider(request).notifier).refreshNow();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not confirm — check the code and try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Widget _statusRow(BuildContext context, Delivery delivery) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Order ${orderReference(delivery.orderId)}',
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

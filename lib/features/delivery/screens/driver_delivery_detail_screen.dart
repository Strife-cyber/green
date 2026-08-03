import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/chat_actions.dart';
import '../../../data/models/delivery.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/providers.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../theme/app_colors.dart';
import '../controllers/delivery_tracking_controller.dart';
import '../controllers/driver_delivery_detail_controller.dart';
import '../widgets/live_delivery_map.dart';

/// Loads the order so the driver can verify its delivery confirmation code.
final driverOrderProvider = FutureProvider.family<Order, String>(
  (ref, orderId) => ref.watch(orderRepositoryProvider).get(orderId),
);

/// Driver view of one delivery: live map, status, pickup/deliver actions and
/// a link to the order's chat (DRV-03/04).
class DriverDeliveryDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const DriverDeliveryDetailScreen({super.key, required this.id});

  @override
  ConsumerState<DriverDeliveryDetailScreen> createState() =>
      _DriverDeliveryDetailScreenState();
}

class _DriverDeliveryDetailScreenState extends ConsumerState<DriverDeliveryDetailScreen> {
  bool _busy = false;
  final _codeController = TextEditingController();

  /// The expected confirmation code for the current order (loaded async).
  String? _expectedCode;

  DeliveryTrackingRequest get _trackingRequest =>
      DeliveryTrackingRequest(deliveryId: widget.id);

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The driver publishes their mock position once the delivery is known, and
    // stops once it is delivered.
    ref.listen(deliveryTrackingControllerProvider(_trackingRequest), (previous, next) {
      final delivery = next.delivery;
      if (delivery == null) return;
      if (delivery.isDelivered) {
        ref.read(deliveryTrackingControllerProvider(_trackingRequest).notifier)
            .stopPublishing();
      } else if (!next.publishing) {
        ref.read(deliveryTrackingControllerProvider(_trackingRequest).notifier)
            .startPublishing();
      }
    });

    final delivery = ref.watch(driverDeliveryDetailControllerProvider(widget.id));
    final tracking = ref.watch(deliveryTrackingControllerProvider(_trackingRequest));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Delivery')),
      body: AsyncView<Delivery>(
        value: delivery,
        onRetry: () => ref.invalidate(driverDeliveryDetailControllerProvider(widget.id)),
        builder: (data) {
          final orderCode =
              ref.watch(driverOrderProvider(data.orderId)).valueOrNull?.confirmationCode;
          _expectedCode = orderCode;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              LiveDeliveryMap(delivery: tracking.delivery ?? data),
              const SizedBox(height: 16),
              _infoCard(context, data),
              const SizedBox(height: 16),
              ..._actions(context, data, orderCode),
            ],
          );
        },
      ),
    );
  }

  Widget _infoCard(BuildContext context, Delivery delivery) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order ${orderReference(delivery.orderId)}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                _statusBadge(delivery),
              ],
            ),
            const SizedBox(height: 12),
            _row(context, Icons.person_outline, 'Driver', delivery.driverName ?? '—'),
            const SizedBox(height: 8),
            _row(context, Icons.schedule_outlined, 'Pickup', _formatTime(delivery.pickupConfirmedAt)),
            const SizedBox(height: 8),
            _row(context, Icons.check_circle_outline, 'Delivered', _formatTime(delivery.deliveredAt)),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.tanDark),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.tanDark)),
        const Spacer(),
        Text(value, style: theme.textTheme.bodyMedium),
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

  List<Widget> _actions(BuildContext context, Delivery delivery, String? orderCode) {
    final actions = <Widget>[];
    if (!delivery.isDelivered) {
      actions.add(
        FilledButton(
          onPressed: delivery.isPickupConfirmed || _busy
              ? null
              : _confirmPickup,
          child: const Text('Confirm pickup'),
        ),
      );
      actions.add(const SizedBox(height: 12));
      if (delivery.isPickupConfirmed) {
        // The delivery can only be handed over once the buyer's confirmation
        // code matches the order's (DEL-07).
        actions.add(
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Confirmation code from buyer',
              prefixIcon: Icon(Icons.pin_outlined),
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (orderCode != null && _codeController.text.trim() != orderCode) {
                _showError('That code does not match this order.');
              }
            },
          ),
        );
        actions.add(const SizedBox(height: 12));
      }
      actions.add(
        FilledButton(
          onPressed: delivery.isPickupConfirmed && !_busy && _codeMatches(orderCode)
              ? _markDelivered
              : null,
          child: const Text('Mark delivered'),
        ),
      );
      actions.add(const SizedBox(height: 12));
    }
    actions.add(
      OutlinedButton.icon(
        onPressed: () => openChatForOrder(context, ref, delivery.orderId),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Chat'),
      ),
    );
    return actions;
  }

  Future<void> _confirmPickup() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(driverDeliveryDetailControllerProvider(widget.id).notifier)
          .confirmPickup();
      await ref
          .read(deliveryTrackingControllerProvider(_trackingRequest).notifier)
          .refreshNow();
    } catch (_) {
      if (mounted) _showError('Could not confirm pickup. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _codeMatches(String? orderCode) {
    final entered = _codeController.text.trim();
    return orderCode != null && entered.isNotEmpty && entered == orderCode;
  }

  Future<void> _markDelivered() async {
    if (!_codeMatches(_expectedCode)) {
      _showError('Enter the correct confirmation code before marking delivered.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(driverDeliveryDetailControllerProvider(widget.id).notifier)
          .markDelivered();
      await ref
          .read(deliveryTrackingControllerProvider(_trackingRequest).notifier)
          .refreshNow();
    } catch (_) {
      if (mounted) _showError('Could not mark as delivered. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '—';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '${time.day}/${time.month} $h:$m';
  }
}

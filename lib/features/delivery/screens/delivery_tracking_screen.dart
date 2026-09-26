import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../chat/chat_actions.dart';
import '../../../data/models/delivery.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/providers.dart';
import '../../../l10n/l10n_ext.dart';
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
        LiveDeliveryMap(
          delivery: delivery,
          height: 280,
          onTap: () => context.push(AppRoutes.liveMap(widget.orderId)),
        ),
        const SizedBox(height: 16),
        _statusRow(context, delivery),
        if (delivery.isPickupConfirmed && !delivery.isDelivered) ...[
          const SizedBox(height: 16),
          _confirmationSection(context, delivery, request),
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

  /// Delivery confirmation (DEL-07). The code input is shown only once the
  /// driver has issued a code, and only to the buyer — a seller or driver
  /// sees no code UI here. Before the code is issued the buyer sees a neutral
  /// "waiting" state instead of a dead input.
  Widget _confirmationSection(
    BuildContext context,
    Delivery delivery,
    DeliveryTrackingRequest request,
  ) {
    final theme = Theme.of(context);
    final role = ref.read(authControllerProvider).valueOrNull?.user?.role;
    if (role != UserRole.buyer) return const SizedBox.shrink();
    if (!delivery.confirmationCodeIssued) {
      // En route but no code issued yet — nothing to enter.
      return Card(
        color: AppColors.backgroundElevated,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.schedule, color: AppColors.tanDark),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'The confirmation code will appear here once the driver issues it.',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
                ),
              ),
            ],
          ),
        ),
      );
    }
    // Code issued — the backend emails it to the buyer; ask for it here. No
    // separate resend endpoint exists (the driver issues/re-issues the code).
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
                    context.t.confirmDeliveryTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.t.confirmDeliveryBody,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.mark_email_read_outlined, size: 16, color: AppColors.greenDark),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.t.deliveryCodeEmailHint,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.greenDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: context.t.confirmationCode,
                prefixIcon: const Icon(Icons.pin_outlined),
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
              label: Text(context.t.confirmDeliveryAction),
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
      await ref.read(deliveryRepositoryProvider).confirm(delivery.id, code: code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.deliveryConfirmed)),
      );
      await ref.read(deliveryTrackingControllerProvider(request).notifier).refreshNow();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.confirmFailed)),
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

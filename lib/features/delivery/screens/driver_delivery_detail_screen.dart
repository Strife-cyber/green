import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/delivery.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/providers.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/report_dialog.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../theme/app_colors.dart';
import '../controllers/delivery_tracking_controller.dart';
import '../controllers/driver_delivery_detail_controller.dart';
import '../widgets/buyer_code_dialog.dart';
import '../widgets/live_delivery_map.dart';

/// Driver view of one delivery: live map, the destination (recipient, phone,
/// address, coordinates) and ONE contextual action — "Confirm pickup" until
/// picked up, then "I've arrived — send buyer the code" (DEL-07/DRV-03/04).
/// Position publishing runs app-wide from the driver home screen, so opening
/// this page is never required for the buyer to see movement.
class DriverDeliveryDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const DriverDeliveryDetailScreen({super.key, required this.id});

  @override
  ConsumerState<DriverDeliveryDetailScreen> createState() =>
      _DriverDeliveryDetailScreenState();
}

class _DriverDeliveryDetailScreenState extends ConsumerState<DriverDeliveryDetailScreen> {
  bool _busy = false;

  DeliveryTrackingRequest get _trackingRequest =>
      DeliveryTrackingRequest(deliveryId: widget.id);

  @override
  Widget build(BuildContext context) {
    // The buyer's confirm lands on the tracking poll/socket first — refresh
    // the detail when the delivery reports delivered so the card doesn't sit
    // on "En route" until the driver navigates away.
    ref.listen(deliveryTrackingControllerProvider(_trackingRequest),
        (previous, next) {
      final wasDelivered = previous?.delivery?.isDelivered ?? false;
      if (!wasDelivered && (next.delivery?.isDelivered ?? false)) {
        ref.invalidate(driverDeliveryDetailControllerProvider(widget.id));
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
        builder: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LiveDeliveryMap(delivery: tracking.delivery ?? data),
            if (data.deliveryAddress != null) ...[
              const SizedBox(height: 16),
              _destinationCard(context, data),
            ],
            const SizedBox(height: 16),
            _infoCard(context, data),
            const SizedBox(height: 16),
            ..._actions(context, data),
            _reportProblem(context, data),
          ],
        ),
      ),
    );
  }

  /// The drop-off, prominent for the driver: recipient, phone and the full
  /// address line plus region — plus raw coordinates for the map-savvy.
  Widget _destinationCard(BuildContext context, Delivery delivery) {
    final theme = Theme.of(context);
    final address = delivery.deliveryAddress!;
    final where = [
      if (address.addressLine.isNotEmpty) address.addressLine,
      if (address.region.isNotEmpty) address.region,
    ].join(' · ');
    final lat = address.latitude;
    final lng = address.longitude;
    return Card(
      color: AppColors.green.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_outlined, size: 18, color: AppColors.greenDark),
                const SizedBox(width: 8),
                Text(
                  'Destination',
                  style: theme.textTheme.labelLarge?.copyWith(color: AppColors.greenDark),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (address.recipientName.isNotEmpty)
              Text(
                address.recipientName,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            if (address.recipientName.isNotEmpty) const SizedBox(height: 2),
            if (where.isNotEmpty) Text(where, style: theme.textTheme.bodyMedium),
            if (address.phone.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 16, color: AppColors.tanDark),
                  const SizedBox(width: 6),
                  Text(address.phone, style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
            if (lat != null && lng != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.my_location, size: 14, color: AppColors.tanDark),
                  const SizedBox(width: 6),
                  Text(
                    '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
                  ),
                ],
              ),
            ],
          ],
        ),
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

  /// One contextual primary action: not picked up → "Confirm pickup";
  /// picked up → "I've arrived — send buyer the code"; delivered → nothing.
  /// Under it sits the "Ask for the buyer's code" hand-off (the driver types
  /// the buyer's 6-digit code and confirms directly) plus a problem report.
  List<Widget> _actions(BuildContext context, Delivery delivery) {
    if (delivery.isDelivered) return const [];
    return [
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _busy
              ? null
              : (delivery.isPickupConfirmed ? _completeDelivery : _confirmPickup),
          icon: Icon(delivery.isPickupConfirmed
              ? Icons.qr_code_2
              : Icons.inventory_2_outlined),
          label: Text(delivery.isPickupConfirmed
              ? "I've arrived — send buyer the code"
              : 'Confirm pickup'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      if (delivery.isPickupConfirmed) ...[
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _askForBuyerCode,
            icon: const Icon(Icons.pin_outlined),
            label: Text(context.t.enterBuyerCode),
          ),
        ),
      ],
      if (delivery.hasDestination) ...[
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _navigate(delivery),
            icon: const Icon(Icons.navigation_outlined),
            label: Text(context.t.navigate),
          ),
        ),
      ],
      const SizedBox(height: 12),
    ];
  }

  /// "Report a problem" (design 24) — flags the order's buyer for admin
  /// follow-up (POST /reports).
  Widget _reportProblem(BuildContext context, Delivery delivery) {
    final buyerId = delivery.buyerId;
    if (buyerId == null || delivery.isDelivered) {
      return const SizedBox.shrink();
    }
    return Center(
      child: TextButton.icon(
        onPressed: () => showReportDialog(
          context,
          ref,
          reportedId: buyerId,
          targetType: ReportTargetType.profile,
        ),
        icon: const Icon(Icons.flag_outlined, size: 16),
        label: Text(context.t.reportProblem),
        style: TextButton.styleFrom(foregroundColor: AppColors.orangeDark),
      ),
    );
  }

  /// Google Maps directions to the destination (design 24).
  Future<void> _navigate(Delivery delivery) async {
    final lat = delivery.destinationLatitude;
    final lng = delivery.destinationLongitude;
    if (lat == null || lng == null) return;
    await launchUrl(
      Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      ),
      mode: LaunchMode.externalApplication,
    );
  }

  /// The driver-side code hand-off: the buyer reads their 6-digit code out
  /// and the driver posts it to `POST /deliveries/{id}/confirm` — the
  /// extended contract accepts it from the assigned driver (DEL-07).
  Future<void> _askForBuyerCode() async {
    final code = await showDialog<String>(
      context: context,
      builder: (context) => const BuyerCodeDialog(),
    );
    if (code == null || code.length != 6 || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(deliveryRepositoryProvider)
          .confirm(widget.id, code: code);
      if (!mounted) return;
      ref.invalidate(driverDeliveryDetailControllerProvider(widget.id));
      final messenger = ScaffoldMessenger.of(context);
      final confirmed = context.t.deliveryConfirmed;
      await ref
          .read(deliveryTrackingControllerProvider(_trackingRequest).notifier)
          .refreshNow();
      messenger.showSnackBar(SnackBar(content: Text(confirmed)));
    } catch (error) {
      if (mounted) {
        _showError(friendlyErrorMessage(error, context));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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

  Future<void> _completeDelivery() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(driverDeliveryDetailControllerProvider(widget.id).notifier)
          .completeDelivery();
      await ref
          .read(deliveryTrackingControllerProvider(_trackingRequest).notifier)
          .refreshNow();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Confirmation code sent to the buyer.')),
        );
      }
    } catch (_) {
      if (mounted) _showError('Could not complete the delivery. Try again.');
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

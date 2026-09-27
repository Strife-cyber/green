import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/nav_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/delivery.dart';
import '../../../data/models/enums.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/language_action.dart';
import '../../../shared/widgets/language_selector.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../order/order_status_text.dart';
import '../controllers/delivery_tracking_controller.dart';
import '../controllers/driver_delivery_detail_controller.dart';
import '../controllers/driver_delivery_list_controller.dart';
import '../utils/route_planner.dart';

/// Undelivered deliveries oldest-first — the driver works one task at a
/// time, so index 0 is always the current task.
List<Delivery> _activeDeliveries(List<Delivery> deliveries) {
  return [
    for (final d in deliveries)
      if (!d.isDelivered) d,
  ]..sort(
      (a, b) => (a.assignedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(b.assignedAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
    );
}

/// The driver's current task (the oldest undelivered delivery).
Delivery? _firstActiveDelivery(List<Delivery> deliveries) =>
    _activeDeliveries(deliveries).firstOrNull;

/// Driver shell (DRV-01, reworked): one task at a time. The driver sees a
/// single big card for the oldest undelivered assignment — pick up at the
/// seller, drop off at the buyer, distance, and Start → Picked up → Arrived.
/// No buyer chat, no manual driver-picking — the buyer confirms the hand-off.
class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    // Hands-free position publishing, anchored app-wide: the oldest
    // undelivered delivery is the current task — broadcast the driver's
    // position for it while the app is open, without requiring the detail
    // screen to be open (DRV-04). Publishing stops on delivered.
    final deliveries =
        ref.watch(driverDeliveryListControllerProvider).valueOrNull ??
            const <Delivery>[];
    final current = _firstActiveDelivery(deliveries);
    final trackingRequest =
        DeliveryTrackingRequest(deliveryId: current?.id ?? '');
    ref.listen(deliveryTrackingControllerProvider(trackingRequest),
        (previous, next) {
      final delivery = next.delivery;
      if (delivery == null) return;
      final notifier = ref.read(
          deliveryTrackingControllerProvider(trackingRequest).notifier);
      if (delivery.isDelivered) {
        notifier.stopPublishing();
      } else if (!next.publishing) {
        notifier.startPublishing();
      }
    });
    // Auto-refresh the active tab's data whenever the user switches tabs.
    ref.listen(driverTabProvider, (previous, next) {
      if (previous == next) return;
      switch (next) {
        case 0: ref.invalidate(driverDeliveryListControllerProvider); break;
        // 1 = Profile — nothing to refetch.
      }
    });
    return AppShell(
      tabProvider: driverTabProvider,
      persistKey: 'driver',
      tabs: [
        AppShellTab(
          label: t.navDeliveries,
          icon: Icons.local_shipping_outlined,
          page: const _TaskTab(),
        ),
        AppShellTab(
          label: t.navProfile,
          icon: Icons.person_outline,
          page: const _ProfileTab(),
        ),
      ],
    );
  }
}

/// The driver's one-at-a-time task view: the oldest undelivered delivery gets
/// a big card with its seller, drop-off address and distance. Deliveries that
/// still await pickup also get a task-complete "Done" so the driver can dismiss
/// them once started — the card drives the whole flow (DRV-02 reworked).
class _TaskTab extends ConsumerWidget {
  const _TaskTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final deliveries = ref.watch(driverDeliveryListControllerProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(t.navDeliveries),
        actions: const [LanguageAction()],
      ),
      body: RefreshableAsyncView<List<Delivery>>(
        value: deliveries,
        onRefresh: () => ref.read(driverDeliveryListControllerProvider.notifier).refresh(),
        onRetry: () => ref.invalidate(driverDeliveryListControllerProvider),
        empty: EmptyState(
          icon: Icons.local_shipping_outlined,
          title: t.noDeliveries,
          message: t.deliveriesHint,
        ),
        builder: (data) {
          // Oldest assignment first — that is the current task.
          final active = _activeDeliveries(data);
          if (active.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                EmptyState(
                  icon: Icons.verified_outlined,
                  title: t.noDeliveries,
                  message: t.deliveriesHint,
                ),
              ],
            );
          }
          final current = active.first;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _TaskCard(delivery: current),
              if (active.length > 1) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    t.moreDeliveries(count: active.length - 1),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.tanDark),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// The big one-task card: pick up at the seller, drop off at the buyer,
/// distance, and the Start → Picked up → Arrived progression.
class _TaskCard extends ConsumerStatefulWidget {
  final Delivery delivery;

  const _TaskCard({required this.delivery});

  @override
  ConsumerState<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<_TaskCard> {
  bool _busy = false;

  Delivery get delivery => widget.delivery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.t;
    final d = delivery;
    final seller = d.sellerName ?? t.roleSeller;
    final address = d.deliveryAddress;
    final dropOff = address?.addressLine ?? address?.label ?? t.dropOffUnknown;
    final status = d.orderStatus ?? _orderStatusFor(d);
    final distanceKm = _distanceKm(d);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await context.push(AppRoutes.driverDelivery(d.id));
          if (mounted) ref.invalidate(driverDeliveryListControllerProvider);
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, color: AppColors.greenDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.currentDelivery,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.tanDark,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                orderReference(d.orderId),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                orderStatusPhrase(context, status),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.greenDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _taskLine(context, Icons.storefront_outlined, t.pickUpFrom(seller: seller)),
              const SizedBox(height: 10),
              _taskLine(context, Icons.location_on_outlined, t.dropOffAt(address: dropOff)),
              if (distanceKm != null) ...[
                const SizedBox(height: 10),
                _taskLine(
                  context,
                  Icons.route_outlined,
                  t.distanceKm(distance: distanceKm.toStringAsFixed(1)),
                ),
              ],
              if (d.codeRequired) ...[
                const SizedBox(height: 10),
                _taskLine(context, Icons.qr_code_2, t.codeRequiredNote, tinted: true),
              ],
              const SizedBox(height: 20),
              _progression(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskLine(BuildContext context, IconData icon, String text, {bool tinted = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: tinted ? AppColors.orangeDark : AppColors.tanDark),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: tinted ? AppColors.orangeDark : null,
              fontWeight: tinted ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }

  /// Start → (picked up) → Arrived.
  Widget _progression(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.t;
    if (!delivery.isPickupConfirmed) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _busy ? null : _start,
          icon: const Icon(Icons.play_arrow),
          label: Text(t.driverTaskStart),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.greenDark,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.greenDark, size: 20),
            const SizedBox(width: 8),
            Text(
              t.pickedUp,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.greenDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.hourglass_top, color: AppColors.orangeDark, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.awaitingBuyerConfirm,
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.orangeDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _arrived,
            icon: const Icon(Icons.flag_outlined),
            label: Text(t.driverTaskArrived),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: AppColors.greenDark,
              side: BorderSide(color: AppColors.green.withValues(alpha: 0.6)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(driverDeliveryDetailControllerProvider(delivery.id).notifier)
          .confirmPickup();
      if (mounted) ref.invalidate(driverDeliveryListControllerProvider);
    } catch (_) {
      if (mounted) _showError();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _arrived() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(driverDeliveryDetailControllerProvider(delivery.id).notifier)
          .completeDelivery();
      if (mounted) ref.invalidate(driverDeliveryListControllerProvider);
    } catch (_) {
      if (mounted) _showError();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t.errorGeneric)),
    );
  }

  double? _distanceKm(Delivery d) {
    final curLat = d.currentLatitude;
    final curLng = d.currentLongitude;
    final dstLat = d.destinationLatitude;
    final dstLng = d.destinationLongitude;
    if (curLat == null || curLng == null || dstLat == null || dstLng == null) {
      return null;
    }
    return haversineKm(LatLng(curLat, curLng), LatLng(dstLat, dstLng));
  }

  OrderStatus _orderStatusFor(Delivery d) {
    if (d.isDelivered) return OrderStatus.delivered;
    if (d.isPickupConfirmed) return OrderStatus.shipped;
    return OrderStatus.confirmed;
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final name = user?.fullName ?? t.roleDriver;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(t.navProfile)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          Center(child: UserAvatar(name: name, radius: 40)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              name,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              user?.email ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.tanDark),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              t.roleDriver,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.language, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  const LanguageSelector(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout),
            label: Text(t.logout),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go(AppRoutes.login);
  }
}

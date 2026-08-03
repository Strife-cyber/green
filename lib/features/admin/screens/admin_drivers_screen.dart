import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/providers.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';
import '../controllers/admin_drivers_controller.dart';

/// All DRIVER accounts, for admin oversight (D6). Tap a driver to assign a
/// delivery. Reachable from the admin overview's quick actions.
class AdminDriversScreen extends ConsumerWidget {
  const AdminDriversScreen({super.key});

  void _showAssignSheet(BuildContext context, WidgetRef ref, User driver) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AssignDeliverySheet(driver: driver),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drivers = ref.watch(adminDriversControllerProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Drivers'),
      ),
      body: RefreshableAsyncView<List<User>>(
        value: drivers,
        onRefresh: () => ref.read(adminDriversControllerProvider.notifier).refresh(),
        onRetry: () => ref.invalidate(adminDriversControllerProvider),
        empty: const EmptyState(
          icon: Icons.local_shipping_outlined,
          title: 'No drivers yet',
          message: 'Create a driver account from the admin console to get started.',
        ),
        builder: (list) => ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final driver = list[index];
            return Card(
              child: ListTile(
                leading: UserAvatar(name: driver.fullName),
                title: Text(
                  driver.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${driver.email}${driver.phone != null && driver.phone!.isNotEmpty ? ' · ${driver.phone}' : ''}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (driver.region != null)
                      Text(
                        driver.region!,
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
                      ),
                    const SizedBox(width: 8),
                    const Icon(Icons.local_shipping_outlined, color: AppColors.tanDark),
                  ],
                ),
                onTap: () => _showAssignSheet(context, ref, driver),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Bottom sheet: pick an assignable order (PENDING/CONFIRMED) for a driver and
/// call `POST /deliveries` to create the delivery.
class _AssignDeliverySheet extends ConsumerStatefulWidget {
  final User driver;

  const _AssignDeliverySheet({required this.driver});

  @override
  ConsumerState<_AssignDeliverySheet> createState() => _AssignDeliverySheetState();
}

class _AssignDeliverySheetState extends ConsumerState<_AssignDeliverySheet> {
  String? _selectedOrderId;
  bool _assigning = false;

  Future<void> _assign() async {
    final orderId = _selectedOrderId;
    if (orderId == null) return;
    setState(() => _assigning = true);
    try {
      await ref.read(deliveryRepositoryProvider).assign(orderId, widget.driver.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delivery assigned to ${widget.driver.fullName}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not assign — the order may already have a delivery.')),
        );
      }
    } finally {
      if (mounted) setState(() => _assigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orders = ref.watch(assignableOrdersProvider);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Assign delivery',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose an order for ${widget.driver.fullName}',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: orders.when(
                  skipLoadingOnRefresh: true,
                  data: (all) {
                    final assignable = [
                      for (final o in all)
                        if (o.status == OrderStatus.pending || o.status == OrderStatus.confirmed)
                          o,
                    ];
                    if (assignable.isEmpty) {
                      return const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No assignable orders',
                        message: 'Orders awaiting a driver (pending or confirmed) will appear here.',
                      );
                    }
                    return ListView.builder(
                      itemCount: assignable.length,
                      itemBuilder: (context, index) {
                        final order = assignable[index];
                        final selected = order.id == _selectedOrderId;
                        return Card(
                          color: selected
                              ? AppColors.greenContainer.withValues(alpha: 0.3)
                              : null,
                          child: ListTile(
                            title: Text('Order ${orderReference(order.id)}'),
                            subtitle: Text(
                              '${order.sellerName ?? 'Seller'} · ${order.status.label}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AmountText(order.totalAmount),
                                if (selected) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.check_circle, color: AppColors.green),
                                ],
                              ],
                            ),
                            onTap: () => setState(() => _selectedOrderId = order.id),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => ErrorView(
                    message: 'Could not load orders.',
                    onRetry: () => ref.invalidate(assignableOrdersProvider),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _selectedOrderId == null || _assigning ? null : _assign,
                child: _assigning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Assign driver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

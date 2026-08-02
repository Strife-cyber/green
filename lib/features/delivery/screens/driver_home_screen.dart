import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/nav_providers.dart';
import '../../../data/models/delivery.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../chat/widgets/chat_thread_list.dart';
import '../controllers/driver_delivery_list_controller.dart';

/// Driver shell: assigned deliveries, chats and profile (DRV-01).
class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    return AppShell(
      tabProvider: driverTabProvider,
      persistKey: 'driver',
      tabs: [
        AppShellTab(
          label: t.navDeliveries,
          icon: Icons.local_shipping_outlined,
          page: const _DeliveriesTab(),
        ),
        AppShellTab(
          label: t.navChat,
          icon: Icons.chat_bubble_outline,
          page: Scaffold(
            appBar: AppBar(title: Text(t.navChat)),
            body: const ChatThreadList(),
          ),
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

class _DeliveriesTab extends ConsumerWidget {
  const _DeliveriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final deliveries = ref.watch(driverDeliveryListControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.navDeliveries)),
      body: AsyncView<List<Delivery>>(
        value: deliveries,
        onRetry: () => ref.read(driverDeliveryListControllerProvider.notifier).refresh(),
        builder: (data) {
          if (data.isEmpty) {
            return EmptyState(
              icon: Icons.local_shipping_outlined,
              title: t.noDeliveries,
              message: t.deliveriesHint,
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(driverDeliveryListControllerProvider.notifier).refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final delivery = data[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      '${t.orderPrefix}${delivery.orderId}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(delivery.driverName ?? t.roleDriver),
                    trailing: _statusBadge(delivery),
                    onTap: () => context.push(AppRoutes.driverDelivery(delivery.id)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _statusBadge(Delivery delivery) {
    if (delivery.isDelivered) {
      return const StatusBadge(label: 'Delivered', color: AppColors.green);
    }
    if (delivery.isPickupConfirmed) {
      return const StatusBadge(label: 'En route', color: AppColors.orange);
    }
    return const StatusBadge(label: 'Pickup pending', color: AppColors.tanDark);
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
      appBar: AppBar(title: Text(t.navProfile)),
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
          const SizedBox(height: 32),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/app_notification.dart';
import '../../../data/models/enums.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../theme/app_colors.dart';
import '../controllers/notification_controller.dart';

/// In-app notification centre (NOT-01..06): icon-per-type list, mark-all-read,
/// and tap-to-mark-read.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Mark all read',
            icon: const Icon(Icons.done_all_outlined),
            onPressed: () => ref.read(notificationControllerProvider.notifier).markAllRead(),
          ),
        ],
      ),
      body: AsyncView<List<AppNotification>>(
        value: notifications,
        onRetry: () => ref.invalidate(notificationControllerProvider),
        builder: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.notifications_none,
                title: 'No notifications',
                message: 'You are all caught up.',
              )
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) => _NotificationTile(notification: list[index]),
              ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    if (notification.isRead) return;
    await ref.read(notificationControllerProvider.notifier).markRead(notification.id);
  }

  IconData _iconFor(NotificationType type) => switch (type) {
        NotificationType.order => Icons.receipt_long_outlined,
        NotificationType.payment => Icons.payments_outlined,
        NotificationType.delivery => Icons.local_shipping_outlined,
        NotificationType.chat => Icons.chat_bubble_outline,
        NotificationType.admin => Icons.admin_panel_settings_outlined,
      };

  Color _colorFor(NotificationType type) => switch (type) {
        NotificationType.order => AppColors.green,
        NotificationType.payment => AppColors.orange,
        NotificationType.delivery => const Color(0xFF4A7CBE),
        NotificationType.chat => AppColors.tanDark,
        NotificationType.admin => AppColors.greenDark,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unread = !notification.isRead;
    return ListTile(
      onTap: () => _open(context, ref),
      leading: CircleAvatar(
        backgroundColor: _colorFor(notification.type).withValues(alpha: 0.14),
        child: Icon(_iconFor(notification.type), color: _colorFor(notification.type)),
      ),
      title: Text(
        notification.title,
        style: unread ? const TextStyle(fontWeight: FontWeight.w700) : null,
      ),
      subtitle: Text(notification.body),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(formatDateTime(notification.createdAt), style: theme.textTheme.labelSmall),
          if (unread) ...[
            const SizedBox(height: 4),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
      tileColor: unread ? AppColors.backgroundElevated : null,
    );
  }
}

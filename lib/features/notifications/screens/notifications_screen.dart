import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/push_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/app_notification.dart';
import '../../../data/models/enums.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../theme/app_colors.dart';
import '../controllers/notification_controller.dart';

/// In-app notification centre (NOT-01..06): icon-per-type list, mark-all-read,
/// and tap-to-mark-read + navigate to the underlying entity.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final successText = context.t.allCaughtUp;
    const failureText = 'Could not mark all as read.';
    messenger.hideCurrentSnackBar();
    try {
      await ref.read(notificationControllerProvider.notifier).markAllRead();
      messenger.showSnackBar(SnackBar(content: Text(successText)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text(failureText)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationControllerProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(context.t.notifications),
        actions: [
          IconButton(
            tooltip: context.t.markAllRead,
            icon: const Icon(Icons.done_all_outlined),
            onPressed: () => _markAllRead(context, ref),
          ),
        ],
      ),
      body: RefreshableAsyncView<List<AppNotification>>(
        value: notifications,
        onRefresh: () => ref.read(notificationControllerProvider.notifier).refresh(),
        onRetry: () => ref.invalidate(notificationControllerProvider),
        empty: EmptyState(
          icon: Icons.notifications_none,
          title: context.t.noNotifications,
          message: context.t.allCaughtUp,
        ),
        builder: (list) => ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
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
    // Mark read (best-effort) so the unread dot clears immediately.
    if (!notification.isRead) {
      ref.read(notificationControllerProvider.notifier).markRead(notification.id);
    }
    final role = ref.read(authControllerProvider).valueOrNull?.user?.role;
    String? path;
    final data = notification.data;
    if (data != null && data.isNotEmpty) {
      // Treat the payload as an entity deep link only when it carries a known
      // entity key — `resolvePath`'s fallback to the role home would otherwise
      // stack a duplicate home over this screen.
      final hasEntity = const ['orderId', 'threadId', 'receiptId', 'deliveryId']
          .any((k) => data.containsKey(k) && (data[k]?.toString().isNotEmpty ?? false));
      if (hasEntity) {
        path = PushService.resolvePath(data, role);
      }
    }
    if (path != null && path.isNotEmpty) {
      context.push(path);
      return;
    }
    // No entity link in the payload — degrade per type so the tap never
    // feels dead.
    final fallback = switch (notification.type) {
      NotificationType.payment => AppRoutes.walletTransactions,
      NotificationType.chat => AppRoutes.chatThreads,
      _ => null,
    };
    if (fallback != null) {
      context.push(fallback);
    }
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

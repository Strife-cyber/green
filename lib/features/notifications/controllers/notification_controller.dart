import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/app_notification.dart';
import '../../../data/repositories/providers.dart';
import '../../auth/controllers/auth_controller.dart';

/// In-app notification centre (NOT-01..06). Marks items read in place so the
/// list updates without a full refetch.
class NotificationController extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    if (ref.watch(currentUserIdProvider) == null) {
      return const [];
    }
    return ref.watch(notificationRepositoryProvider).list();
  }

  /// Mark a single notification as read (NOT-03).
  Future<void> markRead(String id) async {
    await ref.read(notificationRepositoryProvider).markRead(id);
    state = AsyncData([for (final n in state.value ?? <AppNotification>[]) n.id == id ? _read(n) : n]);
  }

  /// Mark every notification as read (NOT-04).
  Future<void> markAllRead() async {
    await ref.read(notificationRepositoryProvider).markAllRead();
    state = AsyncData([for (final n in state.value ?? <AppNotification>[]) _read(n)]);
  }

  AppNotification _read(AppNotification n) {
    if (n.isRead) return n;
    return AppNotification(
      id: n.id,
      userId: n.userId,
      type: n.type,
      title: n.title,
      body: n.body,
      data: n.data,
      readAt: DateTime.now(),
      createdAt: n.createdAt,
    );
  }

  /// Re-fetches the list (pull-to-refresh / notification open).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is surfaced through the AsyncValue's ErrorView.
    }
  }
}

final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, List<AppNotification>>(NotificationController.new);

import '../models/app_notification.dart';

/// In-app notification centre (NOT-01..06).
abstract class NotificationRepository {
  Future<List<AppNotification>> list();
  Future<void> markRead(String id);
  Future<void> markAllRead();
}

import 'enums.dart';

/// An in-app notification (NOT-01..06). Push (FCM/APNs) is wired later.
class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  /// Parses the backend `NotificationItemDto` — camelCase, `type` uppercase,
  /// `readAt` null until read.
  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
        type: NotificationType.fromApi(json['type'] as String? ?? 'order'),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        data: json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null,
        readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'] as String) : null,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

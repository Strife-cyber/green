/// One entry in the admin activity audit trail (ADM-15): who did what, when.
class ActivityLog {
  final String id;
  final String userId;
  final String actorName;
  final String action;
  final String? details;
  final DateTime createdAt;

  const ActivityLog({
    required this.id,
    required this.userId,
    required this.actorName,
    required this.action,
    this.details,
    required this.createdAt,
  });

  /// Parses the backend `ActivityLogListItemDto` — camelCase. The DTO carries
  /// the acting user's id/role (no display name), so [actorName] falls back to
  /// the role string.
  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
        id: json['id'] as String,
        userId: json['actorId'] as String? ?? json['user_id'] as String? ?? '',
        actorName: json['actorRole'] as String? ?? json['actor_name'] as String? ?? '',
        action: json['action'] as String? ?? '',
        details: json['metadata'] is Map<String, dynamic>
            ? (json['metadata'] as Map<String, dynamic>).toString()
            : json['details'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

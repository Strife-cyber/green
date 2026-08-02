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

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
        id: json['id'] as String,
        userId: json['user_id'] as String? ?? '',
        actorName: json['actor_name'] as String? ?? '',
        action: json['action'] as String? ?? '',
        details: json['details'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

import 'enums.dart';

/// A user report filed from a profile, chat message or order (D8, ADM-07).
class Report {
  final String id;
  final String reporterId;
  final String reportedId;
  final ReportTargetType targetType;
  final String? targetId;
  final String reason;
  final String? details;
  final ReportStatus status;
  final DateTime? createdAt;

  const Report({
    required this.id,
    required this.reporterId,
    required this.reportedId,
    required this.targetType,
    this.targetId,
    required this.reason,
    this.details,
    required this.status,
    this.createdAt,
  });

  /// Parses the backend `ReportListItemDto` — camelCase, `targetType`/`status`
  /// uppercase.
  factory Report.fromJson(Map<String, dynamic> json) => Report(
        id: json['id'] as String,
        reporterId: json['reporterId'] as String? ?? json['reporter_id'] as String? ?? '',
        reportedId: json['reportedId'] as String? ?? json['reported_id'] as String? ?? '',
        targetType: ReportTargetType.fromApi(json['targetType'] as String? ?? json['target_type'] as String? ?? 'profile'),
        targetId: json['targetId'] as String? ?? json['target_id'] as String?,
        reason: json['reason'] as String? ?? '',
        details: json['details'] as String?,
        status: ReportStatus.fromApi(json['status'] as String? ?? 'open'),
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      );
}

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

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        id: json['id'] as String,
        reporterId: json['reporter_id'] as String? ?? '',
        reportedId: json['reported_id'] as String? ?? '',
        targetType: ReportTargetType.values.firstWhere(
          (t) => t.name == (json['target_type'] as String? ?? 'profile'),
          orElse: () => ReportTargetType.profile,
        ),
        targetId: json['target_id'] as String?,
        reason: json['reason'] as String? ?? '',
        details: json['details'] as String?,
        status: ReportStatus.fromApi(json['status'] as String? ?? 'open'),
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      );
}

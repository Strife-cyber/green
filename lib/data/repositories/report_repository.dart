import '../models/enums.dart';

/// Flag a user from a profile, chat message or order (D8, ADM-07).
abstract class ReportRepository {
  Future<void> submit(ReportInput input);
}

class ReportInput {
  final String reportedId;
  final ReportTargetType targetType;
  final String? targetId;
  final String reason;
  final String? details;

  const ReportInput({
    required this.reportedId,
    required this.targetType,
    this.targetId,
    required this.reason,
    this.details,
  });
}

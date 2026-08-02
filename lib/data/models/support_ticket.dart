import 'enums.dart';

/// A customer-support ticket from the enquiry desk (ADM-09/10).
class SupportTicket {
  final String id;
  final String userId;
  final String subject;
  final String description;
  final TicketStatus status;
  final String? assignedAdminId;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  const SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.description,
    required this.status,
    this.assignedAdminId,
    this.createdAt,
    this.resolvedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
        id: json['id'] as String,
        userId: json['user_id'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        description: json['description'] as String? ?? '',
        status: TicketStatus.fromApi(json['status'] as String? ?? 'open'),
        assignedAdminId: json['assigned_admin_id'] as String?,
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
        resolvedAt: json['resolved_at'] != null ? DateTime.tryParse(json['resolved_at'] as String) : null,
      );
}

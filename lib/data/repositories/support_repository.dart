import '../models/support_ticket.dart';

/// Customer enquiry desk (ADM-09/10).
abstract class SupportRepository {
  Future<SupportTicket> create(CreateTicketInput input);
  Future<List<SupportTicket>> myTickets();
}

class CreateTicketInput {
  final String subject;
  final String description;

  const CreateTicketInput({required this.subject, required this.description});
}

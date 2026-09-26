import '../models/activity_log.dart';
import '../models/admin_stats.dart';
import '../models/chat.dart';
import '../models/delivery.dart';
import '../models/enums.dart';
import '../models/order.dart';
import '../models/report.dart';
import '../models/seller_profile.dart';
import '../models/support_ticket.dart';
import '../models/user.dart';
import '../models/withdrawal.dart';

/// Admin console — admin-only endpoints (ADM-01..13). Server-side RBAC is the
/// real gate; this repo is only ever exercised from the admin UI.
abstract class AdminRepository {
  // Stats & seller approval
  Future<AdminStats> stats();
  Future<List<SellerProfile>> pendingSellers();
  Future<void> approveSeller(String userId);
  Future<void> rejectSeller(String userId);

  // Withdrawals
  Future<List<Withdrawal>> pendingWithdrawals();
  Future<void> processWithdrawal(String id, {bool reject = false});

  // Deliveries
  Future<List<Delivery>> activeDeliveries();

  // Support & reports
  Future<List<SupportTicket>> tickets();
  /// Assigns a support ticket to the current admin (`PATCH /assign`).
  Future<void> assignTicket(String id);
  Future<void> resolveTicket(String id);
  Future<List<Report>> reports();
  Future<void> actionReport(String id, {bool action = false});

  // Chat read-only access (ADM-12)
  Future<List<ChatThread>> chatThreads();
  Future<List<ChatMessage>> chatMessages(String threadId);

  // Driver accounts (D6)
  /// Creates a driver account. The backend generates the password itself and
  /// returns it as `tempPassword` — the caller shows it to the admin once so it
  /// can be shared with the driver. Returns the temporary password on success,
  /// or null if the backend returned none.
  Future<String?> createDriver(CreateDriverInput input);
  Future<List<User>> drivers();

  // Orders (admin) — for the delivery-assignment picker.
  Future<List<Order>> orders({OrderStatus? status});

  // Audit trail (ADM-15)
  Future<List<ActivityLog>> activityLog();

  // Category management (ADM-16) — the public list is `GET /categories`.
  Future<void> createCategory(String name);
  Future<void> renameCategory(int id, String name);
  Future<void> deleteCategory(int id);
}

class CreateDriverInput {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String region;

  const CreateDriverInput({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.region,
  });
}

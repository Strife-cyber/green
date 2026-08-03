/// Domain enums mirroring the backend Prisma enums 1:1. Their `name` values
/// match the Swagger enum strings (lowercase snake_case).
library;

// ---- accounts --------------------------------------------------------------

/// users.role — selects the Buyer/Seller/Admin/Driver home (AUTH-06).
enum UserRole {
  buyer,
  seller,
  admin,
  driver;

  String get label => switch (this) {
        buyer => 'Buyer',
        seller => 'Seller',
        admin => 'Admin',
        driver => 'Delivery Driver',
      };

  /// API values are uppercase (`BUYER`) — match case-insensitively.
  static UserRole fromApi(String value) => UserRole.values.firstWhere(
        (r) => r.name == value.toLowerCase(),
        orElse: () => UserRole.buyer,
      );

  /// The API enum value sent in request bodies (e.g. signup).
  String get apiValue => name.toUpperCase();
}

/// users.admin_role — the admin sub-role (SUPER_ADMIN can manage other admins).
enum AdminRole {
  superAdmin,
  finance,
  support,
  compliance;

  String get label => switch (this) {
        superAdmin => 'Super Admin',
        finance => 'Finance',
        support => 'Support',
        compliance => 'Compliance',
      };

  /// API values are uppercase (`SUPER_ADMIN`) — match case-insensitively.
  static AdminRole? fromApi(String? value) {
    if (value == null || value.isEmpty) return null;
    return AdminRole.values.firstWhere(
      (r) => r.name == value.toLowerCase(),
      orElse: () => AdminRole.superAdmin,
    );
  }

  String get apiValue => name.toUpperCase();
}

/// seller_profiles.approval_status — the admin approval gate (AUTH-07).
enum SellerApprovalStatus {
  pending,
  approved,
  rejected;

  String get label => switch (this) {
        pending => 'Pending approval',
        approved => 'Approved',
        rejected => 'Rejected',
      };

  /// API values are uppercase (`APPROVED`) — match case-insensitively.
  static SellerApprovalStatus fromApi(String value) => SellerApprovalStatus
      .values
      .firstWhere(
        (s) => s.name == value.toLowerCase(),
        orElse: () => SellerApprovalStatus.pending,
      );
}

// ---- catalog ---------------------------------------------------------------

/// categories.name (BUY-03).
enum CategoryName {
  fruits,
  vegetables,
  grains,
  dairy,
  organic,
  mixed;

  String get label => name[0].toUpperCase() + name.substring(1);
}

// ---- orders ----------------------------------------------------------------

/// orders.status — the lifecycle state machine (DEL-01).
enum OrderStatus {
  pending,
  confirmed,
  shipped,
  delivered,
  cancelled;

  String get label => switch (this) {
        pending => 'Pending',
        confirmed => 'Confirmed',
        shipped => 'Shipped',
        delivered => 'Delivered',
        cancelled => 'Cancelled',
      };

  /// API values are uppercase (`CONFIRMED`) — match case-insensitively.
  static OrderStatus fromApi(String value) =>
      OrderStatus.values.firstWhere(
        (s) => s.name == value.toLowerCase(),
        orElse: () => OrderStatus.pending,
      );

  String get apiValue => name.toUpperCase();
}

/// orders.payment_status (PAY-04).
enum PaymentStatus {
  unpaid,
  paid,
  escrowHeld,
  settled,
  refunded;

  String get label => switch (this) {
        unpaid => 'Unpaid',
        paid => 'Paid',
        escrowHeld => 'Escrow held',
        settled => 'Settled',
        refunded => 'Refunded',
      };

  /// API values are uppercase (`ESCROW_HELD`) — match case-insensitively.
  static PaymentStatus fromApi(String value) => switch (value.toLowerCase()) {
        'escrow_held' => PaymentStatus.escrowHeld,
        _ => PaymentStatus.values.firstWhere(
            (s) => s.name == value.toLowerCase(),
            orElse: () => PaymentStatus.unpaid,
          ),
      };
}

// ---- money -----------------------------------------------------------------

/// transactions.type — every wallet movement (PAY-07).
enum TransactionType {
  paymentIn,
  escrowHold,
  escrowRelease,
  commission,
  withdrawal,
  refund;

  String get label => switch (this) {
        paymentIn => 'Payment in',
        escrowHold => 'Escrow held',
        escrowRelease => 'Escrow released',
        commission => 'Commission',
        withdrawal => 'Withdrawal',
        refund => 'Refund',
      };

  bool get isCredit => switch (this) {
        paymentIn || escrowRelease || refund => true,
        escrowHold || commission || withdrawal => false,
      };

  /// API values are uppercase (`ESCROW_HOLD`) — match case-insensitively.
  static TransactionType fromApi(String value) => switch (value.toLowerCase()) {
        'payment_in' => TransactionType.paymentIn,
        'escrow_hold' => TransactionType.escrowHold,
        'escrow_release' => TransactionType.escrowRelease,
        _ => TransactionType.values.firstWhere(
            (t) => t.name == value.toLowerCase(),
            orElse: () => TransactionType.paymentIn,
          ),
      };

  String get apiValue => name.toUpperCase();
}

enum TransactionStatus {
  pending,
  reconciled,
  failed;

  /// API values are `PENDING` / `SUCCESS` / `FAILED` — map case-insensitively.
  static TransactionStatus fromApi(String value) => switch (value.toLowerCase()) {
        'success' => TransactionStatus.reconciled,
        'failed' => TransactionStatus.failed,
        _ => TransactionStatus.values.firstWhere(
            (s) => s.name == value.toLowerCase(),
            orElse: () => TransactionStatus.pending,
          ),
      };
}

/// withdrawals.channel (D4).
enum WithdrawalChannel {
  mtnMomo,
  orangeMoney;

  String get label => switch (this) {
        mtnMomo => 'MTN Mobile Money',
        orangeMoney => 'Orange Money',
      };

  /// API values are uppercase (`MTN_MOMO`) — match case-insensitively.
  static WithdrawalChannel fromApi(String value) => switch (value.toLowerCase()) {
        'mtn_momo' => WithdrawalChannel.mtnMomo,
        'orange_money' => WithdrawalChannel.orangeMoney,
        _ => WithdrawalChannel.mtnMomo,
      };

  String get apiValue => switch (this) {
        mtnMomo => 'MTN_MOMO',
        orangeMoney => 'ORANGE_MONEY',
      };
}

enum WithdrawalStatus {
  pending,
  processed,
  rejected;

  String get label => switch (this) {
        pending => 'Pending',
        processed => 'Processed',
        rejected => 'Rejected',
      };

  /// API values are uppercase (`PROCESSED`) — match case-insensitively.
  static WithdrawalStatus fromApi(String value) => WithdrawalStatus.values
      .firstWhere(
        (s) => s.name == value.toLowerCase(),
        orElse: () => WithdrawalStatus.pending,
      );
}

// ---- receipts --------------------------------------------------------------

/// Receipt lifecycle (REC-01/02). API sends `ISSUED` / `VOIDED`.
enum ReceiptStatus {
  issued,
  voided;

  static ReceiptStatus fromApi(String value) => ReceiptStatus.values.firstWhere(
        (s) => s.name == value.toLowerCase(),
        orElse: () => ReceiptStatus.issued,
      );
}

enum ReceiptCopyRole {
  buyer,
  seller,
  admin;

  /// API values are uppercase (`BUYER`) — match case-insensitively.
  static ReceiptCopyRole fromApi(String value) => ReceiptCopyRole.values
      .firstWhere(
        (r) => r.name == value.toLowerCase(),
        orElse: () => ReceiptCopyRole.buyer,
      );
}

// ---- chat ------------------------------------------------------------------

enum MessageType {
  text,
  image,
  voice;

  /// API values are uppercase (`IMAGE`) — match case-insensitively.
  static MessageType fromApi(String value) =>
      MessageType.values.firstWhere(
        (m) => m.name == value.toLowerCase(),
        orElse: () => MessageType.text,
      );

  String get apiValue => name.toUpperCase();
}

// ---- notifications ---------------------------------------------------------

/// Notification category. API sends uppercase values (`ORDER`, `PAYMENT`, …).
enum NotificationType {
  order,
  payment,
  delivery,
  chat,
  admin;

  static NotificationType fromApi(String value) =>
      NotificationType.values.firstWhere(
        (t) => t.name == value.toLowerCase(),
        orElse: () => NotificationType.order,
      );
}

enum DevicePlatform { fcm, apns }

// ---- support & reports -----------------------------------------------------

enum TicketStatus {
  open,
  assigned,
  resolved;

  String get label => switch (this) {
        open => 'Open',
        assigned => 'Assigned',
        resolved => 'Resolved',
      };

  /// API values are uppercase (`ASSIGNED`) — match case-insensitively.
  static TicketStatus fromApi(String value) =>
      TicketStatus.values.firstWhere(
        (s) => s.name == value.toLowerCase(),
        orElse: () => TicketStatus.open,
      );
}

enum ReportTargetType {
  profile,
  chat,
  order;

  /// API values are uppercase (`PROFILE`) — match case-insensitively.
  static ReportTargetType fromApi(String value) => ReportTargetType.values
      .firstWhere(
        (t) => t.name == value.toLowerCase(),
        orElse: () => ReportTargetType.profile,
      );

  String get apiValue => name.toUpperCase();
}

enum ReportStatus {
  open,
  reviewed,
  actioned;

  /// API values are uppercase (`ACTIONED`) — match case-insensitively.
  static ReportStatus fromApi(String value) =>
      ReportStatus.values.firstWhere(
        (s) => s.name == value.toLowerCase(),
        orElse: () => ReportStatus.open,
      );
}

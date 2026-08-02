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

  static SellerApprovalStatus fromApi(String value) => SellerApprovalStatus.values
      .firstWhere((s) => s.name == value, orElse: () => SellerApprovalStatus.pending);
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

  static OrderStatus fromApi(String value) =>
      OrderStatus.values.firstWhere((s) => s.name == value, orElse: () => OrderStatus.pending);
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

  static PaymentStatus fromApi(String value) => switch (value) {
        'escrow_held' => PaymentStatus.escrowHeld,
        _ => PaymentStatus.values.firstWhere((s) => s.name == value, orElse: () => PaymentStatus.unpaid),
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

  static TransactionType fromApi(String value) => switch (value) {
        'payment_in' => TransactionType.paymentIn,
        'escrow_hold' => TransactionType.escrowHold,
        'escrow_release' => TransactionType.escrowRelease,
        _ => TransactionType.values
            .firstWhere((t) => t.name == value, orElse: () => TransactionType.paymentIn),
      };
}

enum TransactionStatus {
  pending,
  reconciled,
  failed;

  static TransactionStatus fromApi(String value) =>
      TransactionStatus.values.firstWhere((s) => s.name == value, orElse: () => TransactionStatus.pending);
}

/// withdrawals.channel (D4).
enum WithdrawalChannel {
  mtnMomo,
  orangeMoney;

  String get label => switch (this) {
        mtnMomo => 'MTN Mobile Money',
        orangeMoney => 'Orange Money',
      };

  static WithdrawalChannel fromApi(String value) => switch (value) {
        'mtn_momo' => WithdrawalChannel.mtnMomo,
        'orange_money' => WithdrawalChannel.orangeMoney,
        _ => WithdrawalChannel.mtnMomo,
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

  static WithdrawalStatus fromApi(String value) =>
      WithdrawalStatus.values.firstWhere((s) => s.name == value, orElse: () => WithdrawalStatus.pending);
}

// ---- receipts --------------------------------------------------------------

enum ReceiptStatus { issued }

enum ReceiptCopyRole { buyer, seller, admin }

// ---- chat ------------------------------------------------------------------

enum MessageType {
  text,
  image,
  voice;

  static MessageType fromApi(String value) =>
      MessageType.values.firstWhere((m) => m.name == value, orElse: () => MessageType.text);
}

// ---- notifications ---------------------------------------------------------

enum NotificationType { order, payment, delivery, chat, admin }

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

  static TicketStatus fromApi(String value) =>
      TicketStatus.values.firstWhere((s) => s.name == value, orElse: () => TicketStatus.open);
}

enum ReportTargetType { profile, chat, order }

enum ReportStatus {
  open,
  reviewed,
  actioned;

  static ReportStatus fromApi(String value) =>
      ReportStatus.values.firstWhere((s) => s.name == value, orElse: () => ReportStatus.open);
}

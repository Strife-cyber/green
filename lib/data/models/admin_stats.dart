/// Admin console aggregates (ADM-01..05). The backend stats payload now also
/// reports wallet balances and per-queue pending counts.
class AdminStats {
  final int totalUsers;
  final int totalSellers;
  final int activeSellers;
  final int pendingSellers;
  final int grossRevenue;
  final int commissionEarned;
  final int totalOrders;

  /// Ledger balances held platform-wide (FCFA).
  final int escrowBalance;
  final int sellerBalances;
  final int buyerBalances;

  /// Per-queue open items (approvals, payouts, tickets, reported content).
  final int pendingWithdrawals;
  final int openTickets;
  final int pendingReports;

  const AdminStats({
    required this.totalUsers,
    this.totalSellers = 0,
    required this.activeSellers,
    required this.pendingSellers,
    required this.grossRevenue,
    required this.commissionEarned,
    required this.totalOrders,
    this.escrowBalance = 0,
    this.sellerBalances = 0,
    this.buyerBalances = 0,
    this.pendingWithdrawals = 0,
    this.openTickets = 0,
    this.pendingReports = 0,
  });

  /// Parses the backend stats DTO — camelCase
  /// `{ totalUsers, totalSellers, pendingSellers, activeSellers, totalRevenue,
  /// commissionEarned, totalOrders, escrowBalance, sellerBalances,
  /// buyerBalances, pendingWithdrawals, openTickets, pendingReports }`.
  /// Older payloads lacking the extra fields default them to 0.
  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        totalUsers: _toInt(json['totalUsers'] ?? json['total_users']),
        totalSellers: _toInt(json['totalSellers'] ?? json['total_sellers']),
        activeSellers: _toInt(json['activeSellers'] ?? json['active_sellers']),
        pendingSellers: _toInt(json['pendingSellers'] ?? json['pending_sellers']),
        grossRevenue: _toInt(json['grossRevenueThisMonth'] ??
            json['grossRevenue'] ??
            json['totalRevenue'] ??
            json['gross_revenue'] ??
            json['total_revenue']),
        commissionEarned: _toInt(json['commissionTotal'] ??
            json['commissionEarned'] ??
            json['commission'] ??
            json['commission_earned']),
        totalOrders: _toInt(json['totalOrders'] ?? json['total_orders']),
        escrowBalance: _toInt(json['escrowHeld'] ??
            json['escrowBalance'] ??
            json['escrow_balance'] ??
            json['escrow_held']),
        sellerBalances: _toInt(json['sellerBalances'] ?? json['seller_balances']),
        buyerBalances: _toInt(json['buyerBalances'] ?? json['buyer_balances']),
        pendingWithdrawals: _toInt(json['pendingWithdrawals'] ?? json['pending_withdrawals']),
        openTickets: _toInt(json['openTickets'] ?? json['open_tickets'] ?? json['pendingTickets'] ?? json['pending_tickets']),
        pendingReports: _toInt(json['pendingReports'] ??
            json['pending_reports'] ??
            json['reportedUsers'] ??
            json['reported_users'] ??
            json['reportedCount'] ??
            json['reported_count']),
      );

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? double.tryParse(value.toString())?.toInt() ?? 0;
  }
}

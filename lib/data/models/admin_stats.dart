/// Admin console aggregates (ADM-01..05).
class AdminStats {
  final int totalUsers;
  final int activeSellers;
  final int pendingSellers;
  final int grossRevenue;
  final int commissionEarned;
  final int totalOrders;

  const AdminStats({
    required this.totalUsers,
    required this.activeSellers,
    required this.pendingSellers,
    required this.grossRevenue,
    required this.commissionEarned,
    required this.totalOrders,
  });

  /// Parses the backend stats DTO — camelCase
  /// `{ totalUsers, totalSellers, pendingSellers, activeSellers, totalRevenue }`.
  /// `commissionEarned`/`totalOrders` aren't in the live payload and default to 0.
  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        totalUsers: _toInt(json['totalUsers'] ?? json['total_users']),
        activeSellers: _toInt(json['activeSellers'] ?? json['active_sellers']),
        pendingSellers: _toInt(json['pendingSellers'] ?? json['pending_sellers']),
        grossRevenue: _toInt(json['totalRevenue'] ?? json['gross_revenue'] ?? json['total_revenue']),
        commissionEarned: _toInt(json['commissionEarned'] ?? json['commission_earned']),
        totalOrders: _toInt(json['totalOrders'] ?? json['total_orders']),
      );

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? double.tryParse(value.toString())?.toInt() ?? 0;
  }
}

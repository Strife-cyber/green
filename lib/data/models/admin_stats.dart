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

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        totalUsers: (json['total_users'] as num?)?.toInt() ?? 0,
        activeSellers: (json['active_sellers'] as num?)?.toInt() ?? 0,
        pendingSellers: (json['pending_sellers'] as num?)?.toInt() ?? 0,
        grossRevenue: (json['gross_revenue'] as num?)?.round() ?? 0,
        commissionEarned: (json['commission_earned'] as num?)?.round() ?? 0,
        totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      );
}

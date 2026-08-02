/// Seller dashboard aggregates (SELL-03/04/05/07), computed server-side.
class SellerAnalytics {
  final int weeklyRevenue;
  final int totalCustomers;
  final double averageRating;
  final int ratingCount;
  final List<BestSeller> bestSellers;
  final List<SalesPoint> monthlySales;

  const SellerAnalytics({
    required this.weeklyRevenue,
    required this.totalCustomers,
    required this.averageRating,
    required this.ratingCount,
    this.bestSellers = const [],
    this.monthlySales = const [],
  });

  factory SellerAnalytics.fromJson(Map<String, dynamic> json) => SellerAnalytics(
        weeklyRevenue: (json['weekly_revenue'] as num?)?.round() ?? 0,
        totalCustomers: (json['total_customers'] as num?)?.toInt() ?? 0,
        averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
        ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
        bestSellers: [
          if (json['best_sellers'] is List)
            for (final b in json['best_sellers'] as List)
              if (b is Map<String, dynamic>) BestSeller.fromJson(b),
        ],
        monthlySales: [
          if (json['monthly_sales'] is List)
            for (final m in json['monthly_sales'] as List)
              if (m is Map<String, dynamic>) SalesPoint.fromJson(m),
        ],
      );
}

class BestSeller {
  final String productId;
  final String name;
  final int quantitySold;
  final int revenue;

  const BestSeller({
    required this.productId,
    required this.name,
    required this.quantitySold,
    required this.revenue,
  });

  factory BestSeller.fromJson(Map<String, dynamic> json) => BestSeller(
        productId: json['product_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        quantitySold: (json['quantity_sold'] as num?)?.toInt() ?? 0,
        revenue: (json['revenue'] as num?)?.round() ?? 0,
      );
}

/// One (day → amount) point on the monthly sales chart.
class SalesPoint {
  final DateTime day;
  final int amount;

  const SalesPoint({required this.day, required this.amount});

  factory SalesPoint.fromJson(Map<String, dynamic> json) => SalesPoint(
        day: DateTime.tryParse(json['day'] as String? ?? '') ?? DateTime.now(),
        amount: (json['amount'] as num?)?.round() ?? 0,
      );
}

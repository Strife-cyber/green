import '../../core/utils/money.dart';

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

  /// Parses the backend overview DTO — camelCase, `weeklyRevenue` as decimal
  /// string, plus the `best-sellers` / `monthly` arrays.
  factory SellerAnalytics.fromJson(Map<String, dynamic> json) => SellerAnalytics(
        weeklyRevenue: parseMoney(json['weeklyRevenue']?.toString()),
        totalCustomers: _toInt(json['customerCount'] ?? json['total_customers']),
        averageRating: _toDouble(json['avgRating'] ?? json['average_rating']),
        ratingCount: _toInt(json['ratingCount'] ?? json['rating_count']),
        bestSellers: [
          if (json['bestSellers'] is List)
            for (final b in json['bestSellers'] as List)
              if (b is Map<String, dynamic>) BestSeller.fromJson(b),
        ],
        monthlySales: [
          if (json['monthlySales'] is List)
            for (final m in json['monthlySales'] as List)
              if (m is Map<String, dynamic>) SalesPoint.fromJson(m),
        ],
      );

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
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

  /// Parses the backend best-seller DTO `{ productId, productName,
  /// quantitySold, revenue }` — camelCase.
  factory BestSeller.fromJson(Map<String, dynamic> json) => BestSeller(
        productId: json['productId'] as String? ?? json['product_id'] as String? ?? '',
        name: json['productName'] as String? ?? json['name'] as String? ?? '',
        quantitySold: SellerAnalytics._toInt(json['quantitySold'] ?? json['quantity_sold']),
        revenue: parseMoney(json['revenue']?.toString()),
      );
}

/// One (day → amount) point on the monthly sales chart.
class SalesPoint {
  final DateTime day;
  final int amount;

  const SalesPoint({required this.day, required this.amount});

  /// Parses the backend monthly-sales DTO `{ day, revenue, orders }` — camelCase.
  /// `day` is the **day of the month** (an int, e.g. `2`); some environments
  /// send an ISO string — both are accepted.
  factory SalesPoint.fromJson(Map<String, dynamic> json) {
    final dayValue = json['day'];
    final DateTime day;
    if (dayValue is int) {
      final now = DateTime.now();
      day = DateTime(now.year, now.month, dayValue.clamp(1, 31));
    } else if (dayValue is String && dayValue.isNotEmpty) {
      day = DateTime.tryParse(dayValue) ?? DateTime.now();
    } else {
      day = DateTime.now();
    }
    return SalesPoint(
      day: day,
      amount: parseMoney((json['revenue'] ?? json['amount'])?.toString()),
    );
  }
}

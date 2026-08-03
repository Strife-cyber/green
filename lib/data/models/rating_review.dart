/// A buyer's rating + review of a seller, one per delivered order (BUY-11).
class RatingReview {
  final String id;
  final String orderId;
  final String buyerId;
  final String sellerId;
  final int rating; // 1..5
  final String? reviewText;
  final DateTime createdAt;

  const RatingReview({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.rating,
    this.reviewText,
    required this.createdAt,
  });

  factory RatingReview.fromJson(Map<String, dynamic> json) => RatingReview(
        id: json['id'] as String,
        orderId: json['orderId'] as String? ?? json['order_id'] as String? ?? '',
        buyerId: json['buyerId'] as String? ?? json['buyer_id'] as String? ?? '',
        sellerId: json['sellerId'] as String? ?? json['seller_id'] as String? ?? '',
        rating: (json['rating'] as num?)?.round() ?? 5,
        reviewText: json['reviewText'] as String? ?? json['review_text'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Aggregated seller rating (SELL-06).
class SellerRatingSummary {
  final String sellerId;
  final double average;
  final int count;

  const SellerRatingSummary({
    required this.sellerId,
    required this.average,
    required this.count,
  });

  /// Parses the ratings summary — the live endpoint returns
  /// `{ items, total, avg, count, page, limit }`.
  factory SellerRatingSummary.fromJson(Map<String, dynamic> json) => SellerRatingSummary(
        sellerId: json['sellerId'] as String? ?? json['seller_id'] as String? ?? '',
        average: _toDouble(json['avg'] ?? json['average']),
        count: (json['count'] as num?)?.toInt() ?? 0,
      );

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

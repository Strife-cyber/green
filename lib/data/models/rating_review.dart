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
        orderId: json['order_id'] as String? ?? '',
        buyerId: json['buyer_id'] as String? ?? '',
        sellerId: json['seller_id'] as String? ?? '',
        rating: (json['rating'] as num?)?.round() ?? 5,
        reviewText: json['review_text'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
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

  factory SellerRatingSummary.fromJson(Map<String, dynamic> json) => SellerRatingSummary(
        sellerId: json['seller_id'] as String? ?? '',
        average: (json['average'] as num?)?.toDouble() ?? 0,
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

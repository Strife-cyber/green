import '../models/rating_review.dart';

/// Ratings & reviews — one per delivered order (BUY-11, SELL-06).
abstract class RatingRepository {
  Future<void> create(CreateRatingInput input);
  Future<SellerRatingSummary> sellerSummary(String sellerId);
}

class CreateRatingInput {
  final String orderId;
  final String sellerId;
  final int rating; // 1..5
  final String? reviewText;

  const CreateRatingInput({
    required this.orderId,
    required this.sellerId,
    required this.rating,
    this.reviewText,
  });
}

/// A buyer's saved product (BUY-05).
class WishlistItem {
  final String id;
  final String userId;
  final String productId;

  const WishlistItem({required this.id, required this.userId, required this.productId});

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
        id: json['id'] as String,
        userId: json['user_id'] as String? ?? '',
        productId: json['product_id'] as String,
      );
}

/// A buyer's saved product (BUY-05).
class WishlistItem {
  final String id;
  final String userId;
  final String productId;

  const WishlistItem({required this.id, required this.userId, required this.productId});

  /// Parses a backend wishlist row — the API embeds the full product
  /// (`product: { id, … }`), so `productId` may be top-level or nested.
  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
        id: json['id'] as String,
        userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
        productId: _productId(json),
      );

  static String _productId(Map<String, dynamic> json) {
    final top = json['productId'] ?? json['product_id'];
    if (top is String && top.isNotEmpty) return top;
    final product = json['product'];
    if (product is Map<String, dynamic>) return product['id'] as String? ?? '';
    return '';
  }
}

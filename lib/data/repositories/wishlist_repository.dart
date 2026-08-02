import '../models/wishlist_item.dart';

/// Buyer wishlist (BUY-05).
abstract class WishlistRepository {
  Future<List<WishlistItem>> list();
  Future<void> toggle(String productId);
  Future<Set<String>> savedProductIds();
}

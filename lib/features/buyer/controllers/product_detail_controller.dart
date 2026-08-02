import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/product.dart';
import '../../../data/models/rating_review.dart';
import '../../../data/repositories/providers.dart';

/// Per-seller rating summary shown on the product detail seller card (BUY-11).
final sellerRatingProvider = FutureProvider.autoDispose
    .family<SellerRatingSummary, String>(
  (ref, sellerId) =>
      ref.watch(ratingRepositoryProvider).sellerSummary(sellerId),
);

/// Loads a single [Product] by id (BUY-04).
class ProductDetailController extends AsyncNotifier<Product> {
  String? _id;

  @override
  Future<Product> build() {
    final id = _id;
    if (id == null) {
      // Pending until [load] supplies the id — avoids a spurious error frame.
      return Completer<Product>().future;
    }
    return ref.watch(productRepositoryProvider).get(id);
  }

  /// Starts (or refreshes) the load for [id].
  Future<void> load(String id) async {
    if (_id == id && state.hasValue) return;
    _id = id;
    ref.invalidateSelf();
    await future;
  }
}

final productDetailControllerProvider =
    AsyncNotifierProvider<ProductDetailController, Product>(
  ProductDetailController.new,
);

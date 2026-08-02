import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/providers.dart';

/// The set of product ids the current buyer has saved (BUY-05).
class WishlistController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() {
    return ref.watch(wishlistRepositoryProvider).savedProductIds();
  }

  /// Adds or removes [productId] and reloads the saved set.
  Future<void> toggle(String productId) async {
    await ref.read(wishlistRepositoryProvider).toggle(productId);
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is surfaced through the AsyncValue for the screen.
    }
  }
}

final wishlistControllerProvider =
    AsyncNotifierProvider<WishlistController, Set<String>>(
  WishlistController.new,
);

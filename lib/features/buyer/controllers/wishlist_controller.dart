import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/providers.dart';

/// The set of product ids the current buyer has saved (BUY-05).
class WishlistController extends AsyncNotifier<Set<String>> {
  /// Product ids with a toggle in flight — guards against rapid double-taps
  /// racing each other into a stale final state (BUY-05). The notifier is
  /// recreated on invalidation, so a fresh instance simply starts empty.
  final Set<String> _pending = {};

  @override
  Future<Set<String>> build() {
    return ref.watch(wishlistRepositoryProvider).savedProductIds();
  }

  /// Adds or removes [productId] and reloads the saved set. Concurrent calls
  /// for the same product are coalesced into one request.
  Future<void> toggle(String productId) async {
    if (_pending.contains(productId)) return;
    _pending.add(productId);
    try {
      await ref.read(wishlistRepositoryProvider).toggle(productId);
      ref.invalidateSelf();
      try {
        await future;
      } catch (_) {
        // The error is surfaced through the AsyncValue for the screen.
      }
    } finally {
      _pending.remove(productId);
    }
  }

  /// True while a toggle for [productId] is in flight — the UI can show a
  /// spinner on that heart instead of allowing another tap.
  bool isPending(String productId) => _pending.contains(productId);
}

final wishlistControllerProvider =
    AsyncNotifierProvider<WishlistController, Set<String>>(
  WishlistController.new,
);

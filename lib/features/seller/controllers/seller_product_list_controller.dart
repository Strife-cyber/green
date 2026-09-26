import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/product.dart';
import '../../../data/repositories/providers.dart';
import '../../auth/controllers/auth_controller.dart';

/// The signed-in seller's own listings (SELL-01). `autoDispose` so the list
/// refetches when the seller returns to the screen — create/update/delete stays
/// visible without an explicit invalidate.
class SellerProductListController extends AutoDisposeAsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    final userId = ref.watch(authControllerProvider).valueOrNull?.user?.id;
    if (userId == null) return const [];
    final page = await ref.watch(productRepositoryProvider).list(page: 1, pageSize: 100);
    return [for (final p in page.items) if (p.sellerId == userId) p];
  }

  /// Deletes [id] from the catalog and the list.
  Future<void> deleteProduct(String id) async {
    await ref.read(productRepositoryProvider).delete(id);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData([for (final p in current) if (p.id != id) p]);
    }
  }

  /// Re-fetches the list (pull-to-refresh / tab activation).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is surfaced through the AsyncValue's ErrorView.
    }
  }
}

final sellerProductListControllerProvider =
    AsyncNotifierProvider.autoDispose<SellerProductListController, List<Product>>(
  SellerProductListController.new,
);

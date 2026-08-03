import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/product.dart';
import '../../../data/repositories/providers.dart';
import '../../auth/controllers/auth_controller.dart';

/// The signed-in seller's own listings (SELL-01).
class SellerProductListController extends AsyncNotifier<List<Product>> {
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
}

final sellerProductListControllerProvider =
    AsyncNotifierProvider<SellerProductListController, List<Product>>(SellerProductListController.new);

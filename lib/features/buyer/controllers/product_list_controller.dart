import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/category.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/providers.dart';

/// Lazily-fetched product categories for the catalog filter chips (BUY-03).
/// `autoDispose` so the chips refresh on each screen visit.
final categoryListProvider = FutureProvider.autoDispose<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).list(),
);

/// The full active product catalog. Used by the wishlist to resolve saved
/// product ids back into full products. `autoDispose` so the catalog refetches
/// on each visit instead of caching stale products after seller create/update/
/// delete (SELL-01).
final productCatalogProvider = FutureProvider.autoDispose<List<Product>>(
  (ref) async {
    final page = await ref
        .watch(productRepositoryProvider)
        .list(page: 1, pageSize: 100);
    return page.items;
  },
);

/// Drives the buyer product grid (BUY-01/02): a debounced search text plus an
/// optional category filter, both applied through `productRepositoryProvider`.
///
/// [setQuery] is additive — a `null` [search] leaves the current text alone
/// while a non-null value replaces it (pass `''` to clear). [categoryId]
/// behaves the same way; call [clearCategory] to reset the filter to "All".
class ProductListController extends AsyncNotifier<List<Product>> {
  String _search = '';
  int? _categoryId;

  /// The currently-selected category id, or `null` for "All".
  int? get categoryId => _categoryId;

  /// The current search text (empty when no search is active).
  String get search => _search;

  @override
  Future<List<Product>> build() async {
    final page = await ref.watch(productRepositoryProvider).list(
          search: _search.isEmpty ? null : _search,
          categoryId: _categoryId,
          pageSize: 100,
        );
    return page.items;
  }

  Future<void> setQuery({String? search, int? categoryId}) async {
    if (search != null) _search = search;
    if (categoryId != null) _categoryId = categoryId;
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is surfaced through the AsyncValue for the grid's ErrorView.
    }
  }

  /// Clears the active category filter back to "All".
  Future<void> clearCategory() async {
    _categoryId = null;
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is surfaced through the AsyncValue for the grid's ErrorView.
    }
  }

  /// Re-fetches the catalog (pull-to-refresh / tab activation).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is surfaced through the AsyncValue for the grid's ErrorView.
    }
  }
}

final productListControllerProvider =
    AsyncNotifierProvider<ProductListController, List<Product>>(
  ProductListController.new,
);

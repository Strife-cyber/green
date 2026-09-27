import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/seller_profile.dart';
import '../../../data/repositories/providers.dart';
import '../../auth/controllers/auth_controller.dart';

/// The buyer search box's current text (what the Farms section searches on).
final farmSearchQueryProvider = StateProvider<String>((ref) => '');

/// Farms matching the buyer's search (BUY-02):
/// `GET /seller-profiles?search=` → `{data:{items:[{id,farmName,region,
/// rating,ratingCount}]}}`. Empty query → no request.
final farmSearchProvider =
    FutureProvider.autoDispose.family<List<SellerSearchItem>, String>(
  (ref, query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || ref.watch(currentUserIdProvider) == null) {
      return const [];
    }
    return ref.watch(sellerProfileRepositoryProvider).search(trimmed);
  },
);

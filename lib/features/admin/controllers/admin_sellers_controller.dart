import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/seller_profile.dart';
import '../../../data/repositories/providers.dart';

/// Pending seller applications awaiting the admin approval gate (AUTH-07).
class AdminSellersController extends AsyncNotifier<List<SellerProfile>> {
  @override
  Future<List<SellerProfile>> build() => ref.watch(adminRepositoryProvider).pendingSellers();

  /// Approve a seller application, then re-fetch the pending list.
  Future<void> approve(String userId) async {
    await ref.read(adminRepositoryProvider).approveSeller(userId);
    ref.invalidateSelf();
  }

  /// Reject a seller application, then re-fetch the pending list.
  Future<void> reject(String userId) async {
    await ref.read(adminRepositoryProvider).rejectSeller(userId);
    ref.invalidateSelf();
  }
}

final adminSellersControllerProvider =
    AsyncNotifierProvider<AdminSellersController, List<SellerProfile>>(AdminSellersController.new);

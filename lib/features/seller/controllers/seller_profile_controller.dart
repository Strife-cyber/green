import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/seller_profile.dart';
import '../../../data/repositories/providers.dart';
import '../../auth/controllers/auth_controller.dart';

/// The signed-in seller's profile + approval status (AUTH-07). Scoped to the
/// account — a logout → login refetches the new user's profile.
class SellerProfileController extends AsyncNotifier<SellerProfile> {
  @override
  Future<SellerProfile> build() async {
    if (ref.watch(currentUserIdProvider) == null) {
      return const SellerProfile(userId: '', farmName: '');
    }
    return ref.watch(sellerProfileRepositoryProvider).me();
  }

  /// Re-fetches the profile (pull-to-refresh / tab activation).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is surfaced through the AsyncValue's ErrorView.
    }
  }
}

final sellerProfileControllerProvider =
    AsyncNotifierProvider<SellerProfileController, SellerProfile>(SellerProfileController.new);

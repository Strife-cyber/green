import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/seller_profile.dart';
import '../../../data/repositories/providers.dart';

/// The signed-in seller's profile + approval status (AUTH-07).
class SellerProfileController extends AsyncNotifier<SellerProfile> {
  @override
  Future<SellerProfile> build() async {
    return ref.watch(sellerProfileRepositoryProvider).me();
  }
}

final sellerProfileControllerProvider =
    AsyncNotifierProvider<SellerProfileController, SellerProfile>(SellerProfileController.new);

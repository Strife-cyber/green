import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/wallet.dart';
import '../../../data/repositories/providers.dart';

/// Every user wallet, for admin oversight (ADM-04).
class AdminWalletsController extends AsyncNotifier<List<Wallet>> {
  @override
  Future<List<Wallet>> build() => ref.watch(adminRepositoryProvider).allWallets();
}

final adminWalletsControllerProvider =
    AsyncNotifierProvider<AdminWalletsController, List<Wallet>>(AdminWalletsController.new);

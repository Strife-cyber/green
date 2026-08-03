import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/wallet.dart';
import '../../../data/repositories/providers.dart';

/// Every user wallet, for admin oversight (ADM-04).
class AdminWalletsController extends AsyncNotifier<List<Wallet>> {
  @override
  Future<List<Wallet>> build() => ref.watch(adminRepositoryProvider).allWallets();

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

final adminWalletsControllerProvider =
    AsyncNotifierProvider<AdminWalletsController, List<Wallet>>(AdminWalletsController.new);

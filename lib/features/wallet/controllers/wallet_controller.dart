import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/wallet.dart';
import '../../../data/repositories/providers.dart';

/// The signed-in user's wallet (PAY-03).
class WalletController extends AsyncNotifier<Wallet> {
  @override
  Future<Wallet> build() async {
    return ref.watch(walletRepositoryProvider).me();
  }

  /// Re-fetches the wallet (pull-to-refresh / after a payment).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is surfaced through the AsyncValue's ErrorView.
    }
  }
}

final walletControllerProvider = AsyncNotifierProvider<WalletController, Wallet>(WalletController.new);

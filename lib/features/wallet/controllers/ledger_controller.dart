import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/wallet_transaction.dart';
import '../../../data/repositories/providers.dart';

/// The wallet ledger — every movement on the account (PAY-07).
class LedgerController extends AsyncNotifier<List<WalletTransaction>> {
  @override
  Future<List<WalletTransaction>> build() async {
    return ref.watch(walletRepositoryProvider).transactions();
  }

  /// Re-fetches the ledger (pull-to-refresh / after a payment).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is surfaced through the AsyncValue's ErrorView.
    }
  }
}

final ledgerControllerProvider =
    AsyncNotifierProvider<LedgerController, List<WalletTransaction>>(LedgerController.new);

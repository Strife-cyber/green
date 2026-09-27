import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/wallet_transaction.dart';
import '../../../data/repositories/providers.dart';
import '../../auth/controllers/auth_controller.dart';

/// The wallet ledger — every movement on the account (PAY-07). Scoped to the
/// signed-in user so a logout → login can't show the previous account's rows.
class LedgerController extends AsyncNotifier<List<WalletTransaction>> {
  @override
  Future<List<WalletTransaction>> build() async {
    if (ref.watch(currentUserIdProvider) == null) {
      return const [];
    }
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

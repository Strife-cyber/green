import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/wallet.dart';
import '../../../data/repositories/providers.dart';

/// The signed-in user's wallet (PAY-03).
class WalletController extends AsyncNotifier<Wallet> {
  @override
  Future<Wallet> build() async {
    return ref.watch(walletRepositoryProvider).me();
  }
}

final walletControllerProvider = AsyncNotifierProvider<WalletController, Wallet>(WalletController.new);

import '../models/wallet.dart';
import '../models/wallet_transaction.dart';

/// Greenish Wallet + ledger (PAY-03, PAY-07).
abstract class WalletRepository {
  Future<Wallet> me();
  Future<List<WalletTransaction>> transactions();
}

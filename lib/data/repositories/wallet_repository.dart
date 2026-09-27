import '../models/enums.dart';
import '../models/wallet.dart';
import '../models/wallet_transaction.dart';

/// A downloaded export file's bytes plus the name it should be saved as.
class CsvExport {
  final List<int> bytes;
  final String filename;

  const CsvExport(this.bytes, this.filename);
}

/// Greenish Wallet + ledger (PAY-03, PAY-07).
abstract class WalletRepository {
  Future<Wallet> me();
  Future<List<WalletTransaction>> transactions({TransactionType? type});

  /// `GET /transactions/me/export` — the CSV statement (PAY-07).
  Future<CsvExport> exportTransactions();
}

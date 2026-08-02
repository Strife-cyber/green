import '../models/enums.dart';
import '../models/withdrawal.dart';

/// Wallet withdrawals (PAY-05, D4).
abstract class WithdrawalRepository {
  Future<Withdrawal> request(WithdrawalRequest input);
  Future<List<Withdrawal>> myRequests();
}

class WithdrawalRequest {
  final int amount;
  final WithdrawalChannel channel;
  final String accountReference;

  const WithdrawalRequest({
    required this.amount,
    required this.channel,
    required this.accountReference,
  });
}

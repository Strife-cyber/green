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

  /// Account password — verified server-side (bcrypt) before the request is
  /// accepted; a wrong password comes back as "incorrect password".
  final String password;

  const WithdrawalRequest({
    required this.amount,
    required this.channel,
    required this.accountReference,
    required this.password,
  });
}

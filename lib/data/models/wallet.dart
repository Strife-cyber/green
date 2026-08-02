/// A user's wallet — available balance plus escrow held until delivery
/// (PAY-03). Money is `int` FCFA.
class Wallet {
  final String id;
  final String userId;
  final int balance;
  final int escrowBalance;

  const Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.escrowBalance,
  });

  int get total => balance + escrowBalance;

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        id: json['id'] as String,
        userId: json['user_id'] as String? ?? '',
        balance: parseMoneyFromJson(json['balance']),
        escrowBalance: parseMoneyFromJson(json['escrow_balance']),
      );

  static int parseMoneyFromJson(dynamic value) {
    if (value == null) return 0;
    return (value is num)
        ? value.round()
        : int.tryParse(value.toString()) ?? double.tryParse(value.toString())?.round() ?? 0;
  }
}

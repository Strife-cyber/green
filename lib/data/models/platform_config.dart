/// Runtime-tunable business parameters (D1/D2/D4/D5).
class PlatformConfig {
  final String key;
  final String value;
  final String? description;

  const PlatformConfig({required this.key, required this.value, this.description});

  factory PlatformConfig.fromJson(Map<String, dynamic> json) => PlatformConfig(
        key: json['key'] as String,
        value: json['value'] as String? ?? '',
        description: json['description'] as String?,
      );

  /// Current commission rate as a fraction (e.g. `0.05` for 5%).
  double get commissionRate => double.tryParse(value) ?? 0;
  int get minWithdrawal => int.tryParse(value) ?? 2000;
  String get receiptPrefix => value;
}

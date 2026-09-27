import 'package:intl/intl.dart';

/// Money helpers.
///
/// GREENISH deals in **FCFA (XAF)**. All UI amounts are [`int`] FCFA — never
/// `double`. The backend returns Prisma `Decimal` values as strings
/// (e.g. `"2500.00"`); [parseMoney] centralises that conversion so the rest of
/// the app can treat amounts as integers (D-FE6).
int parseMoney(String? value) {
  if (value == null || value.trim().isEmpty) return 0;
  // Strip thousands separators (`,`); the backend Decimal uses `.` only.
  final normalized = value.trim().replaceAll(',', '');
  final parsed = double.tryParse(normalized);
  return parsed == null ? 0 : parsed.round();
}

/// Flat per-order delivery fee shown in cart/checkout (ORD-05). The platform
/// config key `delivery_fee_flat` overrides it (backend default: 700 FCFA).
const int kDefaultDeliveryFee = 700;

/// Minimum withdrawal (WAL-04); the platform config key `min_withdrawal`
/// overrides it once exposed.
const int kDefaultMinWithdrawal = 5000;

/// Formats an amount as `2 500 FCFA`.
String formatMoney(int amount) => '${formatAmount(amount)} FCFA';

/// Formats an amount without the currency suffix, e.g. `2 500`.
///
/// Groups with a regular space (normalising the narrow no-break space some
/// locales emit) so the output is deterministic and testable.
String formatAmount(int amount) => NumberFormat.decimalPattern('fr-FR')
    .format(amount)
    .replaceAll(' ', ' ');

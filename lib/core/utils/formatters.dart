import 'package:intl/intl.dart';

/// Shared display formatters (dates, quantities).
String formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

String formatDateTime(DateTime date) => DateFormat('dd MMM yyyy · HH:mm').format(date);

/// Formats a kg quantity, trimming trailing zeros: `5`, `2.5`.
String formatKg(num kg) {
  if (kg == kg.roundToDouble()) return '${kg.toInt()} kg';
  return '$kg kg';
}

import 'package:intl/intl.dart';

/// Shared display formatters (dates, quantities).
String formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

String formatDateTime(DateTime date) => DateFormat('dd MMM yyyy · HH:mm').format(date);

/// Formats a kg quantity, trimming trailing zeros: `5`, `2.5`.
String formatKg(num kg) {
  if (kg == kg.roundToDouble()) return '${kg.toInt()} kg';
  return '$kg kg';
}

/// A short, human-friendly order reference derived from a UUID, e.g. the order
/// `299a5c2b-…` displays as `#299A5C` — no raw UUIDs on screens.
String orderReference(String id) {
  final cleaned = id.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
  return cleaned.length >= 6
      ? '#${cleaned.substring(0, 6).toUpperCase()}'
      : '#$id';
}

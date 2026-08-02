import 'package:flutter_test/flutter_test.dart';
import 'package:green/core/utils/money.dart';

void main() {
  group('parseMoney', () {
    test('parses Prisma Decimal-as-string values', () {
      expect(parseMoney('2500.00'), 2500);
      expect(parseMoney('2500'), 2500);
      expect(parseMoney('0'), 0);
    });

    test('rounds fractional values to whole FCFA', () {
      expect(parseMoney('2,500.5'), 2501);
      expect(parseMoney('2,500.4'), 2500);
    });

    test('handles empty / null input', () {
      expect(parseMoney(null), 0);
      expect(parseMoney(''), 0);
      expect(parseMoney('  '), 0);
    });
  });

  group('format', () {
    test('formatMoney renders currency suffix', () {
      expect(formatMoney(2500), '2 500 FCFA');
      expect(formatMoney(0), '0 FCFA');
    });

    test('formatAmount groups thousands with spaces', () {
      expect(formatAmount(1234567), '1 234 567');
      expect(formatAmount(1000), '1 000');
    });
  });
}

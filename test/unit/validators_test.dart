import 'package:flutter_test/flutter_test.dart';
import 'package:green/core/utils/validators.dart';

void main() {
  group('passwordStrength (AUTH-01 rules)', () {
    test('a strong password passes all rules', () {
      final s = passwordStrength('BuyerPass1!');
      expect(s.valid, isTrue);
      expect(s.score, 4);
    });

    test('short password fails', () {
      final s = passwordStrength('Ab1!');
      expect(s.valid, isFalse);
      expect(s.failed, contains('At least 8 characters'));
    });

    test('missing special character fails', () {
      final s = passwordStrength('BuyerPass1');
      expect(s.valid, isFalse);
      expect(s.failed, contains('One special character'));
    });
  });

  group('validateEmail', () {
    test('accepts valid emails', () {
      expect(validateEmail('marie@greenish.cm'), isNull);
      expect(validateEmail('a.b+tag@sub.example.org'), isNull);
    });

    test('rejects invalid emails', () {
      expect(validateEmail('not-an-email'), isNotNull);
      expect(validateEmail(''), isNotNull);
    });
  });

  group('validatePhone', () {
    test('accepts Cameroonian numbers with/without prefix', () {
      expect(validatePhone('655123456'), isNull);
      expect(validatePhone('+237655123456'), isNull);
    });

    test('rejects wrong lengths / prefixes', () {
      expect(validatePhone('12345'), isNotNull);
      expect(validatePhone('455123456'), isNotNull);
    });
  });

  group('validateConfirmPassword', () {
    test('requires a match', () {
      expect(validateConfirmPassword('Same1!', 'Same1!'), isNull);
      expect(validateConfirmPassword('Same1!', 'Other2@'), isNotNull);
      expect(validateConfirmPassword('', 'Other2@'), isNotNull);
    });
  });
}

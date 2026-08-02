/// Form validators shared across screens.
///
/// Password rules follow AUTH-01: min 8 chars with upper, lower, digit and a
/// special character.
library;

final _emailRe = RegExp(r"^[\w.!#$%&'*+/=?^`{|}~-]+@[\w-]+(\.[\w-]+)+$");

/// Cameroon mobile numbers: optional `+237` / `237` prefix, then 9 digits
/// starting with 6, 7, 8 (2 allowed loosely for landlines).
final _phoneRe = RegExp(r'^(?:\+?237)?\s?[23678]\d{8}$');

final _upperRe = RegExp(r'[A-Z]');
final _lowerRe = RegExp(r'[a-z]');
final _digitRe = RegExp(r'\d');
final _specialRe = RegExp(r'[^A-Za-z0-9]');

String? validateRequired(String? value, [String field = 'This field']) {
  if (value == null || value.trim().isEmpty) return '$field is required.';
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return 'Email is required.';
  if (!_emailRe.hasMatch(value.trim())) return 'Enter a valid email address.';
  return null;
}

String? validatePhone(String? value) {
  if (value == null || value.trim().isEmpty) return 'Phone number is required.';
  if (!_phoneRe.hasMatch(value.trim())) {
    return 'Enter a valid Cameroonian number (e.g. 6XX XX XX XX).';
  }
  return null;
}

/// Strength of a password. [score] is 1–4, [valid] is true when all rules pass.
({int score, bool valid, List<String> failed}) passwordStrength(String value) {
  final failed = <String>[];
  if (value.length < 8) failed.add('At least 8 characters');
  if (!_upperRe.hasMatch(value)) failed.add('One uppercase letter');
  if (!_lowerRe.hasMatch(value)) failed.add('One lowercase letter');
  if (!_digitRe.hasMatch(value)) failed.add('One number');
  if (!_specialRe.hasMatch(value)) failed.add('One special character');

  var score = 0;
  if (value.length >= 8) score++;
  if (_upperRe.hasMatch(value) && _lowerRe.hasMatch(value)) score++;
  if (_digitRe.hasMatch(value)) score++;
  if (_specialRe.hasMatch(value)) score++;
  score = score.clamp(1, 4);

  return (score: failed.isEmpty ? 4 : score, valid: failed.isEmpty, failed: failed);
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Password is required.';
  final strength = passwordStrength(value);
  if (!strength.valid) return strength.failed.join(', ');
  return null;
}

String? validateConfirmPassword(String? value, String password) {
  if (value == null || value.isEmpty) return 'Confirm your password.';
  if (value != password) return 'Passwords do not match.';
  return null;
}

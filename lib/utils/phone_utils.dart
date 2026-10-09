/// Shared Tanzanian phone number helpers used across sign-up,
/// subscription, credit/document purchase and booking flows.
class PhoneUtils {
  /// Visual state of a phone input for live feedback.
  static const validBorderWidth = 1.5;

  /// Normalizes raw input to international format without '+'
  /// e.g. "0712 345 678", "+255 712 345 678", "712345678" -> "255712345678"
  static String normalize(String raw) {
    var phone = raw.trim().replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.startsWith('+')) phone = phone.substring(1);
    if (phone.startsWith('0')) return '255${phone.substring(1)}';
    if (phone.startsWith('255')) return phone;
    // Bare local number (9 digits, e.g. 712345678) -> prepend country code
    if (phone.length == 9 && RegExp(r'^[6-9]\d{8}$').hasMatch(phone)) {
      return '255$phone';
    }
    return phone;
  }

  /// True when [raw] is a complete, valid Tanzanian mobile number.
  static bool isValidTanzanian(String raw) {
    return RegExp(r'^255\d{9}$').hasMatch(normalize(raw));
  }
}

/// Live feedback state for a phone text field.
enum PhoneInputState { empty, valid, invalid }

extension PhoneInputStateX on PhoneInputState {
  bool get isValid => this == PhoneInputState.valid;
  bool get isInvalid => this == PhoneInputState.invalid;
}

/// Derives the [PhoneInputState] for a raw phone string.
PhoneInputState phoneInputStateOf(String raw) {
  if (raw.trim().isEmpty) return PhoneInputState.empty;
  return PhoneUtils.isValidTanzanian(raw)
      ? PhoneInputState.valid
      : PhoneInputState.invalid;
}

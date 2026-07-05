/// Utility for formatting phone numbers with Tanzania country code
class PhoneFormatter {
  /// Format phone number with Tanzania country code if missing
  /// Returns formatted phone number with +255 prefix
  static String formatWithCountryCode(String phone) {
    // Remove any non-digit characters
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');

    // If already has country code (starts with 255), add + prefix
    if (digits.startsWith('255')) {
      return '+$digits';
    }

    // If starts with 0, replace with +255
    if (digits.startsWith('0')) {
      return '+255${digits.substring(1)}';
    }

    // If 10 digits (Tanzania format without 0), add +255
    if (digits.length == 10) {
      return '+255$digits';
    }

    // Default: add +255 prefix
    return '+255$digits';
  }

  /// Format phone number as Nexacon NX ID
  /// Returns formatted phone number with +255 prefix (no domain suffix)
  static String formatAsNxId(String phone) {
    return formatWithCountryCode(phone);
  }
}

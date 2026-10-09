/// Utility for formatting phone numbers with Tanzania country code
class PhoneFormatter {
  static const String _nxDomain = 'nxservice.quantumvision-tech.com';

  /// Format phone number with Tanzania country code if missing
  /// Returns formatted phone number with +255 prefix (e.g. +255712345678)
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

  /// Format phone number as Nexacon NX JID (XMPP format)
  /// Returns e.g. +255712345678@nxservice.quantumvision-tech.com
  static String formatAsNxId(String phone) {
    // Strip any existing domain
    final stripped = phone.contains('@') ? phone.split('@')[0] : phone;
    // Get digits only
    final digits = stripped.replaceAll(RegExp(r'[^\d]'), '');
    String formatted;

    if (digits.startsWith('255')) {
      formatted = '+$digits';
    } else if (digits.startsWith('0')) {
      formatted = '+255${digits.substring(1)}';
    } else if (digits.length == 9 || digits.length == 10) {
      formatted = '+255$digits';
    } else {
      formatted = '+255$digits';
    }

    return '$formatted@$_nxDomain';
  }

  /// Normalize a JID or phone to plain digits with 255 prefix for comparison.
  /// Handles +255712..., 255712..., 0712..., 712... formats so they all
  /// produce the same key: 255712...
  static String normalize(String nxIdOrPhone) {
    final local =
        nxIdOrPhone.contains('@') ? nxIdOrPhone.split('@')[0] : nxIdOrPhone;
    var digits = local.replaceAll(RegExp(r'[^\d]'), '');

    // Normalize Tanzania country code:
    // 0712345678 -> 255712345678
    // 712345678  -> 255712345678
    // 255712345678 -> 255712345678 (already correct)
    if (digits.startsWith('0')) {
      digits = '255${digits.substring(1)}';
    } else if (digits.length == 9 && !digits.startsWith('255')) {
      digits = '255$digits';
    }

    return digits;
  }
}

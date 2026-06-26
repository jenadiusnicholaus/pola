import 'package:flutter_dotenv/flutter_dotenv.dart';

class NexaconConfig {
  // Get these from Nexacon console
  // Loaded from .env file for security
  static String get apiKey {
    final key = dotenv.env['NEXACON_API_KEY'] ?? '';
    if (key.isEmpty || key == 'YOUR_NEXACON_API_KEY_HERE') {
      throw Exception('NEXACON_API_KEY not configured in .env file');
    }
    return key;
  }

  static String get secretKey {
    final key = dotenv.env['NEXACON_SECRET_KEY'] ?? '';
    if (key.isEmpty || key == 'YOUR_NEXACON_SECRET_KEY_HERE') {
      throw Exception('NEXACON_SECRET_KEY not configured in .env file');
    }
    return key;
  }

  /// Generate unique call ID for each call
  /// Format: call_{consultantId}_{timestamp}
  static String generateCallId(int consultantId) {
    return 'call_${consultantId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generate a unique user ID from timestamp
  static String generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}';
  }
}

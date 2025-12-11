import 'package:flutter_dotenv/flutter_dotenv.dart';

class AgoraConfig {
  // Get this from console.agora.io
  // Loaded from .env file for security
  static String get APP_ID => dotenv.env['APP_ID'] ?? '';

  // Token is empty for testing (configure in Agora Console)
  // For production, get token from your backend
  static const String TOKEN = '';

  /// Generate unique channel name for each call
  /// Format: call_{consultantId}_{timestamp}
  static String generateChannelName(int consultantId) {
    return 'call_${consultantId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generate a unique user ID
  static int generateUserId() {
    return DateTime.now().millisecondsSinceEpoch % 100000;
  }
}

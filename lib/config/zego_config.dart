import 'package:flutter_dotenv/flutter_dotenv.dart';

class ZegoConfig {
  // Get these from console.zegocloud.com
  // Loaded from .env file for security
  static int get appId {
    final appIdStr = dotenv.env['ZEGO_APP_ID'] ?? '';
    if (appIdStr.isEmpty || appIdStr == 'YOUR_ZEGO_APP_ID_HERE') {
      throw Exception('ZEGO_APP_ID not configured in .env file');
    }
    return int.parse(appIdStr);
  }

  static String get appSign {
    final sign = dotenv.env['ZEGO_APP_SIGN'] ?? '';
    if (sign.isEmpty || sign == 'YOUR_ZEGO_APP_SIGN_HERE') {
      throw Exception('ZEGO_APP_SIGN not configured in .env file');
    }
    return sign;
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

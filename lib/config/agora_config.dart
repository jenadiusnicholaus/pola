class AgoraConfig {
  // Get this from console.agora.io
  // For development, you can use the App ID directly
  // For production, implement token generation on backend
  static const String APP_ID = 'YOUR_AGORA_APP_ID_HERE';

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

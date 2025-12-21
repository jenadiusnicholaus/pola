import '../config/environment_config.dart';

class UrlHelper {
  /// Fix URLs that come from backend with 127.0.0.1 or localhost
  /// Replaces them with the actual network IP from .env
  static String? fixImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    // Get the base URL from environment config (e.g., http://192.168.1.132:8000)
    final baseUrl = EnvironmentConfig.baseUrl;

    // Replace localhost and 127.0.0.1 with the actual network IP
    return url
        .replaceAll('http://127.0.0.1:8000', baseUrl)
        .replaceAll('http://localhost:8000', baseUrl)
        .replaceAll('https://127.0.0.1:8000', baseUrl)
        .replaceAll('https://localhost:8000', baseUrl);
  }

  /// Fix any media URL from the API
  static String? fixMediaUrl(String? url) => fixImageUrl(url);
}

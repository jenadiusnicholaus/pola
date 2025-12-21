import 'package:flutter/material.dart';
import '../config/environment_config.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;
  final double radius;
  final Color? backgroundColor;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.fallbackText,
    this.radius = 28,
    this.backgroundColor,
  });

  static String? _fixUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    final baseUrl = EnvironmentConfig.baseUrl;
    return url
        .replaceAll('http://127.0.0.1:8000', baseUrl)
        .replaceAll('http://localhost:8000', baseUrl);
  }

  Widget _buildFallback(Color bgColor, Color textColor) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fixedUrl = _fixUrl(imageUrl);
    final hasImage = fixedUrl != null && fixedUrl.isNotEmpty;
    final bgColor = backgroundColor ?? theme.colorScheme.primaryContainer;
    final textColor = theme.colorScheme.onPrimaryContainer;

    if (!hasImage) {
      return _buildFallback(bgColor, textColor);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: ClipOval(
        child: Image.network(
          fixedUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: radius * 0.5,
                height: radius * 0.5,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Image load error: $error');
            return _buildFallback(bgColor, textColor);
          },
          cacheWidth: 200,
          cacheHeight: 200,
        ),
      ),
    );
  }
}

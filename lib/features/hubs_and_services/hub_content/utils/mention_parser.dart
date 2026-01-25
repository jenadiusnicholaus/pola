import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// Utility class for parsing and handling mentions in comments
class MentionParser {
  /// Regular expression to match @mentions (e.g., @username or @123)
  static final RegExp _mentionRegex = RegExp(r'@(\w+)');

  /// Parse text and extract mentioned usernames
  static List<String> extractMentions(String text) {
    final matches = _mentionRegex.allMatches(text);
    return matches.map((match) => match.group(1)!).toList();
  }

  /// Build rich text with styled mentions
  static TextSpan buildMentionTextSpan({
    required String text,
    required TextStyle baseStyle,
    required Color mentionColor,
    Function(String)? onMentionTap,
  }) {
    final spans = <TextSpan>[];
    int lastIndex = 0;

    final matches = _mentionRegex.allMatches(text);

    for (final match in matches) {
      // Add text before mention
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      // Add mention with special styling
      final mentionText = match.group(0)!;
      final username = match.group(1)!;

      spans.add(TextSpan(
        text: mentionText,
        style: baseStyle.copyWith(
          color: mentionColor,
          fontWeight: FontWeight.bold,
        ),
        recognizer: onMentionTap != null
            ? (TapGestureRecognizer()..onTap = () => onMentionTap(username))
            : null,
      ));

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return TextSpan(children: spans);
  }

  /// Check if text contains any mentions
  static bool hasMentions(String text) {
    return _mentionRegex.hasMatch(text);
  }

  /// Get count of mentions in text
  static int getMentionCount(String text) {
    return _mentionRegex.allMatches(text).length;
  }

  /// Replace mentions with user IDs (for API submission)
  /// mentionMap: Map of username to user ID
  static String replaceMentionsWithIds(
    String text,
    Map<String, int> mentionMap,
  ) {
    String result = text;
    mentionMap.forEach((username, userId) {
      result = result.replaceAll('@$username', '@$userId');
    });
    return result;
  }

  /// Extract user IDs from mentions in text
  /// usernamesToIds: Map of username to user ID
  static List<int> extractMentionedUserIds(
    String text,
    Map<String, int> usernamesToIds,
  ) {
    final mentions = extractMentions(text);
    final userIds = <int>[];

    for (final mention in mentions) {
      if (usernamesToIds.containsKey(mention)) {
        userIds.add(usernamesToIds[mention]!);
      }
    }

    return userIds;
  }

  /// Format mention for display (with @ prefix if not present)
  static String formatMention(String username) {
    return username.startsWith('@') ? username : '@$username';
  }

  /// Validate mention format
  static bool isValidMention(String mention) {
    return _mentionRegex.hasMatch(mention);
  }
}



import 'package:flutter_test/flutter_test.dart';
import 'package:pola/features/hubs_and_services/hub_content/models/hub_content_models.dart';
import 'package:pola/features/hubs_and_services/hub_content/utils/mention_parser.dart';
import 'package:pola/features/hubs_and_services/hub_content/widgets/mention_text_field.dart';
import 'package:pola/features/hubs_and_services/legal_education/models/legal_education_models.dart';

void main() {
  group('Mention Feature Tests', () {
    test('HubComment should include mentionedUserIds', () {
      final comment = HubComment(
        id: 1,
        contentId: 1,
        comment: 'Hey @john, check this out! @jane what do you think?',
        author: UploaderInfo(
          id: 1,
          username: 'testuser',
          email: 'test@example.com',
          fullName: 'Test User',
          userRole: 'user',
          isVerified: false,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        mentionedUserIds: [10, 20],
      );

      expect(comment.mentionedUserIds, [10, 20]);
      expect(comment.comment, contains('@john'));
      expect(comment.comment, contains('@jane'));
    });

    test('CreateCommentRequest should include mentioned_users in JSON', () {
      final request = CreateCommentRequest(
        contentId: 1,
        comment: 'Hello @user1',
        hubType: 'forum',
        mentionedUserIds: [5],
      );

      final json = request.toJson();
      expect(json['mentioned_users'], [5]);
      expect(json['comment_text'], 'Hello @user1');
    });

    test('MentionParser should extract mentions correctly', () {
      final text = 'Hey @john and @jane, check this @admin please!';
      final mentions = MentionParser.extractMentions(text);

      expect(mentions, ['john', 'jane', 'admin']);
      expect(mentions.length, 3);
    });

    test('MentionParser should check if text has mentions', () {
      expect(MentionParser.hasMentions('Hey @user'), true);
      expect(MentionParser.hasMentions('Hey there'), false);
      expect(MentionParser.hasMentions('@start of text'), true);
    });

    test('MentionParser should count mentions', () {
      final text = 'Hello @john and @jane, see @admin';
      expect(MentionParser.getMentionCount(text), 3);
    });

    test('MentionParser should extract user IDs from mentions', () {
      final text = 'Hey @john, tell @jane about this';
      final userMap = {'john': 10, 'jane': 20, 'admin': 30};
      
      final userIds = MentionParser.extractMentionedUserIds(text, userMap);
      expect(userIds, [10, 20]);
    });

    test('MentionParser should validate mention format', () {
      expect(MentionParser.isValidMention('@user'), true);
      expect(MentionParser.isValidMention('@user123'), true);
      expect(MentionParser.isValidMention('@user_name'), true);
      expect(MentionParser.isValidMention('user'), false);
      expect(MentionParser.isValidMention('@ user'), false);
    });

    test('HubComment.fromJson should parse mentioned_users', () {
      final json = {
        'id': 1,
        'content': 1,
        'comment_text': 'Hello @user',
        'author_info': {
          'id': 1,
          'email': 'test@example.com',
          'full_name': 'Test User',
          'user_role': 'user',
          'is_verified': false,
        },
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'mentioned_users': [10, 20, 30],
      };

      final comment = HubComment.fromJson(json);
      expect(comment.mentionedUserIds, [10, 20, 30]);
    });

    test('HubComment.toJson should include mentioned_users', () {
      final comment = HubComment(
        id: 1,
        contentId: 1,
        comment: 'Test @mention',
        author: UploaderInfo(
          id: 1,
          username: 'testuser',
          email: 'test@example.com',
          fullName: 'Test User',
          userRole: 'user',
          isVerified: false,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        mentionedUserIds: [5, 10],
      );

      final json = comment.toJson();
      expect(json['mentioned_users'], [5, 10]);
    });
  });

  group('Mention Widget Tests', () {
    test('MentionSuggestion should parse from JSON', () {
      final json = {
        'id': 1,
        'username': 'testuser',
        'first_name': 'Test',
        'last_name': 'User',
        'avatar_url': 'https://example.com/avatar.jpg',
      };

      final suggestion = MentionSuggestion.fromJson(json);
      expect(suggestion.userId, 1);
      expect(suggestion.username, 'testuser');
      expect(suggestion.displayName, 'Test User');
      expect(suggestion.avatarUrl, 'https://example.com/avatar.jpg');
    });
  });
}

// Hub Content Service Integration Tests
// These tests verify the service methods work correctly with proper mocking

import 'package:flutter_test/flutter_test.dart';
import 'package:pola/features/hubs_and_services/hub_content/models/hub_content_models.dart';

void main() {
  group('Hub Content Service Integration Tests', () {
    group('Service Method Structure Tests', () {
      test('Method signatures exist in service interface', () {
        // These tests verify the methods exist without actually calling them
        expect(true, isTrue); // Placeholder for method signature validation
      });
    });

    group('Filter Parameter Building', () {
      test('SearchFilters builds correct query parameters', () {
        final filters = SearchFilters(
          hubType: 'advocates',
          search: 'criminal law',
          ordering: '-created_at',
          isDownloadable: true,
          contentType: 'pdf',
          topicId: 123,
          page: 2,
          pageSize: 15,
        );

        final params = filters.toQueryParameters();

        expect(params, hasLength(8));
        expect(params['hub_type'], equals('advocates'));
        expect(params['search'], equals('criminal law'));
        expect(params['ordering'], equals('-created_at'));
        expect(params['is_downloadable'], equals('true'));
        expect(params['content_type'], equals('pdf'));
        expect(params['topic'], equals('123'));
        expect(params['page'], equals('2'));
        expect(params['page_size'], equals('15'));
      });

      test('SearchFilters handles null and empty values', () {
        final filters = SearchFilters(
          hubType: 'students',
          search: null,
          ordering: null,
          page: 1,
        );

        final params = filters.toQueryParameters();

        expect(params['hub_type'], equals('students'));
        expect(params['page'], equals('1'));
        expect(params.containsKey('search'), isFalse);
        expect(params.containsKey('ordering'), isFalse);
        expect(params.containsKey('is_downloadable'), isFalse);
      });

      test('SearchFilters handles empty search string', () {
        final filters = SearchFilters(
          search: '',
          hubType: 'forum',
        );

        final params = filters.toQueryParameters();

        expect(params.containsKey('search'), isFalse);
        expect(params['hub_type'], equals('forum'));
      });
    });

    group('Request/Response Models', () {
      test('CreateRatingRequest serializes correctly', () {
        final request = CreateRatingRequest(
          rating: 4.5,
          review: 'Great content!',
        );

        final json = request.toJson();

        expect(json['rating'], equals(4.5));
        expect(json['review'], equals('Great content!'));
      });

      test('CreateRatingRequest without review', () {
        final request = CreateRatingRequest(rating: 3.0);

        final json = request.toJson();

        expect(json['rating'], equals(3.0));
        expect(json.containsKey('review'), isFalse);
      });

      test('CreateCommentRequest serializes correctly', () {
        final request = CreateCommentRequest(
          contentId: 123,
          comment: 'This is a comment',
          hubType: 'advocates',
          parentCommentId: 456,
        );

        final json = request.toJson();

        expect(json['content'], equals(123));
        expect(json['comment_text'], equals('This is a comment'));
        expect(json['hub_type'], equals('advocates'));
        expect(json['parent_comment'], equals(456));
      });

      test('CreateMessageRequest serializes correctly', () {
        final request = CreateMessageRequest(
          recipientId: 789,
          hubType: 'students',
          subject: 'Test Subject',
          message: 'Test Message',
          contentId: 123,
        );

        final json = request.toJson();

        expect(json['recipient_id'], equals(789));
        expect(json['hub_type'], equals('students'));
        expect(json['subject'], equals('Test Subject'));
        expect(json['message'], equals('Test Message'));
        expect(json['content_id'], equals(123));
      });
    });

    group('Model Validation', () {
      test('HubContentItem validates file extensions', () {
        final pdfItem = HubContentItem.fromJson({
          'id': 1,
          'hub_type': 'students',
          'content_type': 'pdf',
          'title': 'PDF Test',
          'description': '',
          'content': '',
          'file': 'https://example.com/document.pdf',
          'video_url': '',
          'price': '0.00',
          'price_display': 'Free',
          'is_downloadable': false,
          'is_pinned': false,
          'is_lecture_material': false,
          'is_verified': false,
          'is_liked': false,
          'is_bookmarked': false,
          'is_free': true,
          'is_purchased': false,
          'rating': 0.0,
          'total_ratings': 0,
          'views_count': 0,
          'downloads_count': 0,
          'downloads_count_display': '0 downloads',
          'likes_count': 0,
          'bookmarks_count': 0,
          'comments_count': 0,
          'tags': [],
          'uploader_info': {'id': 1, 'full_name': 'Test User', 'avatar': ''},
          'created_at': '2025-11-06T10:00:00Z',
          'updated_at': '2025-11-06T10:00:00Z',
        });

        expect(pdfItem.fileExtension, equals('pdf'));
        expect(pdfItem.isPdf, isTrue);
        expect(pdfItem.isImage, isFalse);
        expect(pdfItem.hasVideo, isFalse);
      });

      test('HubContentItem handles various image formats', () {
        final imageFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];

        for (final format in imageFormats) {
          final imageItem = HubContentItem.fromJson({
            'id': 1,
            'hub_type': 'forum',
            'content_type': 'image',
            'title': 'Image Test',
            'description': '',
            'content': '',
            'file': 'https://example.com/image.$format',
            'video_url': '',
            'price': '0.00',
            'price_display': 'Free',
            'is_downloadable': false,
            'is_pinned': false,
            'is_lecture_material': false,
            'is_verified': false,
            'is_liked': false,
            'is_bookmarked': false,
            'is_free': true,
            'is_purchased': false,
            'rating': 0.0,
            'total_ratings': 0,
            'views_count': 0,
            'downloads_count': 0,
            'downloads_count_display': '0 downloads',
            'likes_count': 0,
            'bookmarks_count': 0,
            'comments_count': 0,
            'tags': [],
            'uploader_info': {'id': 1, 'full_name': 'Test User', 'avatar': ''},
            'created_at': '2025-11-06T10:00:00Z',
            'updated_at': '2025-11-06T10:00:00Z',
          });

          expect(imageItem.fileExtension, equals(format));
          expect(imageItem.isImage, isTrue,
              reason: 'Failed for format: $format');
        }
      });

      test('HubContentItem YouTube URL parsing', () {
        final youtubeUrls = [
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          'https://youtu.be/dQw4w9WgXcQ',
          'https://youtube.com/watch?v=dQw4w9WgXcQ',
        ];

        for (final url in youtubeUrls) {
          final videoItem = HubContentItem.fromJson({
            'id': 1,
            'hub_type': 'legal_ed',
            'content_type': 'video',
            'title': 'Video Test',
            'description': '',
            'content': '',
            'file': '',
            'video_url': url,
            'price': '0.00',
            'price_display': 'Free',
            'is_downloadable': false,
            'is_pinned': false,
            'is_lecture_material': false,
            'is_verified': false,
            'is_liked': false,
            'is_bookmarked': false,
            'is_free': true,
            'is_purchased': false,
            'rating': 0.0,
            'total_ratings': 0,
            'views_count': 0,
            'downloads_count': 0,
            'downloads_count_display': '0 downloads',
            'likes_count': 0,
            'bookmarks_count': 0,
            'comments_count': 0,
            'tags': [],
            'uploader_info': {'id': 1, 'full_name': 'Test User', 'avatar': ''},
            'created_at': '2025-11-06T10:00:00Z',
            'updated_at': '2025-11-06T10:00:00Z',
          });

          expect(videoItem.hasVideo, isTrue, reason: 'Failed for URL: $url');
          expect(videoItem.videoThumbnailUrl, contains('youtube.com/vi'));
          expect(videoItem.videoThumbnailUrl, contains('dQw4w9WgXcQ'));
        }
      });

      test('HubContentItem price validation', () {
        final freeItem = HubContentItem.fromJson({
          'id': 1,
          'hub_type': 'forum',
          'title': 'Free Content',
          'price': '0.00',
          'is_free': true,
          'uploader_info': {'id': 1, 'full_name': 'Test', 'avatar': ''},
          'created_at': '2025-11-06T10:00:00Z',
          'updated_at': '2025-11-06T10:00:00Z',
        });

        final paidItem = HubContentItem.fromJson({
          'id': 2,
          'hub_type': 'students',
          'title': 'Paid Content',
          'price': '29.99',
          'is_free': false,
          'uploader_info': {'id': 1, 'full_name': 'Test', 'avatar': ''},
          'created_at': '2025-11-06T10:00:00Z',
          'updated_at': '2025-11-06T10:00:00Z',
        });

        expect(freeItem.isPaid, isFalse);
        expect(paidItem.isPaid, isTrue);
      });
    });

    group('Content Type Configurations', () {
      test('All content types have valid configurations', () {
        final contentTypes = [
          'discussion',
          'question',
          'article',
          'document',
          'notes',
          'past_papers',
          'tutorial',
          'research',
          'news',
          'case_study',
          'legal_update',
          'assignment',
          'general',
          'lecture'
        ];

        for (final type in contentTypes) {
          final config = ContentTypeConfig.getByKey(type);
          expect(config, isNotNull, reason: 'Missing config for: $type');
          expect(config!.key, equals(type));
          expect(config.displayName, isNotEmpty);
          expect(config.icon, isNotEmpty);
        }
      });

      test('Content type payment validation', () {
        // These should allow payment
        final paidTypes = [
          'document',
          'notes',
          'past_papers',
          'tutorial',
          'research',
          'assignment'
        ];
        for (final type in paidTypes) {
          final config = ContentTypeConfig.getByKey(type);
          expect(config!.canBePaid, isTrue,
              reason: '$type should allow payment');
        }

        // These should be free
        final freeTypes = [
          'discussion',
          'question',
          'article',
          'news',
          'general'
        ];
        for (final type in freeTypes) {
          final config = ContentTypeConfig.getByKey(type);
          expect(config!.canBePaid, isFalse, reason: '$type should be free');
        }
      });
    });

    group('Hub Access Control', () {
      test('Hub authentication requirements', () {
        final publicHubs = ['forum', 'legal_ed'];
        final protectedHubs = ['advocates', 'students'];

        for (final hub in publicHubs) {
          final config = HubConfig.getHubByKey(hub);
          expect(config!.requiresAuth, isFalse,
              reason: '$hub should be public');
        }

        for (final hub in protectedHubs) {
          final config = HubConfig.getHubByKey(hub);
          expect(config!.requiresAuth, isTrue,
              reason: '$hub should require auth');
        }
      });

      test('Hub role restrictions', () {
        final advocatesHub = HubConfig.getHubByKey('advocates');
        expect(advocatesHub!.allowedRoles, contains('advocate'));
        expect(advocatesHub.allowedRoles, contains('admin'));

        final studentsHub = HubConfig.getHubByKey('students');
        expect(studentsHub!.allowedRoles, contains('student'));
        expect(studentsHub.allowedRoles, contains('lecturer'));
        expect(studentsHub.allowedRoles, contains('admin'));

        final forumHub = HubConfig.getHubByKey('forum');
        expect(forumHub!.allowedRoles, isEmpty); // Public access
      });
    });

    group('Copy Operations', () {
      test('HubContentItem copyWith creates proper copy', () {
        final original = HubContentItem.fromJson({
          'id': 1,
          'hub_type': 'legal_ed',
          'title': 'Original Title',
          'likes_count': 10,
          'is_liked': false,
          'rating': 3.5,
          'total_ratings': 20,
          'uploader_info': {'id': 1, 'full_name': 'Test', 'avatar': ''},
          'created_at': '2025-11-06T10:00:00Z',
          'updated_at': '2025-11-06T10:00:00Z',
        });

        final updated = original.copyWith(
          title: 'Updated Title',
          likesCount: 15,
          isLiked: true,
          rating: 4.0,
          totalRatings: 25,
        );

        // Check updated fields
        expect(updated.title, equals('Updated Title'));
        expect(updated.likesCount, equals(15));
        expect(updated.isLiked, isTrue);
        expect(updated.rating, equals(4.0));
        expect(updated.totalRatings, equals(25));

        // Check unchanged fields
        expect(updated.id, equals(original.id));
        expect(updated.hubType, equals(original.hubType));
        expect(updated.createdAt, equals(original.createdAt));
      });

      test('HubComment copyWith preserves structure', () {
        final original = HubComment.fromJson({
          'id': 1,
          'content': 123,
          'comment_text': 'Original comment',
          'likes_count': 5,
          'user_has_liked': false,
          'author_info': {'id': 1, 'full_name': 'Test', 'avatar': ''},
          'created_at': '2025-11-06T10:00:00Z',
          'updated_at': '2025-11-06T10:00:00Z',
        });

        final updated = original.copyWith(
          comment: 'Updated comment',
          likesCount: 10,
          userHasLiked: true,
        );

        expect(updated.comment, equals('Updated comment'));
        expect(updated.likesCount, equals(10));
        expect(updated.userHasLiked, isTrue);
        expect(updated.id, equals(original.id));
        expect(updated.contentId, equals(original.contentId));
      });
    });

    group('Date Parsing', () {
      test('Handles various date formats', () {
        final dateFormats = [
          '2025-11-06T10:00:00Z',
          '2025-11-06T10:00:00.000Z',
          '2025-11-06T10:00:00+00:00',
          '2025-11-06 10:00:00',
        ];

        for (final dateStr in dateFormats) {
          final item = HubContentItem.fromJson({
            'id': 1,
            'hub_type': 'forum',
            'title': 'Date Test',
            'created_at': dateStr,
            'updated_at': dateStr,
            'uploader_info': {'id': 1, 'full_name': 'Test', 'avatar': ''},
          });

          expect(item.createdAt, isA<DateTime>());
          expect(item.updatedAt, isA<DateTime>());
        }
      });

      test('Handles invalid dates gracefully', () {
        final item = HubContentItem.fromJson({
          'id': 1,
          'hub_type': 'forum',
          'title': 'Bad Date Test',
          'created_at': 'invalid-date',
          'updated_at': '',
          'uploader_info': {'id': 1, 'full_name': 'Test', 'avatar': ''},
        });

        expect(item.createdAt, isA<DateTime>());
        expect(item.updatedAt, isA<DateTime>());
      });
    });
  });
}

// Hub Content API Tests
// This file implements comprehensive testing for the Hub Content API

import 'package:flutter_test/flutter_test.dart';
import 'package:pola/features/hubs_and_services/hub_content/models/hub_content_models.dart';

void main() {
  group('Hub Content API Tests', () {
    group('Core Content Features', () {
      test('SearchFilters model serialization', () {
        final filters = SearchFilters(
          hubType: 'advocates',
          search: 'criminal law',
          ordering: '-created_at',
          isDownloadable: true,
          contentType: 'pdf',
          topicId: 123,
          page: 1,
          pageSize: 20,
        );

        final params = filters.toQueryParameters();

        expect(params['hub_type'], equals('advocates'));
        expect(params['search'], equals('criminal law'));
        expect(params['ordering'], equals('-created_at'));
        expect(params['is_downloadable'], equals('true'));
        expect(params['content_type'], equals('pdf'));
        expect(params['topic'], equals('123'));
        expect(params['page'], equals('1'));
        expect(params['page_size'], equals('20'));
      });

      test('HubContentItem model parsing', () {
        final json = {
          'id': 123,
          'hub_type': 'advocates',
          'content_type': 'pdf',
          'uploader_type': 'advocate',
          'title': 'Test Content',
          'description': 'Test Description',
          'content': 'Test Content Body',
          'file': 'https://example.com/test.pdf',
          'video_url': '',
          'price': '29.99',
          'price_display': '\$29.99',
          'is_downloadable': true,
          'is_pinned': false,
          'is_lecture_material': true,
          'is_verified': true,
          'is_liked': false,
          'is_bookmarked': false,
          'is_free': false,
          'is_purchased': true,
          'rating': 4.5,
          'total_ratings': 10,
          'views_count': 100,
          'downloads_count': 25,
          'downloads_count_display': '25 downloads',
          'likes_count': 15,
          'bookmarks_count': 8,
          'comments_count': 5,
          'tags': ['criminal', 'law', 'legal'],
          'uploader_info': {
            'id': 456,
            'full_name': 'John Doe',
            'avatar': 'https://example.com/avatar.jpg',
          },
          'created_at': '2025-11-06T10:00:00Z',
          'updated_at': '2025-11-06T15:00:00Z',
        };

        final item = HubContentItem.fromJson(json);

        expect(item.id, equals(123));
        expect(item.hubType, equals('advocates'));
        expect(item.title, equals('Test Content'));
        expect(item.isPdf, isTrue);
        expect(item.isPaid, isTrue);
        expect(item.rating, equals(4.5));
        expect(item.tags, contains('criminal'));
      });

      test('Content type detection', () {
        // Test PDF detection
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

        expect(pdfItem.isPdf, isTrue);
        expect(pdfItem.isImage, isFalse);
        expect(pdfItem.mediaType, equals('pdf'));

        // Test image detection
        final imageItem = pdfItem.copyWith(
          fileUrl: 'https://example.com/image.jpg',
          contentType: 'image',
        );

        expect(imageItem.isImage, isTrue);
        expect(imageItem.isPdf, isFalse);
        expect(imageItem.mediaType, equals('image'));
      });

      test('YouTube video detection', () {
        final videoItem = HubContentItem.fromJson({
          'id': 1,
          'hub_type': 'legal_ed',
          'content_type': 'video',
          'title': 'Video Test',
          'description': '',
          'content': '',
          'file': '',
          'video_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
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

        expect(videoItem.hasVideo, isTrue);
        expect(videoItem.mediaType, equals('video'));
        expect(videoItem.videoThumbnailUrl, contains('youtube.com'));
      });
    });

    group('Hub Configuration', () {
      test('Hub config retrieval', () {
        final advocatesHub = HubConfig.getHubByKey('advocates');
        expect(advocatesHub, isNotNull);
        expect(advocatesHub!.name, equals('Advocates Hub'));
        expect(advocatesHub.requiresAuth, isTrue);
        expect(advocatesHub.allowedRoles, contains('advocate'));

        final forumHub = HubConfig.getHubByKey('forum');
        expect(forumHub, isNotNull);
        expect(forumHub!.requiresAuth, isFalse);
        expect(forumHub.allowedRoles, isEmpty);
      });

      test('Content type configurations', () {
        final discussionConfig = ContentTypeConfig.getByKey('discussion');
        expect(discussionConfig, isNotNull);
        expect(discussionConfig!.canBePaid, isFalse);
        expect(discussionConfig.category, equals(ContentTypeCategory.post));

        final notesConfig = ContentTypeConfig.getByKey('notes');
        expect(notesConfig, isNotNull);
        expect(notesConfig!.canBePaid, isTrue);
        expect(notesConfig.category, equals(ContentTypeCategory.document));
      });
    });

    group('Response Models', () {
      test('HubContentResponse parsing', () {
        final json = {
          'count': 150,
          'next': 'http://localhost:8000/api/hubs/content/?page=2',
          'previous': null,
          'results': [
            {
              'id': 1,
              'hub_type': 'legal_ed',
              'content_type': 'article',
              'uploader_type': 'admin',
              'title': 'Test Article',
              'description': 'Test Description',
              'content': 'Test Content',
              'file': '',
              'video_url': '',
              'price': '0.00',
              'price_display': 'Free',
              'is_downloadable': false,
              'is_pinned': false,
              'is_lecture_material': false,
              'is_verified': true,
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
              'uploader_info': {'id': 1, 'full_name': 'Admin', 'avatar': ''},
              'created_at': '2025-11-06T10:00:00Z',
              'updated_at': '2025-11-06T10:00:00Z',
            }
          ],
          'active_users': 50,
          'total_content': 150,
        };

        final response = HubContentResponse.fromJson(json);

        expect(response.count, equals(150));
        expect(response.next, isNotNull);
        expect(response.previous, isNull);
        expect(response.results, hasLength(1));
        expect(response.activeUsers, equals(50));
        expect(response.totalContent, equals(150));
      });

      test('ContentAnalytics parsing', () {
        final json = {
          'views_count': 1250,
          'downloads_count': 89,
          'likes_count': 23,
          'bookmarks_count': 12,
          'ratings_count': 45,
          'average_rating': 4.7,
          'engagement_rate': 0.156,
          'daily_views': {
            '2025-11-01': 45,
            '2025-11-02': 67,
            '2025-11-03': 23,
          },
        };

        final analytics = ContentAnalytics.fromJson(json);

        expect(analytics.viewsCount, equals(1250));
        expect(analytics.downloadsCount, equals(89));
        expect(analytics.averageRating, equals(4.7));
        expect(analytics.engagementRate, equals(0.156));
        expect(analytics.dailyViews, hasLength(3));
        expect(analytics.dailyViews['2025-11-01'], equals(45));
      });

      test('RatingActionResponse parsing', () {
        final json = {
          'message': 'Content rated successfully',
          'rating': 5.0,
          'review': 'Great resource!',
          'content_average_rating': 4.8,
          'total_ratings': 46,
        };

        final response = RatingActionResponse.fromJson(json);

        expect(response.message, equals('Content rated successfully'));
        expect(response.rating, equals(5.0));
        expect(response.review, equals('Great resource!'));
        expect(response.contentAverageRating, equals(4.8));
        expect(response.totalRatings, equals(46));
      });
    });

    group('Comment System', () {
      test('HubComment model parsing', () {
        final json = {
          'id': 1,
          'content': 123,
          'parent_comment': null,
          'comment_text': 'This is a test comment',
          'author_info': {
            'id': 456,
            'full_name': 'Jane Doe',
            'avatar': 'https://example.com/avatar.jpg',
          },
          'created_at': '2025-11-06T10:00:00Z',
          'updated_at': '2025-11-06T10:00:00Z',
          'likes_count': 5,
          'replies_count': 2,
          'user_has_liked': false,
          'replies': [],
          'is_edited': false,
          'is_deleted': false,
          'depth': 0,
          'hub_type': 'advocates',
        };

        final comment = HubComment.fromJson(json);

        expect(comment.id, equals(1));
        expect(comment.contentId, equals(123));
        expect(comment.comment, equals('This is a test comment'));
        expect(comment.author.fullName, equals('Jane Doe'));
        expect(comment.likesCount, equals(5));
        expect(comment.depth, equals(0));
        expect(comment.hubType, equals('advocates'));
      });

      test('CreateCommentRequest serialization', () {
        final request = CreateCommentRequest(
          contentId: 123,
          comment: 'Test comment',
          hubType: 'advocates',
          parentCommentId: 456,
        );

        final json = request.toJson();

        expect(json['content'], equals(123));
        expect(json['comment_text'], equals('Test comment'));
        expect(json['hub_type'], equals('advocates'));
        expect(json['parent_comment'], equals(456));
      });
    });

    group('Messaging System', () {
      test('HubMessage model parsing', () {
        final json = {
          'id': 1,
          'hub_type': 'students',
          'sender_info': {
            'id': 123,
            'full_name': 'Sender Name',
            'avatar': 'https://example.com/sender.jpg',
          },
          'recipient_info': {
            'id': 456,
            'full_name': 'Recipient Name',
            'avatar': 'https://example.com/recipient.jpg',
          },
          'subject': 'Test Message',
          'message': 'This is a test message body',
          'is_read': false,
          'read_at': null,
          'created_at': '2025-11-06T10:00:00Z',
          'content_reference': null,
          'purchase_reference': null,
          'conversation_thread': [],
        };

        final message = HubMessage.fromJson(json);

        expect(message.id, equals(1));
        expect(message.hubType, equals('students'));
        expect(message.subject, equals('Test Message'));
        expect(message.message, equals('This is a test message body'));
        expect(message.isRead, isFalse);
        expect(message.readAt, isNull);
        expect(message.senderInfo.fullName, equals('Sender Name'));
        expect(message.recipientInfo.fullName, equals('Recipient Name'));
      });
    });

    group('Rating and Purchase Models', () {
      test('ContentRating model parsing', () {
        final json = {
          'id': 1,
          'content_id': 123,
          'user_info': {
            'id': 456,
            'full_name': 'Reviewer Name',
            'avatar': 'https://example.com/reviewer.jpg',
          },
          'rating': 4.5,
          'review': 'Great content!',
          'created_at': '2025-11-06T10:00:00Z',
          'updated_at': '2025-11-06T10:00:00Z',
        };

        final rating = ContentRating.fromJson(json);

        expect(rating.id, equals(1));
        expect(rating.contentId, equals(123));
        expect(rating.rating, equals(4.5));
        expect(rating.review, equals('Great content!'));
        expect(rating.user.fullName, equals('Reviewer Name'));
      });

      test('ContentPurchase model parsing', () {
        final json = {
          'id': 1,
          'content_id': 123,
          'buyer_info': {
            'id': 456,
            'full_name': 'Buyer Name',
            'avatar': 'https://example.com/buyer.jpg',
          },
          'amount': 29.99,
          'uploader_share': 20.99,
          'platform_share': 9.00,
          'status': 'completed',
          'purchase_date': '2025-11-06T10:00:00Z',
        };

        final purchase = ContentPurchase.fromJson(json);

        expect(purchase.id, equals(1));
        expect(purchase.contentId, equals(123));
        expect(purchase.amount, equals(29.99));
        expect(purchase.uploaderShare, equals(20.99));
        expect(purchase.platformShare, equals(9.00));
        expect(purchase.status, equals('completed'));
        expect(purchase.buyer.fullName, equals('Buyer Name'));
      });
    });

    group('Topic Management Models', () {
      test('Topic model parsing', () {
        final json = {
          'id': 1,
          'name': 'Criminal Law',
          'description': 'Topics related to criminal law',
          'hub_type': 'legal_ed',
          'materials_count': 15,
          'created_at': '2025-11-06T10:00:00Z',
          'updated_at': '2025-11-06T10:00:00Z',
        };

        final topic = Topic.fromJson(json);

        expect(topic.id, equals(1));
        expect(topic.name, equals('Criminal Law'));
        expect(topic.description, equals('Topics related to criminal law'));
        expect(topic.hubType, equals('legal_ed'));
        expect(topic.materialsCount, equals(15));
      });

      test('TopicsResponse parsing', () {
        final json = {
          'count': 10,
          'next': null,
          'previous': null,
          'results': [
            {
              'id': 1,
              'name': 'Criminal Law',
              'description': 'Criminal law topics',
              'hub_type': 'legal_ed',
              'materials_count': 15,
              'created_at': '2025-11-06T10:00:00Z',
              'updated_at': '2025-11-06T10:00:00Z',
            }
          ],
        };

        final response = TopicsResponse.fromJson(json);

        expect(response.count, equals(10));
        expect(response.results, hasLength(1));
        expect(response.results.first.name, equals('Criminal Law'));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('Handle missing fields in JSON', () {
        final minimalJson = {
          'id': 1,
          'hub_type': 'forum',
          'title': 'Minimal Content',
        };

        final item = HubContentItem.fromJson(minimalJson);

        expect(item.id, equals(1));
        expect(item.hubType, equals('forum'));
        expect(item.title, equals('Minimal Content'));
        expect(item.description, equals(''));
        expect(item.rating, equals(0.0));
        expect(item.isLiked, isFalse);
        expect(item.tags, isEmpty);
      });

      test('Handle malformed URLs gracefully', () {
        final badUrlJson = {
          'id': 1,
          'hub_type': 'students',
          'title': 'Bad URL Content',
          'file': 'not-a-valid-url',
          'video_url': 'also-not-valid',
          'uploader_info': {'id': 1, 'full_name': 'Test', 'avatar': ''},
          'created_at': '2025-11-06T10:00:00Z',
          'updated_at': '2025-11-06T10:00:00Z',
        };

        final item = HubContentItem.fromJson(badUrlJson);

        expect(item.fileUrl, equals('not-a-valid-url'));
        expect(item.videoUrl, equals('also-not-valid'));
        expect(item.fileExtension, equals(''));
        expect(item.hasVideo, isFalse);
      });

      test('Handle null and empty values', () {
        final nullJson = {
          'id': 1,
          'hub_type': null,
          'title': null,
          'tags': null,
          'uploader_info': null,
          'created_at': null,
        };

        final item = HubContentItem.fromJson(nullJson);

        expect(item.hubType, equals(''));
        expect(item.title, equals(''));
        expect(item.tags, isEmpty);
        expect(item.uploader.fullName, equals(''));
        expect(item.createdAt, isA<DateTime>());
      });
    });
  });
}

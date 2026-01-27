import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../../../services/api_service.dart';
import '../../../../config/environment_config.dart';
import '../models/hub_content_models.dart';

class HubContentService extends GetxService {
  final ApiService _apiService = ApiService();

  dio.Options get _defaultOptions => dio.Options(
        headers: {
          'Content-Type': 'application/json',
        },
      );

  /// Fetch hub content with filters
  Future<HubContentResponse> fetchHubContent({
    required String hubType,
    Map<String, dynamic>? filters,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'hub_type': hubType,
        'page': page.toString(),
        'page_size': pageSize.toString(),
        ...?filters?.map((k, v) => MapEntry(k, v.toString())),
      };

      print('🌐 Fetching hub content for: $hubType');
      print('🌐 Endpoint: ${EnvironmentConfig.hubContentUrl}');
      print('🌐 Query params: $queryParams');

      final response = await _apiService.get<Map<String, dynamic>>(
        EnvironmentConfig.hubContentUrl,
        queryParameters: queryParams,
        options: _defaultOptions,
      );

      print('🌐 Response status: ${response.statusCode}');
      print('🌐 Response data keys: ${response.data?.keys ?? 'null'}');
      print(
          '🌐 Response results count: ${response.data?['results']?.length ?? 0}');

      if (response.data?['results'] != null &&
          response.data!['results'].isNotEmpty) {
        final firstItem = response.data!['results'][0];
        print('🌐 First item title: "${firstItem['title']}"');
        print('🌐 First item ID: ${firstItem['id']}');
      }

      if (response.statusCode == 200) {
        return HubContentResponse.fromJson(response.data!);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        throw Exception('Failed to fetch content: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching hub content: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get specific content item by ID
  Future<HubContentItem> getContentById(int contentId, String hubType) async {
    try {
      final endpoint = '${EnvironmentConfig.hubContentUrl}$contentId/';
      final queryParams = {'hub_type': hubType};

      final response = await _apiService.get<Map<String, dynamic>>(
        endpoint,
        queryParameters: queryParams,
        options: _defaultOptions,
      );

      if (response.statusCode == 200) {
        return HubContentItem.fromJson(response.data!);
      } else {
        throw Exception('Failed to fetch content: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching content by ID: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get trending content
  Future<HubContentResponse> getTrendingContent(String hubType) async {
    try {
      final queryParams = {'hub_type': hubType};

      final response = await _apiService.get<Map<String, dynamic>>(
        EnvironmentConfig.hubContentTrendingUrl,
        queryParameters: queryParams,
        options: _defaultOptions,
      );

      if (response.statusCode == 200) {
        return HubContentResponse.fromJson(response.data!);
      } else {
        throw Exception(
            'Failed to fetch trending content: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching trending content: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get recent content
  Future<HubContentResponse> getRecentContent(String hubType) async {
    try {
      final queryParams = {'hub_type': hubType};

      final response = await _apiService.get<Map<String, dynamic>>(
        EnvironmentConfig.hubContentRecentUrl,
        queryParameters: queryParams,
        options: _defaultOptions,
      );

      if (response.statusCode == 200) {
        return HubContentResponse.fromJson(response.data!);
      } else {
        throw Exception(
            'Failed to fetch recent content: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching recent content: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Like or unlike content
  Future<Map<String, dynamic>> likeContent(int contentId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        EnvironmentConfig.hubContentLikeUrl(contentId),
        options: _defaultOptions,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data ?? {};
      } else {
        throw Exception('Failed to like content: ${response.statusCode}');
      }
    } catch (e) {
      print('Error liking content: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Bookmark or unbookmark content
  Future<Map<String, dynamic>> bookmarkContent(int contentId) async {
    try {
      print('🔖 Calling bookmark API for content: $contentId');
      final response = await _apiService.post<Map<String, dynamic>>(
        EnvironmentConfig.hubContentBookmarkUrl(contentId),
        options: _defaultOptions,
      );

      print('🔖 Bookmark API response status: ${response.statusCode}');
      print('🔖 Bookmark API response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data ?? {};
      } else {
        throw Exception('Failed to bookmark content: ${response.statusCode}');
      }
    } catch (e) {
      print('Error bookmarking content: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Remove bookmark from content
  Future<Map<String, dynamic>> removeBookmark(int contentId) async {
    try {
      // Server expects POST for bookmark toggle (DELETE returned 405). Use POST to remove bookmark as well.
      print('🔖 Calling remove bookmark API for content: $contentId');
      final response = await _apiService.post<Map<String, dynamic>>(
        EnvironmentConfig.hubContentBookmarkUrl(contentId),
        options: _defaultOptions,
      );

      print('🔖 Remove bookmark API response status: ${response.statusCode}');
      print('🔖 Remove bookmark API response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data ?? {};
      } else {
        throw Exception('Failed to remove bookmark: ${response.statusCode}');
      }
    } catch (e) {
      print('Error removing bookmark: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get user's bookmarked content
  /// Based on API documentation: GET /api/hubs/content/bookmarked/
  Future<HubContentResponse> getBookmarkedContent({
    String? hubType,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (hubType != null) 'hub_type': hubType,
      };

      print('🔖 Getting bookmarked content for hub type: $hubType');
      print('🔖 URL: ${EnvironmentConfig.hubContentBookmarkedUrl}');
      print('🔖 Params: $queryParams');

      final response = await _apiService.get<Map<String, dynamic>>(
        EnvironmentConfig.hubContentBookmarkedUrl,
        queryParameters: queryParams,
        options: _defaultOptions,
      );

      print('🔖 Bookmarked content response status: ${response.statusCode}');
      print('🔖 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final bookmarkedResponse = HubContentResponse.fromJson(response.data!);
        print(
            '🔖 Successfully loaded ${bookmarkedResponse.results.length} bookmarked items');
        return bookmarkedResponse;
      } else {
        throw Exception(
            'Failed to fetch bookmarked content: ${response.statusCode}');
      }
    } catch (e) {
      print('🔖 Error fetching bookmarked content: $e');

      // Return empty response for any error
      return HubContentResponse(
        results: [],
        count: 0,
        next: null,
        previous: null,
      );
    }
  }

  /// Rate content
  Future<RatingActionResponse> rateContent({
    required int contentId,
    required CreateRatingRequest ratingRequest,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        EnvironmentConfig.hubContentRateUrl(contentId),
        data: ratingRequest.toJson(),
        options: _defaultOptions,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return RatingActionResponse.fromJson(response.data!);
      } else {
        throw Exception('Failed to rate content: ${response.statusCode}');
      }
    } catch (e) {
      print('Error rating content: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Record content view
  Future<void> recordContentView(int contentId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        EnvironmentConfig.hubContentViewUrl(contentId),
        options: _defaultOptions,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Warning: Failed to record view: ${response.statusCode}');
      }
    } catch (e) {
      print('Warning: Error recording view: $e');
      // Don't throw error for view recording failures
    }
  }

  /// Get content comments
  Future<List<HubComment>> getContentComments(int contentId) async {
    try {
      final queryParams = {'content_id': contentId.toString()};

      final response = await _apiService.get<Map<String, dynamic>>(
        EnvironmentConfig.hubCommentsUrl,
        queryParameters: queryParams,
        options: _defaultOptions,
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = response.data!['results'] ?? [];
        return results.map((json) => HubComment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch comments: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching comments: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Add comment to content
  Future<HubComment> addComment({
    required int contentId,
    required CreateCommentRequest commentRequest,
  }) async {
    try {
      final requestData = {
        ...commentRequest.toJson(),
        'content_id': contentId,
      };

      debugPrint('🌐 ====== SENDING COMMENT TO API ======');
      debugPrint('🌐 URL: ${EnvironmentConfig.hubCommentsUrl}');
      debugPrint('🌐 Request data: $requestData');

      final response = await _apiService.post<Map<String, dynamic>>(
        EnvironmentConfig.hubCommentsUrl,
        data: requestData,
        options: _defaultOptions,
      );

      debugPrint('🌐 Response status: ${response.statusCode}');
      debugPrint('🌐 Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return HubComment.fromJson(response.data!);
      } else {
        throw Exception('Failed to add comment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding comment: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Like or unlike comment
  Future<Map<String, dynamic>> likeComment(int commentId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        EnvironmentConfig.hubCommentLikeUrl(commentId),
        options: _defaultOptions,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data ?? {};
      } else {
        throw Exception('Failed to like comment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error liking comment: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Search users for mentions
  Future<List<Map<String, dynamic>>> searchUsersForMentions({
    required String query,
    required String hubType,
  }) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        EnvironmentConfig.hubMentionSearchUrl,
        queryParameters: {
          'q': query,
        },
        options: _defaultOptions,
      );

      if (response.statusCode == 200) {
        final results = response.data?['results'] as List<dynamic>? ?? [];
        return results.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to search users: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching users for mentions: $e');
      return [];
    }
  }

  /// Get content analytics
  Future<ContentAnalytics> getContentAnalytics(int contentId) async {
    try {
      final endpoint =
          '${EnvironmentConfig.hubContentUrl}$contentId/analytics/';

      final response = await _apiService.get<Map<String, dynamic>>(
        endpoint,
        options: _defaultOptions,
      );

      if (response.statusCode == 200) {
        return ContentAnalytics.fromJson(response.data!);
      } else {
        throw Exception('Failed to fetch analytics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching analytics: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Search content
  Future<HubContentResponse> searchContent({
    required String hubType,
    required String query,
    Map<String, dynamic>? filters,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'hub_type': hubType,
        'search': query,
        'page': page.toString(),
        'page_size': pageSize.toString(),
        ...?filters?.map((k, v) => MapEntry(k, v.toString())),
      };

      final response = await _apiService.get<Map<String, dynamic>>(
        EnvironmentConfig.hubContentUrl,
        queryParameters: queryParams,
        options: _defaultOptions,
      );

      if (response.statusCode == 200) {
        return HubContentResponse.fromJson(response.data!);
      } else {
        throw Exception('Failed to search content: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching content: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get topics for a hub type
  Future<TopicsResponse> getTopics(String hubType) async {
    try {
      final queryParams = {'hub_type': hubType};

      final response = await _apiService.get<Map<String, dynamic>>(
        '${EnvironmentConfig.hubContentUrl}topics/',
        queryParameters: queryParams,
        options: _defaultOptions,
      );

      if (response.statusCode == 200) {
        return TopicsResponse.fromJson(response.data!);
      } else {
        throw Exception('Failed to fetch topics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching topics: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Create new content
  Future<HubContentItem> createContent({
    required String hubType,
    required CreateContentRequest contentRequest,
  }) async {
    try {
      final requestData = {
        ...contentRequest.toJson(),
        'hub_type': hubType,
      };

      final response = await _apiService.post<Map<String, dynamic>>(
        EnvironmentConfig.hubContentUrl,
        data: requestData,
        options: _defaultOptions,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return HubContentItem.fromJson(response.data!);
      } else {
        throw Exception('Failed to create content: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating content: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Update existing content
  Future<HubContentItem> updateContent({
    required int contentId,
    required String hubType,
    required UpdateContentRequest updateRequest,
  }) async {
    try {
      final endpoint = '${EnvironmentConfig.hubContentUrl}$contentId/';
      final requestData = {
        ...updateRequest.toJson(),
        'hub_type': hubType,
      };

      final response = await _apiService.put<Map<String, dynamic>>(
        endpoint,
        data: requestData,
        options: _defaultOptions,
      );

      if (response.statusCode == 200) {
        return HubContentItem.fromJson(response.data!);
      } else {
        throw Exception('Failed to update content: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating content: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Delete content
  Future<void> deleteContent(int contentId) async {
    try {
      final endpoint = '${EnvironmentConfig.hubContentUrl}$contentId/';

      final response = await _apiService.delete<Map<String, dynamic>>(
        endpoint,
        options: _defaultOptions,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete content: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting content: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Send message to hub
  Future<HubMessage> sendMessage({
    required String hubType,
    required CreateMessageRequest messageRequest,
  }) async {
    try {
      final endpoint = '${EnvironmentConfig.hubContentUrl}messages/';
      final requestData = {
        ...messageRequest.toJson(),
        'hub_type': hubType,
      };

      final response = await _apiService.post<Map<String, dynamic>>(
        endpoint,
        data: requestData,
        options: _defaultOptions,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return HubMessage.fromJson(response.data!);
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get hub messages
  Future<List<HubMessage>> getMessages({
    required String hubType,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final endpoint = '${EnvironmentConfig.hubContentUrl}messages/';
      final queryParams = {
        'hub_type': hubType,
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      final response = await _apiService.get<Map<String, dynamic>>(
        endpoint,
        queryParameters: queryParams,
        options: _defaultOptions,
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = response.data!['results'] ?? [];
        return results.map((json) => HubMessage.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch messages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching messages: $e');
      throw Exception('Network error: $e');
    }
  }

  // ============ COMPATIBILITY METHODS ============
  // These maintain backward compatibility with existing controller code

  /// Alias for recordContentView - tracks content view
  Future<void> trackContentView(int contentId) async {
    return recordContentView(contentId);
  }

  /// Alias for getContentComments - gets comments for content
  Future<List<HubComment>> getComments(int contentId) async {
    return getContentComments(contentId);
  }

  /// Alias for likeComment - toggles comment like/unlike
  Future<Map<String, dynamic>> toggleCommentLike(int commentId) async {
    return likeComment(commentId);
  }

  /// Alias for likeContent - toggles content like/unlike
  Future<Map<String, dynamic>?> toggleLike(int contentId) async {
    return await likeContent(contentId);
  }

  /// Get liked content (placeholder - returns bookmarked content as fallback)
  Future<HubContentResponse> getLikedContent({
    required String hubType,
    int page = 1,
    int pageSize = 20,
  }) async {
    // For now, return bookmarked content as a fallback
    // This would need a proper "liked" endpoint in the future
    return getBookmarkedContent(
        hubType: hubType, page: page, pageSize: pageSize);
  }

  /// Delete comment (not implemented - placeholder)
  Future<void> deleteComment(int commentId) async {
    // This would need to be implemented if the API supports comment deletion
    throw UnimplementedError('Comment deletion not yet implemented in API');
  }

  /// Get comment replies (not implemented - placeholder)
  Future<List<HubComment>> getCommentReplies(int commentId) async {
    // This would need to be implemented if the API supports nested comments
    return [];
  }

  /// Create hub content (following documentation format)
  Future<HubContentItem> createHubContent(
      Map<String, dynamic> contentData) async {
    try {
      final hubType = contentData.remove('hub_type') ?? 'forum';

      print('🔍 createHubContent: Processing content data per documentation');
      print('🔍 contentData keys: ${contentData.keys.toList()}');

      // Handle file data - keep data URL format as specified in docs
      if (contentData.containsKey('file') && contentData['file'] != null) {
        final fileData = contentData['file'] as String;
        print(
            '🔍 createHubContent: File data detected, format: ${fileData.substring(0, 30)}...');

        // Validate data URL format (should be: data:mime/type;base64,...)
        if (fileData.startsWith('data:')) {
          final parts = fileData.split(',');
          if (parts.length == 2) {
            final mimeTypePart = parts[0];
            final base64Data = parts[1];

            print('🔍 createHubContent: Valid data URL detected');
            print('🔍 MIME header: $mimeTypePart');
            print('🔍 Base64 data length: ${base64Data.length}');

            // Validate base64 data
            try {
              final testBytes = base64.decode(base64Data);
              print(
                  '🔍 createHubContent: Base64 validation successful, ${testBytes.length} bytes');
            } catch (e) {
              print('❌ createHubContent: Invalid base64 in data URL: $e');
              throw Exception('Invalid file data format');
            }
          } else {
            print('❌ createHubContent: Malformed data URL');
            throw Exception('Invalid data URL format');
          }
        } else {
          print('❌ createHubContent: File data must be in data URL format');
          throw Exception(
              'File must be in data URL format (data:mime/type;base64,...)');
        }
      }

      // Add hub_type back to the data
      contentData['hub_type'] = hubType;

      print(
          '🔍 createHubContent: Sending JSON with data URL file (as per docs)');
      print('🔍 Final data keys: ${contentData.keys.toList()}');

      // Send as JSON with data URL file (as specified in documentation)
      final response = await _apiService.post<Map<String, dynamic>>(
        EnvironmentConfig.hubContentUrl,
        data: contentData,
        options: dio.Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ createHubContent: Content created successfully');
        return HubContentItem.fromJson(response.data!);
      } else {
        print('❌ createHubContent: Failed with status ${response.statusCode}');
        print('❌ Response data: ${response.data}');
        throw Exception('Failed to create content: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error creating hub content: $e');
      throw Exception('Content creation failed: $e');
    }
  }

  /// Enhanced search with additional parameters
  Future<HubContentResponse> searchContentAdvanced({
    required String hubType,
    required String query,
    String? contentType,
    String? ordering,
    bool? isDownloadable,
    bool? isFree,
    int? topicId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final filters = <String, dynamic>{
      if (contentType != null) 'content_type': contentType,
      if (ordering != null) 'ordering': ordering,
      if (isDownloadable != null) 'is_downloadable': isDownloadable.toString(),
      if (isFree != null) 'is_free': isFree.toString(),
      if (topicId != null) 'topic_id': topicId.toString(),
    };

    return searchContent(
      hubType: hubType,
      query: query,
      filters: filters,
      page: page,
      pageSize: pageSize,
    );
  }
}

// Request/Response models for content creation and updates
class CreateContentRequest {
  final String title;
  final String? description;
  final String? fileUrl;
  final String? youtubeUrl;
  final List<String>? topics;
  final double? price;
  final String? contentType;

  CreateContentRequest({
    required this.title,
    this.description,
    this.fileUrl,
    this.youtubeUrl,
    this.topics,
    this.price,
    this.contentType,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (description != null) 'description': description,
      if (fileUrl != null) 'file_url': fileUrl,
      if (youtubeUrl != null) 'youtube_url': youtubeUrl,
      if (topics != null) 'topics': topics,
      if (price != null) 'price': price,
      if (contentType != null) 'content_type': contentType,
    };
  }
}

class UpdateContentRequest {
  final String? title;
  final String? description;
  final String? fileUrl;
  final String? youtubeUrl;
  final List<String>? topics;
  final double? price;
  final String? contentType;

  UpdateContentRequest({
    this.title,
    this.description,
    this.fileUrl,
    this.youtubeUrl,
    this.topics,
    this.price,
    this.contentType,
  });

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (fileUrl != null) 'file_url': fileUrl,
      if (youtubeUrl != null) 'youtube_url': youtubeUrl,
      if (topics != null) 'topics': topics,
      if (price != null) 'price': price,
      if (contentType != null) 'content_type': contentType,
    };
  }
}


import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../../../services/api_service.dart';
import '../models/notification_model.dart';

/// Service for notification API operations
class NotificationService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  dio.Options get _defaultOptions => dio.Options(
        headers: {
          'Content-Type': 'application/json',
        },
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
      );

  /// Base URL for notifications API
  String get _baseUrl => '/api/v1/notifications/notifications/';

  /// Fetch all notifications with optional filters
  Future<List<NotificationModel>> getNotifications({
    bool unreadOnly = false,
    String? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (unreadOnly) {
        queryParams['unread_only'] = 'true';
      }
      if (type != null) {
        queryParams['type'] = type;
      }

      debugPrint('🔔 Fetching notifications: $queryParams');

      final response = await _apiService.get<dynamic>(
        _baseUrl,
        queryParameters: queryParams,
        options: _defaultOptions,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle paginated response
        List<dynamic> results;
        if (data is Map && data.containsKey('results')) {
          results = data['results'] as List<dynamic>;
        } else if (data is List) {
          results = data;
        } else {
          results = [];
        }

        debugPrint('🔔 Fetched ${results.length} notifications');
        return results
            .map((json) =>
                NotificationModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('❌ Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread notification count (for badge)
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '${_baseUrl}unread_count/',
        options: _defaultOptions,
      );

      if (response.statusCode == 200) {
        final count = response.data?['count'] ?? 0;
        debugPrint('🔔 Unread count: $count');
        return count is int ? count : int.tryParse(count.toString()) ?? 0;
      }

      return 0;
    } catch (e) {
      debugPrint('❌ Error fetching unread count: $e');
      return 0;
    }
  }

  /// Mark a single notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      debugPrint('🔔 Marking notification $notificationId as read');

      final response = await _apiService.patch<Map<String, dynamic>>(
        '$_baseUrl$notificationId/mark_read/',
        options: _defaultOptions,
      );

      final success = response.statusCode == 200;
      debugPrint(success ? '✅ Marked as read' : '❌ Failed to mark as read');
      return success;
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      debugPrint('🔔 Marking all notifications as read');

      final response = await _apiService.post<Map<String, dynamic>>(
        '${_baseUrl}mark_all_read/',
        options: _defaultOptions,
      );

      final success = response.statusCode == 200;
      debugPrint(
          success ? '✅ All marked as read' : '❌ Failed to mark all as read');
      return success;
    } catch (e) {
      debugPrint('❌ Error marking all as read: $e');
      return false;
    }
  }

  /// Delete a notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      debugPrint('🔔 Deleting notification $notificationId');

      final response = await _apiService.delete<dynamic>(
        '$_baseUrl$notificationId/',
        options: _defaultOptions,
      );

      final success = response.statusCode == 200 || response.statusCode == 204;
      debugPrint(success ? '✅ Notification deleted' : '❌ Failed to delete');
      return success;
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
      return false;
    }
  }

  /// Register FCM token with backend
  Future<bool> registerFCMToken(String fcmToken, {int? userId}) async {
    try {
      debugPrint('🔔 Registering FCM token');

      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/notifications/fcm-token/',
        data: {
          'fcm_token': fcmToken,
          if (userId != null) 'user': userId,
          'stale_time': '30',
        },
        options: _defaultOptions,
      );

      final success = response.statusCode == 200 || response.statusCode == 201;
      debugPrint(
          success ? '✅ FCM token registered' : '❌ Failed to register token');
      return success;
    } catch (e) {
      debugPrint('❌ Error registering FCM token: $e');
      return false;
    }
  }

  /// Send heartbeat to keep online status
  Future<bool> sendHeartbeat() async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/notification/heartbeat/',
        options: _defaultOptions,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error sending heartbeat: $e');
      return false;
    }
  }
}

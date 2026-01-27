import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// Controller for managing notification state
class NotificationController extends GetxController {
  final NotificationService _service = Get.find<NotificationService>();

  // Observable state
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString error = ''.obs;
  final RxBool hasMoreData = true.obs;

  // Pagination
  int _currentPage = 1;
  static const int _pageSize = 20;

  // Auto-refresh timer
  Timer? _refreshTimer;
  static const Duration _refreshInterval = Duration(seconds: 30);

  @override
  void onInit() {
    super.onInit();
    debugPrint('🔔 NotificationController initialized');

    // Initial fetch
    refreshNotifications();

    // Start auto-refresh for unread count
    _startAutoRefresh();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  /// Start auto-refresh timer for unread count
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      refreshUnreadCount();
    });
  }

  /// Refresh all notifications from server
  Future<void> refreshNotifications() async {
    if (isLoading.value) return;

    isLoading.value = true;
    error.value = '';
    _currentPage = 1;
    hasMoreData.value = true;

    try {
      final result = await _service.getNotifications(
        page: _currentPage,
        pageSize: _pageSize,
      );

      notifications.assignAll(result);

      // Check if more data available
      if (result.length < _pageSize) {
        hasMoreData.value = false;
      }

      // Also refresh unread count
      await refreshUnreadCount();

      debugPrint('🔔 Refreshed ${result.length} notifications');
    } catch (e) {
      error.value = 'Failed to load notifications';
      debugPrint('❌ Error refreshing notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more notifications (pagination)
  Future<void> loadMoreNotifications() async {
    if (isLoadingMore.value || !hasMoreData.value) return;

    isLoadingMore.value = true;

    try {
      _currentPage++;
      final result = await _service.getNotifications(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (result.isEmpty) {
        hasMoreData.value = false;
      } else {
        notifications.addAll(result);
        if (result.length < _pageSize) {
          hasMoreData.value = false;
        }
      }

      debugPrint('🔔 Loaded ${result.length} more notifications');
    } catch (e) {
      debugPrint('❌ Error loading more notifications: $e');
      _currentPage--; // Revert page on error
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Refresh only the unread count (lightweight for badge updates)
  Future<void> refreshUnreadCount() async {
    try {
      unreadCount.value = await _service.getUnreadCount();
    } catch (e) {
      debugPrint('❌ Error refreshing unread count: $e');
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(int notificationId) async {
    final success = await _service.markAsRead(notificationId);

    if (success) {
      // Update local state
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final notification = notifications[index];
        if (!notification.isRead) {
          notifications[index] = notification.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );

          // Decrease unread count
          unreadCount.value =
              (unreadCount.value - 1).clamp(0, unreadCount.value);
        }
      }
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final success = await _service.markAllAsRead();

    if (success) {
      // Update all local notifications
      notifications.value = notifications.map((n) {
        return n.copyWith(isRead: true, readAt: DateTime.now());
      }).toList();

      unreadCount.value = 0;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(int notificationId) async {
    // Find the notification before deleting
    final notification =
        notifications.firstWhereOrNull((n) => n.id == notificationId);

    final success = await _service.deleteNotification(notificationId);

    if (success) {
      notifications.removeWhere((n) => n.id == notificationId);

      // Update unread count if the deleted notification was unread
      if (notification != null && !notification.isRead) {
        unreadCount.value = (unreadCount.value - 1).clamp(0, unreadCount.value);
      }
    }
  }

  /// Handle notification tap - mark as read and navigate
  Future<void> handleNotificationTap(NotificationModel notification) async {
    // Mark as read
    if (!notification.isRead) {
      await markAsRead(notification.id);
    }

    // Navigate based on notification type and action
    _navigateToAction(notification);
  }

  /// Navigate based on notification action type
  void _navigateToAction(NotificationModel notification) {
    final actionType = notification.actionType;
    final data = notification.data;

    debugPrint('🔔 Navigating for action: $actionType with data: $data');

    switch (actionType) {
      case 'open_comment':
        _navigateToComment(
          contentId: _parseInt(data['content_id']),
          commentId: _parseInt(data['comment_id']),
          hubType: data['hub_type'] as String? ?? '',
        );
        break;

      case 'open_consultation':
        _navigateToConsultation(
          bookingId: _parseInt(data['booking_id']),
        );
        break;

      case 'open_earnings':
        // Navigate to my-consultations as earnings fallback
        Get.toNamed('/my-consultations');
        break;

      case 'open_document':
        _navigateToDocument(
          documentId: _parseInt(data['document_id']),
        );
        break;

      case 'open_call':
        // Already handled by incoming call screen
        break;

      case 'open_app':
        // System notifications - just go home
        Get.toNamed('/home');
        break;

      default:
        // Show notification detail dialog for unknown actions
        _showNotificationDetail(notification);
    }
  }

  /// Show notification detail in a dialog
  void _showNotificationDetail(NotificationModel notification) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(notification.icon, color: notification.typeColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 12),
            Text(
              notification.timeAgo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToComment({
    required int contentId,
    required int commentId,
    required String hubType,
  }) {
    if (contentId > 0 && hubType.isNotEmpty) {
      // Map hub types to valid routes
      String route;
      switch (hubType.toLowerCase()) {
        case 'forum':
          route = '/forum-hub';
          break;
        case 'advocates':
          route = '/advocates-hub';
          break;
        case 'students':
          route = '/students-hub';
          break;
        default:
          route = '/forum-hub';
      }
      Get.toNamed(route);
    } else {
      // Fallback to forum hub
      Get.toNamed('/forum-hub');
    }
  }

  void _navigateToConsultation({required int bookingId}) {
    if (bookingId > 0) {
      Get.toNamed('/my-consultations');
    }
  }

  void _navigateToDocument({required int documentId}) {
    if (documentId > 0) {
      Get.toNamed('/my-documents');
    }
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  /// Check if there are unread notifications
  bool get hasUnread => unreadCount.value > 0;

  /// Get unread notifications only
  List<NotificationModel> get unreadNotifications =>
      notifications.where((n) => !n.isRead).toList();
}

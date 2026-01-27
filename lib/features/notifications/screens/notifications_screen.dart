import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../widgets/notification_card.dart';

/// Screen to display all notifications
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late NotificationController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Get or create controller
    if (Get.isRegistered<NotificationController>()) {
      controller = Get.find<NotificationController>();
    } else {
      controller = Get.put(NotificationController());
    }

    // Refresh on screen open
    controller.refreshNotifications();

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      controller.loadMoreNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Mark all as read button
          Obx(() {
            if (controller.unreadCount.value == 0) {
              return const SizedBox.shrink();
            }
            return TextButton.icon(
              onPressed: () => controller.markAllAsRead(),
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Read all'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            );
          }),
        ],
      ),
      body: Obx(() => _buildBody(theme)),
    );
  }

  Widget _buildBody(ThemeData theme) {
    // Loading state (initial load)
    if (controller.isLoading.value && controller.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state
    if (controller.error.value.isNotEmpty && controller.notifications.isEmpty) {
      return _buildErrorState(theme);
    }

    // Empty state
    if (controller.notifications.isEmpty) {
      return _buildEmptyState(theme);
    }

    // Notifications list
    return RefreshIndicator(
      onRefresh: () => controller.refreshNotifications(),
      color: theme.colorScheme.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount:
            controller.notifications.length + 1, // +1 for loading indicator
        itemBuilder: (context, index) {
          // Loading more indicator
          if (index == controller.notifications.length) {
            return _buildLoadingMore();
          }

          final notification = controller.notifications[index];

          return NotificationCard(
            notification: notification,
            onTap: () => controller.handleNotificationTap(notification),
            onDismiss: () => controller.deleteNotification(notification.id),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No notifications yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You'll see your notifications here when\nsomeone interacts with you",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => controller.refreshNotifications(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              controller.error.value,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => controller.refreshNotifications(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMore() {
    return Obx(() {
      if (!controller.isLoadingMore.value) {
        if (!controller.hasMoreData.value &&
            controller.notifications.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No more notifications',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      }

      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    });
  }
}

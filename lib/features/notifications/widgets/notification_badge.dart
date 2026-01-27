import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../screens/notifications_screen.dart';

/// Notification badge widget for AppBar
/// Shows a bell icon with unread count badge
class NotificationBadge extends StatelessWidget {
  final Color? iconColor;
  final double iconSize;
  final bool showBadge;

  const NotificationBadge({
    super.key,
    this.iconColor,
    this.iconSize = 24,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Initialize controller if not already
    if (!Get.isRegistered<NotificationController>()) {
      Get.put(NotificationController());
    }

    return GetX<NotificationController>(
      builder: (controller) {
        final count = controller.unreadCount.value;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Notification Icon Button
            IconButton(
              icon: Icon(
                count > 0 ? Icons.notifications : Icons.notifications_outlined,
                color: iconColor ?? theme.colorScheme.onSurface,
                size: iconSize,
              ),
              onPressed: () {
                Get.to(() => const NotificationsScreen());
              },
              tooltip: 'Notifications',
            ),

            // Badge (only show if count > 0 and showBadge is true)
            if (showBadge && count > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Compact notification indicator for bottom navigation
class NotificationIndicator extends StatelessWidget {
  const NotificationIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NotificationController>()) {
      return const SizedBox.shrink();
    }

    return GetX<NotificationController>(
      builder: (controller) {
        final count = controller.unreadCount.value;

        if (count == 0) return const SizedBox.shrink();

        return Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

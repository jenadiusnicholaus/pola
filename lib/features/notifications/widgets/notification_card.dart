import 'package:flutter/material.dart';
import '../models/notification_model.dart';

/// Notification card widget for the notifications list
class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Different colors for read/unread
    final backgroundColor = notification.isRead
        ? (isDark ? theme.cardColor : Colors.white)
        : (isDark
            ? theme.colorScheme.primary.withOpacity(0.1)
            : Colors.blue.shade50);

    final borderColor = notification.isRead
        ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
        : (isDark
            ? theme.colorScheme.primary.withOpacity(0.3)
            : Colors.blue.shade200);

    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: notification.isRead
                ? null
                : [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Icon with colored background
                _buildIconContainer(theme),

                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + Unread Indicator
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Body
                      Text(
                        notification.body,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Time ago + Type badge
                      Row(
                        children: [
                          Text(
                            notification.timeAgo,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildTypeBadge(theme),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer(ThemeData theme) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: notification.typeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        notification.icon,
        color: notification.typeColor,
        size: 22,
      ),
    );
  }

  Widget _buildTypeBadge(ThemeData theme) {
    String label;
    switch (notification.type) {
      case NotificationType.mention:
        label = 'Mention';
        break;
      case NotificationType.reply:
        label = 'Reply';
        break;
      case NotificationType.consultationRequest:
        label = 'Booking';
        break;
      case NotificationType.consultationStatus:
        label = 'Update';
        break;
      case NotificationType.paymentReceived:
        label = 'Payment';
        break;
      case NotificationType.documentReady:
        label = 'Document';
        break;
      case NotificationType.incomingCall:
        label = 'Call';
        break;
      case NotificationType.callAccepted:
        label = 'Accepted';
        break;
      case NotificationType.callRejected:
        label = 'Rejected';
        break;
      case NotificationType.callEnded:
        label = 'Ended';
        break;
      case NotificationType.missedCall:
        label = 'Missed';
        break;
      case NotificationType.system:
        label = 'System';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: notification.typeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: notification.typeColor,
        ),
      ),
    );
  }
}

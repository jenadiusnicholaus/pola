import 'package:flutter/material.dart';

/// Notification types supported by the backend
enum NotificationType {
  mention,
  reply,
  consultationRequest,
  consultationStatus,
  paymentReceived,
  documentReady,
  incomingCall,
  callAccepted,
  callRejected,
  callEnded,
  missedCall,
  system,
}

/// Extension to convert string to NotificationType
extension NotificationTypeExtension on String {
  NotificationType toNotificationType() {
    switch (toLowerCase()) {
      case 'mention':
        return NotificationType.mention;
      case 'reply':
        return NotificationType.reply;
      case 'consultation_request':
        return NotificationType.consultationRequest;
      case 'consultation_status':
        return NotificationType.consultationStatus;
      case 'payment_received':
        return NotificationType.paymentReceived;
      case 'document_ready':
        return NotificationType.documentReady;
      case 'incoming_call':
        return NotificationType.incomingCall;
      case 'call_accepted':
        return NotificationType.callAccepted;
      case 'call_rejected':
        return NotificationType.callRejected;
      case 'call_ended':
        return NotificationType.callEnded;
      case 'missed_call':
        return NotificationType.missedCall;
      default:
        return NotificationType.system;
    }
  }
}

/// Notification model matching the backend API response
class NotificationModel {
  final int id;
  final int userId;
  final String notificationType;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? readAt;
  final bool fcmSent;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.notificationType,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    this.readAt,
    required this.fcmSent,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      userId: json['user'] ?? 0,
      notificationType: json['notification_type'] ?? 'system',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: json['data'] ?? {},
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      fcmSent: json['fcm_sent'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'notification_type': notificationType,
      'title': title,
      'body': body,
      'data': data,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'fcm_sent': fcmSent,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Get the notification type enum
  NotificationType get type => notificationType.toNotificationType();

  /// Get icon based on notification type
  IconData get icon {
    switch (type) {
      case NotificationType.mention:
        return Icons.alternate_email;
      case NotificationType.reply:
        return Icons.reply;
      case NotificationType.consultationRequest:
        return Icons.calendar_today;
      case NotificationType.consultationStatus:
        return Icons.update;
      case NotificationType.paymentReceived:
        return Icons.payments;
      case NotificationType.documentReady:
        return Icons.description;
      case NotificationType.incomingCall:
        return Icons.phone;
      case NotificationType.callAccepted:
        return Icons.call;
      case NotificationType.callRejected:
        return Icons.call_end;
      case NotificationType.callEnded:
        return Icons.phone_disabled;
      case NotificationType.missedCall:
        return Icons.phone_missed;
      case NotificationType.system:
        return Icons.notifications;
    }
  }

  /// Get color based on notification type
  Color get typeColor {
    switch (type) {
      case NotificationType.mention:
        return Colors.blue;
      case NotificationType.reply:
        return Colors.purple;
      case NotificationType.consultationRequest:
        return Colors.orange;
      case NotificationType.consultationStatus:
        return Colors.teal;
      case NotificationType.paymentReceived:
        return Colors.green;
      case NotificationType.documentReady:
        return Colors.indigo;
      case NotificationType.incomingCall:
        return Colors.green;
      case NotificationType.callAccepted:
        return Colors.green;
      case NotificationType.callRejected:
        return Colors.orange;
      case NotificationType.callEnded:
        return Colors.blueGrey;
      case NotificationType.missedCall:
        return Colors.red;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  /// Get action type from data
  String? get actionType => data['action_type'] as String?;

  /// Time ago string
  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Create a copy with updated isRead status
  NotificationModel copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      notificationType: notificationType,
      title: title,
      body: body,
      data: data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      fcmSent: fcmSent,
      createdAt: createdAt,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: $notificationType, title: $title, isRead: $isRead)';
  }
}

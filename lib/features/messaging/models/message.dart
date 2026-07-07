class Message {
  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final DateTime timestamp;
  final bool isSent;
  final bool isDelivered;
  final bool isRead;
  final String? avatarUrl;

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    this.isSent = false,
    this.isDelivered = false,
    this.isRead = false,
    this.avatarUrl,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Handle timestamp: API returns microseconds, convert to milliseconds
    int timestampMs;
    if (json['timestamp'] != null) {
      int raw;
      if (json['timestamp'] is int) {
        raw = json['timestamp'] as int;
      } else {
        raw = int.tryParse(json['timestamp'].toString()) ??
            DateTime.now().millisecondsSinceEpoch;
      }
      // If timestamp looks like microseconds (>= year 2100 in ms = 4102444800000)
      // divide by 1000 to convert to milliseconds
      timestampMs = raw > 4102444800000 ? raw ~/ 1000 : raw;
    } else {
      timestampMs = DateTime.now().millisecondsSinceEpoch;
    }

    return Message(
      id: json['id']?.toString() ??
          json['message_id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      // API uses 'body', fallback to 'message' / 'content' for XMPP stream events
      content: json['body']?.toString() ??
          json['message']?.toString() ??
          json['content']?.toString() ??
          '',
      senderId: json['from']?.toString() ?? json['sender_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? 'Unknown',
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
      isSent: json['is_sent'] == true,
      isDelivered: json['is_delivered'] == true,
      isRead: json['is_read'] == true,
      avatarUrl: json['avatar_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': content,
      'from': senderId,
      'sender_name': senderName,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'is_sent': isSent,
      'is_delivered': isDelivered,
      'is_read': isRead,
      'avatar_url': avatarUrl,
    };
  }
}

class Contact {
  final String id;
  final String name;
  final String nxid;
  final String? avatarUrl;
  final bool isOnline;
  final int unreadCount;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  Contact({
    required this.id,
    required this.name,
    required this.nxid,
    this.avatarUrl,
    this.isOnline = false,
    this.unreadCount = 0,
    this.lastMessage,
    this.lastMessageTime,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] ?? json['nxid'] ?? '',
      name: json['name'] ?? 'Unknown',
      nxid: json['nxid'] ?? '',
      avatarUrl: json['avatar_url'],
      isOnline: json['is_online'] ?? false,
      unreadCount: json['unread_count'] ?? 0,
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['last_message_time'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nxid': nxid,
      'avatar_url': avatarUrl,
      'is_online': isOnline,
      'unread_count': unreadCount,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.millisecondsSinceEpoch,
    };
  }
}

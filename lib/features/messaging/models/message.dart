import 'dart:convert';

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
  final String? roomId;
  final bool callEnded;

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
    this.roomId,
    this.callEnded = false,
  });

  Message copyWith({bool? callEnded, bool? isDelivered, bool? isRead}) {
    return Message(
      id: id,
      content: content,
      senderId: senderId,
      senderName: senderName,
      timestamp: timestamp,
      isSent: isSent,
      isDelivered: isDelivered ?? this.isDelivered,
      isRead: isRead ?? this.isRead,
      avatarUrl: avatarUrl,
      roomId: roomId,
      callEnded: callEnded ?? this.callEnded,
    );
  }

  /// Whether this message represents a call invitation (p2p/group call link)
  bool get isCallMessage =>
      content.contains('Incoming p2p call') ||
      content.contains('Incoming group call') ||
      content.contains('nx-group-call');

  /// Whether this represents a missed/ended call notification.
  /// True either when this message itself is a raw call_end event, or when
  /// a call invite has since been marked ended (merged into the same bubble).
  bool get isCallEndMessage =>
      callEnded ||
      content.contains('"type":"call_end"') ||
      content.contains('call_end');

  /// Whether this is a call type (call invite or call end) message
  bool get isCallType => isCallMessage || isCallEndMessage;

  /// Whether the call is a video call (fallback: p2p calls treated as voice unless specified)
  bool get isVideoCall => content.toLowerCase().contains('type=video');

  /// Clean, user-friendly display text for call messages
  String get displayText {
    if (callEnded) {
      return 'Call ended';
    }
    if (isCallMessage) {
      return isVideoCall ? 'Video call' : 'Voice call';
    }
    if (isCallEndMessage) {
      return 'Call ended';
    }
    return _extractHumanText(content);
  }

  /// Extract the call room id from either a call invite URL
  /// (.../nx-group-call/<roomId>?...) or a signaling JSON body's 'roomId' field.
  static String? extractRoomId(String body) {
    final urlMatch = RegExp(r'nx-group-call/([^?\s]+)').firstMatch(body);
    if (urlMatch != null) return urlMatch.group(1);

    if (body.trim().startsWith('{')) {
      try {
        final map = jsonDecode(body) as Map<String, dynamic>;
        final roomId = map['roomId']?.toString();
        if (roomId != null && roomId.isNotEmpty) return roomId;
      } catch (_) {
        // Not valid JSON
      }
    }
    return null;
  }

  /// Whether a raw body represents a call_end signaling event.
  static bool isCallEndBody(String body) {
    if (body.trim().startsWith('{')) {
      try {
        final map = jsonDecode(body) as Map<String, dynamic>;
        return map['type']?.toString() == 'call_end';
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  /// Extract plain text from a raw body that may be JSON-wrapped.
  /// Falls back to the original content if parsing fails.
  static String _extractHumanText(String raw) {
    if (raw.trim().startsWith('{')) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final type = map['type']?.toString();
        if (type == 'chat' || type == null) {
          final extracted = map['message']?.toString() ??
              map['body']?.toString() ??
              map['content']?.toString();
          if (extracted != null && extracted.isNotEmpty) return extracted;
        }
      } catch (_) {
        // Not valid JSON, show as-is
      }
    }
    return raw;
  }

  /// Parse an epoch timestamp that may be in seconds, milliseconds, or microseconds.
  static DateTime parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();

    int raw;
    if (value is int) {
      raw = value;
    } else {
      raw = int.tryParse(value.toString()) ??
          DateTime.now().millisecondsSinceEpoch;
    }

    // Distinguish common epoch units by magnitude.
    // - seconds: ~1.7e9 (won't exceed 1e12 for centuries)
    // - milliseconds: ~1.7e12
    // - microseconds: ~1.7e15
    late final int ms;
    if (raw > 1000000000000000) {
      // microseconds -> milliseconds
      ms = raw ~/ 1000;
    } else if (raw > 1000000000000) {
      // already milliseconds
      ms = raw;
    } else {
      // seconds -> milliseconds
      ms = raw * 1000;
    }

    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  factory Message.fromJson(Map<String, dynamic> json) {
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
      timestamp: parseTimestamp(json['timestamp']),
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
          ? Message.parseTimestamp(json['last_message_time'])
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

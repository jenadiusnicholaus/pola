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

  /// Whether this message represents a call invitation (p2p/group call link).
  ///
  /// A call_end payload can also carry the 'nx-group-call' room reference
  /// (echoing which call it is ending), so it must be excluded explicitly.
  /// Otherwise the end event is misclassified as a second, distinct call
  /// invite instead of the signal that merges into the original invite,
  /// producing duplicate "Voice call" / "Call ended" bubble pairs.
  bool get isCallMessage =>
      !Message.isCallEndBody(content) &&
      (content.contains('Incoming p2p call') ||
          content.contains('Incoming group call') ||
          content.contains('nx-group-call'));

  /// Whether this represents an ended call notification or call session.
  bool get isCallEndMessage => callEnded || Message.isCallEndBody(content);

  /// Whether this is a call type (call invite or call end) message
  bool get isCallType => isCallMessage || isCallEndMessage;

  /// Whether the call is a video call (fallback: p2p calls treated as voice unless specified)
  bool get isVideoCall => content.toLowerCase().contains('type=video');

  /// Clean, user-friendly display text for messages.
  /// All call events are displayed as "Call ended". The raw call
  /// type ("Voice call" / "Video call") is never shown as a log entry.
  String get displayText {
    if (isCallType) return 'Call ended';
    return Message.extractHumanText(content);
  }

  /// Extract the call room id from either a call invite URL
  /// (.../nx-group-call/<roomId>?...) or a signaling JSON body.
  ///
  /// The room identifier is not consistently named across the call invite
  /// and the call_end event, so every known variant is checked. Missing a
  /// variant means the invite and the end cannot be paired, and the call
  /// renders as two separate bubbles instead of one merged bubble.
  static String? extractRoomId(String body) {
    final urlMatch = RegExp(r'nx-group-call/([^?\s]+)').firstMatch(body);
    if (urlMatch != null) return urlMatch.group(1);

    if (body.trim().startsWith('{')) {
      try {
        final map = jsonDecode(body) as Map<String, dynamic>;
        for (final key in [
          'roomId',
          'room_id',
          'channelName',
          'channel_name',
          'room',
        ]) {
          final value = map[key]?.toString();
          if (value != null && value.isNotEmpty) return value;
        }
      } catch (_) {
        // Not valid JSON
      }
    }
    return null;
  }

  /// Whether a raw body represents a call_end signaling event.
  ///
  /// The event is not emitted in a single consistent shape, so known 'type'
  /// spellings are checked first and a plain substring match is used as a
  /// fallback for bodies that are not valid JSON.
  static bool isCallEndBody(String body) {
    if (body.trim().startsWith('{')) {
      try {
        final map = jsonDecode(body) as Map<String, dynamic>;
        final type = map['type']?.toString();
        return type == 'call_end' ||
            type == 'callEnd' ||
            type == 'call_ended' ||
            type == 'callEnded';
      } catch (_) {
        // Not valid JSON - fall through to the substring check.
      }
    }
    return body.contains('call_end') || body.contains('callEnded');
  }

  /// Extract plain text from a raw body that may be JSON-wrapped.
  /// Falls back to the original content if parsing fails.
  static String extractHumanText(String raw) {
    if (raw.trim().startsWith('{')) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final type = map['type']?.toString();
        if (type == 'chat' || type == null) {
          for (final field in [
            'text',
            'msg',
            'message',
            'body',
            'content',
            'data',
            'payload'
          ]) {
            final extracted = map[field]?.toString();
            if (extracted != null && extracted.isNotEmpty) return extracted;
          }
          // Fallback: return the first non-empty string value in the map
          // that isn't the type field itself.
          for (final entry in map.entries) {
            if (entry.key == 'type') continue;
            final val = entry.value?.toString();
            if (val != null && val.isNotEmpty && !val.startsWith('{')) {
              return val;
            }
          }
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

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nexacon_messaging/nexacon_messaging.dart';
import 'chat_room_screen.dart';
import '../services/nexacon_messaging_service.dart';
import '../models/message.dart';
import '../../../utils/phone_formatter.dart';

/// Professional Messages Inbox Screen
/// Modern messaging interface with professional design
class MessagesInboxScreen extends StatefulWidget {
  const MessagesInboxScreen({super.key});

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen>
    with SingleTickerProviderStateMixin {
  final NexaconMessagingService _messagingService =
      Get.find<NexaconMessagingService>();

  List<Map<String, dynamic>> _contacts = [];
  bool _isLoadingContacts = false;
  Map<String, Map<String, dynamic>> _lastMessages =
      {}; // Store last message per contact

  StreamSubscription<NxMessage>? _messageSub;
  Timer? _refreshDebounce;

  @override
  void initState() {
    super.initState();
    debugPrint('📨 MessagesInboxScreen: initState, calling _loadAllMessages');
    _loadAllMessages();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    _messageSub?.cancel();
    super.dispose();
  }

  void _subscribeToMessages() {
    _messageSub = _messagingService.messageStream.listen((_) {
      _refreshDebounce?.cancel();
      _refreshDebounce = Timer(const Duration(milliseconds: 500), () {
        if (mounted) _loadAllMessages();
      });
    });
  }

  bool _isDisplayableMessage(String body) {
    if (body.isEmpty) return false;

    // Human-readable call invite - show as a call preview
    if (body.contains('Incoming p2p call') ||
        body.contains('Incoming group call')) {
      return true;
    }

    if (body.trim().startsWith('{')) {
      try {
        final map = jsonDecode(body) as Map<String, dynamic>;
        final type = map['type']?.toString() ?? '';
        if (type == 'chat' || type.isEmpty) {
          return true;
        }
        if (Message.isCallEndBody(body)) return true;
        return false; // call_invitation, call_response, webrtc, etc.
      } catch (_) {
        // Not valid JSON
      }
    }

    return true;
  }

  Future<void> _loadAllMessages({bool retry = false}) async {
    setState(() => _isLoadingContacts = true);

    try {
      debugPrint('📨 _loadAllMessages: ensuring messaging connection');
      if (retry) {
        await _messagingService.forceReinitialize();
      } else if (!_messagingService.isConnected.value) {
        await _messagingService.initializeConnection();
      }

      // Fetch ALL messages to build contact list with last message
      debugPrint('📨 _loadAllMessages: fetching all messages from API');
      final allMessages = await _messagingService.getAllMessages(pageSize: 100);
      debugPrint(
        '📨 _loadAllMessages: received ${allMessages.length} messages',
      );

      // Build contacts list from messages and extract last message per contact
      final contactsMap = <String, Map<String, dynamic>>{};
      final lastMessagesMap = <String, Map<String, dynamic>>{};

      for (final msg in allMessages) {
        // Skip WebRTC / call signaling JSON (anything with a non-chat type)
        if (!_isDisplayableMessage(msg.body)) {
          continue;
        }

        // Determine peer (the other person in the conversation)
        // Use is_me from API: if I sent it, peer = to; if I received it, peer = from
        final peer = msg.isMe ? msg.to : msg.from;
        // Normalize phone to digits-only for consistent grouping.
        // This handles +255712..., 255712..., 0712... formats that
        // would otherwise create separate contact entries.
        final peerPhone = PhoneFormatter.normalize(peer);

        // Store last message for this peer
        if (!lastMessagesMap.containsKey(peerPhone)) {
          // Get clean, friendly message text
          String messageText = msg.body;

          // Try to unwrap JSON chat messages
          if (messageText.trim().startsWith('{')) {
            final extracted = Message.extractHumanText(messageText);
            if (extracted != messageText && extracted.isNotEmpty) {
              messageText = extracted;
            }
          }

          if (Message.isCallEndBody(msg.body) ||
              messageText.contains('Incoming p2p call') ||
              messageText.contains('Incoming group call')) {
            messageText = '📞 Call ended';
          } else {
            // Truncate long messages
            if (messageText.length > 50) {
              messageText = '${messageText.substring(0, 50)}...';
            }

            // If message still looks like JSON, show a friendly text instead
            if (messageText.trim().startsWith('{') ||
                messageText.trim().startsWith('[')) {
              messageText = 'Message';
            }
          }

          lastMessagesMap[peerPhone] = {
            'body': messageText,
            'timestamp': msg.timestamp,
            'isFromMe': msg.isMe,
          };
        }

        // Add peer to contacts if not already there.
        // Fall back to the phone number — 'Loading...' would stay forever
        // if the contact name lookup fails or has no match.
        if (!contactsMap.containsKey(peerPhone)) {
          contactsMap[peerPhone] = {
            'nxid': peer,
            'name': peerPhone.isNotEmpty ? peerPhone : peer,
          };
        }
      }

      debugPrint(
        '📨 _loadAllMessages: found ${contactsMap.length} unique contacts',
      );

      setState(() {
        _contacts = contactsMap.values.toList();
        _lastMessages = lastMessagesMap;
        _isLoadingContacts = false;
      });

      // Resolve phone numbers to user names via the user search API
      _resolveContactNames();
    } catch (e) {
      debugPrint('❌ Error loading messages: $e');
      setState(() => _isLoadingContacts = false);

      if (!retry &&
          (e.toString().contains('timeout') ||
              e.toString().contains('Authentication'))) {
        _loadAllMessages(retry: true);
      }
    }
  }

  /// Resolve contact display names by matching phone/JID against the
  /// NX contact list from [NexaconMessagingService.getContacts].
  Future<void> _resolveContactNames() async {
    try {
      final nxContacts = await _messagingService.getContacts();
      final nameMap = <String, String>{};
      final avatarMap = <String, String?>{};

      // Index contacts by normalized phone so we can match by any phone format.
      for (final c in nxContacts) {
        final nxid = _extractJid(c);
        final phone = _stripPhone(nxid);
        if (phone.isEmpty) continue;

        final name = _extractName(c) ?? phone;
        final avatar = _extractAvatar(c);

        nameMap[phone] = name;
        avatarMap[phone] = avatar;
      }

      var updated = false;
      for (final contact in _contacts) {
        final nxid = contact['nxid']?.toString() ?? '';
        final phone = _stripPhone(nxid);
        if (phone.isEmpty) continue;

        final name = nameMap[phone];
        final avatar = avatarMap[phone];

        if (name != null && name.isNotEmpty) {
          contact['name'] = name;
          if (avatar != null && avatar.isNotEmpty) {
            contact['avatar'] = avatar;
          }
          updated = true;
        }
      }

      if (updated) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('⚠️ Failed to resolve names from NX contacts: $e');
    }
  }

  /// Extract a bare JID/phone from a NX contact map.
  String _extractJid(Map<String, dynamic> contact) {
    return contact['nxid']?.toString() ??
        contact['username']?.toString() ??
        contact['jid']?.toString() ??
        contact['phone']?.toString() ??
        contact['phone_number']?.toString() ??
        contact['id']?.toString() ??
        '';
  }

  /// Strip a JID down to a normalized digit-only phone key.
  String _stripPhone(String nxid) {
    return PhoneFormatter.normalize(nxid);
  }

  /// Extract a display name from a NX contact map.
  String? _extractName(Map<String, dynamic> contact) {
    for (final field in [
      'nick',
      'nickname',
      'name',
      'display_name',
      'full_name',
      'owner_name'
    ]) {
      final value = contact[field]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    final firstName = contact['first_name']?.toString().trim() ?? '';
    final lastName = contact['last_name']?.toString().trim() ?? '';
    final parts = [firstName, lastName].where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(' ');

    return null;
  }

  /// Extract an avatar URL from a NX contact map.
  String? _extractAvatar(Map<String, dynamic> contact) {
    return contact['avatar']?.toString() ??
        contact['profile_picture']?.toString() ??
        contact['profile_picture_url']?.toString() ??
        contact['photo']?.toString() ??
        contact['image']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        title: const Text('Inbox'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllMessages,
        child: _buildMessagesList(theme),
      ),
    );
  }

  Widget _buildMessagesList(ThemeData theme) {
    // Show actual contacts from messaging API
    if (_isLoadingContacts) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _contacts.toList();

    debugPrint('📨 _buildMessagesList: ${filtered.length} contacts');

    if (filtered.isEmpty) {
      // Scrollable so pull-to-refresh still works when empty.
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 120),
            child: _buildEmptyState(),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: filtered.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 76,
        color: theme.colorScheme.outlineVariant.withOpacity(0.4),
      ),
      itemBuilder: (context, index) {
        final contact = filtered[index];
        final name = contact['name']?.toString() ?? 'Unknown';
        final nxid = contact['nxid']?.toString() ?? '';
        // Use same normalization as _loadAllMessages for consistent lookup
        final phone = PhoneFormatter.normalize(nxid);

        // Get last message for this contact
        final lastMsg = _lastMessages[phone];
        final lastMsgText = lastMsg?['body']?.toString() ?? '';
        final timestamp = lastMsg?['timestamp'] as int?;
        final isFromMe = lastMsg?['isFromMe'] == true;

        return _buildContactTile(
          name: name,
          avatar: contact['avatar'] as String?,
          lastMessage: lastMsgText,
          isFromMe: isFromMe,
          timestamp: timestamp,
          onTap: () => _handleMessageContact(name, nxid),
        );
      },
    );
  }

  /// Plain contacts-style row — no card, minimal padding.
  Widget _buildContactTile({
    required String name,
    required String? avatar,
    String? lastMessage,
    bool isFromMe = false,
    int? timestamp,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    // Format timestamp
    String timeStr = '';
    if (timestamp != null) {
      final dt = Message.parseTimestamp(timestamp);
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        timeStr =
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else {
        timeStr = '${dt.day}/${dt.month}';
      }
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      minVerticalPadding: 8,
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: avatar != null
            ? ClipOval(
                child: Image.network(
                  avatar,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.person, size: 24),
                ),
              )
            : Icon(
                Icons.person,
                color: theme.colorScheme.onPrimaryContainer,
                size: 24,
              ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (timeStr.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                timeStr,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        lastMessage?.isNotEmpty == true
            ? (isFromMe ? 'You: $lastMessage' : lastMessage!)
            : 'Tap to start chatting',
        style: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No Messages Yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with colleagues\nand fellow students',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(
                alpha: 0.5,
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _handleMessageContact(String name, String nxid) async {
    debugPrint('📨 Opening chat with contact: $name ($nxid)');

    try {
      // Ensure messaging is connected
      if (!_messagingService.isConnected.value) {
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );
        await _messagingService.initializeConnection();
        Get.back();
      }

      Get.to(
        () => ChatRoomScreen(
          contactId: nxid,
          contactName: name,
          contactAvatar: null,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error opening chat: $e');
      Get.snackbar('Error', 'Could not open chat. Please try again.');
    }
  }
}

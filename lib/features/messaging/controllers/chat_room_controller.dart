import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nexacon_messaging/nexacon_messaging.dart';
import '../models/message.dart';
import '../services/nexacon_messaging_service.dart';
import '../../../services/token_storage_service.dart';
import '../../../utils/phone_formatter.dart';

class ChatRoomController extends GetxController {
  final String contactId;
  final String contactName;
  final NexaconMessagingService _messagingService =
      Get.find<NexaconMessagingService>();
  final TokenStorageService _tokenStorage = Get.find<TokenStorageService>();

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final RxList<Message> messages = <Message>[].obs;
  final RxBool isOnline = false.obs;
  final RxBool isTyping = false.obs;
  final RxBool isSending = false.obs;
  final RxBool isContactTyping = false.obs;

  // Pagination state (offset-based)
  int _currentOffset = 0;
  int? _nextOffset;
  final int _pageSize = 50;
  final RxBool hasMoreMessages = true.obs;
  final RxBool isLoadingMore = false.obs;

  final List<StreamSubscription> _subscriptions = [];
  Timer? _contactTypingTimer;

  String get myNxId {
    final userData = _tokenStorage.userData;

    // Try multiple possible phone number field names
    String? phone =
        userData?['phone_number'] as String? ??
        userData?['phone'] as String? ??
        userData?['phoneNumber'] as String?;

    // Check nested contact object
    if (phone == null || phone.isEmpty) {
      final contact = userData?['contact'] as Map<String, dynamic>?;
      phone = contact?['phone_number'] as String?;
    }

    if (phone != null && phone.isNotEmpty) {
      return PhoneFormatter.formatAsNxId(phone);
    }

    return 'user_nxid';
  }

  ChatRoomController({required this.contactId, required this.contactName});

  @override
  void onInit() {
    super.onInit();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    try {
      await _messagingService.ensureInitialized();
    } catch (e) {
      print('❌ Chat could not initialize messaging: $e');
    }

    _listenToMessages();
    _checkOnlineStatus();
    _loadConversationHistory();

    // Infinite scroll listener (reverse list: top = older messages)
    scrollController.addListener(() {
      if (scrollController.hasClients &&
          !isLoadingMore.value &&
          hasMoreMessages.value &&
          scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200) {
        loadMoreMessages();
      }
    });

    // Subscribe to live presence updates + fetch initial status
    _messagingService.subscribeToPresence(contactId);
    final cached = _messagingService.getCachedPresenceStatus(
      contactId.split('@').first,
    );
    if (cached != null) {
      isOnline.value = cached == NxPresenceStatus.online;
    }
    final fetched = await _messagingService.fetchPresence(contactId);
    if (fetched != null) {
      isOnline.value = fetched == NxPresenceStatus.online;
    }
  }

  void _loadConversationHistory() async {
    try {
      await _messagingService.ensureInitialized();

      final history = await _messagingService.getConversationHistory(
        contactId,
        offset: _currentOffset,
        pageSize: _pageSize,
      );

      print(
        '📨 Loaded offset $_currentOffset: ${history.messages.length} messages, hasNext=${history.hasNext}',
      );

      hasMoreMessages.value = history.hasNext;
      _nextOffset = history.nextOffset;

      final parsed = _parseHistoryMessages(history.messages);

      // Newest first (reversed list: index 0 = newest at bottom)
      messages.value = parsed.reversed.toList();

      // If most messages were filtered out as signaling, auto-load next page
      // so the user sees enough actual chat messages.
      if (hasMoreMessages.value && parsed.length < 10) {
        print(
          '📨 Only $parsed.length displayable messages, auto-loading next page...',
        );
        await loadMoreMessages();
      }
    } catch (e) {
      print('❌ Error loading conversation history: $e');
    }
  }

  /// Load older messages (next offset) and prepend to the list.
  Future<void> loadMoreMessages() async {
    if (isLoadingMore.value || !hasMoreMessages.value) return;
    if (_nextOffset == null) {
      hasMoreMessages.value = false;
      return;
    }

    isLoadingMore.value = true;
    var needsMore = false;

    try {
      final offsetToFetch = _nextOffset!;
      final history = await _messagingService.getConversationHistory(
        contactId,
        offset: offsetToFetch,
        pageSize: _pageSize,
      );

      print(
        '📨 Loaded offset $offsetToFetch: ${history.messages.length} messages, hasNext=${history.hasNext}',
      );

      hasMoreMessages.value = history.hasNext;
      _nextOffset = history.nextOffset;

      if (history.messages.isEmpty) {
        hasMoreMessages.value = false;
        return;
      }

      final parsed = _parseHistoryMessages(history.messages);
      // Insert older messages at the end of the reversed list (top of screen)
      messages.addAll(parsed.reversed.toList());
      needsMore = hasMoreMessages.value && parsed.length < 10;
      if (needsMore) {
        print(
          '📨 Only ${parsed.length} displayable on this page, auto-loading next...',
        );
      }
    } catch (e) {
      print('❌ Error loading more messages: $e');
    } finally {
      isLoadingMore.value = false;
      if (needsMore) {
        loadMoreMessages();
      }
    }
  }

  /// Convert NxHistoryMessage list to app Message list, filtering signaling junk.
  /// Uses is_me from the API response for reliable sender detection.
  List<Message> _parseHistoryMessages(List<NxHistoryMessage> history) {
    final result = <Message>[];
    for (final m in history) {
      if (!_isDisplayableMessage(m.body)) {
        print('🚫 Filtered out: id=${m.id}, type=${m.type}, isMe=${m.isMe}');
        continue;
      }
      print(
        '✅ Keeping: id=${m.id}, isMe=${m.isMe}, from=${m.from}, body=${m.body.substring(0, m.body.length > 60 ? 60 : m.body.length)}',
      );
      result.add(
        Message(
          id: m.id.isNotEmpty
              ? m.id
              : DateTime.now().millisecondsSinceEpoch.toString(),
          content: m.body,
          senderId: m.from,
          senderName: m.isMe ? 'Me' : contactName,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            m.timestamp > 0
                ? m.timestamp
                : DateTime.now().millisecondsSinceEpoch,
          ),
          isSent: m.isMe,
          isRead: m.read,
        ),
      );
    }
    return result;
  }

  bool _matchesContact(String? from) {
    if (from == null) return false;
    return PhoneFormatter.normalize(from) ==
        PhoneFormatter.normalize(contactId);
  }

  /// Whether a raw message body should be shown in the chat.
  /// - JSON with a non-chat 'type' (call_invitation, call_response,
  ///   webrtc_answer, webrtc_offer, ...) is filtered out.
  /// - JSON chat messages ('type':'chat' or no 'type') are shown.
  /// - Human-readable call invites are shown as call cards.
  static bool _isDisplayableMessage(String body) {
    if (body.isEmpty) return false;

    // Human-readable call invite - show as a call card
    if (body.contains('Incoming p2p call') ||
        body.contains('Incoming group call')) {
      return true;
    }

    if (body.trim().startsWith('{')) {
      try {
        final map = jsonDecode(body) as Map<String, dynamic>;
        final type = map['type']?.toString() ?? '';

        // Allow plain chat JSON (legacy SDK messages or no type)
        if (type == 'chat' || type.isEmpty) {
          return (map['message']?.toString() ??
                  map['body']?.toString() ??
                  map['content']?.toString() ??
                  '')
              .isNotEmpty;
        }

        // Everything else is signaling (webrtc, call_invitation, etc.)
        return false;
      } catch (_) {
        // Not valid JSON, show as plain text
      }
    }

    return true;
  }

  void _listenToMessages() {
    _subscriptions.add(
      _messagingService.messageStream.listen((nxMsg) {
        if (_matchesContact(nxMsg.from)) {
          final body = nxMsg.body ?? '';
          if (!_isDisplayableMessage(body)) {
            print('🚫 Filtered out WebRTC signaling message');
            return; // Skip raw signaling messages
          }

          final message = Message(
            id: nxMsg.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
            content: body,
            senderId: nxMsg.from ?? '',
            senderName: contactName,
            timestamp: DateTime.fromMillisecondsSinceEpoch(nxMsg.timestamp),
            isSent: false,
            isRead: false,
          );
          messages.insertAll(0, [message]);
          _scrollToBottom();
          if (nxMsg.id != null) {
            _messagingService.sendReadReceipt(contactId, nxMsg.id!);
          }
        }
      }),
    );

    _subscriptions.add(
      _messagingService.presenceStream.listen((presence) {
        if (_matchesContact(presence.from)) {
          isOnline.value = presence.status == NxPresenceStatus.online;
        }
      }),
    );

    _subscriptions.add(
      _messagingService.typingStream.listen((typing) {
        if (_matchesContact(typing.from)) {
          isContactTyping.value = typing.isTyping;
          if (typing.isTyping) {
            _contactTypingTimer?.cancel();
            _contactTypingTimer = Timer(const Duration(seconds: 3), () {
              isContactTyping.value = false;
            });
          }
        }
      }),
    );

    _subscriptions.add(
      _messagingService.readReceiptStream.listen((receipt) {
        if (_matchesContact(receipt.from)) {
          final messageId = receipt.messageId;
          if (messageId != null) {
            for (int i = 0; i < messages.length; i++) {
              if (messages[i].id == messageId) {
                final m = messages[i];
                messages[i] = Message(
                  id: m.id,
                  content: m.content,
                  senderId: m.senderId,
                  senderName: m.senderName,
                  timestamp: m.timestamp,
                  isSent: m.isSent,
                  isDelivered: m.isDelivered,
                  isRead: true,
                  avatarUrl: m.avatarUrl,
                );
                break;
              }
            }
          }
        }
      }),
    );

    _subscriptions.add(
      _messagingService.deliveryReceiptStream.listen((receipt) {
        if (_matchesContact(receipt.from)) {
          final messageId = receipt.messageId;
          if (messageId != null) {
            for (int i = 0; i < messages.length; i++) {
              if (messages[i].id == messageId) {
                final m = messages[i];
                messages[i] = Message(
                  id: m.id,
                  content: m.content,
                  senderId: m.senderId,
                  senderName: m.senderName,
                  timestamp: m.timestamp,
                  isSent: m.isSent,
                  isDelivered: true,
                  isRead: m.isRead,
                  avatarUrl: m.avatarUrl,
                );
                break;
              }
            }
          }
        }
      }),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _checkOnlineStatus() {
    // Presence subscription + initial fetch handled in _initializeAndLoad()
  }

  void onTyping(String text) {
    isTyping.value = text.isNotEmpty;
    if (text.isNotEmpty) {
      _messagingService.sendTypingIndicator(contactId, isTyping: true);
    } else {
      _messagingService.sendTypingIndicator(contactId, isTyping: false);
    }
  }

  void sendMessage() async {
    final content = messageController.text.trim();
    if (content.isEmpty) return;

    try {
      await _messagingService.ensureInitialized();
    } catch (e) {
      print('❌ Messaging service not ready: $e');
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        const SnackBar(
          content: Text('Messaging service not initialized. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    isSending.value = true;
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();

    print('📤 sendMessage: content=$content');
    print('📤 myNxId=$myNxId');
    print('📤 contactId=$contactId');

    // Add optimistic message
    final message = Message(
      id: messageId,
      content: content,
      senderId: myNxId,
      senderName: 'Me',
      timestamp: DateTime.now(),
      isSent: true,
    );
    print(
      '📤 Adding optimistic message: ${message.id}, senderId=${message.senderId}',
    );
    messages.insertAll(0, [message]);
    print('📤 Total messages after insert: ${messages.length}');
    messageController.clear();
    isTyping.value = false;
    _scrollToBottom();

    try {
      await _messagingService.sendMessage(to: contactId, message: content);
      print('✅ Message sent successfully');
    } catch (e) {
      print('❌ Error sending message: $e');
      messages.removeWhere((m) => m.id == messageId);
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      isSending.value = false;
    }
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _contactTypingTimer?.cancel();
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}

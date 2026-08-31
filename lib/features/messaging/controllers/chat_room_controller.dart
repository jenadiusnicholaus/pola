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

  // Pagination state (offset-based). The history API paginates
  // oldest -> newest: offset 0 is the OLDEST page, and the newest
  // messages live on the last page.
  int? _nextOffset;
  final int _pageSize = 100;
  int _actualLimit = 100; // updated from API response
  final Set<int> _loadedOffsets = {};
  final RxBool hasMoreMessages = true.obs;
  final RxBool isLoadingMore = false.obs;

  final List<StreamSubscription> _subscriptions = [];
  Timer? _contactTypingTimer;

  String get myNxId {
    final userData = _tokenStorage.userData;

    // Try multiple possible phone number field names
    String? phone = userData?['phone_number'] as String? ??
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

  ChatRoomController({required String contactId, required this.contactName})
      : contactId = PhoneFormatter.formatAsNxId(contactId);

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

    // Subscribe to the contact's presence updates via XMPP.
    // Also broadcast our own presence so the contact's client knows
    // we're online and can reply with their presence.
    _messagingService.setOnline();
    _messagingService.subscribeToPresence(contactId);

    // Check the SDK's presence cache (full bare JID with domain).
    final cached = _messagingService.getCachedPresenceStatus(contactId);
    if (cached != null) {
      isOnline.value = cached == NxPresenceStatus.online;
    }

    // Re-check cache after a short delay — the presence subscription
    // request triggers the contact's client to send us their current
    // presence, but this takes a network round-trip. By the time this
    // timer fires, the cache should have been updated by the SDK's
    // presence stream handler.
    Timer(const Duration(seconds: 3), () {
      if (isClosed) return;
      final c = _messagingService.getCachedPresenceStatus(contactId);
      if (c != null) {
        isOnline.value = c == NxPresenceStatus.online;
      }
    });
  }

  /// Merge new messages into the current list, dedupe by id, and sort by
  /// timestamp descending (index 0 = newest = bottom of screen, since the
  /// ListView uses reverse:true). This guarantees correct ordering
  /// regardless of the raw order returned by the API or the order in
  /// which local/remote messages arrive.
  void _mergeAndSort(List<Message> incoming, {bool prepend = false}) {
    final byId = <String, Message>{};
    for (final m in messages.value) {
      byId[m.id] = m;
    }
    for (final m in incoming) {
      byId[m.id] = m;
    }
    final merged = byId.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    messages.value = _reconcileCallSessions(merged);
  }

  void _loadConversationHistory() async {
    try {
      await _messagingService.ensureInitialized();

      // The API paginates oldest -> newest, so offset 0 is the oldest
      // page. Fetch it first to learn the total, then jump straight to
      // the last page so the chat opens showing the most recent messages.
      final firstPage = await _messagingService.getConversationHistory(
        contactId,
        offset: 0,
        pageSize: _pageSize,
      );
      _loadedOffsets.add(0);

      final total = firstPage.total;
      // Use the ACTUAL limit from the API response, not our requested
      // _pageSize — the server may cap or override it, and computing
      // offsets with the wrong step size skips entire pages.
      _actualLimit = firstPage.limit > 0 ? firstPage.limit : _pageSize;
      final lastOffset =
          total > 0 ? ((total - 1) ~/ _actualLimit) * _actualLimit : 0;

      print(
        '📨 History: total=$total, limit=${firstPage.limit}, actualLimit=$_actualLimit, lastOffset=$lastOffset',
      );

      var parsed = _parseHistoryMessages(firstPage.messages);

      if (lastOffset > 0) {
        var lastPage = await _messagingService.getConversationHistory(
          contactId,
          offset: lastOffset,
          pageSize: _pageSize,
        );
        _loadedOffsets.add(lastOffset);
        print(
          '📨 Loaded page at offset $lastOffset: ${lastPage.messages.length} messages, hasNext=${lastPage.hasNext}',
        );
        parsed = [...parsed, ..._parseHistoryMessages(lastPage.messages)];

        // Safety: if the API says there are MORE pages after our computed
        // lastOffset, our calculation was wrong (e.g. total was stale or
        // limit mismatch). Walk forward until we reach the true last page.
        var safetyCounter = 0;
        while (lastPage.hasNext && safetyCounter < 50) {
          final nextOff =
              lastPage.nextOffset ?? (lastPage.offset + _actualLimit);
          print('📨 hasNext=true, walking forward to offset $nextOff');
          lastPage = await _messagingService.getConversationHistory(
            contactId,
            offset: nextOff,
            pageSize: _pageSize,
          );
          _loadedOffsets.add(nextOff);
          parsed = [...parsed, ..._parseHistoryMessages(lastPage.messages)];
          safetyCounter++;
        }
      }

      // Older pages (between 0 and lastOffset) may still be unloaded;
      // walk offsets backwards from here when the user scrolls up.
      final olderOffset = lastOffset - _actualLimit;
      if (olderOffset >= 0 && !_loadedOffsets.contains(olderOffset)) {
        _nextOffset = olderOffset;
        hasMoreMessages.value = true;
      } else {
        _nextOffset = null;
        hasMoreMessages.value = false;
      }

      // Sort explicitly by timestamp descending - do NOT rely on the raw
      // API order, which is not guaranteed and previously caused messages
      // to render out of chronological order.
      _mergeAndSort(parsed);

      // If most messages were filtered out as signaling, auto-load next page
      // so the user sees enough actual chat messages.
      if (hasMoreMessages.value && parsed.length < 20) {
        print(
          '📨 Only ${parsed.length} displayable messages, auto-loading next page...',
        );
        await loadMoreMessages();
      }
    } catch (e) {
      print('❌ Error loading conversation history: $e');
    }
  }

  /// Load older messages (walking offsets backwards towards 0) and
  /// append them to the end of the reversed list (top of screen).
  Future<void> loadMoreMessages() async {
    if (isLoadingMore.value || !hasMoreMessages.value) return;

    // Skip offsets we have already loaded (e.g. the initial oldest page).
    while (_nextOffset != null && _loadedOffsets.contains(_nextOffset)) {
      final older = _nextOffset! - _actualLimit;
      _nextOffset = older >= 0 ? older : null;
    }
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

      _loadedOffsets.add(offsetToFetch);

      // Move to the next older offset using the actual API limit.
      final olderOffset = offsetToFetch - _actualLimit;
      _nextOffset = olderOffset >= 0 ? olderOffset : null;
      hasMoreMessages.value = _nextOffset != null;

      if (history.messages.isEmpty) {
        hasMoreMessages.value = false;
        return;
      }

      final parsed = _parseHistoryMessages(history.messages);
      // Sort the new page by timestamp descending, then append (older
      // messages go at the end of the reversed list = top of screen).
      // Dedupe against already-loaded messages to avoid duplicates from
      // overlapping pages, without disturbing the scroll position by
      // re-sorting the entire list.
      final existingIds = messages.value.map((m) => m.id).toSet();
      final newOnes = parsed.where((m) => !existingIds.contains(m.id)).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      messages.addAll(newOnes);
      messages.value = _reconcileCallSessions(messages.value);
      needsMore = hasMoreMessages.value && parsed.length < 20;
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
          content: Message.extractHumanText(m.body),
          senderId: m.from,
          senderName: m.isMe ? 'Me' : contactName,
          timestamp: m.timestamp > 0
              ? Message.parseTimestamp(m.timestamp)
              : DateTime.now(),
          isSent: m.isMe,
          isRead: m.read,
          roomId: Message.extractRoomId(m.body),
          callEnded: Message.isCallEndBody(m.body),
        ),
      );
    }
    return result;
  }

  /// Reconcile a call session (invite + end) into a single bubble:
  /// - Both sides of a call post their own mirrored "Incoming p2p call"
  ///   invite (same roomId, different sender). Only one is kept, preferring
  ///   the one where isSent == true so a call *I* made always shows as
  ///   "You: Voice call" rather than flipping based on arbitrary timestamp
  ///   ordering between the two mirrored copies.
  /// - A standalone call_end signaling entry is folded into that same
  ///   invite bubble (marking it ended) instead of appearing on its own.
  List<Message> _reconcileCallSessions(List<Message> input) {
    final endedRoomIds = <String>{
      for (final m in input)
        if (m.callEnded && m.roomId != null) m.roomId!,
    };

    // Pick the canonical invite per roomId, preferring isSent == true.
    final canonicalInviteByRoomId = <String, Message>{};
    for (final m in input) {
      if (!m.isCallMessage || m.roomId == null || m.callEnded) continue;
      final existing = canonicalInviteByRoomId[m.roomId];
      if (existing == null || (m.isSent && !existing.isSent)) {
        canonicalInviteByRoomId[m.roomId!] = m;
      }
    }

    final result = <Message>[];
    for (final m in input) {
      // Drop standalone call_end signaling entries (not real call invites).
      if (m.callEnded && !m.isCallMessage) continue;

      if (m.isCallMessage && m.roomId != null) {
        // Skip the non-canonical mirrored copy.
        if (canonicalInviteByRoomId[m.roomId]?.id != m.id) continue;

        final ended = endedRoomIds.contains(m.roomId) && !m.callEnded;
        result.add(ended ? m.copyWith(callEnded: true) : m);
      } else {
        result.add(m);
      }
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
  /// - 'call_end' is let through so it can be merged into the matching
  ///   call invite bubble (see _reconcileCallSessions), not shown on its own.
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

        // Allow plain chat JSON (legacy SDK messages or no type).
        // Always keep chat messages — the display layer will extract
        // human-readable text via extractHumanText. Filtering them out
        // just because we don't recognise the field name hides real messages.
        if (type == 'chat' || type.isEmpty) {
          return true;
        }

        // Let call_end through for session reconciliation; it never renders
        // as its own bubble (merged into the invite or dropped).
        if (type == 'call_end') return true;

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
            timestamp: Message.parseTimestamp(nxMsg.timestamp),
            isSent: false,
            isRead: false,
            roomId: Message.extractRoomId(body),
            callEnded: Message.isCallEndBody(body),
          );
          _mergeAndSort([message]);
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
    // Presence subscription + initial cache handled in _initializeAndLoad()
  }

  void onTyping(String text) {
    isTyping.value = text.isNotEmpty;
    if (text.isNotEmpty) {
      _messagingService.sendTypingIndicator(contactId, isTyping: true);
    } else {
      _messagingService.sendTypingIndicator(contactId, isTyping: false);
    }
  }

  /// Detects whether the given text contains a phone number.
  /// Matches:
  /// - International: +255XXXXXXXXX, 255XXXXXXXXX
  /// - Local: 0XXXXXXXXX
  /// - Generic: 7+ consecutive digits (with optional + prefix)
  bool _containsPhoneNumber(String text) {
    // Strip spaces and dashes to catch formatted numbers like "0712-345-678"
    final cleaned = text.replaceAll(RegExp(r'[\s\-]'), '');

    // Tanzanian international format: +255 / 255 followed by 9 digits
    if (RegExp(r'\+?255\d{9}').hasMatch(cleaned)) return true;

    // Tanzanian local format: 0 followed by 9 digits
    if (RegExp(r'0\d{9}').hasMatch(cleaned)) return true;

    // Generic: 7+ consecutive digits with optional + prefix
    if (RegExp(r'\+?\d{7,}').hasMatch(cleaned)) return true;

    return false;
  }

  void sendMessage() async {
    final content = messageController.text.trim();
    if (content.isEmpty) return;

    if (_containsPhoneNumber(content)) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        const SnackBar(
          content: Text('Phone numbers are not allowed in chat messages.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

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
    _mergeAndSort([message]);
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
    _subscriptions.clear();
    _contactTypingTimer?.cancel();
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}

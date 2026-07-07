import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  final List<StreamSubscription> _subscriptions = [];
  Timer? _contactTypingTimer;

  String get myNxId {
    final userData = _tokenStorage.userData;
    final phone = userData?['phone_number'] as String?;
    if (phone != null && phone.isNotEmpty) {
      return PhoneFormatter.formatAsNxId(phone);
    }
    return 'user_nxid';
  }

  ChatRoomController({
    required this.contactId,
    required this.contactName,
  });

  @override
  void onInit() {
    super.onInit();
    _loadConversationHistory();
    _listenToMessages();
    _checkOnlineStatus();
  }

  void _loadConversationHistory() async {
    try {
      print('📨 _loadConversationHistory: contactId=$contactId');
      final history = await _messagingService.getConversationHistory(contactId);
      print(
          '📨 _loadConversationHistory: received ${history.length} messages from API');
      print(
          '📨 _loadConversationHistory: first message sample: ${history.isNotEmpty ? history.first.body : "empty"}');

      // Convert NexaconMessage to app's Message model
      // Use displayText for call messages, body for normal messages
      final parsed = history
          .map((m) => Message(
                id: m.id,
                content: m.isCallMessage ? m.displayText : m.body,
                senderId: m.from,
                senderName: 'Unknown', // NexaconMessage doesn't have senderName
                timestamp:
                    DateTime.fromMillisecondsSinceEpoch(m.timestamp ~/ 1000),
                isRead: true,
              ))
          .toList();

      messages.value = parsed;
      print('📨 Loaded ${parsed.length} messages (${history.length} total)');
    } catch (e) {
      print('❌ Error loading conversation history: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  bool _matchesContact(String? from) {
    if (from == null) return false;
    return PhoneFormatter.normalize(from) ==
        PhoneFormatter.normalize(contactId);
  }

  void _listenToMessages() {
    _subscriptions.add(
      _messagingService.messageStream.listen((data) {
        final from = data['from']?.toString();
        if (_matchesContact(from)) {
          final message = Message.fromJson(data);
          messages.insertAll(0, [message]);
          _scrollToBottom();
          _messagingService.sendReadReceipt(contactId, message.id);
        }
      }),
    );

    _subscriptions.add(
      _messagingService.presenceStream.listen((data) {
        final from = data['from']?.toString();
        if (_matchesContact(from)) {
          final type = data['type']?.toString();
          isOnline.value = type == null || type == 'available';
        }
      }),
    );

    _subscriptions.add(
      _messagingService.typingStream.listen((data) {
        final from = data['from']?.toString();
        if (_matchesContact(from)) {
          isContactTyping.value = true;
          _contactTypingTimer?.cancel();
          _contactTypingTimer = Timer(const Duration(seconds: 3), () {
            isContactTyping.value = false;
          });
        }
      }),
    );

    _subscriptions.add(
      _messagingService.readReceiptStream.listen((data) {
        final from = data['from']?.toString();
        if (_matchesContact(from)) {
          final messageId = data['message_id']?.toString();
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
      _messagingService.deliveryReceiptStream.listen((data) {
        final from = data['from']?.toString();
        if (_matchesContact(from)) {
          final messageId = data['message_id']?.toString();
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
    // TODO: Check presence via SDK
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
        '📤 Adding optimistic message: ${message.id}, senderId=${message.senderId}');
    messages.insertAll(0, [message]);
    print('📤 Total messages after insert: ${messages.length}');
    messageController.clear();
    isTyping.value = false;
    _scrollToBottom();

    try {
      _messagingService.sendRealTimeMessage(
        to: contactId,
        message: content,
      );
    } catch (e) {
      print('Error sending message: $e');
      messages.removeWhere((m) => m.id == messageId);
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

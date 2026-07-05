import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/message.dart';
import '../services/nexacon_messaging_service.dart';
import '../../../services/token_storage_service.dart';

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
      return _formatPhoneNumberWithCountryCode(phone);
    }
    return 'user_nxid';
  }

  String _formatPhoneNumberWithCountryCode(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    String formatted;

    if (digits.startsWith('0')) {
      formatted = '+255${digits.substring(1)}';
    } else if (digits.startsWith('255')) {
      formatted = '+$digits';
    } else if (digits.length == 9) {
      // Local 9-digit number without country code or leading 0
      formatted = '+255$digits';
    } else {
      formatted = digits; // assume already international
    }

    return '$formatted@nxservice.quantumvision-tech.com';
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
      final history = await _messagingService.getConversationHistory(contactId);
      messages.value = history.map((e) => Message.fromJson(e)).toList();
    } catch (e) {
      print('Error loading conversation history: $e');
    }
  }

  void _listenToMessages() {
    _subscriptions.add(
      _messagingService.messageStream.listen((data) {
        final from = data['from']?.toString();
        if (from == contactId) {
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
        if (from == contactId) {
          final type = data['type']?.toString();
          isOnline.value = type == null || type == 'available';
        }
      }),
    );

    _subscriptions.add(
      _messagingService.typingStream.listen((data) {
        final from = data['from']?.toString();
        if (from == contactId) {
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
        if (from == contactId) {
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
        if (from == contactId) {
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

    // Add optimistic message
    final message = Message(
      id: messageId,
      content: content,
      senderId: myNxId,
      senderName: 'Me',
      timestamp: DateTime.now(),
      isSent: true,
    );
    messages.insertAll(0, [message]);
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

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
  final RxList<Message> messages = <Message>[].obs;
  final RxBool isOnline = false.obs;
  final RxBool isTyping = false.obs;
  final RxBool isSending = false.obs;

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
    if (digits.startsWith('0')) {
      return '255${digits.substring(1)}';
    } else if (digits.startsWith('255')) {
      return digits;
    }
    return digits;
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
    _messagingService.messageStream.listen((messageData) {
      // Ensure messageData is a Map
      if (messageData is! Map) return;

      final dataMap = messageData as Map<dynamic, dynamic>;
      final from = dataMap['from']?.toString();
      if (from == contactId) {
        final message = Message.fromJson(Map<String, dynamic>.from(dataMap));
        messages.add(message);
        // Scroll to bottom
        // TODO: Implement scroll to bottom
      }
    });

    _messagingService.presenceStream.listen((presence) {
      if (presence is! Map) return;

      final dataMap = presence as Map<dynamic, dynamic>;
      final from = dataMap['from']?.toString();
      if (from == contactId) {
        final type = dataMap['type']?.toString();
        final isOnline = type == null || type == 'available';
        this.isOnline.value = isOnline;
      }
    });

    _messagingService.typingStream.listen((typing) {
      if (typing is! Map) return;

      final dataMap = typing as Map<dynamic, dynamic>;
      final from = dataMap['from']?.toString();
      if (from == contactId) {
        // TODO: Show typing indicator
      }
    });

    _messagingService.readReceiptStream.listen((receipt) {
      if (receipt is! Map) return;

      final dataMap = receipt as Map<dynamic, dynamic>;
      final from = dataMap['from']?.toString();
      if (from == contactId) {
        // Update message read status
        final messageId = dataMap['message_id']?.toString();
        if (messageId != null) {
          for (int i = 0; i < messages.length; i++) {
            if (messages[i].id == messageId) {
              messages[i] = Message(
                id: messages[i].id,
                content: messages[i].content,
                senderId: messages[i].senderId,
                senderName: messages[i].senderName,
                timestamp: messages[i].timestamp,
                isSent: messages[i].isSent,
                isDelivered: messages[i].isDelivered,
                isRead: true,
                avatarUrl: messages[i].avatarUrl,
              );
              break;
            }
          }
        }
      }
    });

    _messagingService.deliveryReceiptStream.listen((receipt) {
      if (receipt is! Map) return;

      final dataMap = receipt as Map<dynamic, dynamic>;
      final from = dataMap['from']?.toString();
      if (from == contactId) {
        // Update message delivered status
        final messageId = dataMap['message_id']?.toString();
        if (messageId != null) {
          for (int i = 0; i < messages.length; i++) {
            if (messages[i].id == messageId) {
              messages[i] = Message(
                id: messages[i].id,
                content: messages[i].content,
                senderId: messages[i].senderId,
                senderName: messages[i].senderName,
                timestamp: messages[i].timestamp,
                isSent: messages[i].isSent,
                isDelivered: true,
                isRead: messages[i].isRead,
                avatarUrl: messages[i].avatarUrl,
              );
              break;
            }
          }
        }
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
    messages.add(message);
    messageController.clear();
    isTyping.value = false;

    try {
      _messagingService.sendRealTimeMessage(
        to: contactId,
        message: content,
      );
    } catch (e) {
      print('Error sending message: $e');
      // Remove message if failed
      messages.removeWhere((m) => m.id == messageId);
      // Update message status to indicate failure
      final failedMessage = Message(
        id: messageId,
        content: content,
        senderId: myNxId,
        senderName: 'Me',
        timestamp: DateTime.now(),
        isSent: false,
        isDelivered: false,
        isRead: false,
      );
      messages.add(failedMessage);
    } finally {
      isSending.value = false;
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}

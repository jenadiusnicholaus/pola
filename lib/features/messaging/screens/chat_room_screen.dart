import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_room_controller.dart';
import '../models/message.dart';
import '../../../utils/phone_formatter.dart';
import '../../calling_booking/services/nexacon_call_service.dart';
import '../../calling_booking/screens/call_screen.dart';
import '../../../services/token_storage_service.dart';

class ChatRoomScreen extends StatelessWidget {
  final String contactId;
  final String contactName;
  final String? contactAvatar;

  const ChatRoomScreen({
    super.key,
    required this.contactId,
    required this.contactName,
    this.contactAvatar,
  });

  void _initiateCall(BuildContext context, {required bool isVideo}) async {
    try {
      // Get user's phone number
      final tokenStorage = Get.find<TokenStorageService>();
      final userData = tokenStorage.userData;
      final myPhone = userData?['phone_number'] as String? ??
          userData?['phone'] as String? ??
          userData?['phoneNumber'] as String?;

      if (myPhone == null || myPhone.isEmpty) {
        Get.snackbar(
          'Error',
          'Unable to start call. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Get or create call service
      final callService = Get.find<NexaconCallService>();

      // Navigate to call screen
      Get.to(
        () => CallScreen(
          callerName: contactName,
          callerPhone: contactId.split('@').first,
          isIncoming: false,
        ),
      );

      // Initiate the call
      await callService.initiateCall(
        username: myPhone,
        to: contactId.split('@').first,
        name: contactName,
      );
    } catch (e) {
      print('❌ Error initiating call: $e');
      Get.snackbar(
        'Error',
        'Failed to start call. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ChatRoomController(
        contactId: contactId,
        contactName: contactName,
      ),
      tag: contactId,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage:
                  contactAvatar != null ? NetworkImage(contactAvatar!) : null,
              child: contactAvatar == null
                  ? Text(
                      contactName[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    contactName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Obx(() => Text(
                        controller.isOnline.value ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: controller.isOnline.value
                              ? Colors.green
                              : Colors.grey,
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => _initiateCall(context, isVideo: false),
            tooltip: 'Audio call',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              final messages = controller.messages;
              if (messages.length == 0) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start a conversation with $contactName',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                reverse: true,
                controller: controller.scrollController,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final normalizedSenderId =
                      PhoneFormatter.normalize(message.senderId);
                  final normalizedMyId =
                      PhoneFormatter.normalize(controller.myNxId);
                  final isMe = normalizedSenderId == normalizedMyId;
                  debugPrint(
                      '📨 Rendering message: id=${message.id}, senderId=${message.senderId}, myNxId=${controller.myNxId}, isMe=$isMe');
                  return _buildMessageBubble(message, isMe);
                },
              );
            }),
          ),
          // Typing indicator
          Obx(() {
            if (!controller.isContactTyping.value)
              return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Get.theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TypingDot(delay: 0),
                        const SizedBox(width: 4),
                        _TypingDot(delay: 150),
                        const SizedBox(width: 4),
                        _TypingDot(delay: 300),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          _buildMessageInput(controller),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe
              ? Get.theme.colorScheme.primary
              : Get.theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe
                    ? Get.theme.colorScheme.onPrimary
                    : Get.theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Get.theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                        : Get.theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead
                        ? Icons.done_all
                        : message.isDelivered
                            ? Icons.done
                            : Icons.access_time,
                    size: 12,
                    color: isMe
                        ? Get.theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                        : Get.theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(ChatRoomController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // TODO: Implement file attachment
            },
          ),
          Expanded(
            child: TextField(
              controller: controller.messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Get.theme.colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onChanged: controller.onTyping,
            ),
          ),
          const SizedBox(width: 8),
          Obx(() => IconButton(
                icon: controller.isTyping.value
                    ? const Icon(Icons.send)
                    : const Icon(Icons.mic),
                onPressed: controller.sendMessage,
              )),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

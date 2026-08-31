import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/chat_room_controller.dart';
import '../models/message.dart';
import '../../../utils/phone_formatter.dart';
import '../../calling_booking/controllers/consultant_controller.dart';
import '../../calling_booking/models/consultant_models.dart';
import '../../calling_booking/screens/call_screen.dart';

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
      // Format contact phone
      final phone = contactId.split('@').first;

      // Try to find the contact in loaded consultants to use proper call flow
      // (backend FCM notification + shared room). ConsultantController may not
      // be registered if the user navigated directly to chat, so guard it.
      Consultant? matchingConsultant;
      if (Get.isRegistered<ConsultantController>()) {
        final consultantController = Get.find<ConsultantController>();
        final consultants = consultantController.consultants;
        matchingConsultant = consultants.firstWhereOrNull((c) {
          final consultantPhone = c.userDetails.phoneNumber ?? '';
          final normalizedConsultant =
              PhoneFormatter.normalize(consultantPhone);
          final normalizedContact = PhoneFormatter.normalize(phone);
          return normalizedConsultant == normalizedContact ||
              consultantPhone.contains(phone) ||
              phone.contains(consultantPhone);
        });
      }

      if (matchingConsultant != null) {
        // Use the proper CallController flow with backend notification.
        // CallScreen will create the controller and initiate the call.
        print(
          '📞 Found matching consultant: ${matchingConsultant.userDetails.fullName}, using CallController',
        );
        Get.to(
          () => CallScreen(consultant: matchingConsultant, isIncoming: false),
        );
        return;
      }

      // Fallback: direct Nexacon call for non-consultant contacts
      print('📞 No matching consultant, initiating direct call to $phone');
      Get.to(
        () => CallScreen(
          callerName: contactName,
          callerPhone: phone,
          isIncoming: false,
          isDirectCall: true,
        ),
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
      ChatRoomController(contactId: contactId, contactName: contactName),
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
                  Obx(
                    () => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: controller.isOnline.value
                                ? const Color(0xFF00E676)
                                : Colors.white.withValues(alpha: 0.4),
                            border: Border.all(
                              color: controller.isOnline.value
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            boxShadow: controller.isOnline.value
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF00E676)
                                          .withValues(alpha: 0.6),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          controller.isOnline.value ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start a conversation with $contactName',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                reverse: true,
                controller: controller.scrollController,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                itemCount: messages.length + 1, // +1 for top loading indicator
                itemBuilder: (context, index) {
                  // Top loading indicator (shown when scrolling to top for more)
                  if (index == messages.length) {
                    return Obx(() {
                      if (!controller.isLoadingMore.value) {
                        return const SizedBox.shrink();
                      }
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    });
                  }

                  final message = messages[index];
                  final isMe = message.isSent ||
                      PhoneFormatter.normalize(message.senderId) ==
                          PhoneFormatter.normalize(controller.myNxId);
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
                      horizontal: 14,
                      vertical: 10,
                    ),
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
    if (message.isCallType) {
      return _buildCallBubble(message, isMe);
    }

    final radius = Radius.circular(18);
    final tailRadius = const Radius.circular(4);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? Get.theme.colorScheme.primary
              : Get.theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: radius,
            topRight: radius,
            bottomLeft: isMe ? radius : tailRadius,
            bottomRight: isMe ? tailRadius : radius,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.displayText,
              style: TextStyle(
                fontSize: 15,
                height: 1.3,
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
                        : Get.theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
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
                    color: message.isRead
                        ? Colors.lightBlueAccent
                        : Get.theme.colorScheme.onPrimary.withValues(
                            alpha: 0.7,
                          ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Professional card-style bubble for call invite / call-ended events.
  Widget _buildCallBubble(Message message, bool isMe) {
    final isEnded = message.isCallEndMessage;
    final icon = isEnded
        ? Icons.call_end
        : (message.isVideoCall ? Icons.videocam : Icons.call);
    final label = isEnded ? 'Call ended' : message.displayText;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? Get.theme.colorScheme.primary
              : Get.theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        constraints: const BoxConstraints(maxWidth: 280),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isMe
                  ? Get.theme.colorScheme.onPrimary
                  : (isEnded
                      ? Colors.redAccent
                      : Get.theme.colorScheme.primary),
            ),
            const SizedBox(width: 8),
            Text(
              isMe ? 'You: $label' : '$contactName: $label',
              style: TextStyle(
                fontSize: 15,
                color: isMe
                    ? Get.theme.colorScheme.onPrimary
                    : Get.theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMe
                    ? Get.theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                    : Get.theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(ChatRoomController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
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
                filled: true,
                fillColor: Get.theme.colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Get.theme.colorScheme.outline.withValues(
                      alpha: 0.15,
                    ),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Get.theme.colorScheme.primary.withValues(
                      alpha: 0.5,
                    ),
                    width: 1.5,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              minLines: 1,
              maxLines: 5,
              inputFormatters: [
                _PhoneNumberBlockFormatter(),
              ],
              onChanged: controller.onTyping,
            ),
          ),
          const SizedBox(width: 6),
          Obx(
            () => IconButton(
              icon: controller.isTyping.value
                  ? const Icon(Icons.send)
                  : const Icon(Icons.mic),
              onPressed: controller.sendMessage,
            ),
          ),
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
    _anim = Tween<double>(
      begin: 0,
      end: -6,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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

/// Strips phone-number-like sequences from the input as the user types.
/// Removes 7+ consecutive digits (with optional + prefix) and Tanzanian
/// formats (+255XXXXXXXXX, 0XXXXXXXXX) to prevent sharing phone numbers.
class _PhoneNumberBlockFormatter extends TextInputFormatter {
  static final _phoneRegex = RegExp(r'\+?\d{7,}');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = newValue.text.replaceAll(_phoneRegex, '');
    // If nothing changed, return as-is to preserve cursor position
    if (cleaned == newValue.text) return newValue;

    final lengthDiff = newValue.text.length - cleaned.length;
    final newSelection = TextSelection.collapsed(
      offset:
          (newValue.selection.baseOffset - lengthDiff).clamp(0, cleaned.length),
    );

    // Defer the snackbar to avoid blocking the frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        const SnackBar(
          content: Text('Phone numbers are not allowed in chat.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    });

    return TextEditingValue(
      text: cleaned,
      selection: newSelection,
    );
  }
}

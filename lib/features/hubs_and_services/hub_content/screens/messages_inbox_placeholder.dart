import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import '../../../calling_booking/controllers/consultant_controller.dart';
import '../../../calling_booking/models/consultant_models.dart';
import '../../../messaging/screens/chat_room_screen.dart';
import '../../../messaging/services/nexacon_messaging_service.dart';
import '../../../../utils/phone_formatter.dart';

/// Messages Inbox Screen with Consultant List
class MessagesInboxScreen extends StatefulWidget {
  const MessagesInboxScreen({super.key});

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NexaconMessagingService _messagingService =
      Get.find<NexaconMessagingService>();
  final ConsultantController _consultantController = Get.put(
    ConsultantController(),
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Messages')),
        actions: [
          IconButton(
            onPressed: () => setState(() {}),
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: tr('Search lawyers...'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: theme.colorScheme.surfaceContainerHighest,
                filled: true,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Consultants List
          Expanded(
            child: Obx(() {
              final consultants = _consultantController.consultants;
              final isLoading = _consultantController.isLoading.value;

              if (isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (consultants.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(height: 16),
                      Text(tr('No lawyers available'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(tr('Check back later for available lawyers.'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: consultants.length,
                itemBuilder: (context, index) {
                  final consultant = consultants[index];
                  final name = consultant.userDetails.fullName;
                  final phone = consultant.userDetails.phoneNumber ?? '';
                  final avatar = consultant.userDetails.profilePicture;

                  // Filter by search
                  if (_searchController.text.isNotEmpty &&
                      !name.toLowerCase().contains(
                        _searchController.text.toLowerCase(),
                      ) &&
                      !phone.contains(_searchController.text)) {
                    return const SizedBox.shrink();
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: avatar != null
                          ? ClipOval(
                              child: Image.network(
                                avatar,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) =>
                                    const Icon(Icons.person),
                              ),
                            )
                          : const Icon(Icons.person),
                    ),
                    title: Text(name),
                    subtitle: Text(phone),
                    trailing: const Icon(Icons.message),
                    onTap: () => _handleMessageConsultant(consultant),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMessageConsultant(Consultant consultant) async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final rawPhone = consultant.userDetails.phoneNumber ?? '';
      if (rawPhone.isEmpty) {
        Get.back();
        Get.snackbar(
          'Cannot Message',
          'This consultant has no phone number registered.',
        );
        return;
      }

      final nxId = PhoneFormatter.formatAsNxId(rawPhone);
      final contactName = consultant.userDetails.fullName;
      final contactAvatar = consultant.userDetails.profilePicture;

      debugPrint('📨 Messaging consultant: $contactName ($nxId)');

      // Ensure messaging is connected
      if (!_messagingService.isConnected.value) {
        await _messagingService.initializeConnection();
      }

      // Note: Contact management not yet implemented in nexacon_messaging
      // The contact will be added automatically when first message is sent

      Get.back();
      Get.to(
        () => ChatRoomScreen(
          contactId: nxId,
          contactName: contactName,
          contactAvatar: contactAvatar,
        ),
      );
    } catch (e) {
      Get.back();
      debugPrint('❌ Error starting chat: $e');
      Get.snackbar('Error', 'Could not start chat. Please try again.');
    }
  }
}

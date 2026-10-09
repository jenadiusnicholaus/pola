import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controllers/consultant_controller.dart';
import '../models/consultant_models.dart';
import '../../../widgets/profile_avatar.dart';
import '../../../services/permission_service.dart';
import '../../../utils/navigation_helper.dart';
import '../../../utils/phone_formatter.dart';
import '../../messaging/screens/chat_room_screen.dart';
import '../../messaging/services/nexacon_messaging_service.dart';

class ConsultantsScreen extends StatefulWidget {
  const ConsultantsScreen({super.key});

  @override
  State<ConsultantsScreen> createState() => _ConsultantsScreenState();
}

class _ConsultantsScreenState extends State<ConsultantsScreen> {
  final NexaconMessagingService _messagingService =
      Get.find<NexaconMessagingService>();

  @override
  void initState() {
    super.initState();
    // Request microphone permission when entering this screen
    _requestMicrophonePermission();
  }

  Future<void> _requestMicrophonePermission() async {
    try {
      debugPrint('🎤 Pre-requesting microphone permission for calls...');
      final status = await Permission.microphone.status;

      if (status.isDenied) {
        debugPrint('🎤 Microphone permission denied, requesting...');
        final result = await Permission.microphone.request();

        if (result.isGranted) {
          debugPrint('✅ Microphone permission granted');
        } else if (result.isPermanentlyDenied) {
          debugPrint('❌ Microphone permission permanently denied');
          // Show dialog to open settings
          if (mounted) {
            _showPermissionDialog();
          }
        } else {
          debugPrint('⚠️ Microphone permission denied');
        }
      } else if (status.isGranted) {
        debugPrint('✅ Microphone permission already granted');
      }
    } catch (e) {
      debugPrint('❌ Error requesting microphone permission: $e');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission Required'),
        content: const Text(
          'Voice calling requires microphone access. Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ConsultantController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Talk to Lawyers')),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: () => Get.toNamed('/buy-credits'),
            icon: Icon(Icons.account_balance_wallet),
            tooltip: tr('My Credits'),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.consultants.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  controller.error.value,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => controller.fetchConsultants(),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        if (controller.consultants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No consultants available',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchConsultants(),
          child: ListView.separated(
            controller: controller.scrollController,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: controller.consultants.length +
                (controller.hasMore.value ? 1 : 0),
            addAutomaticKeepAlives: true,
            addRepaintBoundaries: true,
            cacheExtent: 500,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 76,
              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
            ),
            itemBuilder: (context, index) {
              if (index == controller.consultants.length) {
                // Loading indicator at bottom
                return Obx(
                  () => controller.isLoadingMore.value
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox.shrink(),
                );
              }
              final consultant = controller.consultants[index];
              return RepaintBoundary(
                child: _buildConsultantTile(context, consultant),
              );
            },
          ),
        );
      }),
    );
  }

  /// Compact contacts-style row: avatar + status dot, name, meta line,
  /// and small message/call/book icon buttons on the right.
  Widget _buildConsultantTile(BuildContext context, Consultant consultant) {
    final theme = Theme.of(context);

    final subtitle = consultant.specialization.isNotEmpty
        ? consultant.specialization
        : '${consultant.consultantType.toUpperCase()} • ${consultant.yearsOfExperience} yrs';

    return Dismissible(
      key: ValueKey('consultant_swipe_${consultant.id}'),
      // Swipe left→right to text, right→left to call.
      direction: consultant.offersMobileConsultations
          ? DismissDirection.horizontal
          : DismissDirection.startToEnd,
      background: _swipeBackground(
        theme,
        icon: Icons.chat_bubble_outline,
        label: tr('Message'),
        color: Colors.green,
        fromLeft: true,
      ),
      secondaryBackground: _swipeBackground(
        theme,
        icon: Icons.call_outlined,
        label: tr('Call'),
        color: theme.colorScheme.primary,
        fromLeft: false,
      ),
      confirmDismiss: (direction) async {
        // Fire the action, then snap back — the tile is never dismissed.
        if (direction == DismissDirection.startToEnd) {
          _handleMessageConsultant(context, consultant);
        } else {
          _handleCallConsultant(context, consultant);
        }
        return false;
      },
      child: _consultantListTile(context, consultant, theme, subtitle),
    );
  }

  Widget _swipeBackground(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
    required bool fromLeft,
  }) {
    return Container(
      color: color,
      alignment: fromLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (fromLeft) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ] else ...[
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white, size: 20),
          ],
        ],
      ),
    );
  }

  Widget _consultantListTile(BuildContext context, Consultant consultant,
      ThemeData theme, String subtitle) {
    return ListTile(
      key: ValueKey('consultant_${consultant.id}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () {
        Get.toNamed(
          '/consultant-detail',
          arguments: {'consultant': consultant},
        );
      },
      leading: Stack(
        children: [
          ProfileAvatar(
            imageUrl: consultant.userDetails.profilePicture,
            fallbackText: consultant.userDetails.fullName,
            radius: 24,
          ),
          if (consultant.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              consultant.userDetails.fullName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (consultant.averageRating > 0) ...[
            const SizedBox(width: 6),
            Icon(Icons.star, size: 13, color: Colors.amber.shade700),
            const SizedBox(width: 2),
            Text(
              consultant.averageRating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withOpacity(0.55),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionIcon(
            theme,
            icon: Icons.chat_bubble_outline,
            tooltip: tr('Message'),
            onTap: () => _handleMessageConsultant(context, consultant),
          ),
          if (consultant.offersMobileConsultations) ...[
            const SizedBox(width: 6),
            _actionIcon(
              theme,
              icon: Icons.call_outlined,
              tooltip: tr('Call'),
              onTap: () => _handleCallConsultant(context, consultant),
            ),
          ],
          // Booking is only for law firms that offer physical consultations.
          if (consultant.offersPhysicalConsultations &&
              consultant.consultantType.toLowerCase() == 'law_firm') ...[
            const SizedBox(width: 6),
            _actionIcon(
              theme,
              icon: Icons.calendar_today_outlined,
              tooltip: tr('Book'),
              onTap: () => _handleBookConsultation(context, consultant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionIcon(
    ThemeData theme, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
        ),
      ),
    );
  }

  void _handleCallConsultant(BuildContext context, Consultant consultant) {
    // Calls rely on credits/bundles only; let the CallController credit check
    // handle insufficient balance, not a subscription gate.
    Get.toNamed('/call', arguments: {'consultant': consultant});
  }

  void _handleBookConsultation(BuildContext context, Consultant consultant) {
    // Check permission to book consultation
    if (!NavigationHelper.checkPermissionOrShowUpgrade(
      context,
      PermissionFeature.bookConsultation,
    )) {
      return;
    }

    // Navigate to booking screen - Book button is for physical consultations
    Get.toNamed(
      '/book-consultation',
      arguments: {'consultant': consultant, 'bookingType': 'physical'},
    );
  }

  Future<void> _handleMessageConsultant(
    BuildContext context,
    Consultant consultant,
  ) async {
    debugPrint('📱 _handleMessageConsultant started');

    // 1. Subscription check
    if (!NavigationHelper.checkPermissionOrShowUpgrade(
      context,
      PermissionFeature.talkToLawyer,
    )) {
      debugPrint('🔒 Subscription check failed');
      return;
    }
    debugPrint('✅ Subscription check passed');

    // 2. Resolve NX ID from consultant phone
    final rawPhone = consultant.userDetails.phoneNumber ?? '';
    debugPrint('📞 Raw phone: $rawPhone');

    if (rawPhone.isEmpty) {
      Get.snackbar(
        'Cannot Message',
        'This consultant has no phone number registered.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final nxId = PhoneFormatter.formatAsNxId(rawPhone);
    final contactName = consultant.userDetails.fullName;
    final contactAvatar = consultant.userDetails.profilePicture;

    debugPrint('🆔 Formatted NX ID: $nxId');
    debugPrint('👤 Contact name: $contactName');

    // 3. Show loading while connecting
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // 4. Ensure Nexacon messaging SDK is connected
      debugPrint('🔌 isConnected: ${_messagingService.isConnected.value}');
      if (!_messagingService.isConnected.value) {
        debugPrint('🔌 Initializing messaging connection...');
        await _messagingService.initializeConnection();
        debugPrint('✅ Messaging connected');
      } else {
        debugPrint('✅ Messaging already connected');
      }

      // 5. Note: Contact management not yet implemented in nexacon_messaging
      // The contact will be added automatically when first message is sent
      debugPrint('📨 Contact $nxId will be added on first message');

      Get.back(); // dismiss loader

      // 6. Open chat room
      debugPrint('🚀 Opening chat room...');
      Get.to(
        () => ChatRoomScreen(
          contactId: nxId,
          contactName: contactName,
          contactAvatar: contactAvatar,
        ),
      );
    } catch (e) {
      Get.back(); // dismiss loader
      debugPrint('❌ Messaging init failed: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      Get.snackbar(
        'Connection Error',
        'Could not connect to messaging. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

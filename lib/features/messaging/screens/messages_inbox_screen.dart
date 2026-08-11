import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'chat_room_screen.dart';
import '../services/nexacon_messaging_service.dart';
import '../models/message.dart';
import '../../calling_booking/controllers/consultant_controller.dart';
import '../../calling_booking/models/consultant_models.dart';
import '../../../utils/phone_formatter.dart';
import '../../../services/api_service.dart';

/// Professional Messages Inbox Screen
/// Modern messaging interface with professional design
class MessagesInboxScreen extends StatefulWidget {
  const MessagesInboxScreen({super.key});

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final NexaconMessagingService _messagingService =
      Get.find<NexaconMessagingService>();
  final ConsultantController _consultantController = Get.put(
    ConsultantController(),
    tag: 'messaging_inbox',
  );

  List<Map<String, dynamic>> _contacts = [];
  bool _isLoadingContacts = false;
  Map<String, Map<String, dynamic>> _lastMessages =
      {}; // Store last message per contact

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    debugPrint('📨 MessagesInboxScreen: initState, calling _loadAllMessages');
    _loadAllMessages();
    debugPrint('📨 MessagesInboxScreen: calling fetchConsultants for fallback');
    _consultantController.fetchConsultants();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Whether a message body should appear in the inbox preview.
  /// JSON with a non-chat 'type' (call_invitation, call_response, webrtc, etc.) is hidden.
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
        if (type == 'chat' || type.isEmpty) return true;
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
        final peerPhone = peer.split('@').first.replaceAll('+', '');

        // Store last message for this peer
        if (!lastMessagesMap.containsKey(peerPhone)) {
          // Get clean, friendly message text
          String messageText = msg.body;

          // Try to unwrap JSON chat messages
          if (messageText.trim().startsWith('{')) {
            try {
              final map = jsonDecode(messageText) as Map<String, dynamic>;
              final type = map['type']?.toString() ?? '';
              if (type == 'chat' || type.isEmpty) {
                final extracted = map['message']?.toString() ??
                    map['body']?.toString() ??
                    map['content']?.toString() ??
                    '';
                if (extracted.isNotEmpty) messageText = extracted;
              }
            } catch (_) {
              // Not valid JSON, leave as-is
            }
          }

          if (messageText.contains('Incoming p2p call') ||
              messageText.contains('Incoming group call')) {
            messageText = messageText.toLowerCase().contains('type=video')
                ? '📹 Video call'
                : '📞 Voice call';
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

        // Add peer to contacts if not already there
        if (!contactsMap.containsKey(peerPhone)) {
          contactsMap[peerPhone] = {
            'nxid': peer,
            'name': 'Loading...', // Will be resolved via user search API
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

  /// Resolve phone-number contact names to real user names via the
  /// user search API (/api/v1/authentication/users/search/?q=<phone>).
  Future<void> _resolveContactNames() async {
    final apiService = Get.find<ApiService>();
    var updated = false;

    for (final contact in _contacts) {
      final nxid = contact['nxid']?.toString() ?? '';
      final phoneWithPlus = nxid.split('@').first;
      final phone = phoneWithPlus.replaceAll('+', '');
      // Also try without the Tanzania country code (255)
      final phoneNoCc = phone.startsWith('255') ? phone.substring(3) : phone;
      final currentName = contact['name']?.toString() ?? '';

      // Skip if already resolved to a real name
      if (currentName != 'Loading...' &&
          currentName != phone &&
          currentName != phoneWithPlus &&
          currentName.isNotEmpty) continue;

      Map<String, dynamic>? user;
      // Try searching with multiple phone formats
      final queries = <String>[
        phoneWithPlus,
        phone,
        if (phoneNoCc != phone) phoneNoCc,
      ];

      for (final query in queries) {
        try {
          final response = await apiService.get(
            '/api/v1/authentication/users/search/',
            queryParameters: {'q': query},
          );
          if (response.statusCode == 200) {
            final results = response.data['results'] as List?;
            if (results != null && results.isNotEmpty) {
              // Find the user whose phone_number matches our contact
              for (final r in results) {
                final rPhoneRaw =
                    (r['phone_number']?.toString() ?? '').replaceAll('+', '');
                if (rPhoneRaw.isEmpty) continue;
                // Match if phones are equal, or if one is the other
                // with/without the 255 country code
                if (rPhoneRaw == phone ||
                    rPhoneRaw == phoneNoCc ||
                    rPhoneRaw == '255$phoneNoCc' ||
                    '255$rPhoneRaw' == phone) {
                  user = r as Map<String, dynamic>;
                  break;
                }
              }
              // If no exact phone match, take the first result
              user ??= results.first as Map<String, dynamic>;
              break;
            }
          }
        } catch (e) {
          debugPrint('⚠️ User search for "$query" failed: $e');
        }
      }

      if (user != null) {
        final firstName = user['first_name']?.toString().trim() ?? '';
        final lastName = user['last_name']?.toString().trim() ?? '';
        final fullName = user['full_name']?.toString().trim() ?? '';
        final username = user['username']?.toString().trim() ?? '';

        // Prefer full_name, then first+last, then username
        final displayName = fullName.isNotEmpty
            ? fullName
            : (firstName.isNotEmpty || lastName.isNotEmpty
                ? '$firstName $lastName'.trim()
                : username);

        if (displayName.isNotEmpty) {
          contact['name'] = displayName;
          contact['avatar'] = user['profile_picture_url'];
          updated = true;
          debugPrint('👤 Resolved $phone → $displayName');
        } else {
          contact['name'] = 'User';
          updated = true;
        }
      } else {
        // Could not resolve — show a generic name instead of phone
        contact['name'] = 'User';
        updated = true;
      }
    }

    if (updated) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          // Professional App Bar
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            automaticallyImplyLeading: true,
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0.5,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'Inbox',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: false,
          ),

          // Messages Content
          SliverToBoxAdapter(
            child: _buildMessagesList('all'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(String filter) {
    // Show actual contacts from messaging API
    if (_isLoadingContacts) {
      return const Center(child: CircularProgressIndicator());
    }

    final query = _searchController.text.toLowerCase();

    // Filter contacts based on search query
    final filtered = _contacts.where((contact) {
      if (filter == 'groups') return false; // no groups for now
      final name = (contact['name'] ?? '').toString().toLowerCase();
      final nxid = (contact['nxid'] ?? '').toString().toLowerCase();
      if (query.isNotEmpty) {
        return name.contains(query) || nxid.contains(query);
      }
      return true;
    }).toList();

    debugPrint('📨 _buildMessagesList: filtered=${filtered.length} contacts');

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 1),
      itemBuilder: (context, index) {
        final contact = filtered[index];
        final name = contact['name']?.toString() ?? 'Unknown';
        final nxid = contact['nxid']?.toString() ?? '';
        final phone = nxid.split('@').first;

        // Get last message for this contact
        final lastMsg = _lastMessages[phone];
        final lastMsgText = lastMsg?['body']?.toString() ?? '';
        final timestamp = lastMsg?['timestamp'] as int?;

        return _buildConsultantTile(
          name: name,
          phone: phone,
          avatar: contact['avatar'] as String?,
          nxId: nxid,
          lastMessage: lastMsgText,
          timestamp: timestamp,
          onTap: () => _handleMessageContact(name, nxid),
        );
      },
    );
  }

  Widget _buildConsultantTile({
    required String name,
    required String phone,
    required String? avatar,
    required String nxId,
    String? lastMessage,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: avatar != null
                      ? ClipOval(
                          child: Image.network(
                            avatar,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person, size: 28),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (timeStr.isNotEmpty)
                            Text(
                              timeStr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessage?.isNotEmpty == true
                            ? lastMessage!
                            : 'Tap to start chatting',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showComposeDialog,
            icon: const Icon(Icons.chat),
            label: const Text('Start Conversation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  void _showComposeDialog() {
    final theme = Theme.of(context);

    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Select Contact',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
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
                        const SizedBox(height: 16),
                        Text(
                          'No lawyers available',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for available lawyers.',
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
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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

  Future<void> _handleMessageConsultant(Consultant consultant) async {
    Get.back();
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

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

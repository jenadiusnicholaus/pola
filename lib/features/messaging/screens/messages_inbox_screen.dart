import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'chat_room_screen.dart';
import '../services/nexacon_messaging_service.dart';

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
  String _currentFilter = 'all';
  final NexaconMessagingService _messagingService =
      Get.find<NexaconMessagingService>();
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadContacts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      debugPrint('📨 _loadContacts started');
      debugPrint('📨 isConnected: ${_messagingService.isConnected.value}');

      // Ensure SDK is connected before fetching contacts
      if (!_messagingService.isConnected.value) {
        debugPrint('🔌 Initializing messaging connection...');
        await _messagingService.initializeConnection();
        debugPrint('✅ Messaging connected');
      }

      debugPrint('📨 Fetching contacts...');
      final contacts = await _messagingService.getContacts();
      debugPrint('✅ Received ${contacts.length} contacts');
      for (var c in contacts) {
        debugPrint('   - Contact: $c');
      }

      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading contacts: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            floating: true,
            snap: true,
            automaticallyImplyLeading: true,
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0,
            expandedHeight: _isSearching ? 130 : 70,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Messages',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _toggleSearch,
                                icon: Icon(
                                    _isSearching ? Icons.close : Icons.search),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _showComposeDialog,
                                icon: const Icon(Icons.edit_outlined),
                                style: IconButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_isSearching) ...[
                        const SizedBox(height: 12),
                        Flexible(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search conversations...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              fillColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 0),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Filter Tabs
          SliverPersistentHeader(
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor:
                    theme.colorScheme.onSurface.withValues(alpha: 0.6),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Unread'),
                  Tab(text: 'Groups'),
                ],
              ),
            ),
            pinned: true,
          ),

          // Messages Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMessagesList('all'),
                _buildMessagesList('unread'),
                _buildMessagesList('groups'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showComposeDialog,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }

  Widget _buildMessagesList(String filter) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final messages = _getMessages(filter);

    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      separatorBuilder: (context, index) => const SizedBox(height: 1),
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageTile(message);
      },
    );
  }

  Widget _buildMessageTile(Map<String, dynamic> message) {
    final theme = Theme.of(context);

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
          onTap: () => _openConversation(message),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: message['isGroup']
                          ? theme.colorScheme.secondaryContainer
                          : theme.colorScheme.primaryContainer,
                      child: message['avatar'] != null
                          ? ClipOval(
                              child: Image.network(
                                message['avatar'],
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              message['isGroup'] ? Icons.group : Icons.person,
                              color: message['isGroup']
                                  ? theme.colorScheme.onSecondaryContainer
                                  : theme.colorScheme.onPrimaryContainer,
                              size: 28,
                            ),
                    ),
                    if (message['isOnline'] && !message['isGroup'])
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 12,
                          height: 12,
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

                const SizedBox(width: 16),

                // Message Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              message['name'],
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: message['unreadCount'] > 0
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            message['time'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: message['unreadCount'] > 0
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                              fontWeight: message['unreadCount'] > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (message['isSent'])
                            Icon(
                              message['isDelivered']
                                  ? Icons.done_all
                                  : Icons.done,
                              size: 16,
                              color: message['isRead']
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                            ),
                          if (message['isSent']) const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              message['lastMessage'],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: message['unreadCount'] > 0
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                fontWeight: message['unreadCount'] > 0
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (message['unreadCount'] > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${message['unreadCount']}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
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
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMessages(String filter) {
    // Map real contacts to the expected format
    final messages = _contacts.map((contact) {
      return {
        'id': contact['nxid'] ?? contact['id'],
        'name': contact['name'] ?? 'Unknown',
        'lastMessage': contact['lastMessage'] ?? 'No messages yet',
        'time': contact['time'] ?? 'Recently',
        'unreadCount': contact['unreadCount'] ?? 0,
        'isOnline':
            contact['status'] == 'online' || contact['isOnline'] == true,
        'isGroup': contact['isGroup'] == true,
        'isSent': contact['isSent'] == true,
        'isDelivered': contact['isDelivered'] == true,
        'isRead': contact['isRead'] == true,
        'avatar': contact['avatar'],
      };
    }).toList();

    switch (filter) {
      case 'unread':
        return messages
            .where((m) => (m['unreadCount'] as int? ?? 0) > 0)
            .toList();
      case 'groups':
        return messages.where((m) => m['isGroup'] as bool? ?? false).toList();
      default:
        return messages;
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  void _openConversation(Map<String, dynamic> message) {
    Get.to(
      () => ChatRoomScreen(
        contactId: message['id'] ?? message['name'],
        contactName: message['name'],
        contactAvatar: message['avatar'],
      ),
    );
  }

  void _showComposeDialog() {
    final theme = Theme.of(context);

    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Text(
                    'New Message',
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

            // Coming Soon Content
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.message,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Compose Message',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Message composition feature is coming soon!\nYou\'ll be able to start new conversations here.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
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

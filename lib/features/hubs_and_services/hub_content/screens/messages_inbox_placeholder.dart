import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Placeholder Messages Inbox Screen
/// This demonstrates the messaging interface structure
class MessagesInboxScreen extends StatefulWidget {
  const MessagesInboxScreen({super.key});

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Messages'),
            Tab(text: 'Unread'),
            Tab(text: 'Archived'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showComposeDialog,
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMessagesList('All Messages'),
          _buildMessagesList('Unread Messages'),
          _buildMessagesList('Archived Messages'),
        ],
      ),
    );
  }

  Widget _buildMessagesList(String category) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text('Sample User ${index + 1}'),
            subtitle: const Text('This is a sample message content...'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${index + 1}h ago'),
                if (index % 3 == 0)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            onTap: () {
              Get.snackbar('Message', 'Opened message from User ${index + 1}');
            },
          ),
        );
      },
    );
  }

  void _showComposeDialog() {
    Get.snackbar('Info', 'Compose message feature will be implemented');
  }
}

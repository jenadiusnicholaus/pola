import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../hubs_and_services/hub_content/controllers/hub_content_controller.dart';
import '../../hubs_and_services/hub_content/widgets/hub_content_list.dart';
import '../../hubs_and_services/hub_content/widgets/hub_content_search.dart';
import '../../hubs_and_services/hub_content/widgets/hub_content_filter.dart';
import '../../hubs_and_services/hub_content/widgets/content_creation_fab.dart';
import '../../hubs_and_services/hub_content/models/hub_content_models.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  late HubContentController controller;
  final String hubType =
      'forum'; // Community Hub where all users interact daily

  @override
  void initState() {
    super.initState();
    // Initialize controller for Community Hub (forum)
    controller = Get.put(
      HubContentController(hubType: hubType),
      tag: 'posts_$hubType',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        controller: controller.scrollController,
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            snap: true,
            automaticallyImplyLeading: false,
            title: const Text('Community Posts'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _showSearch,
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilters,
              ),
            ],
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),

          // Community Hub Description
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.forum,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Community Forum',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Open discussions on legal topics, current affairs, and community matters.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Hub Stats
                        Obx(() => Row(
                              children: [
                                _buildStatChip(
                                  theme,
                                  Icons.article_outlined,
                                  '${controller.totalContent.value}',
                                  'Posts',
                                ),
                                const SizedBox(width: 12),
                                _buildStatChip(
                                  theme,
                                  Icons.people_outline,
                                  '${controller.activeUsers.value}',
                                  'Active',
                                ),
                              ],
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content List
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 80), // Space for FAB
            sliver: HubContentList(
              controller: controller,
              onContentTap: _handleContentTap,
            ),
          ),
        ],
      ),
      floatingActionButton: ContentCreationFAB(
        hubType: hubType,
        heroTag: 'posts_fab',
        onContentCreated: () => controller.fetchInitialContent(),
      ),
    );
  }

  Widget _buildStatChip(
      ThemeData theme, IconData icon, String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            count,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: HubContentSearchDelegate(controller),
    );
  }

  void _showFilters() {
    HubContentFilter.showComprehensiveFilter(context, controller);
  }

  void _handleContentTap(HubContentItem content) {
    // Track view when user taps to view content
    controller.trackViewOnInteraction(content, 'view');

    // Navigate to content detail/viewer screen
    // For now, we'll show a simple dialog with content details
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(content.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${content.contentType}'),
            const SizedBox(height: 8),
            Text('Description: ${content.description}'),
            const SizedBox(height: 8),
            if (content.fileUrl.isNotEmpty) Text('File: ${content.fileUrl}'),
            const SizedBox(height: 8),
            Text('Created: ${content.createdAt.toString().split(' ')[0]}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (content.fileUrl.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                // TODO: Implement file viewing/downloading
                Navigator.pop(context);
              },
              child: const Text('View File'),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Don't dispose the controller here as it might be used by other screens
    super.dispose();
  }
}

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

class _PostsScreenState extends State<PostsScreen> with WidgetsBindingObserver {
  late HubContentController controller;
  final String hubType =
      'forum'; // Community Hub where all users interact daily
  bool _hasLoadedContent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize controller for Community Hub (forum)
    // Always create fresh so fetchInitialContent fires on each visit
    if (Get.isRegistered<HubContentController>(tag: 'posts_$hubType')) {
      Get.delete<HubContentController>(tag: 'posts_$hubType');
    }
    controller = Get.put(
      HubContentController(hubType: hubType),
      tag: 'posts_$hubType',
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If the controller has no content (e.g. initial fetch failed because
    // tokens weren't ready), retry now that the user is actually looking
    // at this tab.
    if (!_hasLoadedContent &&
        controller.content.value.isEmpty &&
        !controller.isLoading.value) {
      _hasLoadedContent = true;
      controller.fetchInitialContent();
    }
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
            automaticallyImplyLeading: true,
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

    // Convert hub content to LearningMaterial format for viewer compatibility
    final material = controller.convertToLearningMaterial(content);

    // Navigate to material viewer screen
    Get.toNamed(
      '/material-viewer',
      arguments: {
        'material': material,
        'source': hubType,
      },
    );
  }
}

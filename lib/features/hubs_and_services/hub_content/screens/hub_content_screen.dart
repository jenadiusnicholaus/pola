import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/hub_content_controller.dart';
import '../widgets/hub_content_list.dart';
import '../widgets/hub_content_search.dart';
import '../widgets/hub_content_filter.dart';
import '../widgets/content_creation_fab.dart';
import '../utils/user_role_manager.dart';

class HubContentScreen extends StatefulWidget {
  const HubContentScreen({super.key});

  @override
  State<HubContentScreen> createState() => _HubContentScreenState();
}

class _HubContentScreenState extends State<HubContentScreen> {
  late String hubType;
  late String hubTitle;
  late HubContentController controller;

  @override
  void initState() {
    super.initState();

    // Get hub type from route arguments or route name
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    debugPrint('🎯 Route arguments: $args');

    hubType = args['hubType'] ?? _getHubTypeFromRoute();
    hubTitle = _getHubTitle(hubType);

    debugPrint('🏛️ Final hub setup: type="$hubType", title="$hubTitle"');

    // Initialize controller with hub type
    controller = Get.put(
      HubContentController(hubType: hubType),
      tag: hubType,
    );
  }

  String _getHubTypeFromRoute() {
    final currentRoute = Get.currentRoute;
    debugPrint('🛣️ Current route: "$currentRoute"');

    if (currentRoute.contains('advocates')) {
      debugPrint('✅ Detected advocates hub from route');
      return 'advocates';
    }
    if (currentRoute.contains('students')) {
      debugPrint('✅ Detected students hub from route');
      return 'students';
    }
    if (currentRoute.contains('forum')) {
      debugPrint('✅ Detected forum hub from route');
      return 'forum';
    }

    debugPrint('⚠️ No specific hub detected, defaulting to forum');
    return 'forum'; // Default fallback
  }

  String _getHubTitle(String type) {
    switch (type) {
      case 'advocates':
        return 'Advocates Hub';
      case 'students':
        return 'Students Hub';
      case 'forum':
        return 'Community Forum';
      case 'legal_ed':
        return 'Legal Education';
      default:
        return 'Hub Content';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(hubTitle),
                if (UserRoleManager.isAdmin())
                  Text(
                    '👑 Admin View',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
            expandedHeight: 200,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            floating: false,
            pinned: true,
            stretch: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _showSearch(),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilters(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Text(
                        _getHubDescription(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
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
                              const SizedBox(width: 12),
                              _buildStatChip(
                                theme,
                                Icons.trending_up,
                                '${controller.trendingContent.length}',
                                'Trending',
                              ),
                            ],
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content List with proper spacing
          SliverPadding(
            padding: const EdgeInsets.only(top: 24, bottom: 16),
            sliver: HubContentList(
              controller: controller,
              onContentTap: (content) => _navigateToMaterialViewer(content),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(theme),
    );
  }

  Widget _buildStatChip(
      ThemeData theme, IconData icon, String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            count,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(ThemeData theme) {
    // Only show create button for certain hub types (exclude legal_ed)
    if (!['forum', 'students', 'advocates'].contains(hubType)) {
      return null;
    }

    // Use the new content creation menu FAB
    return ContentCreationMenu(
      hubType: hubType,
      heroTag: 'hub_content_fab_$hubType',
      onContentCreated: () {
        // Refresh hub content after successful creation
        print('🔄 HubContentScreen: onContentCreated callback triggered');
        print('🔄 Controller instance: $controller');
        controller.refreshContent();
      },
    );
  }

  String _getHubDescription() {
    switch (hubType) {
      case 'advocates':
        return 'Connect with fellow advocates, share experiences, and collaborate on legal matters.';
      case 'students':
        return 'Join the student community for study materials, discussions, and academic support.';
      case 'forum':
        return 'Open discussions on legal topics, current affairs, and community matters.';
      default:
        return 'Explore content and connect with the community.';
    }
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

  void _navigateToMaterialViewer(dynamic content) {
    // Track view when user taps to view content
    controller.trackViewOnInteraction(content, 'view');

    // Convert hub content to LearningMaterial format for viewer compatibility
    final material = controller.convertToLearningMaterial(content);

    Get.toNamed(
      '/material-viewer',
      arguments: {
        'material': material,
        'source': hubType,
      },
    );
  }

  @override
  void dispose() {
    // Remove controller when leaving the screen
    Get.delete<HubContentController>(tag: hubType);
    super.dispose();
  }
}

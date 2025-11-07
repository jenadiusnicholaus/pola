import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/hub_content_controller.dart';
import '../models/hub_content_models.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        centerTitle: true,
      ),
      body: _BookmarksContent(),
    );
  }
}

class _BookmarksContent extends StatefulWidget {
  @override
  State<_BookmarksContent> createState() => _BookmarksContentState();
}

class _BookmarksContentState extends State<_BookmarksContent> {
  late Map<String, HubContentController> controllers;
  bool _hasFetched = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Get all available hub controllers to fetch bookmarks from all hubs
    final hubTypes = ['advocates', 'students', 'forum', 'legal_ed'];
    controllers = {};

    // Initialize controllers for each hub type. If a controller doesn't exist
    // yet, create it so we can fetch the user's bookmarked content.
    for (final hubType in hubTypes) {
      HubContentController controller;
      try {
        controller = Get.find<HubContentController>(tag: hubType);
      } catch (e) {
        // Create controller lazily; it's lightweight and will fetch when asked
        controller =
            Get.put(HubContentController(hubType: hubType), tag: hubType);
      }
      controllers[hubType] = controller;
    }

    // Fetch bookmarked content once after initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasFetched) {
        _hasFetched = true;
        _fetchAllBookmarks();
      }
    });
  }

  Future<void> _fetchAllBookmarks() async {
    for (final c in controllers.values) {
      try {
        await c.fetchBookmarkedContent(page: 1);
      } catch (e) {
        // Individual controller errors are handled internally
        debugPrint('Failed to fetch bookmarks for ${c.hubType}: $e');
      }
    }
  }

  void _removeBookmarkWithUndo(BuildContext context, BookmarkedItem bookmark) {
    // Remove the bookmark
    bookmark.controller.toggleBookmark(bookmark.content);

    // Show undo snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bookmark removed'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            // Add the bookmark back
            bookmark.controller.toggleBookmark(bookmark.content);
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchAllBookmarks,
      child: CustomScrollView(
        slivers: [
          // Header with total bookmarks count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Obx(() {
                int totalBookmarks = 0;
                for (final controller in controllers.values) {
                  totalBookmarks += controller.bookmarkedContent.length;
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.bookmark,
                          color: Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Bookmarks',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              '$totalBookmarks items saved',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (totalBookmarks > 0)
                          TextButton(
                            onPressed: () => _fetchAllBookmarks(),
                            child: const Text('Refresh'),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // Bookmarks content
          Obx(() {
            // Combine all bookmarked content from different hubs
            final List<BookmarkedItem> allBookmarks = [];

            for (final entry in controllers.entries) {
              final hubType = entry.key;
              final controller = entry.value;

              for (final content in controller.bookmarkedContent) {
                allBookmarks.add(BookmarkedItem(
                  content: content,
                  hubType: hubType,
                  controller: controller,
                ));
              }
            }

            // Sort by most recently bookmarked (assuming updatedAt reflects bookmark time)
            allBookmarks.sort(
                (a, b) => b.content.updatedAt.compareTo(a.content.updatedAt));

            if (allBookmarks.isEmpty) {
              return SliverFillRemaining(
                child: _buildEmptyState(context),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final bookmark = allBookmarks[index];
                  return _BookmarkCard(
                    bookmark: bookmark,
                    onTap: () => _navigateToContent(bookmark),
                    onRemoveBookmark: () =>
                        _removeBookmarkWithUndo(context, bookmark),
                  );
                },
                childCount: allBookmarks.length,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No bookmarks yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start bookmarking content to see it here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _fetchAllBookmarks(),
            child: const Text('Refresh Bookmarks'),
          ),
        ],
      ),
    );
  }

  void _navigateToContent(BookmarkedItem bookmark) {
    try {
      // Track view when user taps to view bookmarked content
      bookmark.controller.trackViewOnInteraction(bookmark.content, 'view');

      // Convert hub content to LearningMaterial format for viewer compatibility
      final material =
          bookmark.controller.convertToLearningMaterial(bookmark.content);

      Get.toNamed(
        '/material-viewer',
        arguments: {
          'material': material,
          'source': bookmark.hubType,
        },
      );
    } catch (e) {
      print('❌ Error navigating to content: $e');
      Get.snackbar(
        'Navigation Error',
        'Unable to open this content. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

class BookmarkedItem {
  final HubContentItem content;
  final String hubType;
  final HubContentController controller;

  BookmarkedItem({
    required this.content,
    required this.hubType,
    required this.controller,
  });
}

class _BookmarkCard extends StatelessWidget {
  final BookmarkedItem bookmark;
  final VoidCallback onTap;
  final VoidCallback? onRemoveBookmark;

  const _BookmarkCard({
    required this.bookmark,
    required this.onTap,
    this.onRemoveBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = bookmark.content;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with hub type and actions
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getHubColor(bookmark.hubType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getHubDisplayName(bookmark.hubType),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getHubColor(bookmark.hubType),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.bookmark, color: Colors.orange),
                    onPressed: onRemoveBookmark ??
                        () => bookmark.controller
                            .toggleBookmark(bookmark.content),
                    tooltip: 'Remove bookmark',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Content title
              Text(
                content.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (content.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  content.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Stats and metadata
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${content.likesCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.comment_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${content.commentsCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _getTimeAgo(content.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getHubColor(String hubType) {
    switch (hubType) {
      case 'advocates':
        return Colors.blue;
      case 'students':
        return Colors.green;
      case 'forum':
        return Colors.purple;
      case 'legal_ed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getHubDisplayName(String hubType) {
    switch (hubType) {
      case 'advocates':
        return 'Advocates';
      case 'students':
        return 'Students';
      case 'forum':
        return 'Forum';
      case 'legal_ed':
        return 'Legal Education';
      default:
        return hubType.toUpperCase();
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

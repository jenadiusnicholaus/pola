import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/hub_content_models.dart';
import '../controllers/hub_content_controller.dart';
import '../utils/mention_parser.dart';
import 'enhanced_comment_thread.dart';
import 'mention_text_field.dart';
import '../../../profile/services/profile_service.dart';

class HubThreadCard extends StatefulWidget {
  final HubContentItem content;
  final HubContentController controller;
  final Function(HubContentItem) onContentTap;

  const HubThreadCard({
    super.key,
    required this.content,
    required this.controller,
    required this.onContentTap,
  });

  @override
  State<HubThreadCard> createState() => _HubThreadCardState();
}

class _HubThreadCardState extends State<HubThreadCard> {
  bool _isDescriptionExpanded = false;
  bool _hasTrackedView = false;

  /// Extract unique users from existing comments to use as fallback suggestions
  List<MentionSuggestion> _getFallbackUsersFromComments() {
    final comments = widget.controller.contentComments[widget.content.id] ??
        <HubComment>[].obs;
    final Map<int, MentionSuggestion> uniqueUsers = {};

    for (final comment in comments) {
      final author = comment.author;
      if (!uniqueUsers.containsKey(author.id) && author.username.isNotEmpty) {
        uniqueUsers[author.id] = MentionSuggestion(
          userId: author.id,
          username: author.username,
          displayName:
              author.fullName.isNotEmpty ? author.fullName : author.username,
          avatarUrl: author.avatarUrl,
        );
      }
    }

    return uniqueUsers.values.toList();
  }

  /// Build the current user's avatar for the comment input
  Widget _buildUserAvatar(ThemeData theme) {
    final profileService = Get.find<ProfileService>();
    return Obx(() {
      final profile = profileService.currentProfile;
      final profilePicture = profile?.profilePicture;
      final firstName = profile?.firstName ?? '';
      
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.primaryContainer,
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: profilePicture != null && profilePicture.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  profilePicture,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                ),
              )
            : Center(
                child: Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    // Track view when widget is first displayed
    _trackInitialView();
  }

  void _trackInitialView() {
    if (!_hasTrackedView) {
      _hasTrackedView = true;
      // Delay the view tracking slightly to ensure the widget is fully rendered
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          widget.controller.trackViewOnVisible(widget.content);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instagram-style: Full-width image at the very top (if present)
            if (widget.content.isImage &&
                widget.content.fileUrl.isNotEmpty) ...[
              _buildInstagramImage(theme),
            ],

            // Header with author info
            _buildThreadHeader(theme),

            // Content (title, description with read more) - Instagram style
            _buildInstagramContent(theme),

            // Thread Actions
            _buildThreadActions(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundImage:
                widget.content.uploader.avatarUrl?.isNotEmpty == true
                    ? NetworkImage(widget.content.uploader.avatarUrl!)
                    : null,
            child: widget.content.uploader.avatarUrl?.isEmpty != false
                ? Text(
                    widget.content.uploader.fullName.isNotEmpty
                        ? widget.content.uploader.fullName[0].toUpperCase()
                        : 'U',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Author Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      flex: 2,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.content.uploader.fullName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (widget.content.uploader.isVerified) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: Colors.green,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildContentTypeChip(theme),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimeAgo(widget.content.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          // More options
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showContentOptions(),
          ),
        ],
      ),
    );
  }

  Widget _buildContentTypeChip(ThemeData theme) {
    final config = ContentTypeConfig.getByKey(widget.content.contentType);
    final displayText =
        config?.displayName ?? widget.content.contentType.toUpperCase();

    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: config?.backgroundColor ?? theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          displayText,
          style: theme.textTheme.labelSmall?.copyWith(
            color: config?.textColor ?? theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildThreadContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          if (widget.content.title.isNotEmpty)
            Text(
              widget.content.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),

          // Content/Description
          if (widget.content.content.isNotEmpty ||
              widget.content.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildExpandableDescription(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildThreadActions(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Like button
          Obx(() {
            // Get current content state from all possible lists
            HubContentItem currentContent = widget.content;
            final allLists = [
              widget.controller.content,
              widget.controller.trendingContent,
              widget.controller.recentContent,
              widget.controller.searchResults,
              widget.controller.filteredContent,
              widget.controller.bookmarkedContent,
            ];

            for (final list in allLists) {
              try {
                final found =
                    list.firstWhere((item) => item.id == widget.content.id);
                currentContent = found;
                break; // Use the first match found
              } catch (e) {
                // Item not in this list, continue searching
              }
            }

            return _buildActionButton(
              icon: currentContent.isLiked
                  ? Icons.favorite
                  : Icons.favorite_border,
              label: '${currentContent.likesCount}',
              isActive: currentContent.isLiked,
              onTap: () => widget.controller.toggleLike(currentContent),
              theme: theme,
            );
          }),

          const SizedBox(width: 16),

          // Comments button
          Obx(() {
            // Get current content state from all possible lists
            HubContentItem currentContent = widget.content;
            final allLists = [
              widget.controller.content,
              widget.controller.trendingContent,
              widget.controller.recentContent,
              widget.controller.searchResults,
              widget.controller.filteredContent,
              widget.controller.bookmarkedContent,
            ];

            for (final list in allLists) {
              try {
                final found =
                    list.firstWhere((item) => item.id == widget.content.id);
                currentContent = found;
                break; // Use the first match found
              } catch (e) {
                // Item not in this list, continue searching
              }
            }

            return _buildActionButton(
              icon: Icons.comment_outlined,
              label: '${currentContent.commentsCount}',
              isActive: false,
              onTap: () => _showTikTokCommentsModal(context),
              theme: theme,
            );
          }),

          const SizedBox(width: 16),

          // Bookmark button
          Obx(() {
            // Get current content state from all possible lists
            HubContentItem currentContent = widget.content;
            final allLists = [
              widget.controller.content,
              widget.controller.trendingContent,
              widget.controller.recentContent,
              widget.controller.searchResults,
              widget.controller.filteredContent,
              widget.controller.bookmarkedContent,
            ];

            for (final list in allLists) {
              try {
                final found =
                    list.firstWhere((item) => item.id == widget.content.id);
                currentContent = found;
                print(
                    '🔍 HubThreadCard: Found content ${widget.content.id} in list - bookmarked: ${found.isBookmarked}, count: ${found.bookmarksCount}');
                break; // Use the first match found
              } catch (e) {
                // Item not in this list, continue searching
              }
            }

            return _buildActionButton(
              icon: currentContent.isBookmarked
                  ? Icons.bookmark
                  : Icons.bookmark_outline,
              label: '${currentContent.bookmarksCount}',
              isActive: currentContent.isBookmarked,
              onTap: () => widget.controller.toggleBookmark(currentContent),
              theme: theme,
            );
          }),

          const Spacer(),

          // Views count
          Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.content.viewsCount}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isActive = false,
    Color? activeColor,
  }) {
    // Use specific colors for different icon types when active
    final Color effectiveActiveColor =
        activeColor ?? _getActiveColorForIcon(icon, theme);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? effectiveActiveColor
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isActive
                    ? effectiveActiveColor
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: isActive ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get appropriate active color for different icon types
  Color _getActiveColorForIcon(IconData icon, ThemeData theme) {
    switch (icon) {
      case Icons.favorite:
        return Colors.red;
      case Icons.bookmark:
        return Colors.orange;
      default:
        return theme.colorScheme.primary;
    }
  }

  Widget _buildCommentsSection(ThemeData theme) {
    return Obx(() {
      final comments = widget.controller.contentComments[widget.content.id] ??
          <HubComment>[].obs;
      final isLoading =
          widget.controller.commentsLoading[widget.content.id]?.value ?? false;

      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comments Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.comment_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${comments.length} ${comments.length == 1 ? 'Comment' : 'Comments'}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  if (isLoading) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (isLoading)
              const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (comments.isEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No comments yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start the conversation',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: EnhancedCommentThread(
                      comment: comment,
                      contentId: widget.content.id,
                      depth: 0,
                      maxDepth: 2,
                      showReplies: true,
                      controller: widget.controller,
                    ),
                  );
                },
              ),
          ],
        ),
      );
    });
  }

  Widget _buildCommentFAB(ThemeData theme, BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: FloatingActionButton(
        onPressed: () => _showCommentBottomSheet(context, theme),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 8,
        child: const Icon(Icons.edit_outlined, size: 24),
      ),
    );
  }

  void _showCommentBottomSheet(BuildContext context, ThemeData theme) {
    widget.controller.initializeCommentController(widget.content.id);
    final textController =
        widget.controller.commentControllers[widget.content.id]!;
    List<int> mentionedUserIds = []; // Track mentioned user IDs

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Add a comment',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Comment input
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: MentionTextField(
                      controller: textController,
                      maxLines: 6,
                      hintText: 'Share your thoughts... Use @ to mention',
                      fallbackUsers: _getFallbackUsersFromComments(),
                      onMentionsChanged: (userIds) {
                        mentionedUserIds = userIds;
                      },
                      onSearchMentions: (query) async {
                        final results = await widget.controller
                            .searchUsersForMentions(query);
                        return results
                            .map((user) => MentionSuggestion.fromJson(user))
                            .toList();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        textController.clear();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.7)),
                      ),
                    ),
                    Obx(() {
                      final isAdding = widget.controller
                              .addingComment[widget.content.id]?.value ??
                          false;
                      return FilledButton(
                        onPressed: isAdding
                            ? null
                            : () async {
                                await widget.controller.addComment(
                                    widget.content.id,
                                    mentionedUserIds: mentionedUserIds);
                                if (context.mounted &&
                                    textController.text.isEmpty) {
                                  Navigator.pop(context);
                                }
                              },
                        child: isAdding
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Post Comment'),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTikTokCommentsModal(BuildContext context) {
    final theme = Theme.of(context);
    List<int> mentionedUserIds = []; // Track mentioned user IDs

    // Load comments when opening modal
    widget.controller.initializeCommentController(widget.content.id);
    widget.controller.loadComments(widget.content.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar and header
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    Row(
                      children: [
                        Text(
                          'Comments',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Obx(() {
                          final count = widget.controller
                                  .contentComments[widget.content.id]?.length ??
                              0;
                          return Text(
                            '$count',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),

              // Comments list (scrollable)
              Expanded(
                child: Obx(() {
                  final comments =
                      widget.controller.contentComments[widget.content.id] ??
                          <HubComment>[].obs;
                  final isLoading = widget.controller
                          .commentsLoading[widget.content.id]?.value ??
                      false;

                  if (isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (comments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No comments yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to comment!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: EnhancedCommentThread(
                          comment: comment,
                          contentId: widget.content.id,
                          depth: 0,
                          maxDepth: 2,
                          showReplies: true,
                          controller: widget.controller,
                        ),
                      );
                    },
                  );
                }),
              ),

              // Fixed comment input at bottom (Instagram/Twitter style)
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // User profile picture
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _buildUserAvatar(theme),
                      ),
                      const SizedBox(width: 12),
                      // Comment input field
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? theme.colorScheme.surfaceContainerHighest
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          child: MentionTextField(
                            controller: widget.controller
                                .commentControllers[widget.content.id]!,
                            hintText: 'Write a comment...',
                            maxLines: 3,
                            fallbackUsers: _getFallbackUsersFromComments(),
                            onMentionsChanged: (userIds) {
                              mentionedUserIds = userIds;
                            },
                            onSearchMentions: (query) async {
                              debugPrint('🔍 Searching for: "$query"');
                              final results = await widget.controller
                                  .searchUsersForMentions(query);
                              debugPrint('🔍 Found ${results.length} users');
                              return results
                                  .map((user) =>
                                      MentionSuggestion.fromJson(user))
                                  .toList();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Send button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Obx(() {
                          final isAdding = widget.controller
                                  .addingComment[widget.content.id]?.value ??
                              false;
                          return GestureDetector(
                            onTap: isAdding
                                ? null
                                : () => widget.controller.addComment(
                                      widget.content.id,
                                      mentionedUserIds: mentionedUserIds,
                                    ),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: isAdding
                                  ? const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      Icons.send_rounded,
                                      size: 18,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentItem(
    HubComment comment,
    ThemeData theme, {
    bool isReply = false,
    bool showBottomLine = false,
  }) {
    // Calculate dynamic line height based on comment content
    double dynamicLineHeight = _calculateCommentLineHeight(comment, isReply);
    return Container(
      margin: EdgeInsets.only(
        left: isReply ? 32 : 0,
        top: 8,
        bottom:
            showBottomLine ? 0 : 8, // Remove bottom margin when line continues
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with connecting line
          Column(
            children: [
              CircleAvatar(
                radius: isReply ? 14 : 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: comment.author.avatarUrl?.isNotEmpty == true
                    ? NetworkImage(comment.author.avatarUrl!)
                    : null,
                child: comment.author.avatarUrl?.isEmpty != false
                    ? Text(
                        comment.author.fullName.isNotEmpty
                            ? comment.author.fullName[0].toUpperCase()
                            : 'U',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),

              // Vertical connecting line - Dynamic height based on content
              if (showBottomLine)
                Container(
                  width: 2,
                  height:
                      dynamicLineHeight, // Dynamic height based on comment content
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? theme.colorScheme.onSurface.withOpacity(0.15)
                        : theme.colorScheme.outline.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author info row
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.author.fullName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (comment.author.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: Colors.green,
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      _formatTimeAgo(comment.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_horiz,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'reply', child: Text('Reply')),
                        const PopupMenuItem(
                            value: 'report', child: Text('Report')),
                      ],
                      onSelected: (value) =>
                          _handleCommentAction(value, comment),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Comment text bubble
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: comment.comment.isNotEmpty
                      ? RichText(
                          text: MentionParser.buildMentionTextSpan(
                            text: comment.comment,
                            baseStyle: theme.textTheme.bodyMedium!.copyWith(
                              height: 1.4,
                              color: theme.colorScheme.onSurface,
                            ),
                            mentionColor: theme.colorScheme.primary,
                          ),
                        )
                      : Text(
                          'No comment text available',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                ),

                const SizedBox(height: 8),

                // Action buttons
                Row(
                  children: [
                    _buildCommentActionButton(
                      icon: comment.userHasLiked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      label: comment.likesCount > 0
                          ? '${comment.likesCount}'
                          : 'Like',
                      isActive: comment.userHasLiked,
                      onTap: () => widget.controller
                          .toggleCommentLike(comment.id, widget.content.id),
                      theme: theme,
                    ),
                    const SizedBox(width: 16),
                    // Allow replies up to depth 1 (comment → reply → reply-to-reply, then stop)
                    if (comment.depth < 2)
                      _buildCommentActionButton(
                        icon: Icons.reply_outlined,
                        label: 'Reply',
                        onTap: () => _showReplyDialog(comment),
                        theme: theme,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isActive = false,
  }) {
    // Use red color for favorite icons when active
    final Color activeColor =
        icon == Icons.favorite ? Colors.red : theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? activeColor
                  : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isActive
                    ? activeColor
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCommentInput(ThemeData theme) {
    widget.controller.initializeCommentController(widget.content.id);
    final textController =
        widget.controller.commentControllers[widget.content.id]!;
    List<int> mentionedUserIds = []; // Track mentioned user IDs

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // User avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.person_outline,
              size: 16,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),

          const SizedBox(width: 12),

          // Comment input
          Expanded(
            child: MentionTextField(
              controller: textController,
              hintText: 'Share your thoughts... Use @ to mention',
              maxLines: 3,
              fallbackUsers: _getFallbackUsersFromComments(),
              onMentionsChanged: (userIds) {
                mentionedUserIds = userIds;
              },
              onSearchMentions: (query) async {
                final results =
                    await widget.controller.searchUsersForMentions(query);
                return results
                    .map((user) => MentionSuggestion.fromJson(user))
                    .toList();
              },
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          Obx(() {
            final isAdding =
                widget.controller.addingComment[widget.content.id]?.value ??
                    false;
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: isAdding
                    ? null
                    : () => widget.controller.addComment(
                          widget.content.id,
                          mentionedUserIds: mentionedUserIds,
                        ),
                icon: isAdding
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: theme.colorScheme.onPrimary,
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGlobalFloatingInput(ThemeData theme) {
    widget.controller.initializeCommentController(widget.content.id);
    final textController =
        widget.controller.commentControllers[widget.content.id]!;
    List<int> mentionedUserIds = []; // Track mentioned user IDs

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: 2,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, -3),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // User avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_outline,
                  size: 16,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),

              const SizedBox(width: 12),

              // Comment input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: MentionTextField(
                    controller: textController,
                    hintText: 'Share your thoughts... Use @ to mention',
                    maxLines: 3,
                    fallbackUsers: _getFallbackUsersFromComments(),
                    onMentionsChanged: (userIds) {
                      mentionedUserIds = userIds;
                    },
                    onSearchMentions: (query) async {
                      final results = await widget.controller
                          .searchUsersForMentions(query);
                      return results
                          .map((user) => MentionSuggestion.fromJson(user))
                          .toList();
                    },
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              Obx(() {
                final isAdding =
                    widget.controller.addingComment[widget.content.id]?.value ??
                        false;
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: isAdding
                        ? null
                        : () => widget.controller.addComment(
                              widget.content.id,
                              mentionedUserIds: mentionedUserIds,
                            ),
                    icon: isAdding
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            size: 18,
                            color: theme.colorScheme.onPrimary,
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingCommentInput(ThemeData theme) {
    widget.controller.initializeCommentController(widget.content.id);
    final textController =
        widget.controller.commentControllers[widget.content.id]!;
    List<int> mentionedUserIds = []; // Track mentioned user IDs

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: 2,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, -3),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // User avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_outline,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),

              const SizedBox(width: 12),

              // Comment input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: MentionTextField(
                    controller: textController,
                    hintText: 'Share your thoughts... Use @ to mention',
                    maxLines: 4,
                    fallbackUsers: _getFallbackUsersFromComments(),
                    onMentionsChanged: (userIds) {
                      mentionedUserIds = userIds;
                    },
                    onSearchMentions: (query) async {
                      final results = await widget.controller
                          .searchUsersForMentions(query);
                      return results
                          .map((user) => MentionSuggestion.fromJson(user))
                          .toList();
                    },
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              Obx(() {
                final isAdding =
                    widget.controller.addingComment[widget.content.id]?.value ??
                        false;
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: isAdding
                        ? null
                        : () => widget.controller.addComment(
                              widget.content.id,
                              mentionedUserIds: mentionedUserIds,
                            ),
                    icon: isAdding
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            color: theme.colorScheme.onPrimary,
                            size: 20,
                          ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showContentOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(widget.content.isBookmarked
                  ? Icons.bookmark
                  : Icons.bookmark_border),
              title: Text(widget.content.isBookmarked
                  ? 'Remove from bookmarks'
                  : 'Save to bookmarks'),
              onTap: () {
                Get.back();
                widget.controller.toggleBookmark(widget.content);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Report'),
              onTap: () => Get.back(),
            ),
          ],
        ),
      ),
      backgroundColor: Theme.of(Get.context!).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  void _handleCommentAction(String action, HubComment comment) {
    switch (action) {
      case 'reply':
        _showReplyDialog(comment);
        break;
      case 'report':
        Get.snackbar('Report', 'Comment reported');
        break;
    }
  }

  void _showReplyDialog(HubComment parentComment) {
    final replyController = TextEditingController();
    final replyFocusNode = FocusNode();
    final ValueNotifier<bool> isSubmitting = ValueNotifier(false);
    List<int> mentionedUserIds = []; // Track mentioned user IDs

    Get.bottomSheet(
      Container(
        height: Get.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 1.0,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(Get.context!).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Drag Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(Get.context!)
                        .colorScheme
                        .outline
                        .withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  decoration: BoxDecoration(
                    color: Theme.of(Get.context!).colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.reply,
                        color: Theme.of(Get.context!).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Reply to Comment',
                          style: Theme.of(Get.context!)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(Get.context!)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: Icon(
                          Icons.close,
                          color: Theme.of(Get.context!)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Original Comment Preview
                        Text(
                          'Replying to:',
                          style: Theme.of(Get.context!)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color:
                                    Theme.of(Get.context!).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(Get.context!)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(Get.context!)
                                  .colorScheme
                                  .outline
                                  .withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Theme.of(Get.context!)
                                        .colorScheme
                                        .primary,
                                    child: Text(
                                      parentComment.author.fullName.isNotEmpty
                                          ? parentComment.author.fullName[0]
                                              .toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        color: Theme.of(Get.context!)
                                            .colorScheme
                                            .onPrimary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      parentComment.author.fullName,
                                      style: Theme.of(Get.context!)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              RichText(
                                text: MentionParser.buildMentionTextSpan(
                                  text: parentComment.comment,
                                  baseStyle: Theme.of(Get.context!)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        color: Theme.of(Get.context!)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                  mentionColor: Theme.of(Get.context!)
                                      .colorScheme
                                      .primary,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Reply Input
                        Text(
                          'Your Reply:',
                          style: Theme.of(Get.context!)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        MentionTextField(
                          controller: replyController,
                          hintText: 'Write a reply... Use @ to mention',
                          maxLines: 5,
                          fallbackUsers: _getFallbackUsersFromComments(),
                          onMentionsChanged: (userIds) {
                            mentionedUserIds = userIds;
                          },
                          onSearchMentions: (query) async {
                            final results = await widget.controller
                                .searchUsersForMentions(query);
                            return results
                                .map((user) => MentionSuggestion.fromJson(user))
                                .toList();
                          },
                        ),

                        const SizedBox(height: 8),

                        // Character Count
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: replyController,
                          builder: (context, value, child) {
                            final currentLength = value.text.length;
                            final maxLength = 1000;
                            final isNearLimit = currentLength > maxLength * 0.8;

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Be respectful and constructive',
                                  style: Theme.of(Get.context!)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(Get.context!)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                                Text(
                                  '$currentLength/$maxLength',
                                  style: Theme.of(Get.context!)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: isNearLimit
                                            ? Theme.of(Get.context!)
                                                .colorScheme
                                                .error
                                            : Theme.of(Get.context!)
                                                .colorScheme
                                                .onSurfaceVariant,
                                        fontWeight: isNearLimit
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Container(
                  padding: EdgeInsets.fromLTRB(20, 16, 20,
                      20 + MediaQuery.of(Get.context!).padding.bottom),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(Get.context!).colorScheme.surfaceContainerLow,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(Get.context!)
                            .colorScheme
                            .outline
                            .withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: isSubmitting,
                          builder: (context, submitting, child) {
                            return ValueListenableBuilder<TextEditingValue>(
                              valueListenable: replyController,
                              builder: (context, value, child) {
                                final hasText = value.text.trim().isNotEmpty;

                                return FilledButton.icon(
                                  onPressed: hasText && !submitting
                                      ? () async {
                                          isSubmitting.value = true;
                                          try {
                                            await widget.controller.addComment(
                                              widget.content.id,
                                              parentCommentId: parentComment.id,
                                              customText:
                                                  replyController.text.trim(),
                                              mentionedUserIds:
                                                  mentionedUserIds,
                                            );
                                            Get.back();
                                            Get.snackbar(
                                              'Success',
                                              'Your reply has been posted!',
                                              snackPosition:
                                                  SnackPosition.BOTTOM,
                                              backgroundColor:
                                                  Theme.of(Get.context!)
                                                      .colorScheme
                                                      .primaryContainer,
                                              colorText: Theme.of(Get.context!)
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                              icon: Icon(
                                                Icons.check_circle,
                                                color: Theme.of(Get.context!)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            );
                                          } catch (e) {
                                            Get.snackbar(
                                              'Error',
                                              'Failed to post reply. Please try again.',
                                              snackPosition:
                                                  SnackPosition.BOTTOM,
                                              backgroundColor:
                                                  Theme.of(Get.context!)
                                                      .colorScheme
                                                      .errorContainer,
                                              colorText: Theme.of(Get.context!)
                                                  .colorScheme
                                                  .onErrorContainer,
                                              icon: Icon(
                                                Icons.error,
                                                color: Theme.of(Get.context!)
                                                    .colorScheme
                                                    .error,
                                              ),
                                            );
                                          } finally {
                                            isSubmitting.value = false;
                                          }
                                        }
                                      : null,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: submitting
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Theme.of(Get.context!)
                                                .colorScheme
                                                .onPrimary,
                                          ),
                                        )
                                      : const Icon(Icons.send, size: 18),
                                  label: Text(
                                      submitting ? 'Posting...' : 'Post Reply'),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isDismissible: false,
      enableDrag: false,
    );

    // Auto-focus after a short delay to ensure dialog is fully rendered
    Future.delayed(const Duration(milliseconds: 300), () {
      if (replyFocusNode.canRequestFocus) {
        replyFocusNode.requestFocus();
      }
    });
  }

  /// Calculate dynamic line height based on comment content and replies
  double _calculateCommentLineHeight(HubComment comment, bool isReply) {
    final commentTextLength = comment.comment.length;
    final hasReplies = comment.replies.isNotEmpty;

    // Base height (minimum line height)
    double baseHeight = isReply ? 30.0 : 40.0;

    // Calculate text height based on character count
    // Approximate: ~50 characters per line, ~20px per line
    final estimatedLines = (commentTextLength / 50).ceil();
    double textHeight = estimatedLines * 20.0;

    // Minimum text height
    if (textHeight < 20.0) textHeight = 20.0;

    // Add height for replies if this comment has them
    double repliesHeight = 0.0;
    if (hasReplies) {
      for (final reply in comment.replies) {
        // Each reply adds height (base + its text)
        final replyTextLines = (reply.comment.length / 40).ceil();
        repliesHeight +=
            40.0 + (replyTextLines * 16.0); // Slightly smaller for replies
      }
    }

    // Total height: base + text + replies + spacing
    double totalHeight = baseHeight + textHeight + repliesHeight;

    // Add spacing between comments
    if (!isReply) {
      totalHeight += 16.0; // Extra spacing for main comments
    }

    // Cap the maximum height to prevent overly long lines
    if (totalHeight > 200.0) totalHeight = 200.0;

    return totalHeight;
  }

  /// Instagram-style image display for social media posts
  Widget _buildInstagramImage(ThemeData theme) {
    return SizedBox(
      width: double.infinity, // Full width
      height: 280, // Professional Instagram post height
      child: GestureDetector(
        onTap: () {
          // Track view on content tap
          widget.controller.trackViewOnInteraction(widget.content, 'tap');
          widget.onContentTap(widget.content);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Main image with full coverage
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Image.network(
                widget.content.fileUrl,
                fit: BoxFit.cover, // Covers entire area
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image not available',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Modern gradient overlay for better text visibility
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Subtle tap indicator
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.fullscreen,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Instagram-style content with title, description and read more
  Widget _buildInstagramContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with modern Instagram typography
          Text(
            widget.content.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 19,
              height: 1.3,
              letterSpacing: -0.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Description with read more functionality
          _buildExpandableDescription(theme),

          // Non-image attachments (PDFs, etc.)
          if (widget.content.fileUrl.isNotEmpty && !widget.content.isImage) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.content.isPdf
                        ? Icons.picture_as_pdf
                        : Icons.attach_file,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.content.isPdf ? 'PDF Document' : 'Attachment',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onContentTap(widget.content),
                    child: const Text('View'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Expandable description with Instagram-style read more functionality
  Widget _buildExpandableDescription(ThemeData theme) {
    const maxLines = 3;
    const maxChars = 140;

    final description = widget.content.content.isNotEmpty
        ? widget.content.content
        : widget.content.description;
    final isLong = description.length > maxChars;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.85),
            height: 1.45,
            fontSize: 15,
          ),
          maxLines: _isDescriptionExpanded ? null : maxLines,
          overflow: _isDescriptionExpanded
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
        ),
        if (isLong) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(
                () => _isDescriptionExpanded = !_isDescriptionExpanded),
            child: Text(
              _isDescriptionExpanded ? 'Show less' : 'more',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

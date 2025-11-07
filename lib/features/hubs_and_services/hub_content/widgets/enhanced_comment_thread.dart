import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/hub_content_models.dart';
import '../controllers/hub_content_controller.dart';
import 'comment_actions_widget.dart';
import '../../legal_education/models/legal_education_models.dart';
import '../../../profile/screens/public_profile_screen.dart';

class EnhancedCommentThread extends StatefulWidget {
  final HubComment comment;
  final int contentId;
  final int depth;
  final int maxDepth;
  final bool showReplies;
  final HubContentController? controller;

  const EnhancedCommentThread({
    super.key,
    required this.comment,
    required this.contentId,
    this.depth = 0,
    this.maxDepth = 2,
    this.showReplies = true,
    this.controller,
  });

  @override
  State<EnhancedCommentThread> createState() => _EnhancedCommentThreadState();
}

class _EnhancedCommentThreadState extends State<EnhancedCommentThread> {
  late bool _showReplies;
  bool _isLoadingReplies = false;

  @override
  void initState() {
    super.initState();
    // Hide replies by default - user clicks "Show replies" to reveal them
    _showReplies = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentCard(context, theme),
        if (widget.showReplies && _showReplies) ...[
          // Debug info
          Builder(builder: (context) {
            print(
                '📋 Showing replies section for comment ${widget.comment.id}: showReplies=${widget.showReplies}, _showReplies=$_showReplies');
            return _buildRepliesSection(context, theme);
          })
        ],
      ],
    );
  }

  Widget _buildCommentCard(BuildContext context, ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(
        left: widget.depth * 16.0,
        bottom: 8.0,
      ),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: widget.depth == 0
            ? theme.colorScheme.surface
            : theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCommentHeader(theme),
          const SizedBox(height: 8),
          _buildCommentContent(theme),
          const SizedBox(height: 8),
          _buildCommentFooter(context, theme),
          // Show replies button
          if (widget.comment.replies.isNotEmpty ||
              widget.comment.repliesCount > 0)
            _buildShowRepliesButton(theme),
        ],
      ),
    );
  }

  Widget _buildCommentHeader(ThemeData theme) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _navigateToUserProfile(widget.comment.author),
          child: CircleAvatar(
            radius: 16,
            backgroundImage: widget.comment.author.avatarUrl != null
                ? NetworkImage(widget.comment.author.avatarUrl!)
                : null,
            child: widget.comment.author.avatarUrl == null
                ? Text(
                    widget.comment.author.fullName.isNotEmpty
                        ? widget.comment.author.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _navigateToUserProfile(widget.comment.author),
                child: Text(
                  widget.comment.author.fullName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Text(
                _formatTimeAgo(widget.comment.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        if (widget.comment.depth > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Reply',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: 10,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentContent(ThemeData theme) {
    return Text(
      widget.comment.comment,
      style: theme.textTheme.bodyMedium,
    );
  }

  Widget _buildCommentFooter(BuildContext context, ThemeData theme) {
    // TODO: Determine if current user is the comment owner
    final isCurrentUser = false; // This should be determined from auth service
    final hubController = widget.controller ?? Get.find<HubContentController>();

    return CommentActionsWidget(
      comment: widget.comment,
      contentId: widget.contentId,
      isCurrentUser: isCurrentUser,
      controller: hubController,
      onReply: widget.depth < widget.maxDepth
          ? () => _showReplyDialog(context)
          : null,
    );
  }

  Widget _buildShowRepliesButton(ThemeData theme) {
    final replyCount = widget.comment.repliesCount > 0
        ? widget.comment.repliesCount
        : widget.comment.replies.length;

    if (replyCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: GestureDetector(
        onTap: _isLoadingReplies
            ? null
            : () async {
                setState(() {
                  _showReplies = !_showReplies;
                });

                // Debug output
                print('🔽 Reply button pressed: _showReplies = $_showReplies');
                print(
                    '🔽 Comment ${widget.comment.id} - repliesCount: ${widget.comment.repliesCount}, replies.length: ${widget.comment.replies.length}');

                // Load more replies if needed
                if (_showReplies &&
                    widget.comment.replies.isEmpty &&
                    widget.comment.repliesCount > 0) {
                  setState(() {
                    _isLoadingReplies = true;
                  });

                  try {
                    final controller =
                        widget.controller ?? Get.find<HubContentController>();
                    await controller.loadCommentReplies(
                        widget.comment.id, widget.contentId);
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoadingReplies = false;
                      });
                    }
                  }
                }
              },
        child: Row(
          children: [
            if (_isLoadingReplies)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              )
            else
              Icon(
                _showReplies
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            const SizedBox(width: 4),
            Text(
              _isLoadingReplies
                  ? 'Loading replies...'
                  : _showReplies
                      ? 'Hide replies'
                      : 'Show $replyCount ${replyCount == 1 ? 'reply' : 'replies'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepliesSection(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // Show existing replies
        ...widget.comment.replies.map((reply) => EnhancedCommentThread(
              comment: reply,
              contentId: widget.contentId,
              depth: widget.depth + 1,
              maxDepth: widget.maxDepth,
              showReplies: widget.depth + 1 < widget.maxDepth,
              controller: widget.controller,
            )),

        // Show loading indicator if currently loading replies
        if (_isLoadingReplies && widget.comment.replies.isEmpty)
          Container(
            margin: EdgeInsets.only(left: (widget.depth + 1) * 16.0, top: 8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loading replies...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

        // Show "Load more replies" if there are more
        if (widget.comment.repliesCount > widget.comment.replies.length)
          _buildLoadMoreReplies(context, theme),

        // Show "No replies yet" message if showing replies but none exist
        if (!_isLoadingReplies &&
            widget.comment.replies.isEmpty &&
            widget.comment.repliesCount == 0)
          Container(
            margin: EdgeInsets.only(left: (widget.depth + 1) * 16.0, top: 8.0),
            child: Text(
              'No replies yet',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadMoreReplies(BuildContext context, ThemeData theme) {
    final controller = widget.controller ?? Get.find<HubContentController>();

    return Container(
      margin: EdgeInsets.only(left: (widget.depth + 1) * 16.0, top: 8.0),
      child: TextButton(
        onPressed: () =>
            controller.loadCommentReplies(widget.comment.id, widget.contentId),
        child: Text(
          'Load ${widget.comment.repliesCount - widget.comment.replies.length} more replies',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  void _showReplyDialog(BuildContext context) {
    final replyController = TextEditingController();
    final replyFocusNode = FocusNode();
    final hubController = widget.controller ?? Get.find<HubContentController>();
    final ValueNotifier<bool> isSubmitting = ValueNotifier(false);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        child: DraggableScrollableSheet(
          initialChildSize: 1.0,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
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
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.reply,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Reply to Comment',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
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
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context)
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
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    child: Text(
                                      widget.comment.author.fullName.isNotEmpty
                                          ? widget.comment.author.fullName[0]
                                              .toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        color: Theme.of(context)
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
                                      widget.comment.author.fullName,
                                      style: Theme.of(context)
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
                              Text(
                                widget.comment.comment,
                                style: Theme.of(context).textTheme.bodyMedium,
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
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: TextField(
                            controller: replyController,
                            focusNode: replyFocusNode,
                            maxLines: 5,
                            minLines: 3,
                            autofocus: true,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Write a thoughtful reply...',
                              hintStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                              counterText: '',
                            ),
                            maxLength: 1000,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Character Count and Guidelines
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                                Text(
                                  '$currentLength/$maxLength',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: isNearLimit
                                            ? Theme.of(context)
                                                .colorScheme
                                                .error
                                            : Theme.of(context)
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
                  padding: EdgeInsets.fromLTRB(
                      20, 16, 20, 20 + MediaQuery.of(context).padding.bottom),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context)
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
                          onPressed: () => Navigator.of(context).pop(),
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
                                            await hubController.addComment(
                                              widget.contentId,
                                              parentCommentId:
                                                  widget.comment.id,
                                              customText:
                                                  replyController.text.trim(),
                                            );
                                            Navigator.of(context).pop();
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: const Row(
                                                    children: [
                                                      Icon(Icons.check_circle,
                                                          color: Colors.white),
                                                      SizedBox(width: 8),
                                                      Text(
                                                          'Your reply has been posted!'),
                                                    ],
                                                  ),
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: const Row(
                                                    children: [
                                                      Icon(Icons.error,
                                                          color: Colors.white),
                                                      SizedBox(width: 8),
                                                      Text(
                                                          'Failed to post reply. Please try again.'),
                                                    ],
                                                  ),
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .error,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
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
                                            color: Theme.of(context)
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
    );

    // Auto-focus after a short delay to ensure dialog is fully rendered
    Future.delayed(const Duration(milliseconds: 300), () {
      if (replyFocusNode.canRequestFocus) {
        replyFocusNode.requestFocus();
      }
    });
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _navigateToUserProfile(UploaderInfo user) {
    Get.to(() => PublicProfileScreen(user: user));
  }
}

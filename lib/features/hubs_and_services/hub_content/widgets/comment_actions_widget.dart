import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/hub_content_models.dart';
import '../controllers/hub_content_controller.dart';

class CommentActionsWidget extends StatelessWidget {
  final HubComment comment;
  final int contentId;
  final bool isCurrentUser;
  final VoidCallback? onEdit;
  final VoidCallback? onReply;
  final HubContentController? controller;

  const CommentActionsWidget({
    super.key,
    required this.comment,
    required this.contentId,
    required this.isCurrentUser,
    this.onEdit,
    this.onReply,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = this.controller ?? Get.find<HubContentController>();

    return Row(
      children: [
        // Like button
        _buildActionButton(
          icon: comment.userHasLiked ? Icons.favorite : Icons.favorite_border,
          label: comment.likesCount > 0 ? '${comment.likesCount}' : 'Like',
          isActive: comment.userHasLiked,
          onTap: () => controller.toggleCommentLike(comment.id, contentId),
          theme: theme,
        ),
        const SizedBox(width: 16),

        // Reply button
        if (onReply != null)
          _buildActionButton(
            icon: Icons.reply_outlined,
            label: 'Reply',
            onTap: onReply,
            theme: theme,
          ),

        const SizedBox(width: 16),

        // More actions (Edit/Delete) for comment owner
        if (isCurrentUser) ...[
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit,
                        size: 16, color: theme.colorScheme.onSurface),
                    const SizedBox(width: 8),
                    Text('Edit', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete,
                        size: 16, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Text('Delete',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        )),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  if (onEdit != null) {
                    onEdit!();
                  } else {
                    _showEditCommentDialog(context, controller);
                  }
                  break;
                case 'delete':
                  _showDeleteConfirmDialog(context, controller);
                  break;
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required ThemeData theme,
    bool isActive = false,
  }) {
    // Use red color for favorite icons when active
    final Color activeColor =
        icon == Icons.favorite ? Colors.red : theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Row(
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
            ),
          ),
        ],
      ),
    );
  }

  void _showEditCommentDialog(
      BuildContext context, HubContentController controller) {
    final editController = TextEditingController(text: comment.comment);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter your comment...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                // TODO: Implement edit comment functionality in controller
                Navigator.of(context).pop();
                Get.snackbar(
                  'Info',
                  'Edit comment functionality will be implemented',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
      BuildContext context, HubContentController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text(
            'Are you sure you want to delete this comment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              controller.deleteComment(comment.id, contentId);
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

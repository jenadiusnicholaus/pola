import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/hub_content_controller.dart';
import 'enhanced_comment_thread.dart';

class EnhancedCommentsModal extends StatefulWidget {
  final int contentId;
  final String contentTitle;

  const EnhancedCommentsModal({
    super.key,
    required this.contentId,
    required this.contentTitle,
  });

  @override
  State<EnhancedCommentsModal> createState() => _EnhancedCommentsModalState();
}

class _EnhancedCommentsModalState extends State<EnhancedCommentsModal> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final controller = Get.find<HubContentController>();
      controller.loadMoreComments(widget.contentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          Expanded(child: _buildCommentsSection()),
          _buildCommentInput(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Comments',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          GetBuilder<HubContentController>(
            builder: (controller) {
              final comments =
                  controller.contentComments[widget.contentId] ?? [];
              return Text(
                '${comments.length} comments',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return GetBuilder<HubContentController>(
      builder: (controller) {
        final comments = controller.contentComments[widget.contentId] ?? [];
        final isLoading = controller.isLoadingComments.value;

        if (isLoading && comments.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (comments.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadComments(widget.contentId),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            itemCount: comments.length + (isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == comments.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final comment = comments[index];
              final controller = Get.find<HubContentController>();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: EnhancedCommentThread(
                  comment: comment,
                  contentId: widget.contentId,
                  depth: 0,
                  maxDepth: 2,
                  showReplies: true,
                  controller: controller,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.comment_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No comments yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to leave a comment!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.3),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                focusNode: _focusNode,
                maxLines: null,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GetBuilder<HubContentController>(
              builder: (controller) {
                return IconButton(
                  onPressed: controller.isAddingComment.value
                      ? null
                      : () => _submitComment(controller),
                  icon: controller.isAddingComment.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.send,
                          color: theme.colorScheme.primary,
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submitComment(HubContentController controller) async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    _commentController.clear();
    _focusNode.unfocus();

    await controller.addComment(widget.contentId, customText: commentText);
  }
}

/// Show the enhanced comments modal
void showEnhancedCommentsModal(
    BuildContext context, int contentId, String contentTitle) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => EnhancedCommentsModal(
      contentId: contentId,
      contentTitle: contentTitle,
    ),
  );
}

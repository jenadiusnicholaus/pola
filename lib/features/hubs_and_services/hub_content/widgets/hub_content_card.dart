import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import '../../../../utils/navigation_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/hub_content_models.dart';
import '../controllers/hub_content_controller.dart';
import '../../legal_education/screens/material_viewer_screen.dart';
import '../../../../services/permission_service.dart';
import '../../../../routes/app_routes.dart';

class HubContentCard extends StatelessWidget {
  final HubContentItem content;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback? onBookmark;
  final Function(double rating, String? review)? onRate;
  final VoidCallback? onView;
  final String hubType;
  final HubContentController? controller;

  const HubContentCard({
    super.key,
    required this.content,
    required this.onTap,
    required this.onLike,
    this.onBookmark,
    this.onRate,
    this.onView,
    required this.hubType,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contentColor = _getContentTypeColor(theme);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        elevation: 1.5,
        shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Author header
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.12),
                        backgroundImage: content.uploader.avatarUrl != null
                            ? NetworkImage(content.uploader.avatarUrl!)
                            : null,
                        child: content.uploader.avatarUrl == null
                            ? Text(
                                content.uploader.fullName.isNotEmpty
                                    ? content.uploader.fullName[0].toUpperCase()
                                    : 'U',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    content.uploader.fullName,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      height: 1.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (content.uploader.isVerified) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    content.uploader.userRole,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.55),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(
                                  _formatTime(content.createdAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Content type chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: contentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getContentTypeIcon(),
                              size: 12,
                              color: contentColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _getContentTypeLabel(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: contentColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Full-width image preview
                if (content.isImage && content.fileUrl.isNotEmpty)
                  _buildInstagramStyleImage(theme),

                // Video / PDF / File preview
                if (content.hasVideo ||
                    (content.fileUrl.isNotEmpty && !content.isImage))
                  _buildMediaPreview(context, theme),

                // Text content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (content.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          content.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.65),
                            height: 1.45,
                            fontSize: 14,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Action bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
                  child: _buildActionBar(context, theme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  HubContentItem _getCurrentContent() {
    if (controller == null) return content;
    // ignore: invalid_use_of_protected_member
    final allLists = [
      // ignore: invalid_use_of_protected_member
      controller!.searchResults.value,
      // ignore: invalid_use_of_protected_member
      controller!.content.value,
      // ignore: invalid_use_of_protected_member
      controller!.trendingContent.value,
      // ignore: invalid_use_of_protected_member
      controller!.recentContent.value,
      // ignore: invalid_use_of_protected_member
      controller!.filteredContent.value,
      // ignore: invalid_use_of_protected_member
      controller!.bookmarkedContent.value,
    ];
    for (final list in allLists) {
      try {
        return list.firstWhere((item) => item.id == content.id);
      } catch (_) {}
    }
    return content;
  }

  Widget _buildActionBar(BuildContext context, ThemeData theme) {
    final mutedColor = theme.colorScheme.onSurface.withOpacity(0.5);

    return Obx(() {
      final currentContent = _getCurrentContent();

      return Row(
        children: [
          _buildActionButton(
            theme: theme,
            icon: currentContent.isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_outline_rounded,
            count: currentContent.likesCount,
            color: currentContent.isLiked ? Colors.red : mutedColor,
            onTap: onLike,
          ),
          if (currentContent.commentsCount > 0)
            _buildActionButton(
              theme: theme,
              icon: Icons.chat_bubble_outline_rounded,
              count: currentContent.commentsCount,
              color: mutedColor,
            ),
          if (onBookmark != null)
            _buildActionButton(
              theme: theme,
              icon: currentContent.isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_outline_rounded,
              count: currentContent.bookmarksCount,
              color: currentContent.isBookmarked
                  ? theme.colorScheme.primary
                  : mutedColor,
              onTap: onBookmark,
            ),
          if (content.rating > 0)
            _buildActionButton(
              theme: theme,
              icon: Icons.star_rounded,
              count: content.totalRatings > 0
                  ? '${content.rating.toStringAsFixed(1)} (${content.totalRatings})'
                  : content.rating.toStringAsFixed(1),
              color: Colors.amber,
              onTap: onRate != null
                  ? () => _showRatingDialog(context, theme)
                  : null,
            ),
          if (content.downloadsCount > 0)
            _buildActionButton(
              theme: theme,
              icon: Icons.download_outlined,
              count: content.downloadsCount,
              color: mutedColor,
            ),
          Spacer(),
          // Fixed download price badge — students hub documents cost a
          // flat TZS 1,500; reading stays free.
          if (hubType == 'students' &&
              content.isDownloadable &&
              content.fileUrl.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.4),
                ),
              ),
              child: Text(
                'TZS 1,500',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          if (content.isVerified)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified,
                    size: 13,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    tr('Verified'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }

  Widget _buildActionButton({
    required ThemeData theme,
    required IconData icon,
    required dynamic count,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color:
                  onTap != null ? color.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context, ThemeData theme) {
    List<Widget> mediaWidgets = [];

    // Add video if present
    if (content.hasVideo) {
      mediaWidgets.add(_buildVideoPreview(theme));
    }

    // Add file (NOT images - they're shown at top Instagram-style)
    if (content.fileUrl.isNotEmpty && !content.isImage) {
      if (content.isPdf) {
        mediaWidgets.add(_buildPdfPreview(theme));
      } else {
        mediaWidgets.add(_buildFilePreview(theme));
      }
    }

    if (mediaWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    if (mediaWidgets.length == 1) {
      return mediaWidgets.first;
    }

    // Multiple media items - show them in a column
    return Column(
      children: mediaWidgets
          .expand((widget) => [
                widget,
                const SizedBox(height: 8),
              ])
          .take(mediaWidgets.length * 2 - 1) // Remove last SizedBox
          .toList(),
    );
  }

  /// Instagram-style image at the top of the post
  Widget _buildInstagramStyleImage(ThemeData theme) {
    return GestureDetector(
      onTap: () => _openImageViewer(Get.context!),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 1.0, // Square like Instagram
          child: Image.network(
            content.fileUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Instagram image failed: "${content.fileUrl}"');
              return Container(
                color: theme.colorScheme.surfaceContainerHighest,
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
      ),
    );
  }

  Widget _buildImagePreview(ThemeData theme) {
    return Builder(
      builder: (context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: GestureDetector(
          onTap: () => _openImageViewer(context),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Main social media style image
                  AspectRatio(
                    aspectRatio: 16 / 9, // Social media standard ratio
                    child: Image.network(
                      content.fileUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 48,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                              ),
                              SizedBox(height: 12),
                              Text(
                                tr('Image failed to load'),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  content.fileUrl,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.3),
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Gradient overlay for better badge visibility
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 80,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Image indicator badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            tr('IMAGE'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tap to expand indicator
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.zoom_out_map,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview(ThemeData theme) {
    return Builder(
      builder: (context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: GestureDetector(
          onTap: () => _openVideoPlayer(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  Image.network(
                    content.videoThumbnailUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.video_library,
                        size: 40,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 2),
                          Text(
                            tr('VIDEO'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfPreview(ThemeData theme) {
    return Builder(
      builder: (context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PDF Document',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Click "View" to open document',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openPdfViewer(context),
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('View Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFileIcon(),
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'File Attachment',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _openImageViewer(BuildContext context) {
    // Track view when user opens image viewer
    onView?.call();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Image.network(
                    content.fileUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.error,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openVideoPlayer(BuildContext context) async {
    // Track view when user opens video player
    onView?.call();

    final Uri videoUri = Uri.parse(content.videoUrl);
    if (await canLaunchUrl(videoUri)) {
      await launchUrl(videoUri, mode: LaunchMode.externalApplication);
    } else {
      NavigationHelper.showSafeSnackbar(
        title: tr('Error'),
        message: 'Cannot open video URL',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _openPdfViewer(BuildContext context) {
    // Check permission for legal education content
    if (hubType == 'legal_ed') {
      try {
        final permissionService = Get.find<PermissionService>();
        if (!permissionService.canReadLegalEducation) {
          _showLimitReachedDialog(context, permissionService);
          return;
        }
      } catch (e) {
        debugPrint('⚠️ Permission check failed: $e');
      }
    }

    // Navigate to material viewer for PDF preview
    Get.to(
      () => const MaterialViewerScreen(),
      arguments: {
        'material': content.toLearningMaterial(),
      },
    );
  }

  void _showLimitReachedDialog(
      BuildContext context, PermissionService permissionService) {
    final theme = Theme.of(context);
    final isTrial = permissionService.isTrialSubscription;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: theme.colorScheme.error,
              size: 28,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                isTrial ? 'Trial Limit Reached' : 'Reading Limit Reached',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTrial
                  ? 'You have used all ${permissionService.legalEducationLimit} free reads available in your trial period.'
                  : 'You have reached your legal education reading limit for this period.',
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upgrade to Premium for unlimited access to all legal education materials!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              tr('Later'),
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Get.toNamed(AppRoutes.subscriptionPlans);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: Text(tr('Upgrade Now')),
          ),
        ],
      ),
    );
  }

  Color _getContentTypeColor(ThemeData theme) {
    final config = ContentTypeConfig.getByKey(content.contentType);
    return config?.backgroundColor ?? theme.colorScheme.primary;
  }

  String _getContentTypeLabel() {
    final config = ContentTypeConfig.getByKey(content.contentType);
    return config?.displayName ?? content.contentType.toUpperCase();
  }

  IconData _getContentTypeIcon() {
    if (content.isImage) return Icons.image_outlined;
    if (content.hasVideo) return Icons.play_circle_outline;
    if (content.isPdf) return Icons.picture_as_pdf_outlined;
    if (content.fileUrl.isNotEmpty) return Icons.attach_file_outlined;
    return Icons.article_outlined;
  }

  IconData _getFileIcon() {
    if (content.fileUrl.isEmpty) return Icons.attach_file;

    final fileName = content.fileUrl.toLowerCase();
    if (fileName.contains('.pdf')) return Icons.picture_as_pdf;
    if (fileName.contains('.doc') || fileName.contains('.docx'))
      return Icons.description;
    if (fileName.contains('.xls') || fileName.contains('.xlsx'))
      return Icons.table_chart;
    if (fileName.contains('.ppt') || fileName.contains('.pptx'))
      return Icons.slideshow;
    if (fileName.contains('.jpg') ||
        fileName.contains('.jpeg') ||
        fileName.contains('.png')) return Icons.image;

    return Icons.attach_file;
  }

  String _formatTime(DateTime dateTime) {
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

  void _showRatingDialog(BuildContext context, ThemeData theme) {
    if (onRate == null) return;

    double selectedRating = 0;
    String reviewText = '';

    Get.dialog(
      AlertDialog(
        title: Text('Rate "${content.title}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Star rating
            StatefulBuilder(
              builder: (context, setState) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setState(() {
                          selectedRating = (index + 1).toDouble();
                        });
                      },
                      icon: Icon(
                        index < selectedRating
                            ? Icons.star
                            : Icons.star_outline,
                        color: Colors.amber,
                        size: 32,
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 16),
            // Review text field
            TextField(
              onChanged: (value) => reviewText = value,
              decoration: const InputDecoration(
                hintText: 'Write a review (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: selectedRating > 0
                ? () {
                    Get.back();
                    onRate!(selectedRating,
                        reviewText.isNotEmpty ? reviewText : null);
                  }
                : null,
            child: Text(tr('Rate')),
          ),
        ],
      ),
    );
  }
}

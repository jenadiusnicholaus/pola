import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/hub_content_models.dart';
import '../controllers/hub_content_controller.dart';
import '../../legal_education/screens/material_viewer_screen.dart';
import '../../../../services/permission_service.dart';

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

    // Debug: Check if this content should show media
    debugPrint('🔍 Content Card: "${content.title}"');
    debugPrint('   ID: ${content.id}');
    debugPrint('   MediaType: "${content.mediaType}"');
    debugPrint('   FileURL: "${content.fileUrl}"');
    debugPrint('   VideoURL: "${content.videoUrl}"');
    debugPrint('   IsImage: ${content.isImage}');
    debugPrint('   FileExtension: "${content.fileExtension}"');
    debugPrint('   HasVideo: ${content.hasVideo}');
    debugPrint(
        '   Will show Instagram image: ${content.isImage && content.fileUrl.isNotEmpty}');
    debugPrint(
        '   Will show attachment: ${content.hasVideo || (content.fileUrl.isNotEmpty && !content.isImage)}');

    // Debug for image files
    if (content.fileUrl.isNotEmpty) {
      debugPrint('🎯 FILE FOUND! ID: ${content.id}');
      debugPrint('   URL: "${content.fileUrl}"');
      debugPrint('   Extension: "${content.fileExtension}"');
      debugPrint('   Is it an image? ${content.isImage}');
      if (content.isImage) {
        debugPrint('   ✅ Should show INSTAGRAM STYLE at top');
      } else {
        debugPrint('   📎 Should show ATTACHMENT STYLE');
      }
    }

    // Special debug for ID 226 (the jpg test case)
    if (content.id == 226) {
      debugPrint('🔥 SPECIAL DEBUG FOR ID 226:');
      debugPrint('   Full URL: "${content.fileUrl}"');
      debugPrint('   URL ends with .jpg? ${content.fileUrl.endsWith('.jpg')}');
      debugPrint('   fileExtension getter: "${content.fileExtension}"');
      debugPrint('   isImage getter: ${content.isImage}');
      debugPrint(
          '   Should see Instagram image: ${content.isImage && content.fileUrl.isNotEmpty}');
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with author info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          theme.colorScheme.primary.withOpacity(0.1),
                      backgroundImage: content.uploader.avatarUrl != null
                          ? NetworkImage(content.uploader.avatarUrl!)
                          : null,
                      child: content.uploader.avatarUrl == null
                          ? Text(
                              content.uploader.fullName.isNotEmpty
                                  ? content.uploader.fullName[0].toUpperCase()
                                  : 'U',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
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
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (content.uploader.isVerified) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Colors.green,
                                ),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                content.uploader.userRole,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                              Text(
                                ' • ${_formatTime(content.createdAt)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Content type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getContentTypeColor(theme).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getContentTypeLabel(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getContentTypeColor(theme),
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Instagram-style Image Display (at top, before title)
                if (content.isImage && content.fileUrl.isNotEmpty) ...[
                  // Debug indicator to confirm this section is working
                  Container(
                    padding: const EdgeInsets.all(4),
                    color: Colors.green,
                    child: Text(
                      '📸 INSTAGRAM MODE: ${content.id}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  _buildInstagramStyleImage(theme),
                  const SizedBox(height: 16),
                ] else if (content.fileUrl.isNotEmpty) ...[
                  // Debug indicator for non-images
                  Container(
                    padding: const EdgeInsets.all(4),
                    color: Colors.orange,
                    child: Text(
                      '📎 ATTACHMENT MODE: ${content.id} (${content.fileExtension})',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Content title
                Text(
                  content.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Content description
                if (content.description.isNotEmpty) ...[
                  Text(
                    content.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],

                // Thumbnail placeholder (could be added later when backend supports it)
                // For now, we'll show content type icon for visual variety

                // Media Display (Videos, PDFs, Files - NOT Images, they're at top)
                if (content.hasVideo ||
                    (content.fileUrl.isNotEmpty && !content.isImage)) ...[
                  _buildMediaPreview(context, theme),
                  const SizedBox(height: 12),
                ],

                // Actions and stats
                Row(
                  children: [
                    // Like button
                    Obx(() {
                      // Get current content state from controller if available
                      HubContentItem currentContent = content;
                      if (controller != null) {
                        // Check all possible lists for the most up-to-date version
                        final allLists = [
                          controller!.searchResults,
                          controller!.content,
                          controller!.trendingContent,
                          controller!.recentContent,
                          controller!.filteredContent,
                          controller!.bookmarkedContent,
                        ];

                        for (final list in allLists) {
                          try {
                            final found = list
                                .firstWhere((item) => item.id == content.id);
                            currentContent = found;
                            break; // Use the first match found
                          } catch (e) {
                            // Item not in this list, continue searching
                          }
                        }
                      }

                      return InkWell(
                        onTap: onLike,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                currentContent.isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_outline,
                                size: 16,
                                color: currentContent.isLiked
                                    ? Colors.red
                                    : theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${currentContent.likesCount}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // Comments count
                    Obx(() {
                      // Get current content state from controller if available
                      HubContentItem currentContent = content;
                      if (controller != null) {
                        // Check all possible lists for the most up-to-date version
                        final allLists = [
                          controller!.searchResults,
                          controller!.content,
                          controller!.trendingContent,
                          controller!.recentContent,
                          controller!.filteredContent,
                          controller!.bookmarkedContent,
                        ];

                        for (final list in allLists) {
                          try {
                            final found = list
                                .firstWhere((item) => item.id == content.id);
                            currentContent = found;
                            break; // Use the first match found
                          } catch (e) {
                            // Item not in this list, continue searching
                          }
                        }
                      }

                      if (currentContent.commentsCount > 0) {
                        return Row(
                          children: [
                            const SizedBox(width: 16),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.comment_outlined,
                                  size: 16,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${currentContent.commentsCount}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    // Bookmark button
                    if (onBookmark != null) ...[
                      const SizedBox(width: 16),
                      Obx(() {
                        // Get current content state from controller if available
                        HubContentItem currentContent = content;
                        if (controller != null) {
                          // Check all possible lists for the most up-to-date version
                          final allLists = [
                            controller!.searchResults,
                            controller!.content,
                            controller!.trendingContent,
                            controller!.recentContent,
                            controller!.filteredContent,
                            controller!.bookmarkedContent,
                          ];

                          for (final list in allLists) {
                            try {
                              final found = list
                                  .firstWhere((item) => item.id == content.id);
                              currentContent = found;
                              print(
                                  '🔍 HubContentCard: Found content ${content.id} in list - bookmarked: ${found.isBookmarked}, count: ${found.bookmarksCount}');
                              break; // Use the first match found
                            } catch (e) {
                              // Item not in this list, continue searching
                            }
                          }
                        }

                        return InkWell(
                          onTap: onBookmark,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  currentContent.isBookmarked
                                      ? Icons.bookmark
                                      : Icons.bookmark_outline,
                                  size: 16,
                                  color: currentContent.isBookmarked
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${currentContent.bookmarksCount}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],

                    // Rating display
                    if (content.rating > 0) ...[
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: onRate != null
                            ? () => _showRatingDialog(context, theme)
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${content.rating.toStringAsFixed(1)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                              if (content.totalRatings > 0) ...[
                                Text(
                                  ' (${content.totalRatings})',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Downloads count
                    if (content.downloadsCount > 0) ...[
                      const SizedBox(width: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.download_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${content.downloadsCount}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const Spacer(),

                    // Verified badge
                    if (content.isVerified) ...[
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: Colors.green,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context, ThemeData theme) {
    debugPrint('🎬 Building media preview for "${content.title}"');
    debugPrint('   HasVideo: ${content.hasVideo}');
    debugPrint('   IsImage: ${content.isImage}');
    debugPrint('   IsPdf: ${content.isPdf}');
    debugPrint('   FileURL: "${content.fileUrl}"');
    debugPrint('   VideoURL: "${content.videoUrl}"');

    List<Widget> mediaWidgets = [];

    // Add video if present
    if (content.hasVideo) {
      debugPrint('   → Adding video preview');
      mediaWidgets.add(_buildVideoPreview(theme));
    }

    // Add file (NOT images - they're shown at top Instagram-style)
    if (content.fileUrl.isNotEmpty && !content.isImage) {
      if (content.isPdf) {
        debugPrint('   → Adding PDF preview');
        mediaWidgets.add(_buildPdfPreview(theme));
      } else {
        debugPrint('   → Adding file preview');
        mediaWidgets.add(_buildFilePreview(theme));
      }
    } else if (content.isImage) {
      debugPrint('   → Skipping image (shown at top)');
    }

    if (mediaWidgets.isEmpty) {
      debugPrint('   → No media to show');
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
    debugPrint('📸 Building Instagram-style image for: "${content.fileUrl}"');
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
    debugPrint(
        '🖼️ Building social media style image preview for URL: "${content.fileUrl}"');
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
                        if (loadingProgress == null) {
                          debugPrint(
                              '✅ Image loaded successfully: "${content.fileUrl}"');
                          return child;
                        }
                        debugPrint(
                            '⏳ Loading image: "${content.fileUrl}" - ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
                        return Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint(
                            '❌ Image failed to load: "${content.fileUrl}"');
                        debugPrint('   Error: $error');
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
                              const SizedBox(height: 12),
                              Text(
                                'Image failed to load',
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
                          const Icon(
                            Icons.image_outlined,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'IMAGE',
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
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
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
                          const Icon(
                            Icons.play_arrow,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'VIDEO',
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
      Get.snackbar(
        'Error',
        'Cannot open video URL',
        snackPosition: SnackPosition.BOTTOM,
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

  void _showLimitReachedDialog(BuildContext context, PermissionService permissionService) {
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
            const SizedBox(width: 12),
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
            const SizedBox(height: 16),
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
                  const SizedBox(width: 8),
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
              'Later',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Get.toNamed('/subscription');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('Upgrade Now'),
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
            child: const Text('Rate'),
          ),
        ],
      ),
    );
  }
}

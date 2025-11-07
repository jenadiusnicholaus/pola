// Hub content models that extend the existing LearningMaterial model
import 'package:flutter/material.dart';
import '../../legal_education/models/legal_education_models.dart';

class HubContentResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<HubContentItem> results;
  final int? activeUsers;
  final int? totalContent;

  HubContentResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
    this.activeUsers,
    this.totalContent,
  });

  factory HubContentResponse.fromJson(Map<String, dynamic> json) {
    return HubContentResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List<dynamic>? ?? [])
          .map((item) => HubContentItem.fromJson(item))
          .toList(),
      activeUsers: json['active_users'],
      totalContent: json['total_content'],
    );
  }
}

class HubContentItem {
  final int id;
  final String hubType;
  final String contentType;
  final String uploaderType;
  final String title;
  final String description;
  final String content;
  final String fileUrl;
  final String videoUrl;
  final String price;
  final String priceDisplay;
  final bool isDownloadable;
  final bool isPinned;
  final bool isLectureMaterial;
  final bool isVerified;
  final bool isLiked;
  final bool isBookmarked;
  final bool isFree;
  final bool isPurchased;
  final double rating;
  final int totalRatings;
  final int viewsCount;
  final int downloadsCount;
  final String downloadsCountDisplay;
  final int likesCount;
  final int bookmarksCount;
  final int commentsCount;
  final List<String> tags;
  final UploaderInfo uploader;
  final DateTime createdAt;
  final DateTime updatedAt;

  HubContentItem({
    required this.id,
    required this.hubType,
    required this.contentType,
    required this.uploaderType,
    required this.title,
    required this.description,
    required this.content,
    required this.fileUrl,
    required this.videoUrl,
    required this.price,
    required this.priceDisplay,
    required this.isDownloadable,
    required this.isPinned,
    required this.isLectureMaterial,
    required this.isVerified,
    required this.isLiked,
    required this.isBookmarked,
    required this.isFree,
    required this.isPurchased,
    required this.rating,
    required this.totalRatings,
    required this.viewsCount,
    required this.downloadsCount,
    required this.downloadsCountDisplay,
    required this.likesCount,
    required this.bookmarksCount,
    required this.commentsCount,
    required this.tags,
    required this.uploader,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HubContentItem.fromJson(Map<String, dynamic> json) {
    return HubContentItem(
      id: json['id'] ?? 0,
      hubType: json['hub_type']?.toString() ?? '',
      contentType: json['content_type']?.toString() ?? '',
      uploaderType: json['uploader_type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      fileUrl: json['file']?.toString() ?? json['file_url']?.toString() ?? '',
      videoUrl: json['video_url']?.toString() ?? '',
      price: json['price']?.toString() ?? '0.00',
      priceDisplay: json['price_display']?.toString() ?? 'Free',
      isDownloadable: json['is_downloadable'] ?? false,
      isPinned: json['is_pinned'] ?? false,
      isLectureMaterial: json['is_lecture_material'] ?? false,
      isVerified: json['is_verified'] ?? false,
      isLiked: json['is_liked'] ?? false,
      isBookmarked: json['is_bookmarked'] ?? false,
      isFree: json['is_free'] ?? true,
      isPurchased: json['is_purchased'] ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'] ?? 0,
      viewsCount: json['views_count'] ?? 0,
      downloadsCount: json['downloads_count'] ?? 0,
      downloadsCountDisplay:
          json['downloads_count_display']?.toString() ?? '0 downloads',
      likesCount: json['likes_count'] ?? 0,
      bookmarksCount: json['bookmarks_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((tag) => tag.toString())
          .toList(),
      uploader: UploaderInfo.fromJson(
          json['uploader_info'] ?? json['uploader'] ?? {}),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  // Create a copy with updated values
  HubContentItem copyWith({
    int? id,
    String? hubType,
    String? contentType,
    String? uploaderType,
    String? title,
    String? description,
    String? content,
    String? fileUrl,
    String? videoUrl,
    String? price,
    String? priceDisplay,
    bool? isDownloadable,
    bool? isPinned,
    bool? isLectureMaterial,
    bool? isVerified,
    bool? isLiked,
    bool? isBookmarked,
    bool? isFree,
    bool? isPurchased,
    double? rating,
    int? totalRatings,
    int? viewsCount,
    int? downloadsCount,
    String? downloadsCountDisplay,
    int? likesCount,
    int? bookmarksCount,
    int? commentsCount,
    List<String>? tags,
    UploaderInfo? uploader,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HubContentItem(
      id: id ?? this.id,
      hubType: hubType ?? this.hubType,
      contentType: contentType ?? this.contentType,
      uploaderType: uploaderType ?? this.uploaderType,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      fileUrl: fileUrl ?? this.fileUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      price: price ?? this.price,
      priceDisplay: priceDisplay ?? this.priceDisplay,
      isDownloadable: isDownloadable ?? this.isDownloadable,
      isPinned: isPinned ?? this.isPinned,
      isLectureMaterial: isLectureMaterial ?? this.isLectureMaterial,
      isVerified: isVerified ?? this.isVerified,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isFree: isFree ?? this.isFree,
      isPurchased: isPurchased ?? this.isPurchased,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      viewsCount: viewsCount ?? this.viewsCount,
      downloadsCount: downloadsCount ?? this.downloadsCount,
      downloadsCountDisplay:
          downloadsCountDisplay ?? this.downloadsCountDisplay,
      likesCount: likesCount ?? this.likesCount,
      bookmarksCount: bookmarksCount ?? this.bookmarksCount,
      commentsCount: commentsCount ?? this.commentsCount,
      tags: tags ?? this.tags,
      uploader: uploader ?? this.uploader,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to LearningMaterial for compatibility with existing viewer
  LearningMaterial toLearningMaterial() {
    return LearningMaterial(
      id: id,
      hubType: hubType,
      contentType: contentType,
      uploaderInfo: uploader,
      title: title,
      description: description,
      fileUrl: fileUrl,
      language: 'en', // Default language
      price: price,
      isDownloadable: isDownloadable,
      isLectureMaterial: isLectureMaterial,
      isVerified: isVerified,
      downloadsCount: downloadsCount,
      likesCount: likesCount,
      isLiked: isLiked,
      createdAt: createdAt,
      lastUpdated: updatedAt,
    );
  }

  // Check if material is paid
  bool get isPaid {
    final priceValue = double.tryParse(price) ?? 0.0;
    return priceValue > 0.0;
  }

  // Get file extension
  String get fileExtension {
    if (fileUrl.isEmpty) return '';
    try {
      final uri = Uri.parse(fileUrl);
      final path = uri.path;
      final lastDot = path.lastIndexOf('.');
      if (lastDot != -1) {
        final extension = path.substring(lastDot + 1).toLowerCase();
        debugPrint('🎯 FileExtension for "$fileUrl" = "$extension"');
        return extension;
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing fileUrl "$fileUrl": $e');
    }
    debugPrint('🎯 No extension found for "$fileUrl"');
    return '';
  }

  // Check if file is PDF
  bool get isPdf {
    return contentType.toLowerCase() == 'pdf' ||
        fileExtension == 'pdf' ||
        fileUrl.toLowerCase().contains('.pdf');
  }

  // Check if file is an image
  bool get isImage {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
    final hasImageExtension = imageExtensions.contains(fileExtension);
    final hasImageInUrl = fileUrl.toLowerCase().contains('image');
    final result = hasImageExtension || hasImageInUrl;

    debugPrint('🖼️ Image check for "$fileUrl":');
    debugPrint('  - Extension: "$fileExtension"');
    debugPrint('  - Has image extension: $hasImageExtension');
    debugPrint('  - Has "image" in URL: $hasImageInUrl');
    debugPrint('  - Final isImage result: $result');

    return result;
  }

  // Check if has video URL (YouTube)
  bool get hasVideo {
    return videoUrl.isNotEmpty &&
        (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be'));
  }

  // Get video thumbnail URL for YouTube videos
  String get videoThumbnailUrl {
    if (!hasVideo) return '';

    // Extract YouTube video ID and generate thumbnail
    String videoId = '';
    if (videoUrl.contains('youtube.com/watch?v=')) {
      videoId = videoUrl.split('v=')[1].split('&')[0];
    } else if (videoUrl.contains('youtu.be/')) {
      videoId = videoUrl.split('youtu.be/')[1].split('?')[0];
    }

    return videoId.isNotEmpty
        ? 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg'
        : '';
  }

  // Check what type of media this content has
  String get mediaType {
    String result;
    if (hasVideo) {
      result = 'video';
    } else if (isImage) {
      result = 'image';
    } else if (isPdf) {
      result = 'pdf';
    } else if (fileUrl.isNotEmpty) {
      result = 'file';
    } else {
      result = 'text';
    }

    debugPrint('📱 MediaType for "$title" (fileUrl: "$fileUrl"): $result');
    return result;
  }
}

// Hub configuration
class HubConfig {
  final String key;
  final String name;
  final String description;
  final bool requiresAuth;
  final List<String> allowedRoles;
  final List<String> contentTypes;

  const HubConfig({
    required this.key,
    required this.name,
    required this.description,
    required this.requiresAuth,
    required this.allowedRoles,
    required this.contentTypes,
  });

  static const List<HubConfig> allHubs = [
    HubConfig(
      key: 'advocates',
      name: 'Advocates Hub',
      description: 'Content for verified advocates',
      requiresAuth: true,
      allowedRoles: ['advocate', 'admin'],
      contentTypes: [
        'discussion',
        'article',
        'news',
        'case_study',
        'legal_update'
      ],
    ),
    HubConfig(
      key: 'students',
      name: 'Students Hub',
      description: 'Educational materials and discussions',
      requiresAuth: true,
      allowedRoles: ['student', 'lecturer', 'admin'],
      contentTypes: [
        'notes',
        'past_papers',
        'assignment',
        'discussion',
        'question',
        'tutorial'
      ],
    ),
    HubConfig(
      key: 'forum',
      name: 'Community Forum',
      description: 'Public discussions and debates',
      requiresAuth: false,
      allowedRoles: [], // Public access
      contentTypes: ['discussion', 'question', 'news', 'general'],
    ),
    HubConfig(
      key: 'legal_ed',
      name: 'Legal Education',
      description: 'Admin-curated learning materials',
      requiresAuth: false,
      allowedRoles: [], // Public access
      contentTypes: [
        'lecture',
        'article',
        'tutorial',
        'case_study',
        'legal_update'
      ],
    ),
  ];

  static HubConfig? getHubByKey(String key) {
    try {
      return allHubs.firstWhere((hub) => hub.key == key);
    } catch (e) {
      return null;
    }
  }
}

// Content type configuration
enum ContentTypeCategory {
  post, // Free content like discussions, questions
  document, // Files that can be paid or free
}

class ContentTypeConfig {
  final String key;
  final String displayName;
  final String icon;
  final ContentTypeCategory category;
  final bool canBePaid;
  final Color backgroundColor;
  final Color textColor;

  const ContentTypeConfig({
    required this.key,
    required this.displayName,
    required this.icon,
    required this.category,
    required this.canBePaid,
    required this.backgroundColor,
    required this.textColor,
  });

  static const Map<String, ContentTypeConfig> contentTypes = {
    'discussion': ContentTypeConfig(
      key: 'discussion',
      displayName: 'Discussion',
      icon: '💬',
      category: ContentTypeCategory.post,
      canBePaid: false,
      backgroundColor: Color(0xFF2196F3), // Blue
      textColor: Colors.white,
    ),
    'question': ContentTypeConfig(
      key: 'question',
      displayName: 'Question',
      icon: '❓',
      category: ContentTypeCategory.post,
      canBePaid: false,
      backgroundColor: Color(0xFF9C27B0), // Purple
      textColor: Colors.white,
    ),
    'article': ContentTypeConfig(
      key: 'article',
      displayName: 'Article',
      icon: '📄',
      category: ContentTypeCategory.post,
      canBePaid: false,
      backgroundColor: Color(0xFF607D8B), // Blue Grey
      textColor: Colors.white,
    ),
    'document': ContentTypeConfig(
      key: 'document',
      displayName: 'Document',
      icon: '📁',
      category: ContentTypeCategory.document,
      canBePaid: true,
      backgroundColor: Color(0xFFFF9800), // Orange
      textColor: Colors.white,
    ),
    'notes': ContentTypeConfig(
      key: 'notes',
      displayName: 'Study Notes',
      icon: '📝',
      category: ContentTypeCategory.document,
      canBePaid: true,
      backgroundColor: Color(0xFF4CAF50), // Green
      textColor: Colors.white,
    ),
    'past_papers': ContentTypeConfig(
      key: 'past_papers',
      displayName: 'Past Papers',
      icon: '📋',
      category: ContentTypeCategory.document,
      canBePaid: true,
      backgroundColor: Color(0xFFE91E63), // Pink
      textColor: Colors.white,
    ),
    'tutorial': ContentTypeConfig(
      key: 'tutorial',
      displayName: 'Tutorial',
      icon: '🎓',
      category: ContentTypeCategory.document,
      canBePaid: true,
      backgroundColor: Color(0xFF3F51B5), // Indigo
      textColor: Colors.white,
    ),
    'research': ContentTypeConfig(
      key: 'research',
      displayName: 'Research Paper',
      icon: '🔬',
      category: ContentTypeCategory.document,
      canBePaid: true,
      backgroundColor: Color(0xFF009688), // Teal
      textColor: Colors.white,
    ),
    'news': ContentTypeConfig(
      key: 'news',
      displayName: 'News',
      icon: '📰',
      category: ContentTypeCategory.post,
      canBePaid: false,
      backgroundColor: Color(0xFFFF5722), // Deep Orange
      textColor: Colors.white,
    ),
    'case_study': ContentTypeConfig(
      key: 'case_study',
      displayName: 'Case Study',
      icon: '⚖️',
      category: ContentTypeCategory.document,
      canBePaid: false,
      backgroundColor: Color(0xFF8BC34A), // Light Green
      textColor: Colors.white,
    ),
    'legal_update': ContentTypeConfig(
      key: 'legal_update',
      displayName: 'Legal Update',
      icon: '📝',
      category: ContentTypeCategory.post,
      canBePaid: false,
      backgroundColor: Color(0xFF673AB7), // Deep Purple
      textColor: Colors.white,
    ),
    'assignment': ContentTypeConfig(
      key: 'assignment',
      displayName: 'Assignment',
      icon: '📚',
      category: ContentTypeCategory.document,
      canBePaid: true,
      backgroundColor: Color(0xFF795548), // Brown
      textColor: Colors.white,
    ),
    'general': ContentTypeConfig(
      key: 'general',
      displayName: 'General',
      icon: '💭',
      category: ContentTypeCategory.post,
      canBePaid: false,
      backgroundColor: Color(0xFF607D8B), // Blue Grey
      textColor: Colors.white,
    ),
    'lecture': ContentTypeConfig(
      key: 'lecture',
      displayName: 'Lecture',
      icon: '🎯',
      category: ContentTypeCategory.document,
      canBePaid: false,
      backgroundColor: Color(0xFF1976D2), // Blue
      textColor: Colors.white,
    ),
  };

  static ContentTypeConfig? getByKey(String key) {
    return contentTypes[key];
  }
}

// Comment Models for Thread-like Discussion

class HubComment {
  final int id;
  final int contentId;
  final int? parentCommentId;
  final String comment;
  final UploaderInfo author;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final int repliesCount;
  final bool userHasLiked;
  final List<HubComment> replies;
  final bool isEdited;
  final bool isDeleted;
  final int depth; // For tracking nesting level (max 3)
  final String hubType; // Track which hub this comment belongs to

  HubComment({
    required this.id,
    required this.contentId,
    this.parentCommentId,
    required this.comment,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
    this.likesCount = 0,
    this.repliesCount = 0,
    this.userHasLiked = false,
    this.replies = const [],
    this.isEdited = false,
    this.isDeleted = false,
    this.depth = 0,
    this.hubType = '',
  });

  factory HubComment.fromJson(Map<String, dynamic> json) {
    return HubComment(
      id: json['id'] ?? 0,
      contentId: json['content'] ?? json['content_id'] ?? 0,
      parentCommentId: json['parent_comment'] ?? json['parent_comment_id'],
      comment:
          json['comment_text']?.toString() ?? json['comment']?.toString() ?? '',
      author: UploaderInfo.fromJson(
          json['author_info'] ?? json['author'] ?? json['user'] ?? {}),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      likesCount: json['likes_count'] ?? 0,
      repliesCount: json['replies_count'] ?? 0,
      userHasLiked: json['user_has_liked'] ?? json['is_liked'] ?? false,
      replies: (json['replies'] as List<dynamic>? ?? [])
          .map((reply) => HubComment.fromJson(reply))
          .toList(),
      isEdited: json['is_edited'] ?? false,
      isDeleted: json['is_deleted'] ?? json['is_active'] == false,
      depth: json['depth'] ?? 0,
      hubType: json['hub_type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_id': contentId,
      'parent_comment_id': parentCommentId,
      'comment_text': comment,
      'author_info': author.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'likes_count': likesCount,
      'replies_count': repliesCount,
      'user_has_liked': userHasLiked,
      'replies': replies.map((reply) => reply.toJson()).toList(),
      'is_edited': isEdited,
      'is_deleted': isDeleted,
      'depth': depth,
      'hub_type': hubType,
    };
  }

  HubComment copyWith({
    int? id,
    int? contentId,
    int? parentCommentId,
    String? comment,
    UploaderInfo? author,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    int? repliesCount,
    bool? userHasLiked,
    List<HubComment>? replies,
    bool? isEdited,
    bool? isDeleted,
    int? depth,
    String? hubType,
  }) {
    return HubComment(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      comment: comment ?? this.comment,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      repliesCount: repliesCount ?? this.repliesCount,
      userHasLiked: userHasLiked ?? this.userHasLiked,
      replies: replies ?? this.replies,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      depth: depth ?? this.depth,
      hubType: hubType ?? this.hubType,
    );
  }
}

class HubCommentsResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<HubComment> results;

  HubCommentsResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory HubCommentsResponse.fromJson(Map<String, dynamic> json) {
    return HubCommentsResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List<dynamic>? ?? [])
          .map((item) => HubComment.fromJson(item))
          .toList(),
    );
  }
}

class CreateCommentRequest {
  final int contentId;
  final String comment;
  final String hubType;
  final int? parentCommentId;

  CreateCommentRequest({
    required this.contentId,
    required this.comment,
    required this.hubType,
    this.parentCommentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': contentId,
      'comment_text': comment,
      'hub_type': hubType,
      if (parentCommentId != null) 'parent_comment': parentCommentId,
    };
  }
}

// Messaging System Models

class HubMessage {
  final int id;
  final String hubType;
  final UploaderInfo senderInfo;
  final UploaderInfo recipientInfo;
  final String subject;
  final String message;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final HubContentItem? contentReference;
  final Map<String, dynamic>? purchaseReference;
  final List<HubMessage> conversationThread;

  HubMessage({
    required this.id,
    required this.hubType,
    required this.senderInfo,
    required this.recipientInfo,
    required this.subject,
    required this.message,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    this.contentReference,
    this.purchaseReference,
    this.conversationThread = const [],
  });

  factory HubMessage.fromJson(Map<String, dynamic> json) {
    return HubMessage(
      id: json['id'] ?? 0,
      hubType: json['hub_type']?.toString() ?? '',
      senderInfo: UploaderInfo.fromJson(json['sender_info'] ?? {}),
      recipientInfo: UploaderInfo.fromJson(json['recipient_info'] ?? {}),
      subject: json['subject']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] ?? false,
      readAt:
          json['read_at'] != null ? DateTime.tryParse(json['read_at']) : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      contentReference: json['content_reference'] != null
          ? HubContentItem.fromJson(json['content_reference'])
          : null,
      purchaseReference: json['purchase_reference'],
      conversationThread: (json['conversation_thread'] as List<dynamic>? ?? [])
          .map((item) => HubMessage.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hub_type': hubType,
      'sender_info': senderInfo.toJson(),
      'recipient_info': recipientInfo.toJson(),
      'subject': subject,
      'message': message,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      if (contentReference != null)
        'content_reference': {
          'id': contentReference!.id,
          'title': contentReference!.title,
          'url': '/api/v1/hubs/content/${contentReference!.id}/'
        },
      if (purchaseReference != null) 'purchase_reference': purchaseReference,
      'conversation_thread':
          conversationThread.map((msg) => msg.toJson()).toList(),
    };
  }
}

class HubMessageResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<HubMessage> results;
  final Map<String, dynamic>? summary;

  HubMessageResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
    this.summary,
  });

  factory HubMessageResponse.fromJson(Map<String, dynamic> json) {
    return HubMessageResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List<dynamic>? ?? [])
          .map((item) => HubMessage.fromJson(item))
          .toList(),
      summary: json['summary'],
    );
  }
}

class CreateMessageRequest {
  final int recipientId;
  final String hubType;
  final String subject;
  final String message;
  final int? contentId;

  CreateMessageRequest({
    required this.recipientId,
    required this.hubType,
    required this.subject,
    required this.message,
    this.contentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'recipient_id': recipientId,
      'hub_type': hubType,
      'subject': subject,
      'message': message,
      if (contentId != null) 'content_id': contentId,
    };
  }
}

// Content Rating System Models

class ContentRating {
  final int id;
  final int contentId;
  final UploaderInfo user;
  final double rating;
  final String? review;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContentRating({
    required this.id,
    required this.contentId,
    required this.user,
    required this.rating,
    this.review,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContentRating.fromJson(Map<String, dynamic> json) {
    return ContentRating(
      id: json['id'] ?? 0,
      contentId: json['content_id'] ?? 0,
      user: UploaderInfo.fromJson(json['user_info'] ?? {}),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      review: json['review']?.toString(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_id': contentId,
      'user_info': user.toJson(),
      'rating': rating,
      'review': review,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CreateRatingRequest {
  final double rating;
  final String? review;

  CreateRatingRequest({
    required this.rating,
    this.review,
  });

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      if (review != null) 'review': review,
    };
  }
}

class ContentRatingsResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<ContentRating> results;
  final double averageRating;
  final Map<int, int> ratingDistribution; // star -> count

  ContentRatingsResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
    required this.averageRating,
    required this.ratingDistribution,
  });

  factory ContentRatingsResponse.fromJson(Map<String, dynamic> json) {
    return ContentRatingsResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List<dynamic>? ?? [])
          .map((item) => ContentRating.fromJson(item))
          .toList(),
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      ratingDistribution: Map<int, int>.from(json['rating_distribution'] ?? {}),
    );
  }
}

class RatingActionResponse {
  final String message;
  final double rating;
  final String? review;
  final double contentAverageRating;
  final int totalRatings;

  RatingActionResponse({
    required this.message,
    required this.rating,
    this.review,
    required this.contentAverageRating,
    required this.totalRatings,
  });

  factory RatingActionResponse.fromJson(Map<String, dynamic> json) {
    return RatingActionResponse(
      message: json['message'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      review: json['review'],
      contentAverageRating:
          (json['content_average_rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'] ?? 0,
    );
  }
}

// Content Analytics Models

class ContentAnalytics {
  final int viewsCount;
  final int downloadsCount;
  final int likesCount;
  final int bookmarksCount;
  final int ratingsCount;
  final double averageRating;
  final double engagementRate;
  final Map<String, int> dailyViews;

  ContentAnalytics({
    required this.viewsCount,
    required this.downloadsCount,
    required this.likesCount,
    required this.bookmarksCount,
    required this.ratingsCount,
    required this.averageRating,
    required this.engagementRate,
    required this.dailyViews,
  });

  factory ContentAnalytics.fromJson(Map<String, dynamic> json) {
    return ContentAnalytics(
      viewsCount: json['views_count'] ?? 0,
      downloadsCount: json['downloads_count'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
      bookmarksCount: json['bookmarks_count'] ?? 0,
      ratingsCount: json['ratings_count'] ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      engagementRate: (json['engagement_rate'] as num?)?.toDouble() ?? 0.0,
      dailyViews: Map<String, int>.from(json['daily_views'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'views_count': viewsCount,
      'downloads_count': downloadsCount,
      'likes_count': likesCount,
      'bookmarks_count': bookmarksCount,
      'ratings_count': ratingsCount,
      'average_rating': averageRating,
      'engagement_rate': engagementRate,
      'daily_views': dailyViews,
    };
  }
}

class ViewTrackingResponse {
  final String message;
  final int newViewsCount;

  ViewTrackingResponse({
    required this.message,
    required this.newViewsCount,
  });

  factory ViewTrackingResponse.fromJson(Map<String, dynamic> json) {
    return ViewTrackingResponse(
      message: json['message'] ?? '',
      newViewsCount: json['views_count'] ?? 0,
    );
  }
}

// Topics Management Models

class Topic {
  final int id;
  final String name;
  final String? description;
  final String hubType;
  final int materialsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Topic({
    required this.id,
    required this.name,
    this.description,
    required this.hubType,
    required this.materialsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      hubType: json['hub_type'] ?? '',
      materialsCount: json['materials_count'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'hub_type': hubType,
      'materials_count': materialsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class TopicsResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<Topic> results;

  TopicsResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory TopicsResponse.fromJson(Map<String, dynamic> json) {
    return TopicsResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List<dynamic>? ?? [])
          .map((item) => Topic.fromJson(item))
          .toList(),
    );
  }
}

// Search and Filter Models

class SearchFilters {
  final String? hubType;
  final String? search;
  final String? ordering;
  final bool? isDownloadable;
  final String? contentType;
  final int? topicId;
  final int? page;
  final int? pageSize;

  SearchFilters({
    this.hubType,
    this.search,
    this.ordering,
    this.isDownloadable,
    this.contentType,
    this.topicId,
    this.page,
    this.pageSize,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};

    if (hubType != null) params['hub_type'] = hubType;
    if (search != null && search!.isNotEmpty) params['search'] = search;
    if (ordering != null) params['ordering'] = ordering;
    if (isDownloadable != null)
      params['is_downloadable'] = isDownloadable.toString();
    if (contentType != null) params['content_type'] = contentType;
    if (topicId != null) params['topic'] = topicId.toString();
    if (page != null) params['page'] = page.toString();
    if (pageSize != null) params['page_size'] = pageSize.toString();

    return params;
  }
}

class PurchaseResponse {
  final String message;
  final String status;
  final double amount;
  final DateTime purchaseDate;
  final String paymentMethod;

  PurchaseResponse({
    required this.message,
    required this.status,
    required this.amount,
    required this.purchaseDate,
    required this.paymentMethod,
  });

  factory PurchaseResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseResponse(
      message: json['message'] ?? '',
      status: json['status'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      purchaseDate:
          DateTime.tryParse(json['purchase_date'] ?? '') ?? DateTime.now(),
      paymentMethod: json['payment_method'] ?? '',
    );
  }
}

// Content Purchase Models (for Students Hub)

class ContentPurchase {
  final int id;
  final int contentId;
  final UploaderInfo buyer;
  final double amount;
  final double uploaderShare;
  final double platformShare;
  final String status;
  final DateTime purchaseDate;

  ContentPurchase({
    required this.id,
    required this.contentId,
    required this.buyer,
    required this.amount,
    required this.uploaderShare,
    required this.platformShare,
    required this.status,
    required this.purchaseDate,
  });

  factory ContentPurchase.fromJson(Map<String, dynamic> json) {
    return ContentPurchase(
      id: json['id'] ?? 0,
      contentId: json['content_id'] ?? 0,
      buyer: UploaderInfo.fromJson(json['buyer_info'] ?? {}),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      uploaderShare: (json['uploader_share'] as num?)?.toDouble() ?? 0.0,
      platformShare: (json['platform_share'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? '',
      purchaseDate:
          DateTime.tryParse(json['purchase_date'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_id': contentId,
      'buyer_info': buyer.toJson(),
      'amount': amount,
      'uploader_share': uploaderShare,
      'platform_share': platformShare,
      'status': status,
      'purchase_date': purchaseDate.toIso8601String(),
    };
  }
}

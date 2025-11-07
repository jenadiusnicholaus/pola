import 'package:flutter/material.dart';
import '../models/hub_content_models.dart';

/// Simple test to debug image detection logic
void testImageDetection() {
  // Create test data that matches your API response
  final testJson = {
    "id": 226,
    "hub_type": "advocates",
    "content_type": "news",
    "uploader_info": {
      "id": 130,
      "email": "testadvocate@gmail.com",
      "full_name": "testadvocate testadvocated",
      "user_role": 2,
      "is_verified": true,
      "avatar_url": null
    },
    "uploader_type": "advocate",
    "title": "[TEST] Legal News: Green Inc Case Update",
    "description":
        "Professional legal content for advocates. Pattern under seem husband keep out.",
    "content": "Human meet newspaper after...",
    "file":
        "http://192.168.1.181:8000/media/learning_materials/test_image_news_6331.jpg",
    "file_size": 0,
    "video_url": null,
    "language": "en",
    "price": "0.00",
    "is_downloadable": true,
    "is_lecture_material": false,
    "is_verified_quality": false,
    "is_pinned": false,
    "views_count": 190,
    "downloads_count": 94,
    "likes_count": 0,
    "comments_count": 0,
    "bookmarks_count": 0,
    "average_rating": null,
    "ratings_count": 0,
    "is_liked": false,
    "is_bookmarked": false,
    "has_purchased": true,
    "can_download": true,
    "is_approved": true,
    "is_active": true,
    "created_at": "2025-11-05T09:35:15.683678Z",
    "updated_at": "2025-11-05T09:35:15.687724Z"
  };

  // Create the content item
  final content = HubContentItem.fromJson(testJson);

  debugPrint('=== IMAGE DETECTION TEST ===');
  debugPrint('File URL: "${content.fileUrl}"');
  debugPrint('Video URL: "${content.videoUrl}"');
  debugPrint('File Extension: "${content.fileExtension}"');
  debugPrint('Is Image: ${content.isImage}');
  debugPrint('Is PDF: ${content.isPdf}');
  debugPrint('Has Video: ${content.hasVideo}');
  debugPrint('Media Type: "${content.mediaType}"');
  debugPrint('File URL is not empty: ${content.fileUrl.isNotEmpty}');
  debugPrint(
      'Should show media: ${content.hasVideo || content.fileUrl.isNotEmpty}');
  debugPrint('===========================');
}

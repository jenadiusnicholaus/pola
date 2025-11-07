import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../hub_content/services/hub_content_service.dart';
import '../legal_education/models/legal_education_models.dart';

class HubContentController extends GetxController {
  final HubContentService _service = Get.put(HubContentService());

  // Observable variables for like functionality
  final RxBool _isLiking = false.obs;
  final RxString _error = ''.obs;

  // Getters
  bool get isLiking => _isLiking.value;
  String get error => _error.value;

  /// Toggle like status for content
  Future<bool> toggleLike(LearningMaterial material) async {
    if (_isLiking.value) return false; // Prevent multiple simultaneous requests

    try {
      _isLiking.value = true;
      _error.value = '';

      // Call the like API
      final response = await _service.toggleLike(material.id);

      // Get the updated like status from response
      final newLikeStatus = response?['is_liked'] ?? !material.isLiked;

      // Show appropriate feedback
      if (newLikeStatus) {
        Get.snackbar(
          '❤️ Liked',
          'Content added to your favorites',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );
      } else {
        Get.snackbar(
          '💔 Unliked',
          'Removed from your favorites',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.grey.withOpacity(0.8),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );
      }

      return newLikeStatus;
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to update like status: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
      return material.isLiked; // Return original state on error
    } finally {
      _isLiking.value = false;
    }
  }

  /// Get fresh content data to sync like status
  Future<LearningMaterial?> refreshContent(
      int contentId, String hubType) async {
    try {
      final hubContent = await _service.getContentById(contentId, hubType);
      return hubContent.toLearningMaterial();
    } catch (e) {
      _error.value = e.toString();
      return null;
    }
  }

  /// Clear any error state
  void clearError() {
    _error.value = '';
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../hub_content/services/hub_content_service.dart';
import '../../../utils/navigation_helper.dart';
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
        NavigationHelper.showSafeSnackbar(
          title: '❤️ Liked',
          message: 'Content added to your favorites',
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
      } else {
        NavigationHelper.showSafeSnackbar(
          title: '💔 Unliked',
          message: 'Removed from your favorites',
          backgroundColor: Colors.grey.withOpacity(0.8),
          colorText: Colors.white,
        );
      }

      return newLikeStatus;
    } catch (e) {
      _error.value = e.toString();
      NavigationHelper.showSafeSnackbar(
        title: 'Error',
        message: 'Failed to update like status: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
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

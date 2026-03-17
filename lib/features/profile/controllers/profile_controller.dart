import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../services/profile_service.dart';
import '../models/profile_models.dart';
import '../../../services/permission_service.dart';
import '../../../utils/navigation_helper.dart';

class ProfileController extends GetxController {
  final ProfileService _profileService = Get.find<ProfileService>();

  // Observable profile data
  UserProfile? get profile => _profileService.currentProfile;

  // Observable states
  bool get isLoading => _profileService.isLoading;
  String get error => _profileService.error;

  @override
  void onInit() {
    super.onInit();
    debugPrint('👤 ProfileController initialized');
    // Use microtask to avoid rebuild issues
    Future.microtask(() => _loadProfile());
  }

  /// Load profile (from cache or API)
  Future<void> _loadProfile() async {
    try {
      // Try loading from cache first for immediate display
      final cachedProfile = await _profileService.loadCachedProfile();
      if (cachedProfile != null) {
        debugPrint('� Loaded profile from cache');
      }

      // Always fetch fresh data from API as requested
      debugPrint('� Fetching fresh profile from API...');
      await _profileService.fetchProfile();
    } catch (e) {
      debugPrint('❌ Error loading profile: $e');
    }
  }

  /// Refresh profile and permissions from API
  Future<void> refreshProfile() async {
    try {
      await _profileService.refreshProfile();

      // Also refresh permissions after profile update
      try {
        final permService = Get.find<PermissionService>();
        await permService.refreshPermissions();
      } catch (e) {
        debugPrint('⚠️ Could not refresh permissions: $e');
      }

      NavigationHelper.showSafeSnackbar(
        title: 'Success',
        message: 'Profile refreshed successfully',
      );
    } catch (e) {
      NavigationHelper.showSafeSnackbar(
        title: 'Error',
        message: 'Failed to refresh profile: ${e.toString()}',
      );
    }
  }

  /// Update profile data
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      await _profileService.updateProfile(updates);
      NavigationHelper.showSafeSnackbar(
        title: 'Success',
        message: 'Profile updated successfully',
      );
    } catch (e) {
      NavigationHelper.showSafeSnackbar(
        title: 'Error',
        message: 'Failed to update profile: ${e.toString()}',
      );
    }
  }

  /// Check if user has a specific permission
  bool hasPermission(String permission) {
    return _profileService.hasPermission(permission);
  }

  /// Get display information
  Map<String, String?> getDisplayInfo() {
    return _profileService.getDisplayInfo();
  }
}

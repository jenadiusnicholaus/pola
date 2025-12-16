import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../../../services/auth_service.dart';
import '../../../services/token_storage_service.dart';
import '../../../services/permission_service.dart';
import '../../profile/services/profile_service.dart';

class HomeController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final TokenStorageService _tokenStorage = Get.find<TokenStorageService>();
  final ProfileService _profileService = Get.find<ProfileService>();
  final PermissionService _permissionService = Get.find<PermissionService>();

  // Current tab index
  final RxInt _currentIndex = 0.obs;
  int get currentIndex => _currentIndex.value;

  // Loading state for token refresh
  final RxBool _isRefreshing = false.obs;
  bool get isRefreshing => _isRefreshing.value;

  @override
  void onInit() {
    super.onInit();
    debugPrint('🏠 HomeController initialized');

    // Verify session and refresh profile on initialization
    _verifySession();
    _refreshProfileData();
  }

  @override
  void onReady() {
    super.onReady();
    // Refresh profile every time home screen is ready
    _refreshProfileData();
  }

  /// Refresh profile and permissions data
  Future<void> _refreshProfileData() async {
    try {
      debugPrint('🔄 Refreshing profile data on home screen...');
      await _profileService.fetchProfile(forceRefresh: true);
      await _permissionService.refreshPermissions();
      debugPrint('✅ Profile refreshed successfully');
    } catch (e) {
      debugPrint('❌ Error refreshing profile: $e');
    }
  }

  /// Verify the current session is still valid
  Future<void> _verifySession() async {
    final isValid = await _authService.verifySession();
    if (!isValid) {
      debugPrint('❌ Invalid session detected in HomeController');
      // AuthService will handle navigation to login
    }
  }

  /// Set the current navigation index
  void setCurrentIndex(int index) {
    _currentIndex.value = index;
    debugPrint('🏠 Navigation changed to index: $index');
  }

  /// Get user display name
  String get userDisplayName {
    final name = _tokenStorage.getUserFullName();
    return name ?? 'User';
  }

  /// Get user email
  String get userEmail {
    final email = _tokenStorage.getUserEmail();
    return email ?? 'No email';
  }

  /// Get user initials for avatar
  String get userInitials {
    final fullName = _tokenStorage.getUserFullName();
    if (fullName == null || fullName.isEmpty) {
      return 'U';
    }

    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }

    return 'U';
  }

  /// Manual token refresh
  Future<void> manualTokenRefresh() async {
    if (_isRefreshing.value) {
      debugPrint('🔄 Token refresh already in progress');
      return;
    }

    _isRefreshing.value = true;

    try {
      debugPrint('🔄 Manual token refresh initiated');

      final success = await _authService.manualRefreshToken();

      if (success) {
        Get.snackbar(
          'Session Refreshed',
          'Your session has been refreshed successfully.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        debugPrint('✅ Manual token refresh successful');
      } else {
        Get.snackbar(
          'Refresh Failed',
          'Failed to refresh session. You may need to log in again.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        debugPrint('❌ Manual token refresh failed');
      }
    } catch (e) {
      debugPrint('❌ Error during manual token refresh: $e');
      Get.snackbar(
        'Error',
        'An error occurred while refreshing your session.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      _isRefreshing.value = false;
    }
  }

  /// Logout the user
  Future<void> logout() async {
    try {
      debugPrint('👋 Logout initiated from HomeController');
      await _authService.logout();
    } catch (e) {
      debugPrint('❌ Error during logout: $e');
      // Even if there's an error, clear local tokens and navigate to login
      Get.offAllNamed('/login');
    }
  }

  /// Get user information for display
  Map<String, String?> getUserInfo() {
    return _authService.getUserDisplayInfo();
  }

  /// Debug token status
  void debugTokenStatus() {
    _tokenStorage.debugTokenStatus();

    // Also show token info in snackbar
    final isLoggedIn = _tokenStorage.isLoggedIn;
    final hasAccessToken = _tokenStorage.accessToken.isNotEmpty;
    final hasRefreshToken = _tokenStorage.refreshToken.isNotEmpty;

    Get.snackbar(
      'Token Status',
      'Logged In: $isLoggedIn\nAccess Token: ${hasAccessToken ? 'Present' : 'Missing'}\nRefresh Token: ${hasRefreshToken ? 'Present' : 'Missing'}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  /// Check if user is logged in
  bool get isLoggedIn => _tokenStorage.isLoggedIn;

  /// Get current user role
  String? get userRole => _tokenStorage.getUserRole();

  /// Get user role asynchronously and update UI when available
  Future<String?> getUserRoleAsync() async {
    final role = await _tokenStorage.getUserRoleAsync();
    if (role != null) {
      // Trigger UI update
      update();
    }
    return role;
  }

  /// Check if user is verified
  bool get isUserVerified => _tokenStorage.isUserVerified();

  /// Navigate to specific page (for external navigation)
  void navigateToPage(int pageIndex) {
    if (pageIndex >= 0 && pageIndex <= 3) {
      setCurrentIndex(pageIndex);
    } else {
      debugPrint('⚠️ Invalid page index: $pageIndex');
    }
  }

  /// Refresh user data if needed
  Future<void> refreshUserData() async {
    debugPrint('🔄 Refreshing user data...');
    // This would typically fetch updated user data from the server
    // For now, we just verify the session
    await _verifySession();
  }

  /// Handle app resume (when app comes back from background)
  void onAppResumed() {
    debugPrint('📱 App resumed - verifying session');
    _verifySession();
  }

  /// Handle app paused (when app goes to background)
  void onAppPaused() {
    debugPrint('📱 App paused');
    // Could implement session timeout logic here if needed
  }

  @override
  void onClose() {
    debugPrint('🏠 HomeController disposed');
    super.onClose();
  }
}

import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../../../services/auth_service.dart';
import '../../../services/token_storage_service.dart';
import '../../../services/permission_service.dart';
import '../../../services/device_registration_service.dart';
import '../../profile/services/profile_service.dart';
import '../../../utils/navigation_helper.dart';

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
    _checkDeviceStatus();
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

  /// Check device status — if another device took over, force logout to login.
  /// Otherwise if OTP/takeover is needed, open verification.
  Future<void> _checkDeviceStatus() async {
    if (!_tokenStorage.isLoggedIn) {
      debugPrint('🔍 Skipping device status check — user not logged in');
      return;
    }
    try {
      debugPrint('🔍 Checking device status from HomeController...');
      final deviceService = Get.find<DeviceRegistrationService>();
      final checkResult = await deviceService.checkAndHandleDevice();

      if (checkResult.wasReplacedByAnotherDevice) {
        debugPrint('📱 Device replaced — forcing logout to login from home');
        await _authService.forceLogoutToLogin(
          message: checkResult.message.isNotEmpty
              ? checkResult.message
              : 'Your account was signed in on another device. Please log in again.',
        );
        return;
      }

      if (checkResult.needsVerification) {
        final isTakeover = checkResult.needsTakeover;
        debugPrint(
            '${isTakeover ? "🔄" : "🔐"} Device needs ${isTakeover ? "takeover " : ""}verification from home — navigating to OTP screen');
        Get.offAllNamed('/device-verification', arguments: {
          'device_id': checkResult.deviceId ?? '',
          'device_name': 'this device',
          'is_takeover': isTakeover,
          'new_user_email': checkResult.newUserEmail ?? '',
          'takeover_message': checkResult.message,
        });
      }
    } catch (e) {
      debugPrint('⚠️ Device check from HomeController failed: $e');
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
        NavigationHelper.showSafeSnackbar(
          title: 'Session Refreshed',
          message: 'Your session has been refreshed successfully.',
          duration: const Duration(seconds: 2),
        );
        debugPrint('✅ Manual token refresh successful');
      } else {
        NavigationHelper.showSafeSnackbar(
          title: 'Refresh Failed',
          message: 'Failed to refresh session. You may need to log in again.',
          duration: const Duration(seconds: 3),
        );
        debugPrint('❌ Manual token refresh failed');
      }
    } catch (e) {
      debugPrint('❌ Error during manual token refresh: $e');
      NavigationHelper.showSafeSnackbar(
        title: 'Error',
        message: 'An error occurred while refreshing your session.',
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

    NavigationHelper.showSafeSnackbar(
      title: 'Token Status',
      message:
          'Logged In: $isLoggedIn\nAccess Token: ${hasAccessToken ? 'Present' : 'Missing'}\nRefresh Token: ${hasRefreshToken ? 'Present' : 'Missing'}',
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
    _checkDeviceStatus();
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

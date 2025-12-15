import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../config/environment_config.dart';
import 'api_service.dart';
import 'token_storage_service.dart';
import '../features/profile/services/profile_service.dart';
import 'dart:async';

class AuthService extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final TokenStorageService _tokenStorage = Get.find<TokenStorageService>();
  ProfileService get _profileService => Get.find<ProfileService>();

  Timer? _tokenRefreshTimer;
  static const Duration _refreshInterval =
      Duration(minutes: 15); // Check every 15 minutes

  @override
  void onInit() {
    super.onInit();
    _startTokenRefreshTimer();
    debugPrint('🔐 AuthService initialized with automatic token refresh');
  }

  @override
  void onClose() {
    _tokenRefreshTimer?.cancel();
    super.onClose();
  }

  /// Start the automatic token refresh timer
  void _startTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer.periodic(_refreshInterval, (_) {
      _checkAndRefreshToken();
    });

    // Also check immediately on startup
    _checkAndRefreshToken();
  }

  /// Check if token needs refresh and refresh if necessary
  Future<void> _checkAndRefreshToken() async {
    try {
      if (!_tokenStorage.isLoggedIn) {
        debugPrint('🔐 User not logged in, skipping token refresh check');
        return;
      }

      if (_tokenStorage.isRefreshTokenExpired()) {
        debugPrint('🔐 Refresh token expired, logging out user');
        await _handleTokenExpiration();
        return;
      }

      if (_tokenStorage.isAccessTokenExpired()) {
        debugPrint('🔄 Access token expired, attempting refresh');
        await refreshAccessToken();
      } else {
        debugPrint('🔐 Access token still valid, no refresh needed');
      }
    } catch (e) {
      debugPrint('❌ Error during automatic token refresh check: $e');
    }
  }

  /// Refresh the access token using the refresh token
  Future<bool> refreshAccessToken() async {
    try {
      if (_tokenStorage.refreshToken.isEmpty) {
        debugPrint('❌ No refresh token available');
        return false;
      }

      if (_tokenStorage.isRefreshTokenExpired()) {
        debugPrint('❌ Refresh token is expired');
        await _handleTokenExpiration();
        return false;
      }

      debugPrint('🔄 Refreshing access token...');

      final response = await _apiService.post(
        EnvironmentConfig.refreshTokenUrl,
        data: {
          'refresh': _tokenStorage.refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'] as String?;

        if (newAccessToken != null) {
          await _tokenStorage.updateAccessToken(newAccessToken);
          debugPrint('✅ Access token refreshed successfully');
          return true;
        } else {
          debugPrint('❌ Invalid refresh response: missing access token');
          return false;
        }
      } else {
        debugPrint(
            '❌ Token refresh failed with status: ${response.statusCode}');
        return false;
      }
    } on dio.DioException catch (e) {
      debugPrint('❌ Dio error during token refresh: ${e.type}');

      if (e.response?.statusCode == 401) {
        debugPrint('🔐 Refresh token is invalid or expired');
        await _handleTokenExpiration();
      }

      return false;
    } catch (e) {
      debugPrint('❌ Unexpected error during token refresh: $e');
      return false;
    }
  }

  /// Handle token expiration by logging out the user
  Future<void> _handleTokenExpiration() async {
    debugPrint('⏰ Handling token expiration - logging out user');

    await _tokenStorage.logout();

    // Navigate to login screen
    Get.offAllNamed('/login');

    // Show notification to user
    Get.snackbar(
      'Session Expired',
      'Your session has expired. Please log in again.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  /// Login user and store tokens
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔑 Attempting login for: $email');

      final response = await _apiService.post(
        EnvironmentConfig.loginUrl,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return await handleLoginSuccess(response.data);
      } else {
        debugPrint('❌ Login failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      return false;
    }
  }

  /// Handle successful login response
  Future<bool> handleLoginSuccess(Map<String, dynamic> responseData) async {
    try {
      final accessToken = responseData['access'] as String?;
      final refreshToken = responseData['refresh'] as String?;
      final userData = responseData['user'] as Map<String, dynamic>?;

      if (accessToken == null || refreshToken == null) {
        debugPrint('❌ Invalid login response: missing tokens');
        return false;
      }

      // Store tokens and user data
      await _tokenStorage.storeTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userData: userData,
      );

      // Fetch and store complete user profile after login
      try {
        debugPrint('📥 Fetching complete user profile after login...');
        // Check if ProfileService is available before using it
        if (Get.isRegistered<ProfileService>()) {
          await _profileService.fetchProfile();
          debugPrint('✅ Complete profile stored securely');
        } else {
          debugPrint('⚠️ ProfileService not available, skipping profile fetch');
        }
      } catch (profileError) {
        debugPrint(
            '⚠️ Warning: Failed to fetch complete profile: $profileError');
        // Don't fail login if profile fetch fails, we have basic user data
      }

      // Start/restart the token refresh timer
      _startTokenRefreshTimer();

      final userEmail = userData?['email'];
      final isAdmin = _tokenStorage.isUserAdmin();
      debugPrint('✅ Login successful for: $userEmail (Admin: $isAdmin)');
      return true;
    } catch (e) {
      debugPrint('❌ Error processing login response: $e');
      return false;
    }
  }

  /// Logout user and clear all tokens
  Future<void> logout() async {
    try {
      debugPrint('👋 Logging out user');

      // Cancel the refresh timer
      _tokenRefreshTimer?.cancel();

      // Clear stored tokens and user data
      await _tokenStorage.clearTokens();

      // Clear profile cache
      try {
        final profileService = Get.find<ProfileService>();
        profileService.clearCache();
        debugPrint('🧹 Profile cache cleared');
      } catch (e) {
        debugPrint('⚠️ ProfileService not found or error clearing cache: $e');
      }

      // Navigate to login screen and clear all previous routes
      Get.offAllNamed('/login');

      debugPrint('✅ User logged out successfully - all data cleared');
    } catch (e) {
      debugPrint('❌ Error during logout: $e');
      // Still try to navigate to login even if there's an error
      Get.offAllNamed('/login');
    }
  }

  /// Check if user is currently logged in
  bool get isLoggedIn => _tokenStorage.isLoggedIn;

  /// Get current user data
  Map<String, dynamic>? get currentUser => _tokenStorage.userData;

  /// Get current access token for API requests
  String get currentAccessToken => _tokenStorage.accessToken;

  /// Verify current session is valid
  Future<bool> verifySession() async {
    try {
      debugPrint('🔐 Verifying session...');

      if (!_tokenStorage.isLoggedIn) {
        debugPrint('❌ No tokens found in storage');
        return false;
      }

      // Check refresh token first
      if (_tokenStorage.isRefreshTokenExpired()) {
        debugPrint('❌ Refresh token is expired');
        await _clearExpiredSession();
        return false;
      }

      // Check access token
      if (_tokenStorage.isAccessTokenExpired()) {
        debugPrint('🔄 Access token expired, attempting refresh...');
        final refreshSuccess = await refreshAccessToken();

        if (refreshSuccess) {
          debugPrint('✅ Session verified after token refresh');
          return true;
        } else {
          debugPrint('❌ Token refresh failed - session invalid');
          return false;
        }
      }

      debugPrint('✅ Session is valid - access token still active');
      return true;
    } catch (e) {
      debugPrint('❌ Error verifying session: $e');
      return false;
    }
  }

  /// Clear expired session without showing UI messages (for silent cleanup)
  Future<void> _clearExpiredSession() async {
    debugPrint('🧹 Clearing expired session silently');
    await _tokenStorage.logout();
  }

  /// Initialize the auth service and check existing session
  /// Returns true if session is valid, false otherwise
  Future<bool> initializeSession() async {
    try {
      debugPrint('🔐 Initializing auth session...');

      // Check if we have stored tokens
      if (!_tokenStorage.isLoggedIn) {
        debugPrint('❌ No stored tokens found');
        return false;
      }

      // Verify session validity
      final isValidSession = await verifySession();

      if (isValidSession) {
        debugPrint('✅ Valid session found - user is logged in');
        // Start the token refresh timer if not already started
        _startTokenRefreshTimer();
        return true;
      } else {
        debugPrint('❌ Session validation failed');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error initializing session: $e');
      return false;
    }
  }

  /// Manual token refresh (can be called by user action)
  Future<bool> manualRefreshToken() async {
    debugPrint('🔄 Manual token refresh requested');
    return await refreshAccessToken();
  }

  /// Get formatted user info for display
  Map<String, String?> getUserDisplayInfo() {
    return {
      'name': _tokenStorage.getUserFullName(),
      'email': _tokenStorage.getUserEmail(),
      'role': _tokenStorage.getUserRole(),
      'verified': _tokenStorage.isUserVerified().toString(),
    };
  }

  /// Change user role
  Future<Map<String, dynamic>> changeRole({
    required String newRole,
    String? reason,
  }) async {
    try {
      debugPrint('🔄 Attempting to change role to: $newRole');

      final data = <String, dynamic>{
        'new_role': newRole,
      };

      if (reason != null && reason.isNotEmpty) {
        data['reason'] = reason;
      }

      final response = await _apiService.post(
        EnvironmentConfig.authChangeRoleUrl,
        data: data,
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        debugPrint('✅ Role changed successfully');
        debugPrint('  - Old Role: ${responseData['old_role']}');
        debugPrint('  - New Role: ${responseData['new_role']}');
        debugPrint(
            '  - Verification Required: ${responseData['verification_required']}');

        // Refresh the access token to get updated user data
        await refreshAccessToken();

        // Fetch updated profile
        if (Get.isRegistered<ProfileService>()) {
          await _profileService.fetchProfile();
          debugPrint('✅ Profile refreshed after role change');
        }

        return {
          'success': true,
          'message': responseData['message'],
          'old_role': responseData['old_role'],
          'new_role': responseData['new_role'],
          'verification_required': responseData['verification_required'],
          'is_verified': responseData['is_verified'],
        };
      } else {
        debugPrint('❌ Role change failed with status: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Failed to change role: ${response.statusCode}',
        };
      }
    } on dio.DioException catch (e) {
      debugPrint('❌ Dio error during role change: ${e.type}');

      if (e.response != null && e.response!.data != null) {
        final errorData = e.response!.data;
        String errorMessage = 'Failed to change role';

        if (errorData is Map && errorData.containsKey('error')) {
          errorMessage = errorData['error'].toString();
        } else if (errorData is String) {
          errorMessage = errorData;
        }

        return {
          'success': false,
          'error': errorMessage,
        };
      }

      return {
        'success': false,
        'error': 'Network error: ${e.message}',
      };
    } catch (e) {
      debugPrint('❌ Unexpected error during role change: $e');
      return {
        'success': false,
        'error': 'Unexpected error: $e',
      };
    }
  }
}

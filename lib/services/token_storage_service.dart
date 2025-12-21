import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:convert';
import 'dart:async';
import '../features/profile/services/profile_service.dart';

class TokenStorageService extends GetxController {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpirationKey = 'token_expiration';
  static const String _userDataKey = 'user_data';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Observable variables for reactive UI
  final RxBool _isLoggedIn = false.obs;
  final RxString _currentAccessToken = ''.obs;
  final RxString _currentRefreshToken = ''.obs;
  final Rx<Map<String, dynamic>?> _userData = Rx<Map<String, dynamic>?>(null);

  // Getters
  bool get isLoggedIn => _isLoggedIn.value;
  String get accessToken => _currentAccessToken.value;
  String get refreshToken => _currentRefreshToken.value;
  Map<String, dynamic>? get userData => _userData.value;

  bool _isInitialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  // onInit removed - initialization is now async via init() method

  /// Initialize the service asynchronously (called via Get.putAsync)
  Future<TokenStorageService> init() async {
    await _initializeFromStorage();
    return this;
  }

  /// Wait for the service to be fully initialized
  Future<void> waitForInitialization() async {
    if (_isInitialized) return;

    try {
      await _initCompleter.future.timeout(const Duration(seconds: 5));
    } catch (_) {
      debugPrint('⚠️ TokenStorageService initialization timeout');
    }
  }

  /// Initialize tokens and user data from secure storage
  Future<void> _initializeFromStorage() async {
    try {
      debugPrint('🔐 Initializing token storage from secure storage...');

      final accessToken = await _secureStorage.read(key: _accessTokenKey);
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      final userDataString = await _secureStorage.read(key: _userDataKey);

      if (accessToken != null && refreshToken != null) {
        _currentAccessToken.value = accessToken;
        _currentRefreshToken.value = refreshToken;

        if (userDataString != null) {
          _userData.value = jsonDecode(userDataString);
        }

        debugPrint('✅ Tokens loaded from storage');
        debugPrint('🔐 Access token: ${accessToken.substring(0, 20)}...');
        debugPrint('🔄 Refresh token: ${refreshToken.substring(0, 20)}...');
        debugPrint('👤 User: ${_userData.value?['email'] ?? 'Unknown'}');

        // Check if tokens are still valid
        final isValid = await _areTokensValid();
        _isLoggedIn.value = isValid;

        if (isValid) {
          debugPrint('✅ Stored tokens are valid - user logged in');
        } else {
          debugPrint('⚠️ Stored tokens are expired - clearing storage');
          await _clearStoredTokens();
        }
      } else {
        _isLoggedIn.value = false;
        debugPrint('❌ No stored tokens found - user not logged in');
      }
    } catch (e) {
      debugPrint('❌ Error initializing tokens from storage: $e');
      _isLoggedIn.value = false;
    } finally {
      _isInitialized = true;
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
      debugPrint('🔐 TokenStorageService initialization complete');
    }
  }

  /// Store JWT tokens and user data securely
  Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
    Map<String, dynamic>? userData,
  }) async {
    try {
      // Store tokens
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);

      // Store user data if provided
      if (userData != null) {
        await _secureStorage.write(
            key: _userDataKey, value: jsonEncode(userData));
        _userData.value = userData;
      }

      // Store current timestamp for expiration tracking
      final currentTime = DateTime.now().millisecondsSinceEpoch.toString();
      await _secureStorage.write(key: _tokenExpirationKey, value: currentTime);

      // Update reactive variables
      _currentAccessToken.value = accessToken;
      _currentRefreshToken.value = refreshToken;
      _isLoggedIn.value = true;

      debugPrint('🔐 Tokens stored successfully');
      debugPrint(
          '👤 User data stored: ${userData?['email'] ?? 'No user data'}');
    } catch (e) {
      debugPrint('❌ Error storing tokens: $e');
      throw Exception('Failed to store authentication tokens');
    }
  }

  /// Update only the access token (used during token refresh)
  Future<void> updateAccessToken(String newAccessToken) async {
    try {
      await _secureStorage.write(key: _accessTokenKey, value: newAccessToken);
      _currentAccessToken.value = newAccessToken;

      debugPrint('🔄 Access token updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating access token: $e');
      throw Exception('Failed to update access token');
    }
  }

  /// Check if tokens exist and are valid using jwt_decoder
  Future<bool> _areTokensValid() async {
    try {
      final accessToken = _currentAccessToken.value;
      final refreshToken = _currentRefreshToken.value;

      if (accessToken.isEmpty || refreshToken.isEmpty) {
        debugPrint('❌ No tokens found for validation');
        return false;
      }

      // Use jwt_decoder to validate refresh token (most important for persistence)
      try {
        final isRefreshExpired = JwtDecoder.isExpired(refreshToken);
        if (isRefreshExpired) {
          debugPrint('⚠️ Refresh token is expired - clearing tokens');
          await clearTokens();
          return false;
        }

        // Get token expiration info
        final refreshExp = JwtDecoder.getExpirationDate(refreshToken);
        debugPrint('✅ Refresh token valid until: $refreshExp');

        return true;
      } catch (e) {
        debugPrint('❌ Invalid JWT format or malformed token: $e');
        await clearTokens();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error validating tokens: $e');
      return false;
    }
  }

  /// Check if access token is expired (for refresh logic)
  bool isAccessTokenExpired() {
    try {
      if (_currentAccessToken.value.isEmpty) {
        debugPrint('🔐 Access token is empty');
        return true;
      }

      final isExpired = JwtDecoder.isExpired(_currentAccessToken.value);
      debugPrint('🔐 Access token check: isExpired=$isExpired');

      return isExpired;
    } catch (e) {
      debugPrint('⚠️ Error checking access token expiration: $e');
      // For access token, we can be more lenient - if it fails to decode,
      // let the API server reject it instead of assuming it's expired
      return false;
    }
  }

  /// Check if refresh token is expired
  bool isRefreshTokenExpired() {
    try {
      if (_currentRefreshToken.value.isEmpty) {
        debugPrint('🔐 Refresh token is empty');
        return true;
      }

      final isExpired = JwtDecoder.isExpired(_currentRefreshToken.value);
      final expDate = JwtDecoder.getExpirationDate(_currentRefreshToken.value);
      debugPrint(
          '🔐 Refresh token check: isExpired=$isExpired, expires=$expDate');

      return isExpired;
    } catch (e) {
      debugPrint('⚠️ Error checking refresh token expiration: $e');
      debugPrint(
          '⚠️ Token value (first 50 chars): ${_currentRefreshToken.value.substring(0, _currentRefreshToken.value.length > 50 ? 50 : _currentRefreshToken.value.length)}');
      // Don't assume expired on parse errors - token might be valid but malformed
      // Only return true if token is actually empty
      return false;
    }
  }

  /// Get remaining time until token expires
  Duration? getTokenRemainingTime(String token) {
    try {
      if (token.isEmpty) return null;
      return JwtDecoder.getRemainingTime(token);
    } catch (e) {
      debugPrint('❌ Error getting token remaining time: $e');
      return null;
    }
  }

  /// Get token expiration date
  DateTime? getTokenExpirationDate(String token) {
    try {
      if (token.isEmpty) return null;
      return JwtDecoder.getExpirationDate(token);
    } catch (e) {
      debugPrint('❌ Error getting token expiration date: $e');
      return null;
    }
  }

  /// Clear all stored tokens and user data
  Future<void> clearTokens() async {
    try {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _tokenExpirationKey);
      await _secureStorage.delete(key: _userDataKey);

      // Clear reactive variables
      _currentAccessToken.value = '';
      _currentRefreshToken.value = '';
      _userData.value = null;
      _isLoggedIn.value = false;

      debugPrint('🧹 All tokens and user data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing tokens: $e');
    }
  }

  /// Get user ID from stored user data
  int? getUserId() {
    return _userData.value?['id'] as int?;
  }

  /// Get user email from stored user data
  String? getUserEmail() {
    return _userData.value?['email'] as String?;
  }

  /// Get user full name from stored user data
  String? getUserFullName() {
    final firstName = _userData.value?['first_name'] as String?;
    final lastName = _userData.value?['last_name'] as String?;

    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName;
  }

  /// Get user role from stored user data or JWT token
  String? getUserRole() {
    debugPrint('🔐 DEBUG getUserRole: Starting role extraction');
    debugPrint('🔐 DEBUG getUserRole: _userData.value = ${_userData.value}');

    // First try to get from stored user data
    final userRoleData = _userData.value?['user_role'];
    debugPrint(
        '🔐 DEBUG getUserRole: userRoleData = $userRoleData (type: ${userRoleData.runtimeType})');

    if (userRoleData != null) {
      // Handle different formats of user_role data
      if (userRoleData is String) {
        debugPrint('🔐 DEBUG getUserRole: Found string role: $userRoleData');
        return userRoleData;
      } else if (userRoleData is Map<String, dynamic>) {
        debugPrint('🔐 DEBUG getUserRole: Found role object: $userRoleData');
        // Extract role_name from user_role object
        final roleName = userRoleData['role_name'] as String?;
        debugPrint('🔐 Got user role from profile data: $roleName');
        return roleName;
      } else {
        debugPrint(
            '🔐 DEBUG getUserRole: Unexpected userRoleData type: ${userRoleData.runtimeType}');
      }
    } else {
      debugPrint(
          '🔐 DEBUG getUserRole: userRoleData is null, checking all keys in _userData.value');
      debugPrint(
          '🔐 DEBUG getUserRole: Available keys: ${_userData.value?.keys.toList()}');

      // Check if user profile might be stored separately
      debugPrint(
          '🔐 DEBUG getUserRole: Will attempt to load from stored profile async');
    }

    // If not available in user data, try to decode from JWT access token
    try {
      final accessToken = _currentAccessToken.value;
      if (accessToken.isNotEmpty) {
        final decodedToken = JwtDecoder.decode(accessToken);

        // Check different possible role field names in JWT payload
        final roleFromToken = decodedToken['role'] ??
            decodedToken['user_role'] ??
            decodedToken['user_type'] ??
            decodedToken['role_name'];

        if (roleFromToken != null) {
          debugPrint('🔐 Got user role from JWT token: $roleFromToken');
          return roleFromToken.toString();
        }
      }
    } catch (e) {
      debugPrint('⚠️ Could not decode role from JWT token: $e');
    }

    // If still not found, return null
    debugPrint('⚠️ User role not found in stored data or JWT token');
    return null;
  }

  /// Get user role asynchronously, fetching from API if not available locally (with caching)
  Future<String?> getUserRoleAsync() async {
    debugPrint('🔐 Starting async role extraction');

    // First try the synchronous method
    String? role = getUserRole();
    if (role != null && role.isNotEmpty) {
      debugPrint('🔐 Found role in sync method: $role');
      return role;
    }

    // If no role found, try to load from cached profile
    debugPrint('🔐 No role in sync method, checking cached profile...');
    final cachedProfile = await getUserProfile();
    if (cachedProfile != null) {
      final cachedRoleData = cachedProfile['user_role'];
      if (cachedRoleData != null) {
        String? cachedRole;
        if (cachedRoleData is String) {
          cachedRole = cachedRoleData;
        } else if (cachedRoleData is Map<String, dynamic>) {
          cachedRole = cachedRoleData['role_name'] as String?;
        }

        if (cachedRole != null && cachedRole.isNotEmpty) {
          debugPrint('🔐 Found role in cached profile: $cachedRole');
          // Update the _userData with profile data
          _userData.value = cachedProfile;
          return cachedRole;
        }
      }
    }

    // No role found in cache - don't make API calls here
    // Profile should be fetched once during login, not repeatedly
    debugPrint(
        '⚠️ No user role found in cache. Profile should be fetched during login.');
    return null;
  }

  /// Check if user is verified
  bool isUserVerified() {
    return _userData.value?['is_verified'] == true;
  }

  /// Get profile picture URL
  String? getProfilePictureUrl() {
    return _userData.value?['profile_picture'] as String?;
  }

  /// Store user profile data (separate from login user data)
  Future<void> storeUserProfile(Map<String, dynamic> profileData) async {
    try {
      const String profileKey = 'user_profile';
      await _secureStorage.write(
        key: profileKey,
        value: jsonEncode(profileData),
      );
      debugPrint('✅ User profile stored successfully');
    } catch (e) {
      debugPrint('❌ Error storing user profile: $e');
      throw Exception('Failed to store user profile');
    }
  }

  /// Get stored user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      const String profileKey = 'user_profile';
      final profileString = await _secureStorage.read(key: profileKey);

      if (profileString != null) {
        return jsonDecode(profileString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user profile: $e');
      return null;
    }
  }

  /// Clear user profile data
  Future<void> clearUserProfile() async {
    try {
      const String profileKey = 'user_profile';
      await _secureStorage.delete(key: profileKey);
      debugPrint('🧹 User profile cleared');
    } catch (e) {
      debugPrint('❌ Error clearing user profile: $e');
    }
  }

  /// Clear stored tokens from secure storage (internal method)
  Future<void> _clearStoredTokens() async {
    try {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _userDataKey);
      await _secureStorage.delete(key: _tokenExpirationKey);

      // Clear user profile as well
      await clearUserProfile();

      // Reset reactive variables
      _currentAccessToken.value = '';
      _currentRefreshToken.value = '';
      _userData.value = null;
      _isLoggedIn.value = false;

      debugPrint('🧹 Stored tokens and profile cleared from secure storage');
    } catch (e) {
      debugPrint('❌ Error clearing stored tokens: $e');
    }
  }

  /// Force logout - clear everything and navigate to login
  Future<void> logout() async {
    await clearTokens();
    debugPrint('👋 User logged out - redirecting to login');
    // This will be handled by the auth service or main app
  }

  /// Check if current user is admin (staff or superuser)
  bool isUserAdmin() {
    final profile = _userData.value;
    if (profile == null) return false;

    // Check both is_staff and is_superuser flags
    final isStaff = profile['is_staff'] == true;
    final isSuperuser = profile['is_superuser'] == true;

    debugPrint('🔐 Admin check: is_staff=$isStaff, is_superuser=$isSuperuser');

    return isStaff || isSuperuser;
  }

  /// Check if user is superuser specifically
  bool isUserSuperuser() {
    final profile = _userData.value;
    if (profile == null) return false;

    final isSuperuser = profile['is_superuser'] == true;
    debugPrint('🔐 Superuser check: $isSuperuser');

    return isSuperuser;
  }

  /// Check if user has specific admin permissions
  bool hasAdminPermission(String permission) {
    final profile = _userData.value;
    if (profile == null) return false;

    final permissions = profile['permissions'] as List<dynamic>?;
    if (permissions == null) return false;

    // Check for specific permission or superuser wildcard
    final hasPermission =
        permissions.contains(permission) || permissions.contains('*superuser*');

    debugPrint('🔐 Permission check for "$permission": $hasPermission');

    return hasPermission;
  }

  /// Get user permissions list
  List<String> getUserPermissions() {
    final profile = _userData.value;
    if (profile == null) return [];

    final permissions = profile['permissions'] as List<dynamic>?;
    if (permissions == null) return [];

    return permissions.cast<String>();
  }

  /// Check if user can create content (for hub access control)
  bool canCreateContent() {
    // Admins can always create content
    if (isUserAdmin()) return true;

    // Check subscription permissions
    final profile = _userData.value;
    if (profile == null) return false;

    final subscription = profile['subscription'] as Map<String, dynamic>?;
    if (subscription == null) return false;

    final permissions = subscription['permissions'] as Map<String, dynamic>?;
    if (permissions == null) return false;

    // Check if subscription is active and allows forum access
    return permissions['can_access_forum'] == true ||
        permissions['can_access_student_hub'] == true;
  }

  /// Check if user has specific subscription permission
  bool hasSubscriptionPermission(String permissionName) {
    final profile = _userData.value;
    if (profile == null) return false;

    final subscription = profile['subscription'] as Map<String, dynamic>?;
    if (subscription == null) return false;

    final permissions = subscription['permissions'] as Map<String, dynamic>?;
    if (permissions == null) return false;

    return permissions[permissionName] == true;
  }

  /// Get user display name for UI
  String getUserDisplayName() {
    final profile = _userData.value;
    if (profile == null) return 'Unknown User';

    final firstName = profile['first_name'] as String?;
    final lastName = profile['last_name'] as String?;
    final email = profile['email'] as String?;

    if (firstName != null && firstName.isNotEmpty) {
      if (lastName != null && lastName.isNotEmpty) {
        return '$firstName $lastName';
      }
      return firstName;
    }

    return email ?? 'Unknown User';
  }

  /// Update user profile data and store securely
  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      // Update in-memory data
      _userData.value = profileData;

      // Store in both locations for backward compatibility
      await _secureStorage.write(
        key: _userDataKey,
        value: jsonEncode(profileData),
      );

      await storeUserProfile(profileData);

      debugPrint('✅ User profile updated and stored securely');
      debugPrint('👤 User: ${getUserDisplayName()}');
      debugPrint('🔐 Admin: ${isUserAdmin()}');
    } catch (e) {
      debugPrint('❌ Error updating user profile: $e');
      throw Exception('Failed to update user profile');
    }
  }

  /// Manually refresh profile data (use sparingly, only when needed)
  /// This should only be called during login or when user data changes
  Future<void> refreshProfileData() async {
    try {
      debugPrint('🔄 Manually refreshing profile data...');

      // Check if ProfileService is available
      if (!Get.isRegistered<ProfileService>()) {
        debugPrint('❌ ProfileService not available for manual refresh');
        return;
      }

      // Import ProfileService dynamically to avoid circular dependency
      final ProfileService profileService = Get.find<ProfileService>();
      final profile = await profileService.fetchProfile();

      if (profile != null) {
        debugPrint('✅ Profile refreshed manually');
      }
    } catch (e) {
      debugPrint('❌ Error manually refreshing profile: $e');
    }
  }

  /// Debug method to print current token status
  void debugTokenStatus() {
    debugPrint('🔐 === TOKEN STATUS ===');
    debugPrint(
        '🔑 Access Token: ${_currentAccessToken.value.isNotEmpty ? 'Present (${_currentAccessToken.value.length} chars)' : 'Not present'}');
    debugPrint(
        '🔄 Refresh Token: ${_currentRefreshToken.value.isNotEmpty ? 'Present (${_currentRefreshToken.value.length} chars)' : 'Not present'}');
    debugPrint('✅ Is Logged In: $_isLoggedIn');
    debugPrint('👤 User: ${getUserEmail() ?? 'Unknown'}');
    debugPrint('🔐 Admin Status: ${isUserAdmin()}');
    debugPrint('🔐 === END STATUS ===');
  }
}

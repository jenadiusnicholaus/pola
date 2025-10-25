import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:convert';

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

  @override
  void onInit() {
    super.onInit();
    _initializeFromStorage();
  }

  /// Wait for the service to be fully initialized
  Future<void> waitForInitialization() async {
    if (_isInitialized) return;

    // If not initialized, wait for it to complete
    int attempts = 0;
    const maxAttempts = 50; // 5 seconds max wait
    const delayMs = 100;

    while (!_isInitialized && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: delayMs));
      attempts++;
    }

    if (!_isInitialized) {
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
      if (_currentAccessToken.value.isEmpty) return true;
      return JwtDecoder.isExpired(_currentAccessToken.value);
    } catch (e) {
      debugPrint('❌ Error checking access token expiration: $e');
      return true; // Assume expired on error
    }
  }

  /// Check if refresh token is expired
  bool isRefreshTokenExpired() {
    try {
      if (_currentRefreshToken.value.isEmpty) return true;
      return JwtDecoder.isExpired(_currentRefreshToken.value);
    } catch (e) {
      debugPrint('❌ Error checking refresh token expiration: $e');
      return true; // Assume expired on error
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

  /// Get user role from stored user data
  String? getUserRole() {
    return _userData.value?['user_role'] as String?;
  }

  /// Check if user is verified
  bool isUserVerified() {
    return _userData.value?['is_verified'] == true;
  }

  /// Get profile picture URL
  String? getProfilePictureUrl() {
    return _userData.value?['profile_picture'] as String?;
  }

  /// Clear stored tokens from secure storage (internal method)
  Future<void> _clearStoredTokens() async {
    try {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _userDataKey);
      await _secureStorage.delete(key: _tokenExpirationKey);

      // Reset reactive variables
      _currentAccessToken.value = '';
      _currentRefreshToken.value = '';
      _userData.value = null;
      _isLoggedIn.value = false;

      debugPrint('🧹 Stored tokens cleared from secure storage');
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

  /// Debug method to print current token status
  void debugTokenStatus() {
    debugPrint('🔐 === TOKEN STATUS ===');
    debugPrint(
        '🔑 Access Token: ${_currentAccessToken.value.isNotEmpty ? 'Present (${_currentAccessToken.value.length} chars)' : 'Not present'}');
    debugPrint(
        '🔄 Refresh Token: ${_currentRefreshToken.value.isNotEmpty ? 'Present (${_currentRefreshToken.value.length} chars)' : 'Not present'}');
    debugPrint('✅ Is Logged In: $_isLoggedIn');
    debugPrint('👤 User: ${getUserEmail() ?? 'Unknown'}');
    debugPrint('🔐 === END STATUS ===');
  }
}

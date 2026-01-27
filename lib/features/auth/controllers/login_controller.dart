import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/device_registration_service.dart';
import '../../../config/environment_config.dart';
import '../models/login_data.dart';
import '../../profile/services/profile_service.dart';

class LoginController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Storage keys
  static const String _keyRememberMe = 'remember_me';
  static const String _keySavedEmail = 'saved_email';
  static const String _keySavedPassword = 'saved_password';

  // Form controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Form key for validation
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Loading states
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  // Password visibility
  final RxBool _isPasswordVisible = false.obs;
  bool get isPasswordVisible => _isPasswordVisible.value;

  // Remember me checkbox
  final RxBool _rememberMe = false.obs;
  bool get rememberMe => _rememberMe.value;

  @override
  void onInit() {
    super.onInit();
    debugPrint('🔑 Login Controller initialized');

    // Load saved credentials if any
    _loadSavedCredentials();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    _isPasswordVisible.value = !_isPasswordVisible.value;
    debugPrint('👁️ Password visibility toggled: ${_isPasswordVisible.value}');
  }

  void toggleRememberMe(bool? value) async {
    _rememberMe.value = value ?? false;
    debugPrint('💭 Remember me toggled: ${_rememberMe.value}');

    // If unchecked, clear saved credentials immediately
    if (!_rememberMe.value) {
      await _clearSavedCredentials();
    }
  }

  /// Fetch user profile after successful login
  Future<void> _fetchUserProfile() async {
    try {
      debugPrint('� Fetching user profile after login...');

      // Initialize profile service if not already done
      if (!Get.isRegistered<ProfileService>()) {
        Get.put(ProfileService());
      }

      final profileService = Get.find<ProfileService>();

      // Fetch profile from API
      final profile = await profileService.fetchProfile();

      if (profile != null) {
        debugPrint(
            '✅ User profile fetched successfully: ${profile.fullName} (${profile.userRole.roleName})');
      } else {
        debugPrint('⚠️ Profile fetch returned null');
      }
    } catch (e) {
      debugPrint('⚠️ Non-critical error fetching profile after login: $e');
      // Don't throw here - profile fetch failure shouldn't prevent login success
      // User can manually refresh profile from the app later
    }
  }

  Future<void> _loadSavedCredentials() async {
    try {
      debugPrint('📱 Loading saved credentials (if any)');

      // Check if remember me was enabled
      final rememberMeValue = await _secureStorage.read(key: _keyRememberMe);

      if (rememberMeValue == 'true') {
        final savedEmail = await _secureStorage.read(key: _keySavedEmail);
        final savedPassword = await _secureStorage.read(key: _keySavedPassword);

        if (savedEmail != null && savedEmail.isNotEmpty) {
          emailController.text = savedEmail;
          debugPrint('✅ Loaded saved email: $savedEmail');
        }

        if (savedPassword != null && savedPassword.isNotEmpty) {
          passwordController.text = savedPassword;
          debugPrint(
              '✅ Loaded saved password (length: ${savedPassword.length})');
        }

        _rememberMe.value = true;
        debugPrint('✅ Remember me is enabled');
      } else {
        debugPrint('ℹ️ No saved credentials found or remember me disabled');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading saved credentials: $e');
    }
  }

  Future<void> login() async {
    debugPrint('🔑 Starting login process...');

    // Validate form
    if (!formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      return;
    }

    // Check if fields are empty (additional validation)
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please fill in all required fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    _isLoading.value = true;

    try {
      // Prepare login data
      final loginData = LoginData(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      debugPrint('📤 Sending login request for: ${loginData.email}');
      debugPrint('🌐 Login endpoint: ${EnvironmentConfig.loginUrl}');

      // Make API call
      final response = await _apiService.post(
        EnvironmentConfig.loginUrl,
        data: loginData.toJson(),
      );

      debugPrint('📥 Login response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        await _handleLoginSuccess(response.data);
      } else {
        _handleLoginError(response);
      }
    } on dio.DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      debugPrint('🚨 Unexpected error during login: $e');
      debugPrint('📚 Stack trace: ${StackTrace.current}');

      Get.snackbar(
        'Error',
        'Login failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _handleLoginSuccess(Map<String, dynamic> responseData) async {
    debugPrint('✅ Login successful!');
    debugPrint('👤 Response data keys: ${responseData.keys.toList()}');

    try {
      // Handle the actual JWT response format
      final accessToken = responseData['access'] as String?;
      final refreshToken = responseData['refresh'] as String?;

      if (accessToken == null || refreshToken == null) {
        throw Exception('Invalid response: Missing tokens');
      }

      debugPrint('🔐 Access token received (length: ${accessToken.length})');
      debugPrint('🔄 Refresh token received (length: ${refreshToken.length})');

      // Use AuthService to handle login and token storage
      final authService = Get.find<AuthService>();
      final loginSuccess = await authService.handleLoginSuccess({
        'access': accessToken,
        'refresh': refreshToken,
        'user': null, // The response format doesn't include user data
      });

      if (loginSuccess) {
        // Save credentials if remember me is checked
        if (_rememberMe.value) {
          await _saveCredentials();
        }

        // Fetch user profile immediately after successful login
        await _fetchUserProfile();

        // Register device in background (don't block login flow)
        _registerDevice();

        // Show success message
        Get.snackbar(
          'Success',
          'Welcome back! You are now logged in.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        // Navigate to home screen
        debugPrint('🏠 Navigating to home screen...');
        Get.offAllNamed('/home');
      } else {
        throw Exception('Failed to process login tokens');
      }
    } catch (e) {
      debugPrint('❌ Error processing login response: $e');
      Get.snackbar(
        'Error',
        'Login successful but failed to process response: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  void _handleLoginError(dio.Response response) {
    debugPrint('❌ Login failed with status: ${response.statusCode}');
    debugPrint('📄 Error response: ${response.data}');

    String errorMessage = 'Login failed. Please try again.';

    if (response.data is Map<String, dynamic>) {
      final errorData = response.data as Map<String, dynamic>;

      // Handle specific error cases
      if (errorData.containsKey('detail')) {
        errorMessage = errorData['detail'].toString();
      } else if (errorData.containsKey('email') ||
          errorData.containsKey('password')) {
        // Validation errors
        List<String> errors = [];
        if (errorData['email'] != null) {
          errors.add('Email: ${errorData['email'].join(', ')}');
        }
        if (errorData['password'] != null) {
          errors.add('Password: ${errorData['password'].join(', ')}');
        }
        errorMessage = errors.join('\\n');
      }
    }

    Get.snackbar(
      'Login Failed',
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  void _handleDioError(dio.DioException e) {
    debugPrint('🌐 Dio error during login: ${e.type}');
    debugPrint('📄 Error message: ${e.message}');
    debugPrint('📄 Error response: ${e.response?.data}');

    String errorMessage;
    switch (e.type) {
      case dio.DioExceptionType.connectionTimeout:
      case dio.DioExceptionType.sendTimeout:
      case dio.DioExceptionType.receiveTimeout:
        errorMessage =
            'Connection timeout. Please check your internet connection.';
        break;
      case dio.DioExceptionType.badResponse:
        if (e.response?.statusCode == 401) {
          errorMessage = 'Invalid email or password. Please try again.';
        } else if (e.response?.statusCode == 403) {
          errorMessage =
              'Account not verified. Please check your email for verification link.';
        } else {
          errorMessage = 'Server error occurred. Please try again later.';
        }
        break;
      case dio.DioExceptionType.connectionError:
        errorMessage = 'No internet connection. Please check your network.';
        break;
      default:
        errorMessage = 'Network error occurred. Please try again.';
    }

    Get.snackbar(
      'Connection Error',
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 6),
    );
  }

  Future<void> _saveCredentials() async {
    try {
      debugPrint('💾 Saving login credentials...');

      if (_rememberMe.value) {
        // Save credentials securely
        await _secureStorage.write(key: _keyRememberMe, value: 'true');
        await _secureStorage.write(
            key: _keySavedEmail, value: emailController.text.trim());
        await _secureStorage.write(
            key: _keySavedPassword, value: passwordController.text);

        debugPrint('✅ Credentials saved securely');
      } else {
        // Clear saved credentials if remember me is disabled
        await _clearSavedCredentials();
      }
    } catch (e) {
      debugPrint('⚠️ Error saving credentials: $e');
    }
  }

  Future<void> _clearSavedCredentials() async {
    try {
      debugPrint('🗑️ Clearing saved credentials...');

      await _secureStorage.delete(key: _keyRememberMe);
      await _secureStorage.delete(key: _keySavedEmail);
      await _secureStorage.delete(key: _keySavedPassword);

      debugPrint('✅ Saved credentials cleared');
    } catch (e) {
      debugPrint('⚠️ Error clearing credentials: $e');
    }
  }

  void _showLoginSuccessDialog(Map<String, dynamic>? userData) {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Login Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You have successfully logged into your account.'),
            if (userData != null) ...[
              const SizedBox(height: 16),
              Text(
                  'Welcome back, ${userData['first_name']} ${userData['last_name']}!'),
              const SizedBox(height: 8),
              Text('Role: ${userData['user_role'] ?? 'Unknown'}'),
              Text('Email: ${userData['email'] ?? 'Unknown'}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              // For now, just return to landing/registration
              // TODO: Navigate to proper home screen when implemented
            },
            child: const Text('Continue'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // Validation methods
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    if (!GetUtils.isEmail(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    return null;
  }

  // Helper method to clear form
  void clearForm() async {
    emailController.clear();
    passwordController.clear();
    _isPasswordVisible.value = false;
    _rememberMe.value = false;
    await _clearSavedCredentials();
    debugPrint('🧹 Login form cleared');
  }

  // Navigate to registration
  void goToRegistration() {
    Get.toNamed('/registration');
    debugPrint('📝 Navigating to registration...');
  }

  // Navigate to forgot password (TODO: implement)
  void goToForgotPassword() {
    // TODO: Implement forgot password functionality
    Get.snackbar(
      'Coming Soon',
      'Forgot password functionality will be available soon.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
    debugPrint('🔒 Forgot password requested (not implemented yet)');
  }

  // Register device after successful login
  void _registerDevice() async {
    try {
      debugPrint('📱 Registering device after login...');
      final deviceRegistrationService = Get.find<DeviceRegistrationService>();

      // Get FCM token to register with device
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        debugPrint('🔑 FCM Token obtained: ${fcmToken?.substring(0, 20)}...');
      } catch (e) {
        debugPrint('⚠️ Failed to get FCM token: $e');
      }

      // Register device with FCM token
      await deviceRegistrationService.registerDevice(fcmToken: fcmToken);
      debugPrint('✅ Device registration completed with FCM token');
    } catch (e) {
      debugPrint('⚠️ Device registration failed (non-blocking): $e');
      // Don't show error to user - this is a background operation
    }
  }
}

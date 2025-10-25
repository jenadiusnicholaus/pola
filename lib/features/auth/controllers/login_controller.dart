import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart' as dio;
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../config/environment_config.dart';
import '../models/login_data.dart';
import '../../profile/services/profile_service.dart';

class LoginController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

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

  void toggleRememberMe(bool? value) {
    _rememberMe.value = value ?? false;
    debugPrint('💭 Remember me toggled: ${_rememberMe.value}');
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

  void _loadSavedCredentials() {
    // TODO: Load saved credentials from secure storage if remember me was checked
    debugPrint('📱 Loading saved credentials (if any)');
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
    debugPrint('💾 Saving login credentials...');
    // TODO: Implement secure storage for credentials
    // Use flutter_secure_storage or similar
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
  void clearForm() {
    emailController.clear();
    passwordController.clear();
    _isPasswordVisible.value = false;
    _rememberMe.value = false;
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
}

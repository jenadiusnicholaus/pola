import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart' as dio;
import '../../../services/api_service.dart';
import '../../../config/environment_config.dart';
import '../models/registration_data.dart';
import '../services/lookup_service.dart';

class RegistrationController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Getter for lookup service
  LookupService get lookupService => Get.find<LookupService>();

  // Registration data
  final Rx<RegistrationData> _registrationData = RegistrationData().obs;
  RegistrationData get registrationData => _registrationData.value;

  // Page navigation
  final RxInt _currentPage = 0.obs;
  int get currentPage => _currentPage.value;

  final PageController pageController = PageController();

  // Loading state
  final RxBool _isSubmitting = false.obs;
  bool get isSubmitting => _isSubmitting.value;

  // Form keys for validation
  final GlobalKey<FormState> basicInfoFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> contactFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> professionalFormKey = GlobalKey<FormState>();

  // Total pages based on user role
  int get totalPages {
    switch (_registrationData.value.userRole) {
      case 'citizen': // Citizen - no professional info needed
        return 4; // Role + Basic + Contact + Review
      default: // All professional roles
        return 5; // Role + Basic + Contact + Professional + Review
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Initialize lookup service
    Get.put(LookupService());
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  // Update registration data
  void updateRegistrationData(RegistrationData data) {
    _registrationData.value = data;
  }

  // Navigate to next page
  void nextPage() {
    if (_currentPage.value < totalPages - 1) {
      if (_validateCurrentPage()) {
        _currentPage.value++;
        pageController.animateToPage(
          _currentPage.value,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  // Navigate to previous page
  void previousPage() {
    if (_currentPage.value > 0) {
      _currentPage.value--;
      pageController.animateToPage(
        _currentPage.value,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Jump to specific page
  void goToPage(int page) {
    if (page >= 0 && page < totalPages) {
      _currentPage.value = page;
      pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Validate current page
  bool _validateCurrentPage() {
    switch (_currentPage.value) {
      case 0: // Role Selection
        return _registrationData
            .value.userRole.isNotEmpty; // Must have selected a role
      case 1: // Basic Info
        return basicInfoFormKey.currentState?.validate() ?? false;
      case 2: // Contact
        return contactFormKey.currentState?.validate() ?? false;
      case 3: // Professional (for professional roles) or Review (for citizens)
        if (_registrationData.value.userRole == 'citizen') {
          return true; // Citizen goes to review
        }
        return professionalFormKey.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  // Submit registration with confirmation
  Future<void> submitRegistration() async {
    // Final validation first
    final errors = _registrationData.value.validateForRole();
    if (errors.isNotEmpty) {
      debugPrint('❗ Validation failed with ${errors.length} error(s):');
      for (int i = 0; i < errors.length; i++) {
        debugPrint('   ${i + 1}. ${errors[i]}');
      }

      Get.snackbar(
        'Validation Error',
        errors.first,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Show confirmation dialog
    debugPrint('💭 Showing confirmation dialog to user...');
    final confirmed = await _showSubmissionConfirmation();
    if (!confirmed) {
      debugPrint('❌ User cancelled registration submission');
      return;
    }
    debugPrint('✅ User confirmed registration submission');

    try {
      _isSubmitting.value = true;

      // Debug: Log registration attempt
      debugPrint('🚀 Starting registration submission...');
      debugPrint(
          '📝 User Role: ${_getRoleDisplayName(_registrationData.value.userRole)}');
      debugPrint('📧 Email: ${_registrationData.value.email}');
      debugPrint('🌐 Endpoint: ${EnvironmentConfig.registerUrl}');

      // Submit to API
      final response = await _apiService.post(
        EnvironmentConfig.registerUrl,
        data: _registrationData.value.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('✅ Registration successful!');
        debugPrint('📊 Status code: ${response.statusCode}');
        debugPrint('📄 Response data: ${response.data}');

        Get.snackbar(
          'Success',
          'Registration completed successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Show success dialog with option to login
        _showRegistrationSuccessDialog();
      } else {
        _handleRegistrationError(response);
      }
    } on dio.DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      debugPrint('🚨 Unexpected error during registration: $e');
      debugPrint('📚 Stack trace: ${StackTrace.current}');

      Get.snackbar(
        'Error',
        'Registration failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      _isSubmitting.value = false;
    }
  }

  // Update user role and reset role-specific data
  void updateUserRole(String roleName) {
    final currentData = _registrationData.value;

    // Reset role-specific fields when role changes
    _registrationData.value = RegistrationData(
      email: currentData.email,
      password: currentData.password,
      passwordConfirm: currentData.passwordConfirm,
      firstName: currentData.firstName,
      lastName: currentData.lastName,
      dateOfBirth: currentData.dateOfBirth,
      agreedToTerms: currentData.agreedToTerms,
      userRole: roleName,
      gender: currentData.gender,
      phoneNumber: currentData.phoneNumber,
      idNumber: currentData.idNumber,
      region: currentData.region,
      district: currentData.district,
      ward: currentData.ward,
    );

    // Stay on role selection page when role changes
    // Page 0 is role selection, don't change the page
    update();
  }

  // Get page title based on current page and user role
  String getPageTitle() {
    switch (_currentPage.value) {
      case 0:
        return 'Select Your Role';
      case 1:
        return 'Basic Information';
      case 2:
        return 'Contact Information';
      case 3:
        // For citizens, page 3 is review; for professionals, it's professional info
        if (_registrationData.value.userRole == 'citizen') {
          return 'Review & Submit';
        }
        return _getProfessionalPageTitle();
      case 4:
        return 'Review & Submit';
      default:
        return 'Registration';
    }
  }

  String _getProfessionalPageTitle() {
    switch (_registrationData.value.userRole) {
      case 'lawyer':
        return 'Lawyer Information';
      case 'advocate':
        return 'Advocate Information';
      case 'paralegal':
        return 'Paralegal Information';
      case 'law_student':
        return 'Law Student Information';
      case 'law_firm':
        return 'Law Firm Information';
      case 'lecturer':
        return 'Lecturer Information';
      default:
        return 'Professional Information';
    }
  }

  // Check if current page is the last page
  bool get isLastPage => _currentPage.value == totalPages - 1;

  // Check if current page is the first page
  bool get isFirstPage => _currentPage.value == 0;

  // Get progress percentage
  double get progress => (_currentPage.value + 1) / totalPages;

  // Show confirmation dialog before submission
  Future<bool> _showSubmissionConfirmation() async {
    return await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Confirm Submission'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Are you sure you want to submit your registration?'),
                const SizedBox(height: 12),
                Text(
                  'Role: ${_getRoleDisplayName(_registrationData.value.userRole)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Email: ${_registrationData.value.email}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Name: ${_registrationData.value.firstName} ${_registrationData.value.lastName}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Confirm'),
              ),
            ],
          ),
          barrierDismissible: false,
        ) ??
        false;
  }

  // Get role display name for confirmation dialog
  String _getRoleDisplayName(String roleName) {
    switch (roleName) {
      case 'lawyer':
        return 'Lawyer';
      case 'advocate':
        return 'Advocate';
      case 'paralegal':
        return 'Paralegal';
      case 'law_student':
        return 'Law Student';
      case 'law_firm':
        return 'Law Firm';
      case 'citizen':
        return 'Citizen';
      case 'lecturer':
        return 'Lecturer';
      default:
        return 'Unknown';
    }
  }

  // Debug helper method
  void _debugLog(String message) {
    debugPrint('🔍 [RegistrationController] $message');
  }

  // Handle registration response errors
  void _handleRegistrationError(dio.Response<dynamic> response) {
    debugPrint('❌ Registration failed with status: ${response.statusCode}');
    debugPrint('📋 Response headers: ${response.headers}');
    debugPrint('📄 Response data: ${response.data}');

    String errorMessage = 'Registration failed';

    if (response.data != null) {
      try {
        final errorData = response.data as Map<String, dynamic>;

        // Handle validation errors (422 status usually)
        if (errorData.containsKey('errors') || response.statusCode == 422) {
          final errors = <String>[];

          errorData.forEach((key, value) {
            if (value is List) {
              errors.addAll(value.map((e) => '$key: $e').cast<String>());
            } else if (value is String) {
              errors.add('$key: $value');
            }
          });

          errorMessage = errors.isNotEmpty
              ? errors.join('\n')
              : 'Validation errors occurred';
        } else if (errorData.containsKey('message')) {
          errorMessage = errorData['message'].toString();
        } else if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'].toString();
        }
      } catch (e) {
        errorMessage =
            'Registration failed with status: ${response.statusCode}';
      }
    }

    Get.snackbar(
      'Registration Error',
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 8),
      maxWidth: 400,
    );
  }

  // Handle Dio errors (network, timeout, etc.)
  void _handleDioError(dio.DioException error) {
    debugPrint('💥 DioException occurred: ${error.type}');
    debugPrint('📍 Error message: ${error.message}');
    debugPrint('🎯 Request URL: ${error.requestOptions.uri}');
    debugPrint('🔗 Request method: ${error.requestOptions.method}');
    if (error.response != null) {
      debugPrint('📊 Response status: ${error.response!.statusCode}');
      debugPrint('📦 Response data: ${error.response!.data}');
    }

    String errorMessage;

    switch (error.type) {
      case dio.DioExceptionType.connectionTimeout:
        errorMessage =
            'Connection timeout. Please check your internet connection.';
        break;
      case dio.DioExceptionType.sendTimeout:
        errorMessage = 'Request timeout. Please try again.';
        break;
      case dio.DioExceptionType.receiveTimeout:
        errorMessage = 'Server response timeout. Please try again.';
        break;
      case dio.DioExceptionType.badResponse:
        errorMessage =
            'Server error (${error.response?.statusCode}). Please try again.';
        break;
      case dio.DioExceptionType.cancel:
        errorMessage = 'Request was cancelled.';
        break;
      case dio.DioExceptionType.connectionError:
        errorMessage = 'No internet connection. Please check your network.';
        break;
      default:
        errorMessage = 'Network error occurred. Please try again.';
    }

    Get.snackbar(
      'Network Error',
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 6),
    );
  }

  void _showRegistrationSuccessDialog() {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text('Registration Successful!'),
            ),
          ],
        ),
        content: const Text(
          'Your account has been created successfully. You can now log in with your credentials.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              // Reset registration flow to start fresh
              _currentPage.value = 0;
              _clearAllData();
            },
            child: const Text('Start Over'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.offNamed('/login'); // Navigate to login
            },
            child: const Text('Login Now'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _clearAllData() {
    // Reset registration data to initial state
    _registrationData.value = RegistrationData();

    // Reset loading state
    _isSubmitting.value = false;

    debugPrint('🔄 All registration data cleared');
  }
}

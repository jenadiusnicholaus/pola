import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart' as dio;
import '../../../services/api_service.dart';
import '../../../services/token_storage_service.dart';
import '../../../config/environment_config.dart';
import '../models/profile_models.dart';

class ProfileService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();
  final TokenStorageService _tokenStorage = Get.find<TokenStorageService>();

  // Observable profile data
  final Rx<UserProfile?> _currentProfile = Rx<UserProfile?>(null);
  UserProfile? get currentProfile => _currentProfile.value;

  // Loading state
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  // Error state
  final RxString _error = ''.obs;
  String get error => _error.value;

  @override
  void onInit() {
    super.onInit();
    debugPrint('👤 ProfileService initialized');
  }

  /// Fetch user profile from API
  Future<UserProfile?> fetchProfile() async {
    _isLoading.value = true;
    _error.value = '';

    try {
      debugPrint('📤 Fetching user profile...');

      // Check if user is authenticated
      if (!_tokenStorage.isLoggedIn) {
        throw Exception('User not authenticated');
      }

      // Make API request
      final response = await _apiService.get(
        EnvironmentConfig.profileUrl,
      );

      debugPrint('📥 Profile response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        // Create profile using factory based on role
        final profile = ProfileFactory.createProfile(response.data);

        _currentProfile.value = profile;

        // Store profile in local storage for caching
        await _tokenStorage.storeUserProfile(response.data);

        debugPrint(
            '✅ Profile fetched successfully for: ${profile.fullName} (${profile.userRole.roleName})');
        return profile;
      } else {
        throw Exception('Failed to fetch profile: ${response.statusMessage}');
      }
    } on dio.DioException catch (e) {
      debugPrint('❌ DioException during profile fetch: ${e.message}');

      String errorMessage;
      switch (e.response?.statusCode) {
        case 401:
          errorMessage = 'Authentication failed. Please login again.';
          // Clear tokens on 401
          await _tokenStorage.clearTokens();
          break;
        case 403:
          errorMessage =
              'Access forbidden. You don\'t have permission to view this profile.';
          break;
        case 404:
          errorMessage = 'Profile not found.';
          break;
        case 500:
          errorMessage = 'Server error. Please try again later.';
          break;
        default:
          errorMessage = e.message ?? 'Network error occurred';
      }

      _error.value = errorMessage;
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('🚨 Unexpected error during profile fetch: $e');
      _error.value = 'Unexpected error occurred: ${e.toString()}';
      throw Exception(_error.value);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load cached profile from storage
  Future<UserProfile?> loadCachedProfile() async {
    try {
      final cachedData = await _tokenStorage.getUserProfile();
      if (cachedData != null) {
        final profile = ProfileFactory.createProfile(cachedData);
        _currentProfile.value = profile;
        debugPrint('📋 Loaded cached profile for: ${profile.fullName}');
        return profile;
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ Error loading cached profile: $e');
      return null;
    }
  }

  /// Update user profile
  Future<UserProfile?> updateProfile(Map<String, dynamic> updates) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      debugPrint('📤 Updating user profile...');
      debugPrint('📊 Update data: $updates');

      // Check if user is authenticated
      if (!_tokenStorage.isLoggedIn) {
        throw Exception('User not authenticated');
      }

      // Make API request
      final response = await _apiService.patch(
        EnvironmentConfig.profileUrl,
        data: updates,
      );

      debugPrint('📥 Profile update response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        // Create updated profile
        final profile = ProfileFactory.createProfile(response.data);

        _currentProfile.value = profile;

        // Store updated profile in local storage
        await _tokenStorage.storeUserProfile(response.data);

        debugPrint('✅ Profile updated successfully');
        return profile;
      } else {
        throw Exception('Failed to update profile: ${response.statusMessage}');
      }
    } on dio.DioException catch (e) {
      debugPrint('❌ DioException during profile update: ${e.message}');

      String errorMessage;
      if (e.response?.statusCode == 400) {
        // Validation errors
        final errors = e.response?.data;
        if (errors is Map<String, dynamic>) {
          final errorList = <String>[];
          errors.forEach((field, messages) {
            if (messages is List) {
              errorList.addAll(messages.map((m) => '$field: $m'));
            } else {
              errorList.add('$field: $messages');
            }
          });
          errorMessage = errorList.join('\n');
        } else {
          errorMessage = 'Validation error occurred';
        }
      } else {
        errorMessage = e.message ?? 'Update failed';
      }

      _error.value = errorMessage;
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('🚨 Unexpected error during profile update: $e');
      _error.value = 'Unexpected error occurred: ${e.toString()}';
      throw Exception(_error.value);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Clear profile data
  void clearProfile() {
    _currentProfile.value = null;
    _error.value = '';
    debugPrint('🧹 Profile data cleared');
  }

  /// Refresh profile (fetch from server)
  Future<UserProfile?> refreshProfile() async {
    debugPrint('🔄 Refreshing profile data...');
    return await fetchProfile();
  }

  /// Get display info for quick access
  Map<String, String?> getDisplayInfo() {
    final profile = _currentProfile.value;
    if (profile == null) {
      return {
        'name': 'Unknown User',
        'email': '',
        'role': '',
        'avatar': null,
      };
    }

    return {
      'name': profile.fullName,
      'email': profile.email,
      'role': profile.displayRole,
      'avatar': null, // TODO: Add profile picture when available
    };
  }

  /// Check if user has specific permission
  bool hasPermission(String permission) {
    final profile = _currentProfile.value;
    return profile?.permissions.contains(permission) ?? false;
  }

  /// Check subscription status
  bool get hasActiveSubscription {
    final profile = _currentProfile.value;
    return profile?.subscription.isActive ?? false;
  }

  /// Get subscription plan name
  String get subscriptionPlanName {
    final profile = _currentProfile.value;
    return profile?.subscription.planName ?? 'No Plan';
  }

  /// Check if user is verified
  bool get isUserVerified {
    final profile = _currentProfile.value;
    return profile?.isVerified ?? false;
  }

  /// Get verification progress
  double get verificationProgress {
    final profile = _currentProfile.value;
    return profile?.verificationStatus.progress ?? 0.0;
  }

  /// Debug method to log profile information
  void debugProfile() {
    final profile = _currentProfile.value;
    if (profile == null) {
      debugPrint('📝 No profile loaded');
      return;
    }

    debugPrint('📝 Profile Debug Info:');
    debugPrint('   Name: ${profile.fullName}');
    debugPrint('   Email: ${profile.email}');
    debugPrint('   Role: ${profile.displayRole}');
    debugPrint('   Verified: ${profile.isVerified}');
    debugPrint(
        '   Subscription: ${profile.subscription.planName} (${profile.subscription.status})');
    debugPrint('   Permissions: ${profile.permissions.length} permissions');

    // Role-specific debug info
    if (profile is AdvocateProfile) {
      debugPrint('   Roll Number: ${profile.rollNumber}');
      debugPrint('   TLS Chapter: ${profile.regionalChapter?.name}');
    } else if (profile is LawyerProfile) {
      debugPrint('   Experience: ${profile.yearsOfExperience} years');
      debugPrint('   Workplace: ${profile.placeOfWork?.nameEn}');
    } else if (profile is LawStudentProfile) {
      debugPrint('   University: ${profile.universityName}');
      debugPrint('   Year: ${profile.yearOfStudy}');
    }
  }
}

import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart' as dio;
import '../../../services/api_service.dart';
import '../../../services/token_storage_service.dart';
import '../../../services/permission_service.dart';
import '../../../config/environment_config.dart';
import '../../../config/dio_config.dart';
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

  // Caching mechanism
  DateTime? _lastFetchTime;
  static const Duration _cacheValidDuration =
      Duration(minutes: 5); // Cache for 5 minutes
  bool _isFetching = false; // Prevent concurrent API calls

  @override
  void onInit() {
    super.onInit();
    debugPrint('👤 ProfileService initialized');

    // Load cached profile on initialization to avoid unnecessary API calls
    _loadCachedProfileOnInit();
  }

  /// Load cached profile during initialization
  void _loadCachedProfileOnInit() async {
    try {
      if (_tokenStorage.isLoggedIn) {
        final cachedProfile = await loadCachedProfile();
        if (cachedProfile != null) {
          // Set cache time to a bit ago so it's valid but will refresh when needed
          _lastFetchTime = DateTime.now().subtract(const Duration(minutes: 1));
          debugPrint('📋 Initialized with cached profile');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load cached profile on init: $e');
    }
  }

  /// Update profile picture
  Future<bool> updateProfilePicture(String imagePath) async {
    try {
      debugPrint('📤 Updating profile picture...');

      // Get the token for authorization
      await _tokenStorage.waitForInitialization();
      final token = _tokenStorage.accessToken;

      if (token.isEmpty) {
        debugPrint('❌ No access token available');
        return false;
      }

      // Create multipart file
      final file = await dio.MultipartFile.fromFile(
        imagePath,
        filename: imagePath.split('/').last,
      );

      final formData = dio.FormData.fromMap({
        'profile_picture': file,
      });

      // Use Dio directly with proper configuration for multipart
      final dioInstance = DioConfig.instance;
      final response = await dioInstance.patch(
        EnvironmentConfig.profilePictureUrl,
        data: formData,
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-API-Key': EnvironmentConfig.apiKey,
          },
          contentType: 'multipart/form-data',
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('📥 Profile picture update response: ${response.statusCode}');
      debugPrint('📥 Response data: ${response.data}');

      if (response.statusCode == 200) {
        debugPrint('✅ Profile picture updated successfully');

        // Update the profile picture URL immediately from response
        if (response.data != null && response.data is Map) {
          final newProfilePictureUrl = response.data['profile_picture_url'] ??
              response.data['profile_picture'];
          if (newProfilePictureUrl != null && _currentProfile.value != null) {
            // Create updated profile with new picture URL
            final updatedProfile = UserProfile(
              id: _currentProfile.value!.id,
              email: _currentProfile.value!.email,
              firstName: _currentProfile.value!.firstName,
              lastName: _currentProfile.value!.lastName,
              dateOfBirth: _currentProfile.value!.dateOfBirth,
              userRole: _currentProfile.value!.userRole,
              gender: _currentProfile.value!.gender,
              isActive: _currentProfile.value!.isActive,
              isVerified: _currentProfile.value!.isVerified,
              contact: _currentProfile.value!.contact,
              address: _currentProfile.value!.address,
              verificationStatus: _currentProfile.value!.verificationStatus,
              permissions: _currentProfile.value!.permissions,
              subscription: _currentProfile.value!.subscription,
              dateJoined: _currentProfile.value!.dateJoined,
              lastLogin: _currentProfile.value!.lastLogin,
              idNumber: _currentProfile.value!.idNumber,
              profilePicture: newProfilePictureUrl,
            );

            // Update the observable immediately
            _currentProfile.value = updatedProfile;
            debugPrint('🖼️ Profile picture updated in local state');
          }
        }

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error updating profile picture: $e');
      if (e is dio.DioException) {
        debugPrint('   Response: ${e.response?.data}');
        debugPrint('   Status code: ${e.response?.statusCode}');
      }
      return false;
    }
  }

  /// Fetch user profile from API with caching
  Future<UserProfile?> fetchProfile({bool forceRefresh = false}) async {
    // Check if we have a valid cached profile
    if (!forceRefresh && _currentProfile.value != null && _isCacheValid()) {
      debugPrint(
          '📋 Using cached profile data (${_getRemainingCacheTime()}s remaining)');
      return _currentProfile.value;
    }

    // Prevent concurrent API calls
    if (_isFetching) {
      debugPrint('⏳ Profile fetch already in progress, waiting...');
      while (_isFetching) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _currentProfile.value;
    }

    _isFetching = true;
    _isLoading.value = true;
    _error.value = '';

    try {
      debugPrint('📤 Fetching user profile from API...');

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
        _lastFetchTime = DateTime.now(); // Update cache timestamp

        // Store profile in local storage for caching
        await _tokenStorage.storeUserProfile(response.data);

        // Update user data in token storage for admin role detection
        await _tokenStorage.updateUserProfile(response.data);

        // Notify permission service that profile was updated
        try {
          final permService = Get.find<PermissionService>();
          permService.debugSubscriptionStatus();
        } catch (e) {
          debugPrint('⚠️ Could not notify permission service: $e');
        }

        debugPrint(
            '✅ Profile fetched and cached: ${profile.fullName} (${profile.userRole.roleName})');
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
      _isFetching = false; // Reset fetch flag
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

  /// Check if cached profile is still valid
  bool _isCacheValid() {
    if (_lastFetchTime == null) return false;

    final now = DateTime.now();
    final difference = now.difference(_lastFetchTime!);

    return difference < _cacheValidDuration;
  }

  /// Get remaining cache time in seconds
  int _getRemainingCacheTime() {
    if (_lastFetchTime == null) return 0;

    final now = DateTime.now();
    final elapsed = now.difference(_lastFetchTime!);
    final remaining = _cacheValidDuration - elapsed;

    return remaining.inSeconds > 0 ? remaining.inSeconds : 0;
  }

  /// Clear profile cache and force refresh on next fetch
  void clearCache() {
    _lastFetchTime = null;
    _currentProfile.value = null;
    debugPrint('🧹 Profile cache cleared');
  }

  /// Get profile with caching (public method)
  Future<UserProfile?> getProfile({bool forceRefresh = false}) async {
    return await fetchProfile(forceRefresh: forceRefresh);
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

import 'package:get/get.dart';
import '../../../../services/token_storage_service.dart';

/// Utility class for managing user roles and permissions in hub content system
class UserRoleManager {
  static final TokenStorageService _tokenStorage =
      Get.find<TokenStorageService>();

  /// Check if current user is admin (staff or superuser)
  static bool isAdmin() {
    return _tokenStorage.isUserAdmin();
  }

  /// Check if current user is superuser
  static bool isSuperuser() {
    return _tokenStorage.isUserSuperuser();
  }

  /// Check if user has specific permission
  static bool hasPermission(String permission) {
    return _tokenStorage.hasAdminPermission(permission);
  }

  /// Check if user can create content in any hub
  static bool canCreateContent() {
    return _tokenStorage.canCreateContent();
  }

  /// Check if user can moderate content (admin permissions)
  static bool canModerateContent() {
    return isAdmin() ||
        hasPermission('can_approve_documents') ||
        hasPermission('can_verify_others');
  }

  /// Check if user can delete content
  static bool canDeleteContent() {
    return isAdmin() ||
        hasPermission('delete_polauser') ||
        hasPermission('delete_document');
  }

  /// Check if user can access admin features in hub content
  static bool canAccessAdminFeatures() {
    return isAdmin();
  }

  /// Check if user can view all content (admin privilege)
  static bool canViewAllContent() {
    // Admins (staff or superuser) can view all content in all hubs
    return isAdmin();
  }

  /// Check if user can moderate content across all hubs
  static bool canModerateAllHubs() {
    // Only admins can moderate across all hubs
    return isAdmin();
  }

  /// Get user display name
  static String getUserDisplayName() {
    return _tokenStorage.getUserDisplayName();
  }

  /// Get all user permissions
  static List<String> getUserPermissions() {
    return _tokenStorage.getUserPermissions();
  }

  /// Debug method to print all user data and permissions
  static void debugUserPermissions() {
    print('🔍 === USER PERMISSIONS DEBUG ===');
    print('🔍 Is Admin: ${isAdmin()}');
    print('🔍 Is Logged In: ${_tokenStorage.isLoggedIn}');
    print('🔍 User Role: ${_tokenStorage.getUserRole() ?? "None"}');
    print('🔍 User Email: ${_tokenStorage.getUserEmail() ?? "None"}');
    print('🔍 User Display Name: ${getUserDisplayName()}');
    print('🔍 User Permissions: ${getUserPermissions()}');

    // Check subscription permissions
    final userData = _tokenStorage.userData;
    if (userData != null) {
      print('🔍 User Data Keys: ${userData.keys.toList()}');

      final subscription = userData['subscription'] as Map<String, dynamic>?;
      if (subscription != null) {
        print('🔍 Subscription Keys: ${subscription.keys.toList()}');

        final permissions =
            subscription['permissions'] as Map<String, dynamic>?;
        if (permissions != null) {
          print('🔍 Subscription Permissions: $permissions');
        } else {
          print('🔍 No subscription permissions found');
        }
      } else {
        print('🔍 No subscription data found');
      }
    } else {
      print('🔍 No user data found');
    }

    // Test hub access
    for (final hubType in ['advocates', 'students', 'forum', 'legal_ed']) {
      print('🔍 Can access $hubType hub: ${canAccessHub(hubType)}');
      print(
          '🔍 Can create content in $hubType hub: ${canCreateContentInHub(hubType)}');
    }
    print('🔍 === END DEBUG ===');
  }

  /// Check if user can access specific hub based on subscription and admin status
  static bool canAccessHub(String hubType) {
    // Admins can access all hubs
    if (isAdmin()) return true;

    // Get user role
    final userRole = _tokenStorage.getUserRole()?.toLowerCase() ?? '';

    // Role checks based on ROLE_CHOICES
    final isAdvocate = userRole.contains('advocate');
    final isLawStudent = userRole.contains('law_student');
    final isLecturer = userRole.contains('lecturer');
    final isLawFirm = userRole.contains('law_firm');

    // Check hub-specific access permissions
    switch (hubType) {
      case 'advocates':
        // Advocates hub - ONLY advocates can access (not lawyers, law firms, or others)
        final result = isAdvocate;
        print(
            '🔍 canAccessHub: Advocates - userRole: "$userRole", isAdvocate: $isAdvocate, result: $result');
        return result;

      case 'students':
        // Students hub - only law students and lecturers can access
        final hasStudentPerm =
            _tokenStorage.hasSubscriptionPermission('can_access_student_hub');
        final result = hasStudentPerm || isLawStudent || isLecturer;
        print(
            '🔍 canAccessHub: Students - hasStudentPerm: $hasStudentPerm, isLawStudent: $isLawStudent, isLecturer: $isLecturer, result: $result');
        return result;

      case 'forum':
        // Forum - open to ALL logged-in users (community hub)
        final result = _tokenStorage.isLoggedIn;
        print(
            '🔍 canAccessHub: Forum - open to all logged-in users, result: $result');
        return result;

      case 'legal_ed':
        // Legal education - open to all logged-in users
        final result = _tokenStorage.isLoggedIn;
        print(
            '🔍 canAccessHub: Legal Ed - open to all logged-in users, result: $result');
        return result;

      default:
        print('🔍 canAccessHub: Unknown hub "$hubType" - denying');
        return false;
    }
  }

  /// Check if user can create premium content (pricing)
  static bool canCreatePremiumContent() {
    // Admins can always create premium content
    if (isAdmin()) return true;

    // Advocates can create premium content in advocates hub
    if (hasPermission('can_generate_documents')) return true;

    // For now, allow all users to create premium content in community forum
    // This can be further restricted based on subscription later
    return true;
  }

  /// Get user role for UI display
  static String getUserRoleDisplayName() {
    if (isSuperuser()) return 'Super Administrator';
    if (isAdmin()) return 'Administrator';
    return 'User';
  }

  /// Check if user has content creation permissions for specific hub
  static bool canCreateContentInHub(String hubType) {
    print(
        '🔍 UserRoleManager: Checking content creation permissions for hub "$hubType"');
    print('🔍 UserRoleManager: User is admin: ${isAdmin()}');
    print(
        '🔍 UserRoleManager: User role: ${_tokenStorage.getUserRole() ?? "Unknown"}');

    // Check hub-specific permissions
    switch (hubType) {
      case 'advocates':
        // Advocates hub - admins OR verified advocates
        final canAccess = canAccessHub(hubType);
        final result = isAdmin() || canAccess;
        print(
            '🔍 UserRoleManager: Advocates hub - canAccess: $canAccess, final result: $result');
        return result;
      case 'students':
        // Students hub - admins OR users with subscription
        final canAccess = canAccessHub(hubType);
        final result = isAdmin() || canAccess;
        print(
            '🔍 UserRoleManager: Students hub - canAccess: $canAccess, final result: $result');
        return result;
      case 'forum':
        // Forum - ALL logged-in users can create posts (community hub)
        final result = _tokenStorage.isLoggedIn;
        print(
            '🔍 UserRoleManager: Forum hub - all logged-in users can post, result: $result');
        return result;
      case 'legal_ed':
        // Legal education - ONLY admins can create content
        final result = isAdmin();
        print('🔍 UserRoleManager: Legal Ed hub - admin only, result: $result');
        return result;
      default:
        print(
            '🔍 UserRoleManager: Unknown hub type "$hubType" - denying access');
        return false;
    }
  }

  /// Check if user can set prices for content in specific hub
  static bool canSetPrice(String hubType) {
    switch (hubType) {
      case 'students':
        // Students hub - all users can create payable content
        return canCreateContentInHub(hubType);
      case 'legal_ed':
        // Legal Education hub - only admins can create payable content
        return isAdmin();
      default:
        // No pricing allowed in other hubs
        return false;
    }
  }

  /// Get content creation limits for user
  static Map<String, dynamic> getContentLimits() {
    final userData = _tokenStorage.userData;
    if (userData == null) return {};

    // Admins have no limits
    if (isAdmin()) {
      return {
        'has_limits': false,
        'can_upload_files': true,
        'max_file_size_mb': 100,
        'can_set_price': true,
        'can_create_premium': true,
      };
    }

    // Get subscription limits
    final subscription = userData['subscription'] as Map<String, dynamic>?;
    final permissions = subscription?['permissions'] as Map<String, dynamic>?;

    return {
      'has_limits': true,
      'can_upload_files': permissions?['can_generate_documents'] == true,
      'max_file_size_mb': 50,
      'can_set_price': false,
      'can_create_premium': false,
      'questions_limit': permissions?['questions_limit'] ?? 0,
      'documents_limit': permissions?['free_documents_limit'] ?? 0,
    };
  }

  /// Debug method to print user role information
  static void debugUserRole() {
    final userData = _tokenStorage.userData;
    print('🔐 === USER ROLE DEBUG ===');
    print('👤 Display Name: ${getUserDisplayName()}');
    print('🎭 Role: ${getUserRoleDisplayName()}');
    print('🔓 Is Admin: ${isAdmin()}');
    print('⭐ Is Superuser: ${isSuperuser()}');
    print('👮 Is Staff: ${userData?['is_staff'] ?? false}');
    print('🔑 Is Superuser (raw): ${userData?['is_superuser'] ?? false}');
    print('👁️ Can View All Content: ${canViewAllContent()}');
    print('✏️ Can Create Content: ${canCreateContent()}');
    print('🛡️ Can Moderate: ${canModerateContent()}');
    print('🗑️ Can Delete: ${canDeleteContent()}');
    print('📋 Permissions: ${getUserPermissions().join(', ')}');
    print('📊 Content Limits: ${getContentLimits()}');
    print('🔐 === END DEBUG ===');
  }
}

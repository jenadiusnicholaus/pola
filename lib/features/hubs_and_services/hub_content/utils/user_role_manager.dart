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

  /// Check if user can access specific hub based on subscription and admin status
  static bool canAccessHub(String hubType) {
    // Admins can access all hubs
    if (isAdmin()) return true;

    // Check subscription permissions for regular users
    return _tokenStorage.canCreateContent();
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
    // Check hub-specific permissions
    switch (hubType) {
      case 'advocates':
        // Advocates hub - admins OR verified advocates
        return isAdmin() || canAccessHub(hubType);
      case 'students':
        // Students hub - admins OR users with subscription
        return isAdmin() || canAccessHub(hubType);
      case 'forum':
        // Forum - admins OR all active users (community access)
        return isAdmin() || canAccessHub(hubType);
      case 'legal_ed':
        // Legal education - ONLY admins can create content
        return isAdmin();
      default:
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

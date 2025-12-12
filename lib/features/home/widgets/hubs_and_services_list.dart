import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../hubs_and_services/data.dart';
import '../controllers/home_controller.dart';
import '../../../services/token_storage_service.dart';
import '../../hubs_and_services/hub_content/utils/user_role_manager.dart';

class HubsAndServicesList extends StatelessWidget {
  const HubsAndServicesList({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) => _buildContent(context, controller),
    );
  }

  Widget _buildContent(BuildContext context, HomeController controller) {
    // Debug: Check user role and login status
    debugPrint('🔍 HUB FILTER: User logged in: ${controller.isLoggedIn}');
    debugPrint(
        '🔍 HUB FILTER: Raw user role: "${controller.userRole}" (type: ${controller.userRole.runtimeType})');

    // Let's also check the TokenStorageService directly
    final tokenService = Get.find<TokenStorageService>();
    final directRole = tokenService.getUserRole();
    debugPrint('🔍 HUB FILTER: Direct from TokenService: "$directRole"');

    // Check admin status using UserRoleManager
    final isAdmin = UserRoleManager.isAdmin();
    debugPrint('🔍 HUB FILTER: Admin status check: $isAdmin');

    if (isAdmin) {
      debugPrint('🔍 HUB FILTER: ✅ User is admin - should see ALL hubs');
    } else {
      debugPrint(
          '🔍 HUB FILTER: ❌ User is not admin - role-based filtering applied');
    }

    // If role is null, try to fetch it asynchronously
    if (controller.userRole == null && controller.isLoggedIn) {
      debugPrint(
          '🔍 HUB FILTER: Role is null but user is logged in, fetching async...');
      controller.getUserRoleAsync().then((asyncRole) {
        debugPrint('🔍 HUB FILTER: Async role result: "$asyncRole"');
      });
    }

    // Filter hubs based on user role
    final allHubs = HubsAndServicesData.hubAndServices
        .where((item) => item['type'] == 'hub')
        .toList();

    debugPrint(
        '🔍 HUB FILTER: All available hubs: ${allHubs.map((h) => h['key']).join(', ')}');

    final hubs = _filterHubsByRole(allHubs, controller.userRole);

    debugPrint(
        '🔍 HUB FILTER: Filtered hubs: ${hubs.map((h) => h['key']).join(', ')}');

    final services = HubsAndServicesData.hubAndServices
        .where((item) => item['type'] == 'service')
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          _buildSectionHeader(context),
          const SizedBox(height: 24),

          // Hubs Section
          if (hubs.isNotEmpty) ...[
            _buildSubsectionTitle(
                context, 'Legal Hubs', Icons.hub, Colors.blue, hubs.length),
            const SizedBox(height: 16),
            _buildItemsList(context, hubs.cast<Map<String, String>>()),
            const SizedBox(height: 32),
          ],

          // Services Section
          if (services.isNotEmpty) ...[
            _buildSubsectionTitle(context, 'Legal Services',
                Icons.miscellaneous_services, Colors.green, services.length),
            const SizedBox(height: 16),
            _buildItemsList(context, services),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance,
              color: theme.colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Legal Platform',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Access comprehensive legal resources and services',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubsectionTitle(
      BuildContext context, String title, IconData icon, Color color,
      [int? count]) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
            letterSpacing: 0.2,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
        const SizedBox(width: 12),
        Expanded(
          child: Divider(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList(
      BuildContext context, List<Map<String, String>> items) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == items.length - 1;

        return _buildHubServiceItem(
          context,
          item,
          isLast,
        );
      }).toList(),
    );
  }

  Widget _buildHubServiceItem(
    BuildContext context,
    Map<String, String> item,
    bool isLast,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final key = item['key'] ?? '';
    final labelEng = item['label_eng'] ?? '';
    final labelSw = item['label_sw'] ?? '';
    final type = item['type'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _onItemTap(key, type),
          splashColor: theme.colorScheme.primary.withOpacity(0.1),
          highlightColor: theme.colorScheme.primary.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Labels with separator - Swahili first, then English
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: labelSw,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: 0.1,
                          ),
                        ),
                        TextSpan(
                          text: ' | ',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                        TextSpan(
                          text: labelEng,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Subtle arrow icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onItemTap(String key, String type) {
    final controller = Get.find<HomeController>();

    // Check if user has access to this hub
    if (type == 'hub' && !_hasAccessToHub(key, controller.userRole)) {
      Get.snackbar(
        'Access Denied',
        'You don\'t have permission to access this hub',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Handle navigation based on key
    switch (key) {
      case 'legal_ed':
        Get.toNamed('/legal-education');
        break;
      case 'advocates':
        Get.toNamed('/advocates-hub');
        break;
      case 'students':
        Get.toNamed('/students-hub');
        break;
      case 'forum':
        Get.toNamed('/forum-hub');
        break;
      case 'ask_a_legal_question':
        Get.toNamed('/my-questions');
        break;
      case 'talk_to_lawyers':
        Get.toNamed('/consultants');
        break;
      case 'legal_templates':
        Get.toNamed('/templates');
        break;
      case 'search_nearby_lawyers':
        Get.toNamed('/nearby-lawyers');
        break;
      default:
        // Show a snackbar for other items - will implement later
        Get.snackbar(
          '${type.capitalize} Selected',
          'Coming Soon: $key',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: type == 'hub' ? Colors.blue : Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        break;
    }
  }

  /// Normalize role name to consistent string
  String _normalizeRole(String? userRole) {
    debugPrint(
        '🔍 NORMALIZE ROLE: Input = "$userRole" (type: ${userRole.runtimeType})');

    if (userRole == null || userRole.isEmpty) {
      debugPrint(
          '🔍 NORMALIZE ROLE: No user role provided, defaulting to citizen');
      return 'citizen';
    }

    final normalized = userRole.toLowerCase().trim();
    debugPrint('🔍 NORMALIZE ROLE: "$userRole" → "$normalized"');
    return normalized;
  }

  /// Check if user has access to specific hub
  bool _hasAccessToHub(String hubKey, String? userRole) {
    debugPrint('🔍 ACCESS CHECK: Hub "$hubKey", Raw Role: "$userRole"');

    // First check if user is admin using proper admin detection
    if (UserRoleManager.isAdmin()) {
      debugPrint(
          '🔍 ACCESS CHECK: Admin user (is_staff/is_superuser) - access to ALL hubs');
      return true;
    }

    if (userRole == null) {
      debugPrint('🔍 ACCESS CHECK: No user role - only forum access');
      // Only forum access for non-logged-in users
      return hubKey == 'forum';
    }

    final role = _normalizeRole(userRole);
    debugPrint('🔍 ACCESS CHECK: Normalized role: "$role"');

    bool hasAccess = false;
    switch (hubKey) {
      case 'advocates':
        // Advocates, lawyers, and law firms can access
        hasAccess = ['advocate', 'lawyer', 'law_firm', 'admin'].contains(role);
        debugPrint(
            '🔍 ACCESS CHECK: Advocates hub - checking if role "$role" in [advocate, lawyer, law_firm, admin]: $hasAccess');
        break;
      case 'students':
        hasAccess = ['law_student', 'lecturer', 'admin'].contains(role);
        debugPrint(
            '🔍 ACCESS CHECK: Students hub - checking if role "$role" in [law_student, lecturer, admin]: $hasAccess');
        break;
      case 'forum':
        hasAccess = true; // Forum is accessible to all
        debugPrint(
            '🔍 ACCESS CHECK: Forum hub - accessible to all: $hasAccess');
        break;
      case 'legal_ed':
        hasAccess = true; // Legal Education is now accessible to all users
        debugPrint(
            '🔍 ACCESS CHECK: Legal Ed hub - accessible to all users: $hasAccess');
        break;
      default:
        hasAccess = false;
        debugPrint('🔍 ACCESS CHECK: Unknown hub "$hubKey" - no access');
        break;
    }

    debugPrint(
        '🔍 ACCESS CHECK RESULT: Hub "$hubKey" for role "$role" = $hasAccess');
    return hasAccess;
  }

  /// Filter hubs based on user role
  List<Map<String, dynamic>> _filterHubsByRole(
      List<Map<String, dynamic>> hubs, String? userRole) {
    print(
        'DEBUG FILTER: Input user role: "$userRole" (type: ${userRole.runtimeType})');

    // Check admin status first - admins see all hubs regardless of role
    if (UserRoleManager.isAdmin()) {
      print('DEBUG FILTER: Admin user detected - showing ALL hubs');
      return hubs; // Return all hubs for admin
    }

    // If user is not logged in, only show forum
    if (userRole == null || userRole.isEmpty) {
      print('DEBUG FILTER: No user role - showing only forum');
      return hubs.where((hub) => hub['key'] == 'forum').toList();
    }

    // Convert role to normalized string for comparison
    final normalizedRole = _normalizeRole(userRole);
    print('DEBUG FILTER: Normalized role: "$normalizedRole"');

    // If normalization failed, show only forum
    if (normalizedRole.isEmpty) {
      print('DEBUG FILTER: Role normalization failed - showing only forum');
      return hubs.where((hub) => hub['key'] == 'forum').toList();
    }

    // Filter hubs based on role access
    final filteredHubs = hubs.where((hub) {
      final hubKey = hub['key'] as String?;
      if (hubKey == null) return false;

      final hasAccess = _hasAccessToHub(hubKey, userRole);
      print(
          'DEBUG FILTER: Hub "$hubKey" access for role "$normalizedRole": $hasAccess');
      return hasAccess;
    }).toList();

    print(
        'DEBUG FILTER: Final filtered hubs: ${filteredHubs.map((h) => h['key']).join(', ')}');
    return filteredHubs;
  }
}

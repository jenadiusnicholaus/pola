import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../hubs_and_services/data.dart';
import '../../../constants/app_colors.dart';
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
            _buildItemsList(context, hubs.cast<Map<String, String>>(),
                Colors.blue.withOpacity(0.1), Colors.blue),
            const SizedBox(height: 32),
          ],

          // Services Section
          if (services.isNotEmpty) ...[
            _buildSubsectionTitle(context, 'Legal Services',
                Icons.miscellaneous_services, Colors.green, services.length),
            const SizedBox(height: 16),
            _buildItemsList(
                context, services, Colors.green.withOpacity(0.1), Colors.green),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isDark
              ? [
                  AppColors.primaryAmber.withOpacity(0.2),
                  AppColors.primaryAmber.withOpacity(0.08),
                ]
              : [
                  AppColors.primaryAmber.withOpacity(0.12),
                  AppColors.primaryAmber.withOpacity(0.04),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.primaryAmber.withOpacity(0.4)
              : AppColors.primaryAmber.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.primaryAmber.withOpacity(0.15)
                : AppColors.primaryAmber.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryAmber,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.account_balance,
              color: isDark ? Colors.black87 : Colors.black,
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Access comprehensive legal resources and services',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
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
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Color.lerp(color, Colors.white, 0.2)
                : Color.lerp(color, Colors.black, 0.3),
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Color.lerp(color, Colors.white, 0.3)
                    : Color.lerp(color, Colors.black, 0.4),
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.05),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList(BuildContext context, List<Map<String, String>> items,
      Color bgColor, Color accentColor) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == items.length - 1;

        return _buildHubServiceItem(
          context,
          item,
          bgColor,
          accentColor,
          isLast,
        );
      }).toList(),
    );
  }

  Widget _buildHubServiceItem(
    BuildContext context,
    Map<String, String> item,
    Color bgColor,
    Color accentColor,
    bool isLast,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final key = item['key'] ?? '';
    final labelEng = item['label_eng'] ?? '';
    final labelSw = item['label_sw'] ?? '';
    final type = item['type'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onItemTap(key, type),
          splashColor: isDark
              ? accentColor.withOpacity(0.2)
              : accentColor.withOpacity(0.1),
          highlightColor: isDark
              ? accentColor.withOpacity(0.1)
              : accentColor.withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? theme.colorScheme.outline.withOpacity(0.3)
                    : theme.colorScheme.outline.withOpacity(0.2),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Labels with separator
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: labelEng,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        TextSpan(
                          text: ' | ',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? AppColors.primaryAmber.withOpacity(0.7)
                                : Colors.red.withOpacity(0.7),
                          ),
                        ),
                        TextSpan(
                          text: labelSw,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.primaryAmber : Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Subtle arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
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
        // Only advocates and law firms can access (NOT lawyers/paralegals)
        hasAccess = ['advocate', 'law_firm', 'admin'].contains(role);
        debugPrint(
            '🔍 ACCESS CHECK: Advocates hub - checking if role "$role" in [advocate, law_firm, admin]: $hasAccess');
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

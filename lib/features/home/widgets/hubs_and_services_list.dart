import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import '../../../utils/navigation_helper.dart';
import '../../hubs_and_services/data.dart';
import '../controllers/home_controller.dart';
import '../../../services/token_storage_service.dart';
import '../../../services/language_service.dart';
import '../../profile/services/profile_service.dart';
import '../../hubs_and_services/hub_content/utils/user_role_manager.dart';

class HubsAndServicesList extends StatelessWidget {
  const HubsAndServicesList({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        // Make it reactive to profile changes
        return Obx(() {
          // Trigger rebuild when profile changes
          try {
            final profileService = Get.find<ProfileService>();
            final profile = profileService.currentProfile;
            debugPrint(
                '🔄 HubsAndServicesList rebuild - Profile: ${profile?.email ?? 'not loaded'}');
          } catch (e) {
            debugPrint('⚠️ ProfileService not ready: $e');
          }
          return _buildContent(context, controller);
        });
      },
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

    // Show ALL hubs to all users — access control happens on tap
    final hubs = allHubs;

    debugPrint(
        '🔍 HUB FILTER: Showing all hubs: ${hubs.map((h) => h['key']).join(', ')}');

    // Filter services based on role permissions
    final allServices = HubsAndServicesData.hubAndServices
        .where((item) => item['type'] == 'service')
        .toList();

    final services = _filterServicesByRole(allServices);

    debugPrint(
        '🔍 SERVICE FILTER: Filtered services: ${services.map((s) => s['key']).join(', ')}');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          // _buildSectionHeader(context),
          const SizedBox(height: 24),

          // Hubs Section
          if (hubs.isNotEmpty) ...[
            _buildSubsectionTitle(
                context, tr('Legal Hubs'), Icons.hub, hubs.length),
            const SizedBox(height: 16),
            _buildItemsList(context, hubs.cast<Map<String, String>>()),
            const SizedBox(height: 32),
          ],

          // Services Section
          if (services.isNotEmpty) ...[
            _buildSubsectionTitle(context, tr('Legal Services'),
                Icons.miscellaneous_services, services.length),
            const SizedBox(height: 16),
            _buildItemsList(context, services.cast<Map<String, String>>()),
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
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Legal Platform'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('Access comprehensive legal resources and services'),
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
      BuildContext context, String title, IconData icon,
      [int? count]) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            size: 17,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            letterSpacing: 0.2,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
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
    final subtitleEng = item['subtitle_eng'] ?? '';
    final subtitleSw = item['subtitle_sw'] ?? '';
    final type = item['type'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _onItemTap(key, type),
          splashColor: theme.colorScheme.primary.withOpacity(0.08),
          highlightColor: theme.colorScheme.primary.withOpacity(0.04),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon tile
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getItemIcon(key),
                    size: 20,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 14),

                // Label + subtitle follow the user's selected language
                Expanded(
                  child: Obx(() {
                    final lang = Get.find<LanguageService>().languageObs.value;
                    final label = lang == 'sw'
                        ? (labelSw.isNotEmpty ? labelSw : labelEng)
                        : (labelEng.isNotEmpty ? labelEng : labelSw);
                    final subtitle = lang == 'sw'
                        ? (subtitleSw.isNotEmpty ? subtitleSw : subtitleEng)
                        : (subtitleEng.isNotEmpty ? subtitleEng : subtitleSw);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: 0.1,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.3,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.55),
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
                ),

                // Chevron button
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.45),
                  ),
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
      _showRoleChangeDialog(key);
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
      case 'tanzania_statutes_laws':
        Get.toNamed('/statutes');
        break;
      case 'search_nearby_lawyers':
        Get.toNamed('/nearby-lawyers');
        break;
      default:
        // Show a snackbar for other items - will implement later
        NavigationHelper.showSafeSnackbar(
          title:
              tr('{type} Selected').replaceAll('{type}', '${type.capitalize}'),
          message: tr('Coming Soon: {key}').replaceAll('{key}', key),
          backgroundColor: type == 'hub' ? Colors.blue : Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        break;
    }
  }

  /// Icon for a hub/service key
  IconData _getItemIcon(String key) {
    switch (key) {
      case 'legal_ed':
        return Icons.menu_book_rounded;
      case 'talk_to_lawyers':
        return Icons.forum_rounded;
      case 'ask_a_legal_question':
        return Icons.help_outline_rounded;
      case 'forum':
        return Icons.groups_rounded;
      case 'legal_templates':
        return Icons.description_outlined;
      case 'tanzania_statutes_laws':
        return Icons.account_balance_rounded;
      case 'advocates':
        return Icons.gavel_rounded;
      case 'students':
        return Icons.school_rounded;
      case 'search_nearby_lawyers':
        return Icons.location_on_outlined;
      default:
        return Icons.star_outline_rounded;
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

    // Convert to lowercase and trim whitespace
    var normalized = userRole.toLowerCase().trim();

    // Handle variations of role names
    if (normalized == 'advocates' || normalized == 'wakili') {
      normalized = 'advocate';
    } else if (normalized == 'lawyers' || normalized == 'mwanasheria') {
      normalized = 'lawyer';
    } else if (normalized == 'students' || normalized == 'mwanafunzi') {
      normalized = 'law_student';
    } else if (normalized == 'lecturers' || normalized == 'mhadhiri') {
      normalized = 'lecturer';
    }

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

    final role = _normalizeRole(userRole);
    debugPrint('🔍 ACCESS CHECK: Normalized role: "$role"');

    // NOTE: no blanket grant for professional roles — role-based hubs
    // (advocates, students) must enforce their own role so lawyers,
    // paralegals and law firms don't get access to advocate-only content.
    // legal_ed and forum are open to all users anyway.

    bool hasAccess = false;
    switch (hubKey) {
      case 'legal_ed':
        // Legal Education is accessible to ALL users
        hasAccess = true;
        debugPrint(
            '🔍 ACCESS CHECK: Legal Ed hub - accessible to all users: $hasAccess');
        break;
      case 'forum':
        // Community Forum is accessible to ALL users
        hasAccess = true;
        debugPrint(
            '🔍 ACCESS CHECK: Forum hub - accessible to all users: $hasAccess');
        break;
      case 'advocates':
        // Only advocates can access advocate hub — lawyers, paralegals
        // and law firms do NOT belong to this role-based hub.
        hasAccess = role == 'advocate';
        debugPrint(
            '🔍 ACCESS CHECK: Advocates hub - checking if role "$role" is advocate: $hasAccess');
        break;
      case 'students':
        // Students, lecturers, or anyone with the student-hub
        // subscription permission can access the student hub.
        bool hasStudentPerm = false;
        try {
          hasStudentPerm = Get.find<TokenStorageService>()
              .hasSubscriptionPermission('can_access_student_hub');
        } catch (_) {}
        hasAccess =
            hasStudentPerm || ['law_student', 'lecturer'].contains(role);
        debugPrint(
            '🔍 ACCESS CHECK: Students hub - perm: $hasStudentPerm, role "$role" in [law_student, lecturer]: $hasAccess');
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

  /// Show all services to all users — professionals can also talk to
  /// each other and find nearby lawyers
  List<Map<String, dynamic>> _filterServicesByRole(
      List<Map<String, dynamic>> services) {
    return services;
  }

  /// Show role-change dialog when user taps a hub they can't access
  void _showRoleChangeDialog(String hubKey) {
    final theme = Get.context?.theme ?? ThemeData.light();
    final hubName = _getHubDisplayName(hubKey);

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.lock_outline,
                color: theme.colorScheme.primary, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                tr('Role Required'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('You need a specific role to access {hub}.')
                  .replaceAll('{hub}', hubName),
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr('Change your role to gain access to this hub and its content.'),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              tr('Cancel'),
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.toNamed('/change-role');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(tr('Change Role')),
          ),
        ],
      ),
    );
  }

  /// Get display name for a hub key
  String _getHubDisplayName(String hubKey) {
    switch (hubKey) {
      case 'advocates':
        return tr('Advocates Hub');
      case 'students':
        return tr('Students & Lecturers Hub');
      case 'forum':
        return tr('Community Forum');
      case 'legal_ed':
        return tr('Legal Education');
      default:
        return hubKey
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
            .join(' ');
    }
  }
}

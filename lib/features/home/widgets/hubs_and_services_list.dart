import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../hubs_and_services/data.dart';
import '../../../constants/app_colors.dart';

class HubsAndServicesList extends StatelessWidget {
  const HubsAndServicesList({super.key});

  @override
  Widget build(BuildContext context) {
    // Separate hubs and services
    final hubs = HubsAndServicesData.hubAndServices
        .where((item) => item['type'] == 'hub')
        .toList();

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
            _buildItemsList(
                context, hubs, Colors.blue.withOpacity(0.1), Colors.blue),
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
    // Handle navigation based on key
    switch (key) {
      case 'legal_ed':
        Get.toNamed('/legal-education');
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
}

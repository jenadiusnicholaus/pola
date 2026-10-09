import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';
import '../../../services/language_service.dart';
import 'package:localization_lite/translate.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: tr('Settings'),
        showLogo: false,
        showTagline: false,
      ),
      body: Obx(
        () {
          final themeController = Get.find<ThemeController>();
          final languageService = Get.find<LanguageService>();
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Theme Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Appearance'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      SizedBox(height: 16),

                      // Theme Mode Selection
                      ListTile(
                        leading: Icon(
                          themeController.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: AppColors.primaryAmber,
                        ),
                        title: Text(tr('Theme')),
                        subtitle:
                            Text('Current: ${themeController.themeModeText}'),
                        trailing: Switch(
                          value: themeController.isDarkMode,
                          onChanged: (value) {
                            themeController.toggleTheme();
                          },
                          activeColor: AppColors.primaryAmber,
                        ),
                      ),

                      // Theme Options
                      Divider(),

                      RadioListTile<ThemeMode>(
                        title: Text(tr('Light')),
                        subtitle: Text(tr('Use light theme')),
                        value: ThemeMode.light,
                        groupValue: themeController.themeMode,
                        onChanged: (ThemeMode? value) {
                          if (value != null) {
                            themeController.changeThemeMode(value);
                          }
                        },
                        activeColor: AppColors.primaryAmber,
                      ),

                      RadioListTile<ThemeMode>(
                        title: Text(tr('Dark')),
                        subtitle: Text(tr('Use dark theme')),
                        value: ThemeMode.dark,
                        groupValue: themeController.themeMode,
                        onChanged: (ThemeMode? value) {
                          if (value != null) {
                            themeController.changeThemeMode(value);
                          }
                        },
                        activeColor: AppColors.primaryAmber,
                      ),

                      RadioListTile<ThemeMode>(
                        title: Text(tr('System')),
                        subtitle: Text(tr('Follow system theme')),
                        value: ThemeMode.system,
                        groupValue: themeController.themeMode,
                        onChanged: (ThemeMode? value) {
                          if (value != null) {
                            themeController.changeThemeMode(value);
                          }
                        },
                        activeColor: AppColors.primaryAmber,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Language Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Language / Lugha'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        tr('Used for content that supports multiple languages (e.g. Elimu ya Kisheria)'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                      ),
                      SizedBox(height: 8),
                      RadioListTile<String>(
                        title: Text(tr('English')),
                        value: 'en',
                        groupValue: languageService.language,
                        onChanged: (value) {
                          if (value != null) {
                            languageService.setLanguage(value);
                          }
                        },
                        activeColor: AppColors.primaryAmber,
                      ),
                      RadioListTile<String>(
                        title: Text(tr('Kiswahili')),
                        value: 'sw',
                        groupValue: languageService.language,
                        onChanged: (value) {
                          if (value != null) {
                            languageService.setLanguage(value);
                          }
                        },
                        activeColor: AppColors.primaryAmber,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Safety & Privacy Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Safety & Privacy'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      SizedBox(height: 16),
                      ListTile(
                        leading: Icon(
                          Icons.block,
                          color: AppColors.primaryAmber,
                        ),
                        title: Text(tr('Blocked Users')),
                        subtitle: Text(tr('Manage users you have blocked')),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Get.toNamed('/blocked-users'),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.flag_outlined,
                          color: AppColors.primaryAmber,
                        ),
                        title: Text(tr('My Reports')),
                        subtitle: Text(tr('View your submitted reports')),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Get.toNamed('/my-reports'),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.privacy_tip_outlined,
                          color: AppColors.primaryAmber,
                        ),
                        title: Text(tr('Manage My Data')),
                        subtitle: Text(
                            tr('Delete specific data without closing account')),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Get.toNamed('/manage-data'),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        title: Text(tr('Delete Account')),
                        subtitle: Text(
                            tr('Permanently delete your account and data')),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Get.toNamed('/delete-account'),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // App Info Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('About'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      SizedBox(height: 16),
                      ListTile(
                        leading: Icon(
                          Icons.info_outline,
                          color: AppColors.primaryAmber,
                        ),
                        title: Text('${AppStrings.appName} App'),
                        subtitle: Text(tr('Version') + ' 1.0.0'),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.gavel,
                          color: AppColors.primaryAmber,
                        ),
                        title: Text(tr('Legal Assistant')),
                        subtitle: Text(tr('Your portable lawyer companion')),
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(
                          Icons.help_outline,
                          color: AppColors.primaryAmber,
                        ),
                        title: Text(tr('Help & Support')),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Navigate to help screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tr('Help & Support coming soon')),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.privacy_tip_outlined,
                          color: AppColors.primaryAmber,
                        ),
                        title: Text(tr('Privacy Policy')),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Navigate to privacy policy
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tr('Privacy Policy coming soon')),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

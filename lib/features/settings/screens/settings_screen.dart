import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Settings',
        showLogo: false,
        showTagline: false,
      ),
      body: GetBuilder<ThemeController>(
        builder: (themeController) {
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
                        'Appearance',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Theme Mode Selection
                      ListTile(
                        leading: Icon(
                          themeController.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: AppColors.primaryAmber,
                        ),
                        title: const Text('Theme'),
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
                      const Divider(),

                      RadioListTile<ThemeMode>(
                        title: const Text('Light'),
                        subtitle: const Text('Use light theme'),
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
                        title: const Text('Dark'),
                        subtitle: const Text('Use dark theme'),
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
                        title: const Text('System'),
                        subtitle: const Text('Follow system theme'),
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

              const SizedBox(height: 16),

              // App Info Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(
                          Icons.info_outline,
                          color: AppColors.primaryAmber,
                        ),
                        title: Text('${AppStrings.appName} App'),
                        subtitle: const Text('Version 1.0.0'),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.gavel,
                          color: AppColors.primaryAmber,
                        ),
                        title: const Text('Legal Assistant'),
                        subtitle: const Text('Your portable lawyer companion'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(
                          Icons.help_outline,
                          color: AppColors.primaryAmber,
                        ),
                        title: const Text('Help & Support'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Navigate to help screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Help & Support coming soon'),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.privacy_tip_outlined,
                          color: AppColors.primaryAmber,
                        ),
                        title: const Text('Privacy Policy'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Navigate to privacy policy
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Privacy Policy coming soon'),
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

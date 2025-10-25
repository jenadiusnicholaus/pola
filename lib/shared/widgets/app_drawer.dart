import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../features/settings/screens/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
            decoration: const BoxDecoration(
              color: AppColors.primaryAmber,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Logo and Name
                Row(
                  children: [
                    const Text(
                      '⚖️',
                      style: TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.appName,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'the lawyer you carry',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.home_outlined,
                    color: AppColors.primaryAmber,
                  ),
                  title: const Text('Home'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.document_scanner_outlined,
                    color: AppColors.primaryAmber,
                  ),
                  title: const Text('Document Scanner'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Document Scanner coming soon!'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.search_outlined,
                    color: AppColors.primaryAmber,
                  ),
                  title: const Text('Legal Research'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Legal Research coming soon!'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.chat_outlined,
                    color: AppColors.primaryAmber,
                  ),
                  title: const Text('Legal Consultation'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Legal Consultation coming soon!'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.library_books_outlined,
                    color: AppColors.primaryAmber,
                  ),
                  title: const Text('Case Library'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Case Library coming soon!'),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.settings_outlined,
                    color: AppColors.primaryAmber,
                  ),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.help_outline,
                    color: AppColors.primaryAmber,
                  ),
                  title: const Text('Help & Support'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Help & Support coming soon!'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: AppColors.primaryAmber,
                  ),
                  title: const Text('About'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppStrings.appName,
      applicationVersion: '1.0.0',
      applicationIcon: const Text('⚖️', style: TextStyle(fontSize: 32)),
      children: const [
        Text(
          'Your portable legal assistant. Get instant access to legal guidance, document analysis, and professional consultation.',
        ),
        SizedBox(height: 16),
        Text(
          'the lawyer you carry',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

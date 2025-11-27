import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_strings.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../services/token_storage_service.dart';
import '../../features/consultation/services/consultation_service.dart';
import '../../features/consultation/screens/consultant_profile_screen.dart';
import '../../features/subscription/screens/subscription_plans_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: Column(
        children: [
          // Professional Header
          _buildDrawerHeader(context, theme),

          // Navigation Section
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildNavigationSection(context, theme),
                  _buildConsultationSection(context, theme),
                  _buildToolsSection(context, theme),
                  _buildAccountSection(context, theme),
                  _buildSupportSection(context, theme),
                ],
              ),
            ),
          ),

          // Professional Footer
          _buildDrawerFooter(context, theme),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Section
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.onPrimary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 24,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'John Advocate',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Premium Member',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // App Branding
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⚖️',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.appName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'the lawyer you carry',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSection(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        _buildSectionHeader('Navigation', theme),
        _buildDrawerItem(
          context: context,
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          title: 'Home',
          subtitle: 'Dashboard & Overview',
          onTap: () => _navigateAndClose(context, '/home'),
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.forum_outlined,
          activeIcon: Icons.forum,
          title: 'Community Posts',
          subtitle: 'Join discussions',
          onTap: () => _navigateAndClose(context, '/'),
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.bookmark_outline,
          activeIcon: Icons.bookmark,
          title: 'Bookmarks',
          subtitle: 'Saved content',
          onTap: () => _navigateAndClose(context, '/bookmarks'),
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.message_outlined,
          activeIcon: Icons.message,
          title: 'Messages',
          subtitle: 'Chat & conversations',
          onTap: () => _navigateAndClose(context, '/messages'),
        ),
      ],
    );
  }

  Widget _buildConsultationSection(BuildContext context, ThemeData theme) {
    final tokenStorage = Get.find<TokenStorageService>();
    final userRole = tokenStorage.getUserRole()?.toLowerCase() ?? '';
    final isVerified = tokenStorage.isUserVerified();

    // Only show for verified advocates, lawyers, paralegals, and law firms
    final eligibleRoles = ['advocate', 'lawyer', 'paralegal', 'law_firm'];
    final isEligible =
        isVerified && eligibleRoles.any((role) => userRole.contains(role));

    if (!isEligible) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildSectionHeader('Professional', theme),
        _buildDrawerItem(
          context: context,
          icon: Icons.psychology_outlined,
          activeIcon: Icons.psychology,
          title: 'Consultation',
          subtitle: 'Manage or apply',
          badge: 'NEW',
          badgeColor: Colors.green,
          onTap: () => _handleConsultationTap(context),
        ),
      ],
    );
  }

  Widget _buildToolsSection(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        _buildSectionHeader('Legal Tools', theme),
        _buildDrawerItem(
          context: context,
          icon: Icons.document_scanner_outlined,
          title: 'Document Scanner',
          subtitle: 'Scan & digitize documents',
          badge: 'NEW',
          onTap: () => _showComingSoon(context, 'Document Scanner'),
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.search_outlined,
          title: 'Legal Research',
          subtitle: 'Search laws & cases',
          onTap: () => _showComingSoon(context, 'Legal Research'),
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.chat_bubble_outline,
          title: 'AI Legal Assistant',
          subtitle: 'Get instant legal advice',
          badge: 'AI',
          onTap: () => _showComingSoon(context, 'AI Legal Assistant'),
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.library_books_outlined,
          title: 'Case Library',
          subtitle: 'Browse legal cases',
          onTap: () => _showComingSoon(context, 'Case Library'),
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context, ThemeData theme) {
    // Check if user needs to show upgrade option
    final profileService = Get.find<ProfileService>();
    final profile = profileService.currentProfile;
    bool showUpgrade = true; // Default to showing upgrade option

    if (profile != null) {
      final subscription = profile.subscription;
      // Only hide upgrade if user has an active paid subscription
      // Show upgrade for: free trial, inactive subscriptions, or free plan
      final isPaidPlan = subscription.planType != 'free_trial' &&
          subscription.planType != 'free';
      showUpgrade = !isPaidPlan || !subscription.isActive;
    }

    return Column(
      children: [
        _buildSectionHeader('Account', theme),
        _buildDrawerItem(
          context: context,
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          title: 'Profile',
          subtitle: 'Manage your account',
          onTap: () => _navigateAndClose(
            context,
            () => Get.to(() => const ProfileScreen()),
          ),
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings,
          title: 'Settings',
          subtitle: 'App preferences',
          onTap: () => _navigateAndClose(
            context,
            () => Get.to(() => const SettingsScreen()),
          ),
        ),
        if (showUpgrade)
          _buildDrawerItem(
            context: context,
            icon: Icons.workspace_premium,
            activeIcon: Icons.workspace_premium,
            title: 'Upgrade to Premium',
            subtitle: 'Unlock all features',
            badge: 'PRO',
            badgeColor: Colors.amber,
            onTap: () => _navigateAndClose(
              context,
              () => Get.to(() => const SubscriptionPlansScreen()),
            ),
          ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        _buildSectionHeader('Support', theme),
        _buildDrawerItem(
          context: context,
          icon: Icons.help_outline,
          title: 'Help & Support',
          subtitle: 'Get assistance',
          onTap: () => _navigateAndClose(context, '/help-support'),
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.feedback_outlined,
          title: 'Send Feedback',
          subtitle: 'Share your thoughts',
          onTap: () => _showComingSoon(context, 'Feedback'),
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.info_outline,
          title: 'About',
          subtitle: 'App information',
          onTap: () {
            Navigator.pop(context);
            _showAboutDialog(context);
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    IconData? activeIcon,
    required String title,
    String? subtitle,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor ?? theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badge,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerFooter(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _showLogoutConfirmation(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.logout,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sign Out',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Version 1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 10,
                ),
              ),
              Text(
                '© 2025 Pola',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateAndClose(BuildContext context, dynamic route) {
    Navigator.pop(context);
    if (route is String) {
      Get.toNamed(route);
    } else if (route is Function) {
      route();
    }
  }

  Future<void> _handleConsultationTap(BuildContext context) async {
    Navigator.pop(context); // Close drawer

    // Initialize consultation service if not already done
    if (!Get.isRegistered<ConsultationService>()) {
      Get.put(ConsultationService());
    }

    // Navigate to consultant profile screen
    Get.to(() => const ConsultantProfileScreen());
  }

  void _showComingSoon(BuildContext context, String feature) {
    Navigator.pop(context);
    Get.snackbar(
      'Coming Soon',
      '$feature will be available in future updates!',
      icon: const Icon(Icons.schedule, color: Colors.white),
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close drawer

                // Perform logout - clear all user data and tokens
                try {
                  final authService = Get.find<AuthService>();
                  await authService.logout();

                  Get.snackbar(
                    'Signed Out',
                    'You have been signed out successfully',
                    icon: const Icon(Icons.logout, color: Colors.white),
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                  );
                } catch (e) {
                  debugPrint('❌ Logout error: $e');
                  // Still navigate to login even if there's an error
                  Get.offAllNamed('/login');
                }
              },
              child: Text(
                'Sign Out',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppStrings.appName,
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('⚖️', style: TextStyle(fontSize: 32)),
      ),
      children: [
        const Text(
          'Your comprehensive legal education platform. Access courses, connect with professionals, and advance your legal career.',
        ),
        const SizedBox(height: 16),
        Text(
          'the lawyer you carry',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Built with ❤️ for the legal community',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

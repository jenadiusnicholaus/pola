import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_strings.dart';
import '../../features/profile/services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../services/token_storage_service.dart';
import '../../features/consultation/services/consultation_service.dart';
import '../../features/consultation/screens/consultant_profile_screen.dart';
import '../../features/subscription/screens/subscription_plans_screen.dart';
import '../../routes/app_routes.dart';
import '../../features/navigation/controllers/main_navigation_controller.dart';

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
    final isDark = theme.brightness == Brightness.dark;
    final profileService = Get.find<ProfileService>();

    return Obx(() {
      final profile = profileService.currentProfile;

      // Get user details
      final firstName = profile?.firstName ?? '';
      final lastName = profile?.lastName ?? '';
      final userEmail = profile?.email ?? '';
      final profilePicture = profile?.profilePicture;

      // Build user name, fallback to email username if names are empty
      String userName = 'User';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        userName = '$firstName $lastName'.trim();
      } else if (userEmail.isNotEmpty) {
        userName = userEmail.split('@').first;
      }

      // Get subscription status - use real subscription data
      final subscription = profile?.subscription;
      String subscriptionBadge = 'Free';
      Color badgeColor = theme.colorScheme.onSurfaceVariant;

      if (subscription != null && subscription.isActive) {
        // Use the actual plan name from subscription
        subscriptionBadge = subscription.planName;

        if (subscription.isTrial) {
          badgeColor = Colors.blue;
        } else if (subscription.planType.toLowerCase().contains('monthly')) {
          badgeColor = Colors.green;
        } else if (subscription.planType.toLowerCase().contains('yearly')) {
          badgeColor = Colors.amber;
        } else if (subscription.planType.toLowerCase().contains('premium')) {
          badgeColor = Colors.amber;
        } else {
          badgeColor = theme.colorScheme.primary;
        }
      }

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.surfaceContainer,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                // Profile Picture
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primaryContainer,
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: profilePicture != null
                      ? ClipOval(
                          child: Image.network(
                            profilePicture,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 24,
                                color: theme.colorScheme.onPrimaryContainer,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 24,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                ),

                const SizedBox(width: 12),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // User Name
                      Text(
                        userName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 2),

                      // User Email
                      Text(
                        userEmail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Subscription Badge (compact)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: badgeColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    subscriptionBadge,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
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
          onTap: () => _navigateToTab(context, 0),
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.forum_outlined,
          activeIcon: Icons.forum,
          title: 'Community Posts',
          subtitle: 'Join discussions',
          onTap: () => _navigateToTab(context, 1),
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.bookmark_outline,
          activeIcon: Icons.bookmark,
          title: 'Bookmarks',
          subtitle: 'Saved content',
          onTap: () => _navigateToTab(context, 3),
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.message_outlined,
          activeIcon: Icons.message,
          title: 'Messages',
          subtitle: 'Chat & conversations',
          onTap: () => _navigateToTab(context, 4),
        ),
      ],
    );
  }

  Widget _buildConsultationSection(BuildContext context, ThemeData theme) {
    final tokenStorage = Get.find<TokenStorageService>();
    final userRole = tokenStorage.getUserRole()?.toLowerCase() ?? '';
    final isVerified = tokenStorage.isUserVerified();

    // Check role eligibility for different professional features
    final isAdvocateOrLawyerOrFirm = isVerified &&
        (userRole.contains('advocate') ||
            userRole.contains('lawyer') ||
            userRole.contains('law_firm'));
    final isLegalProfessional = isVerified &&
        ['advocate', 'lawyer', 'paralegal', 'law_firm']
            .any((role) => userRole.contains(role));
    final isStudent =
        userRole.contains('law_student') || userRole.contains('lecturer');

    // If no professional features available, don't show section
    if (!isLegalProfessional && !isStudent) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildSectionHeader('Professional', theme),

        // Advocate Hub - for advocates, lawyers, and law firms
        if (isAdvocateOrLawyerOrFirm)
          _buildDrawerItem(
            context: context,
            icon: Icons.gavel_outlined,
            activeIcon: Icons.gavel,
            title: 'Advocate Hub',
            subtitle: 'Professional resources',
            onTap: () => _navigateAndClose(context, AppRoutes.advocatesHub),
          ),

        // Students Hub - for law students and lecturers
        if (isStudent)
          _buildDrawerItem(
            context: context,
            icon: Icons.school_outlined,
            activeIcon: Icons.school,
            title: 'Students Hub',
            subtitle: 'Academic resources',
            onTap: () => _navigateAndClose(context, AppRoutes.studentsHub),
          ),

        // Consultation - for all verified legal professionals
        if (isLegalProfessional)
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

        // My Consultations - for verified professionals to view bookings
        if (isLegalProfessional)
          _buildDrawerItem(
            context: context,
            icon: Icons.event_note_outlined,
            activeIcon: Icons.event_note,
            title: 'My Consultations',
            subtitle: 'View client bookings',
            onTap: () => _navigateAndClose(context, AppRoutes.myConsultations),
          ),
      ],
    );
  }

  Widget _buildToolsSection(BuildContext context, ThemeData theme) {
    // Note: These tools can be gated with PermissionMenuItem when features are ready
    // Example:
    // PermissionMenuItem(
    //   feature: PermissionFeature.legalLibrary,
    //   icon: Icons.library_books_outlined,
    //   title: 'Case Library',
    //   subtitle: 'Browse legal cases',
    //   onTap: () => Get.toNamed(AppRoutes.caseLibrary),
    // ),

    return Column(
      children: [
        _buildSectionHeader('Legal Tools', theme),
        _buildDrawerItem(
          context: context,
          icon: Icons.document_scanner_outlined,
          title: 'Document Scanner',
          subtitle: 'Scan & digitize documents',
          badge: 'NEW',
          onTap: () => _navigateToComingSoon(context, 'Document Scanner'),
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.search_outlined,
          title: 'Legal Research',
          subtitle: 'Search laws & cases',
          onTap: () => _navigateToComingSoon(context, 'Legal Research'),
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.chat_bubble_outline,
          title: 'AI Legal Assistant',
          subtitle: 'Get instant legal advice',
          badge: 'AI',
          onTap: () => _navigateToComingSoon(context, 'AI Legal Assistant'),
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.library_books_outlined,
          title: 'Case Library',
          subtitle: 'Browse legal cases',
          onTap: () => _navigateToComingSoon(context, 'Case Library'),
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context, ThemeData theme) {
    final profileService = Get.find<ProfileService>();

    return Obx(() {
      final profile = profileService.currentProfile;
      final subscription = profile?.subscription;

      // Hide upgrade if user has an active subscription (any type)
      final showUpgrade = subscription == null || !subscription.isActive;

      return Column(children: [
        _buildSectionHeader('Account', theme),
        _buildDrawerItem(
          context: context,
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          title: 'Profile',
          subtitle: 'Manage your account',
          onTap: () => _navigateAndClose(context, AppRoutes.profile),
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings,
          title: 'Settings',
          subtitle: 'App preferences',
          onTap: () => _navigateAndClose(context, AppRoutes.settings),
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
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const SubscriptionPlansScreen());
            },
          ),
      ]);
    });
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
          onTap: () => _navigateAndClose(context, AppRoutes.helpSupport),
        ),
        _buildDrawerItem(
          context: context,
          icon: Icons.feedback_outlined,
          title: 'Send Feedback',
          subtitle: 'Share your thoughts',
          onTap: () => _navigateToComingSoon(context, 'Send Feedback'),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          splashColor: theme.colorScheme.primary.withOpacity(0.1),
          highlightColor: theme.colorScheme.primary.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Simple icon without background
                Icon(
                  icon,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  size: 22,
                ),
                const SizedBox(width: 16),
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
                                fontWeight: FontWeight.w500,
                                fontSize: 14.5,
                                letterSpacing: 0.1,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (badgeColor ?? theme.colorScheme.primary)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      (badgeColor ?? theme.colorScheme.primary)
                                          .withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                badge,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color:
                                      badgeColor ?? theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logout button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showLogoutConfirmation(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_outlined,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Sign Out',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Version info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Version 1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
              Text(
                ' • ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              Text(
                '© 2025 Pola',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 11,
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

  void _navigateToTab(BuildContext context, int tabIndex) {
    Navigator.pop(context);
    // Get the navigation controller and change to the specified tab
    final navController = Get.find<MainNavigationController>();
    navController.changePage(tabIndex);
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

  void _navigateToComingSoon(BuildContext context, String feature) {
    Navigator.pop(context);
    Get.toNamed(
      AppRoutes.comingSoon,
      parameters: {'feature': feature},
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

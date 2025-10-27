import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../user_verification/screens/verification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    const expandedHeight = 200.0;
    const toolbarHeight = 56.0;

    if (_scrollController.hasClients) {
      final isCollapsed =
          _scrollController.offset > (expandedHeight - toolbarHeight);
      if (isCollapsed != _isCollapsed) {
        setState(() {
          _isCollapsed = isCollapsed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize the home controller
    final controller = Get.put(HomeController());

    return PopScope(
      // Prevent back navigation
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmation(context, controller);
      },
      child: Scaffold(
        drawer: _buildDrawer(context, controller),
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Dynamic Sliver App Bar
            _buildDynamicSliverAppBar(context, controller),

            // Empty Body Content
            const SliverFillRemaining(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Home Content Coming Soon',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(context, controller),
      ),
    );
  }

  Widget _buildDynamicSliverAppBar(
      BuildContext context, HomeController controller) {
    return SliverAppBar(
      backgroundColor: AppColors.primaryAmber,
      foregroundColor: AppColors.black,
      elevation: 4,
      pinned: true,
      floating: false,
      snap: false,
      stretch: true,
      expandedHeight: 200.0,

      // Dynamic title that appears when collapsed - with opacity based on scroll
      title: AnimatedOpacity(
        opacity: _isCollapsed ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '⚖️',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(width: 8),
            Text(
              AppStrings.appName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),

      // Actions
      actions: _buildAppBarActions(context, controller),

      // Flexible space with expanded content
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        title: AnimatedOpacity(
          opacity: _isCollapsed ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Justice scale icon (responsive size)
                  Text(
                    '⚖️',
                    style: TextStyle(
                      fontSize: _isCollapsed ? 20 : 28,
                    ),
                  ),

                  SizedBox(height: _isCollapsed ? 4 : 6),

                  // App name (responsive size)
                  Text(
                    AppStrings.appName,
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: _isCollapsed ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: _isCollapsed ? 1.0 : 2.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Separator line (only show when not collapsed)
                  if (!_isCollapsed) ...[
                    Container(
                      width: 60,
                      height: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.black,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),

                    // Tagline (only show when not collapsed)
                    Text(
                      AppStrings.lawyerTagline,
                      style: TextStyle(
                        color: AppColors.black.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Background gradient
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryAmber,
                AppColors.primaryAmber.withOpacity(0.9),
                AppColors.primaryAmber.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),

      // Stretch configuration
      stretchTriggerOffset: 100.0,
      onStretchTrigger: () async {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pull to refresh activated!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  List<Widget> _buildAppBarActions(
      BuildContext context, HomeController controller) {
    return [
      // Token refresh indicator
      Obx(() => controller.isRefreshing
          ? const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ),
            )
          : const SizedBox.shrink()),

      // Notifications button with badge
      Stack(
        children: [
          IconButton(
            onPressed: () => _showNotifications(context, controller),
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
          ),
          // Notification badge
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              constraints: const BoxConstraints(
                minWidth: 14,
                minHeight: 14,
              ),
              child: const Text(
                '3',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),

      // User profile button
      IconButton(
        onPressed: () => _showUserProfile(context, controller),
        icon: const Icon(Icons.account_circle_outlined),
        tooltip: 'Profile',
      ),

      const SizedBox(width: 8), // Add some spacing from the edge
    ];
  }

  Widget _buildDrawer(BuildContext context, HomeController controller) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // User info header
          Obx(() => UserAccountsDrawerHeader(
                accountName: Text(controller.userDisplayName),
                accountEmail: Text(controller.userEmail),
                currentAccountPicture: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.2),
                  child: Text(
                    controller.userInitials,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
              )),

          // Navigation items
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Get.back();
            },
          ),

          ListTile(
            leading: const Icon(Icons.gavel),
            title: const Text('Legal Services'),
            onTap: () {
              Get.back();
            },
          ),

          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Case History'),
            onTap: () {
              Get.back();
            },
          ),

          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Documents'),
            onTap: () {
              Get.back();
            },
          ),

          // Show verification item only for professional roles
          Obx(() {
            final userRole = controller.userRole;
            final requiresVerification = [
              'advocate',
              'lawyer',
              'law_firm',
              'paralegal'
            ].contains(userRole);

            if (!requiresVerification) {
              return const SizedBox.shrink();
            }

            return ListTile(
              leading: const Icon(Icons.verified_user),
              title: const Text('Account Verification'),
              onTap: () {
                Get.back();
                Get.to(() => const VerificationScreen());
              },
            );
          }),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Get.back();
              Get.toNamed('/settings');
            },
          ),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Get.back(); // Close drawer first
              _showLogoutConfirmation(context, controller);
            },
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(
      BuildContext context, HomeController controller) {
    return null; // No floating action button for now
  }

  void _showExitConfirmation(BuildContext context, HomeController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _showUserProfile(BuildContext context, HomeController controller) {
    // Navigate to profile page
    Get.toNamed('/profile');
  }

  void _showNotifications(BuildContext context, HomeController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications, color: AppColors.primaryAmber),
            SizedBox(width: 8),
            Text('Notifications'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildNotificationItem(
                icon: Icons.gavel,
                title: 'New Case Assignment',
                message: 'You have been assigned to case #2024-001',
                time: '2 hours ago',
                isRead: false,
              ),
              const Divider(),
              _buildNotificationItem(
                icon: Icons.schedule,
                title: 'Court Hearing Reminder',
                message: 'Court hearing scheduled for tomorrow at 10:00 AM',
                time: '1 day ago',
                isRead: false,
              ),
              const Divider(),
              _buildNotificationItem(
                icon: Icons.document_scanner,
                title: 'Document Review',
                message: 'New documents uploaded for case #2024-002',
                time: '3 days ago',
                isRead: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mark All as Read'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String message,
    required String time,
    required bool isRead,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isRead ? null : AppColors.primaryAmber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryAmber.withOpacity(0.2),
          child: Icon(icon, color: AppColors.primaryAmber),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: !isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryAmber,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  void _showLogoutConfirmation(
      BuildContext context, HomeController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

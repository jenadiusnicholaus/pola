import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../widgets/hubs_and_services_list.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../../shared/widgets/app_drawer.dart';

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
        drawer: const AppDrawer(),
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Dynamic Sliver App Bar
            _buildDynamicSliverAppBar(context, controller),

            // Hubs and Services Content
            const SliverToBoxAdapter(
              child: HubsAndServicesList(),
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(context, controller),
      ),
    );
  }

  Widget _buildDynamicSliverAppBar(
      BuildContext context, HomeController controller) {
    final theme = Theme.of(context);
    return SliverAppBar(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      iconTheme: IconThemeData(
        color: theme.colorScheme.onPrimary,
        size: 24,
      ),
      actionsIconTheme: IconThemeData(
        color: theme.colorScheme.onPrimary,
        size: 24,
      ),
      elevation: 2,
      pinned: true,
      floating: false,
      snap: false,
      expandedHeight: 180.0,
      leadingWidth: 56, // Proper width for icon button
      toolbarHeight: 56, // Standard toolbar height

      // Dynamic title that appears when collapsed
      centerTitle: true,
      title: AnimatedOpacity(
        opacity: _isCollapsed ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '⚖️',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.appName,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.5,
                color: theme.colorScheme.onPrimary,
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
        titlePadding: const EdgeInsets.only(bottom: 12),
        title: AnimatedOpacity(
          opacity: _isCollapsed ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '⚖️',
                style: TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 3),
              Text(
                AppStrings.appName,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                AppStrings.lawyerTagline,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary.withOpacity(0.8),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),

        // Background gradient
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.9),
                theme.colorScheme.primary.withOpacity(0.85),
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                ),
              ),
            )
          : const SizedBox.shrink()),

      // Notifications button with badge
      Stack(
        children: [
          IconButton(
            onPressed: () => _showNotifications(context, controller),
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.black87,
            ),
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
        icon: const Icon(
          Icons.account_circle_outlined,
          color: Colors.black87,
        ),
        tooltip: 'Profile',
      ),

      const SizedBox(width: 8), // Add some spacing from the edge
    ];
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../widgets/hubs_and_services_list.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../profile/services/profile_service.dart';
import '../../notifications/widgets/notification_badge.dart';

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

      // Notifications button with dynamic badge
      const NotificationBadge(
        iconColor: Colors.black87,
        iconSize: 24,
      ),

      // User profile button with picture
      Obx(() {
        final profileService = Get.find<ProfileService>();
        final profilePicture = profileService.currentProfile?.profilePicture;

        return GestureDetector(
          onTap: () => _showUserProfile(context, controller),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage:
                  profilePicture != null && profilePicture.isNotEmpty
                      ? NetworkImage(profilePicture)
                      : null,
              child: profilePicture == null || profilePicture.isEmpty
                  ? const Icon(
                      Icons.account_circle_outlined,
                      color: Colors.black87,
                      size: 24,
                    )
                  : null,
            ),
          ),
        );
      }),

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

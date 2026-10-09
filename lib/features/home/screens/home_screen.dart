import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../widgets/hubs_and_services_list.dart';
import '../../../constants/app_strings.dart';
import '../../../shared/widgets/app_drawer.dart';
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
    // Comment/upgrade snackbars must not linger on Home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isSnackbarOpen) {
        Get.closeAllSnackbars();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    const expandedHeight = 110.0;
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
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      iconTheme: IconThemeData(
        color: theme.colorScheme.onPrimary,
        size: 24,
      ),
      actionsIconTheme: IconThemeData(
        color: theme.colorScheme.onPrimary,
        size: 24,
      ),
      elevation: 0,
      scrolledUnderElevation: 1,
      pinned: true,
      floating: false,
      snap: false,
      expandedHeight: 110.0,
      leadingWidth: 56, // Proper width for icon button
      toolbarHeight: 56, // Standard toolbar height
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),

      // Dynamic title that appears when collapsed
      centerTitle: true,
      title: AnimatedOpacity(
        opacity: _isCollapsed ? 1.0 : 0.0,
        duration: Duration(milliseconds: 200),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr('⚖️'),
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(width: 8),
            Text(
              AppStrings.appName,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
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
          duration: Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '⚖️',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppStrings.appName,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 15,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                tr(AppStrings.lawyerTagline),
                style: TextStyle(
                  color: theme.colorScheme.onPrimary.withOpacity(0.75),
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),

        // Vibrant background gradient with layered decorative shapes
        background: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.4, 0.75, 1.0],
              colors: [
                Color.lerp(theme.colorScheme.primary, Colors.black, 0.18)!,
                theme.colorScheme.primary,
                Color.lerp(theme.colorScheme.primary,
                    theme.colorScheme.secondary, 0.55)!,
                Color.lerp(theme.colorScheme.tertiary,
                    theme.colorScheme.primary, 0.25)!,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                right: 30,
                top: 60,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.secondary.withOpacity(0.18),
                  ),
                ),
              ),
              Positioned(
                right: -20,
                bottom: -30,
                child: Icon(
                  Icons.balance,
                  size: 120,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              Positioned(
                left: -18,
                bottom: -20,
                child: Icon(
                  Icons.gavel,
                  size: 80,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
              Positioned(
                left: 50,
                top: -30,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.tertiary.withOpacity(0.15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Stretch configuration
      stretchTriggerOffset: 100.0,
      onStretchTrigger: () async {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Pull to refresh activated!')),
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
          ? Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            )
          : const SizedBox.shrink()),

      // Notifications button with dynamic badge
      NotificationBadge(
        iconColor: Theme.of(context).colorScheme.onPrimary,
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
                  ? Icon(
                      Icons.account_circle_outlined,
                      color: Theme.of(context).colorScheme.onPrimary,
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
        title: Text(tr('Exit App')),
        content: Text(tr('Are you sure you want to exit the app?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('Cancel')),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: Text(tr('Exit')),
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
        title: Text(tr('Logout')),
        content: Text(tr('Are you sure you want to logout?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('Cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.logout();
            },
            child: Text(tr('Logout')),
          ),
        ],
      ),
    );
  }
}

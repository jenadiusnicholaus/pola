import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/main_navigation_controller.dart';
import '../../home/screens/home_screen.dart';
import '../../posts/screens/posts_screen.dart';
import '../../help/screens/help_support_screen.dart';
import '../../bookmarks/screens/bookmark_screen.dart';
import '../../consultation/screens/my_bookings_screen.dart';
import '../../consultation/screens/my_consultations_screen.dart';
import '../../../services/permission_service.dart';
import '../../profile/services/profile_service.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainNavigationController());
    final permissionService = Get.find<PermissionService>();
    final profileService = Get.find<ProfileService>();

    return Obx(() {
      // React to profile changes
      final profile = profileService.currentProfile;
      final isProfessional = permissionService.isProfessional;
      
      debugPrint('🔄 Navigation rebuild - Profile: ${profile?.fullName}, Role: ${profile?.userRole.roleName}, isProfessional: $isProfessional');

      // Build screens list with the correct bookings screen based on role
      final List<Widget> screens = [
        const HomeScreen(),
        const PostsScreen(),
        isProfessional ? const MyConsultationsScreen() : const MyBookingsScreen(),
        const HelpSupportScreen(),
        const BookmarkScreen(),
      ];

      return Scaffold(
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: screens,
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.changePage,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            selectedFontSize: 12,
            unselectedFontSize: 12,
            elevation: 8,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.article_outlined),
                activeIcon: Icon(Icons.article),
                label: 'Posts',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.calendar_today_outlined),
                activeIcon: const Icon(Icons.calendar_today),
                label: isProfessional ? 'Consultations' : 'Bookings',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.help_outline),
                activeIcon: Icon(Icons.help),
                label: 'Help & Support',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.bookmark_outline),
                activeIcon: Icon(Icons.bookmark),
                label: 'Bookmarks',
              ),
            ],
          ),
        ),
      );
    });
  }
}

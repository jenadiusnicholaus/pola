import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:localization_lite/translate.dart';
import '../controllers/main_navigation_controller.dart';
import '../../home/screens/home_screen.dart';
import '../../posts/screens/posts_screen.dart';
import '../../messaging/screens/messages_inbox_screen.dart';
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

      debugPrint(
          '🔄 Navigation rebuild - Profile: ${profile?.fullName}, Role: ${profile?.userRole.roleName}, isProfessional: $isProfessional');

      // Build screens list with the correct bookings screen based on role
      final List<Widget> screens = [
        const HomeScreen(),
        const PostsScreen(),
        isProfessional
            ? const MyConsultationsScreen()
            : const MyBookingsScreen(),
        const MessagesInboxScreen(),
        const BookmarkScreen(),
      ];

      return Scaffold(
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: screens,
        ),
        extendBody: true,
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Theme(
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
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_outlined),
                    activeIcon: const Icon(Icons.home),
                    label: tr('Home'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.article_outlined),
                    activeIcon: const Icon(Icons.article),
                    label: tr('Posts'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.calendar_today_outlined),
                    activeIcon: const Icon(Icons.calendar_today),
                    label:
                        isProfessional ? tr('Consultations') : tr('Bookings'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.inbox_outlined),
                    activeIcon: const Icon(Icons.inbox),
                    label: tr('Inbox'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.bookmark_outline),
                    activeIcon: const Icon(Icons.bookmark),
                    label: tr('Bookmarks'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

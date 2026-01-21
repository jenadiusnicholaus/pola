import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/main_navigation_controller.dart';
import '../../home/screens/home_screen.dart';
import '../../posts/screens/posts_screen.dart';
import '../../help/screens/help_support_screen.dart';
import '../../bookmarks/screens/bookmark_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainNavigationController());

    final List<Widget> screens = [
      const HomeScreen(),
      const PostsScreen(),
      const HelpSupportScreen(),
      const BookmarkScreen(),
    ];

    return Obx(
      () => Scaffold(
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
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.article_outlined),
                activeIcon: Icon(Icons.article),
                label: 'Posts',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.help_outline),
                activeIcon: Icon(Icons.help),
                label: 'Help & Support',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bookmark_outline),
                activeIcon: Icon(Icons.bookmark),
                label: 'Bookmarks',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

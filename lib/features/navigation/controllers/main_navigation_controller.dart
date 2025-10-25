import 'package:get/get.dart';

class MainNavigationController extends GetxController {
  // Observable for current page index
  final RxInt currentIndex = 0.obs;

  // Change page
  void changePage(int index) {
    currentIndex.value = index;
  }

  // Navigate to specific page programmatically
  void navigateToHome() => changePage(0);
  void navigateToPosts() => changePage(1);
  void navigateToHelp() => changePage(2);
  void navigateToBookmarks() => changePage(3);
}

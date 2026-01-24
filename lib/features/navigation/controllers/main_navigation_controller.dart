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
  void navigateToBookings() => changePage(2);
  void navigateToHelp() => changePage(3);
  void navigateToBookmarks() => changePage(4);
}

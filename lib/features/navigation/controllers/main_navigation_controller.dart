import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainNavigationController extends GetxController {
  // Observable for current page index
  final RxInt currentIndex = 0.obs;

  // Key for the root Scaffold so drawer can be opened from tab screens
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // Change page
  void changePage(int index) {
    try {
      if (Get.isSnackbarOpen) {
        Get.closeAllSnackbars();
      }
    } catch (_) {
      // GetX throws LateInitializationError when the snackbar controller
      // was never fully initialized — nothing to close anyway.
    }
    currentIndex.value = index;
  }

  // Navigate to specific page programmatically
  void navigateToHome() => changePage(0);
  void navigateToPosts() => changePage(1);
  void navigateToBookings() => changePage(2);
  void navigateToInbox() => changePage(3);
  void navigateToBookmarks() => changePage(4);
}

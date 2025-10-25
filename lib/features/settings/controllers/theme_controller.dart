import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final GetStorage _storage = GetStorage();

  // Observable theme mode
  final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;
  ThemeMode get themeMode => _themeMode.value;

  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }

  // Load theme mode from storage
  void _loadThemeMode() {
    final dynamic storedValue = _storage.read('theme_mode');
    if (storedValue != null) {
      if (storedValue is String) {
        _themeMode.value = _getThemeModeFromString(storedValue);
      } else if (storedValue is int) {
        // Handle legacy integer storage
        _themeMode.value = _getThemeModeFromIndex(storedValue);
        // Convert to string format for future use
        _storage.write('theme_mode', _themeMode.value.toString());
      }
    }
  }

  // Change theme mode
  void changeThemeMode(ThemeMode themeMode) {
    _themeMode.value = themeMode;
    _storage.write('theme_mode', themeMode.toString());
    Get.changeThemeMode(themeMode);
  }

  // Toggle between light and dark theme
  void toggleTheme() {
    if (_themeMode.value == ThemeMode.light) {
      changeThemeMode(ThemeMode.dark);
    } else {
      changeThemeMode(ThemeMode.light);
    }
  }

  // Convert string to ThemeMode
  ThemeMode _getThemeModeFromString(String themeMode) {
    switch (themeMode) {
      case 'ThemeMode.light':
        return ThemeMode.light;
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // Convert integer index to ThemeMode (for legacy support)
  ThemeMode _getThemeModeFromIndex(int index) {
    switch (index) {
      case 0:
        return ThemeMode.light;
      case 1:
        return ThemeMode.dark;
      case 2:
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  // Check if current theme is dark
  bool get isDarkMode {
    if (_themeMode.value == ThemeMode.system) {
      return Get.isPlatformDarkMode;
    }
    return _themeMode.value == ThemeMode.dark;
  }

  // Check if current theme is light
  bool get isLightMode {
    if (_themeMode.value == ThemeMode.system) {
      return !Get.isPlatformDarkMode;
    }
    return _themeMode.value == ThemeMode.light;
  }

  // Get theme mode text for display
  String get themeModeText {
    switch (_themeMode.value) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}

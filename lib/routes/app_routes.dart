import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../main.dart';
import '../features/onboarding/screens/landing_screen.dart';
import '../features/auth/screens/registration_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/navigation/screens/main_navigation_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/profile/screens/profile_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String landing = '/landing';
  static const String registration = '/registration';
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static List<GetPage> routes = [
    GetPage(
      name: splash,
      page: () => const AuthCheckScreen(),
    ),
    GetPage(
      name: landing,
      page: () => const LandingScreen(),
    ),
    GetPage(
      name: registration,
      page: () => const RegistrationScreen(),
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: home,
      page: () => const MainNavigationScreen(),
    ),
    GetPage(
      name: profile,
      page: () => const ProfileScreen(),
    ),
    GetPage(
      name: settings,
      page: () => const SettingsScreen(),
    ),
  ];

  // Route not found handler
  static GetPage unknownRoute = GetPage(
    name: '/not-found',
    page: () => const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The requested page could not be found.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

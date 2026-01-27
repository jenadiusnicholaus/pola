import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'constants/app_theme.dart';
import 'constants/app_colors.dart';
import 'constants/app_strings.dart';
import 'routes/app_routes.dart';
import 'features/settings/controllers/theme_controller.dart';
import 'services/token_storage_service.dart';
import 'services/auth_service.dart';
import 'services/app_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use the optimized AppInitializer for parallel service loading
  final initializer = AppInitializer();
  
  await initializer.initialize(
    onError: (details) async {
      debugPrint('❌ Initialization error: ${details.exception}');
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the ThemeController to use persisted theme
    final themeController = Get.find<ThemeController>();

    return Obx(() => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppStrings.appName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.themeMode, // Use persisted theme mode
          initialRoute: AppRoutes.splash, // Start with auth check
          getPages: AppRoutes.routes,
          unknownRoute: AppRoutes.unknownRoute,
        ));
  }
}

/// Screen that checks authentication status on app startup
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      debugPrint('🚀 Starting authentication check...');

      // Ensure services are initialized
      final tokenStorage = Get.find<TokenStorageService>();
      final authService = Get.find<AuthService>();

      // Wait for TokenStorageService to be fully initialized
      debugPrint('⏳ Waiting for TokenStorageService initialization...');
      await tokenStorage.waitForInitialization();
      debugPrint('✅ TokenStorageService initialization complete');

      debugPrint('🔐 TokenStorage isLoggedIn: ${tokenStorage.isLoggedIn}');
      debugPrint('🔐 Access token length: ${tokenStorage.accessToken.length}');
      debugPrint(
          '🔐 Refresh token length: ${tokenStorage.refreshToken.length}');

      // Check if user has stored tokens
      if (tokenStorage.isLoggedIn) {
        debugPrint('🔐 Found stored tokens, checking JWT validity...');

        // Check refresh token expiration first (most critical)
        if (tokenStorage.isRefreshTokenExpired()) {
          debugPrint('❌ Refresh token expired - redirecting to login');
          await Future.delayed(const Duration(milliseconds: 1500));

          Get.offAllNamed(AppRoutes.login);
          return;
        }

        // Verify the session validity with potential token refresh
        final isValidSession = await authService.verifySession();

        if (isValidSession) {
          debugPrint('✅ Valid session confirmed - redirecting to home page');

          // Show token info for debugging
          final refreshExpiry =
              tokenStorage.getTokenExpirationDate(tokenStorage.refreshToken);
          debugPrint('🕒 Refresh token expires: $refreshExpiry');

          await Future.delayed(const Duration(milliseconds: 500));
          Get.offAllNamed(AppRoutes.home);
          return;
        } else {
          debugPrint('❌ Session validation failed - redirecting to login');
          await Future.delayed(const Duration(seconds: 1));

          Get.offAllNamed(AppRoutes.login);
          return;
        }
      } else {
        debugPrint('❌ No stored session - redirecting to landing');
        await Future.delayed(const Duration(milliseconds: 800));

        Get.offAllNamed(AppRoutes.landing);
      }
    } catch (e) {
      debugPrint('❌ Error checking auth status: $e');

      await Future.delayed(const Duration(seconds: 1));
      // Default to landing screen on error
      Get.offAllNamed(AppRoutes.landing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Set system UI overlay style for amber background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Brightness.dark, // Dark icons on amber background
        statusBarBrightness: Brightness.light, // Light status bar
        systemNavigationBarColor: AppColors.primaryAmber,
        systemNavigationBarIconBrightness: Brightness.dark, // Dark nav icons
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.primaryAmber,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryAmber,
              AppColors.primaryAmber.withOpacity(0.9),
              AppColors.primaryAmberLight,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Centered logo only
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Justice scale icon
                     const Text(
                      '⚖️',
                      style: TextStyle(
                        fontSize: 80,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App name
                    Text(
                      'POLA',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                        letterSpacing: 5.0,
                        fontSize: 48,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Separator line
                    Container(
                      width: 120,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.black,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),

              // Simple loader at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 80,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.black,
                    strokeWidth: 3,
                    backgroundColor: AppColors.black.withOpacity(0.2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

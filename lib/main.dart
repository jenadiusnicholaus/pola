import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'constants/app_theme.dart';
import 'constants/app_colors.dart';
import 'constants/app_strings.dart';
import 'routes/app_routes.dart';
import 'features/settings/controllers/theme_controller.dart';
import 'config/dio_config.dart';
import 'services/api_service.dart';
import 'services/token_storage_service.dart';
import 'services/auth_service.dart';
import 'features/profile/services/profile_service.dart';
import 'features/hubs_and_services/legal_education/services/legal_education_service.dart';
import 'features/hubs_and_services/hub_content/services/hub_content_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetStorage first
  await GetStorage.init();

  // Initialize environment variables
  try {
    await dotenv.load(fileName: ".env");
    print('Environment file loaded successfully');
  } catch (e) {
    print('Warning: Could not load .env file: $e');
    // Set default values if .env file is not found
    if (!dotenv.isInitialized) {
      dotenv.testLoad(fileInput: '''
APP_ENV=development
BASE_URL=http://192.168.1.181:8000
API_VERSION=v1
CONNECTION_TIMEOUT=30000
RECEIVE_TIMEOUT=30000
SEND_TIMEOUT=30000
API_KEY=your_api_key_here
ENABLE_LOGGING=true
LOGIN_ENDPOINT=/api/v1/authentication/login/
REGISTER_ENDPOINT=/api/v1/authentication/register/
REFRESH_TOKEN_ENDPOINT=/api/v1/authentication/refresh/
LOGOUT_ENDPOINT=/api/v1/authentication/logout/
''');
    }
  }

  // Initialize Dio configuration after environment is loaded
  DioConfig.initialize();

  // Initialize services in correct dependency order
  debugPrint('🚀 Initializing core services...');

  Get.put(ApiService());
  debugPrint('✅ ApiService initialized');

  // Initialize token storage service first
  Get.put(TokenStorageService());
  debugPrint('✅ TokenStorageService initialized');

  // Initialize profile service before auth service (dependency)
  Get.put(ProfileService());
  debugPrint('✅ ProfileService initialized');

  // Initialize auth service (depends on ProfileService)
  Get.put(AuthService());
  debugPrint('✅ AuthService initialized');

  // Initialize legal education service
  Get.put(LegalEducationService());

  // Initialize hub content service
  Get.put(HubContentService());

  // Initialize controllers
  Get.put(ThemeController());

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
                    Text(
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

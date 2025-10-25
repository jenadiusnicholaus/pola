import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'constants/app_theme.dart';
import 'constants/app_strings.dart';
import 'routes/app_routes.dart';
import 'features/settings/controllers/theme_controller.dart';
import 'config/dio_config.dart';
import 'services/api_service.dart';
import 'services/token_storage_service.dart';
import 'services/auth_service.dart';

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
LOGIN_ENDPOINT=/authentication/login/
REGISTER_ENDPOINT=/authentication/register/
REFRESH_TOKEN_ENDPOINT=/authentication/refresh/
LOGOUT_ENDPOINT=/authentication/logout/
''');
    }
  }

  // Initialize Dio configuration after environment is loaded
  DioConfig.initialize();

  // Initialize services
  Get.put(ApiService());

  // Initialize token storage and auth services
  Get.put(TokenStorageService());
  Get.put(AuthService());

  // Initialize controllers
  Get.put(ThemeController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Follows system theme
      initialRoute: AppRoutes.splash, // Start with auth check
      getPages: AppRoutes.routes,
      unknownRoute: AppRoutes.unknownRoute,
    );
  }
}

/// Screen that checks authentication status on app startup
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      debugPrint('🚀 Starting authentication check...');
      setState(() {
        _statusMessage = 'Checking your session...';
      });

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
          setState(() {
            _statusMessage =
                'Your session has expired completely. Please sign in again.';
          });

          debugPrint('❌ Refresh token expired - redirecting to login');
          await Future.delayed(const Duration(milliseconds: 1500));

          Get.offAllNamed(AppRoutes.login);
          return;
        }

        setState(() {
          _statusMessage = 'Validating your session...';
        });

        // Verify the session validity with potential token refresh
        final isValidSession = await authService.verifySession();

        if (isValidSession) {
          setState(() {
            _statusMessage = 'Welcome back! Redirecting to home...';
          });

          debugPrint('✅ Valid session confirmed - redirecting to home page');

          // Show token info for debugging
          final refreshExpiry =
              tokenStorage.getTokenExpirationDate(tokenStorage.refreshToken);
          debugPrint('🕒 Refresh token expires: $refreshExpiry');

          await Future.delayed(const Duration(milliseconds: 500));
          Get.offAllNamed(AppRoutes.home);
          return;
        } else {
          setState(() {
            _statusMessage = 'Session validation failed. Please sign in again.';
          });

          debugPrint('❌ Session validation failed - redirecting to login');
          await Future.delayed(const Duration(seconds: 1));

          Get.offAllNamed(AppRoutes.login);
          return;
        }
      } else {
        setState(() {
          _statusMessage = 'No active session found.';
        });

        debugPrint('❌ No stored session - redirecting to landing');
        await Future.delayed(const Duration(milliseconds: 800));

        Get.offAllNamed(AppRoutes.landing);
      }
    } catch (e) {
      debugPrint('❌ Error checking auth status: $e');

      setState(() {
        _statusMessage = 'Error checking session. Redirecting...';
      });

      await Future.delayed(const Duration(seconds: 1));
      // Default to landing screen on error
      Get.offAllNamed(AppRoutes.landing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    // Set adaptive system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: colorScheme.surface,
        systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [
                    colorScheme.surface,
                    colorScheme.surface.withOpacity(0.8),
                  ]
                : [
                    colorScheme.surface,
                    colorScheme.primaryContainer.withOpacity(0.1),
                  ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo with consistent structure (like app bar and landing page)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? colorScheme.primaryContainer.withOpacity(0.15)
                      : colorScheme.primaryContainer.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary
                          .withOpacity(isDarkMode ? 0.1 : 0.15),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Justice scale icon (consistent with app bar/landing)
                    Text(
                      '⚖️',
                      style: TextStyle(
                        fontSize: 48,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // App name (consistent with app bar/landing)
                    Text(
                      'POLA',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: 2.0,
                      ),
                    ),

                    // Separator line (consistent with app bar/landing)
                    Container(
                      width: 60,
                      height: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),

                    // Tagline (consistent with app bar/landing)
                    Text(
                      'The lawyer you carry',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Loading indicator with adaptive colors
              CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 3,
              ),

              const SizedBox(height: 24),

              // Status message with improved readability
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _statusMessage,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 32),

              // Platform title (consistent branding)
              Text(
                'Pola Legal Platform',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 16),

              // Subtle branding element
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Legal Solutions Platform',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
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

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../firebase_options.dart';
import '../config/dio_config.dart';
import 'api_service.dart';
import 'token_storage_service.dart';
import 'auth_service.dart';
import 'permission_service.dart';
import '../features/auth/services/lookup_service.dart';
import '../features/profile/services/profile_service.dart';
import '../features/hubs_and_services/legal_education/services/legal_education_service.dart';
import '../features/hubs_and_services/hub_content/services/hub_content_service.dart';
import '../features/consultation/services/consultation_service.dart';
import '../features/subscription/services/subscription_service.dart';
import 'device_registration_service.dart';
import '../features/nearbylawyers/services/nearby_lawyers_service.dart';
import '../features/calling_booking/services/fcm_service.dart';
import '../features/calling_booking/services/online_status_service.dart';
import '../features/settings/controllers/theme_controller.dart';
import '../features/notifications/services/notification_service.dart';

/// Handles app initialization with optimized parallel loading
class AppInitializer {
  static final AppInitializer _instance = AppInitializer._internal();
  factory AppInitializer() => _instance;
  AppInitializer._internal();

  // Progress tracking
  final RxDouble progress = 0.0.obs;
  final RxString currentTask = ''.obs;
  final RxBool isComplete = false.obs;

  /// Initialize all app services with parallel loading where possible
  Future<void> initialize({
    required Future<void> Function(FlutterErrorDetails) onError,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Phase 1: Critical synchronous initialization (must be sequential)
      await _initializeCriticalServices();
      progress.value = 0.3;

      // Phase 2: Parallel initialization of independent services
      await _initializeParallelServices();
      progress.value = 0.7;

      // Phase 3: Dependent services (need previous services)
      await _initializeDependentServices();
      progress.value = 0.9;

      // Phase 4: Background services (can run after app starts)
      _initializeBackgroundServicesAsync();
      progress.value = 1.0;

      isComplete.value = true;

      stopwatch.stop();
      debugPrint(
          '🚀 App initialization completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e, stackTrace) {
      debugPrint('❌ Error during app initialization: $e');
      debugPrint('Stack trace: $stackTrace');
      onError(FlutterErrorDetails(exception: e, stack: stackTrace));
      rethrow;
    }
  }

  /// Phase 1: Critical services that must be initialized first
  Future<void> _initializeCriticalServices() async {
    currentTask.value = 'Initializing core services...';

    // Firebase must be first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');

    // GetStorage for local persistence
    await GetStorage.init();
    debugPrint('✅ GetStorage initialized');

    // Environment variables
    try {
      await dotenv.load(fileName: ".env");
      debugPrint('✅ Environment file loaded');
    } catch (e) {
      debugPrint('⚠️ Could not load .env file: $e');
    }

    // Dio configuration
    DioConfig.initialize();
    debugPrint('✅ Dio configured');

    // Core API service
    Get.put(ApiService());
    debugPrint('✅ ApiService initialized');
  }

  /// Phase 2: Services that can be initialized in parallel
  Future<void> _initializeParallelServices() async {
    currentTask.value = 'Loading services...';

    // Token storage (async initialization)
    final tokenFuture = Get.putAsync(() => TokenStorageService().init());

    // These services don't depend on each other and can be registered in parallel
    await Future.wait([
      tokenFuture,
      _initServiceAsync(() {
        Get.put(LookupService());
        return Future.value();
      }),
    ]);

    debugPrint('✅ Parallel services phase 1 complete');

    // Now register services that depend on token storage
    // These can be done in parallel since they only need tokenStorage
    Get.put(ProfileService());
    Get.put(PermissionService());
    Get.put(AuthService());

    debugPrint('✅ Auth-dependent services initialized');
  }

  /// Phase 3: Services that depend on auth being ready
  Future<void> _initializeDependentServices() async {
    currentTask.value = 'Finalizing setup...';

    // These services can be initialized in parallel
    // as they're independent of each other
    await Future.wait([
      _initServiceAsync(() {
        Get.put(LegalEducationService());
        return Future.value();
      }),
      _initServiceAsync(() {
        Get.put(HubContentService());
        return Future.value();
      }),
      _initServiceAsync(() {
        Get.put(ConsultationService());
        return Future.value();
      }),
      _initServiceAsync(() {
        Get.put(SubscriptionService());
        return Future.value();
      }),
    ]);

    debugPrint('✅ Content services initialized');
  }

  /// Phase 4: Background services that can load after the app starts
  void _initializeBackgroundServicesAsync() {
    currentTask.value = 'Starting background services...';

    // These can initialize lazily without blocking app launch
    Future.microtask(() async {
      // Device registration
      Get.put(DeviceRegistrationService());
      debugPrint('✅ DeviceRegistrationService initialized (background)');

      // Nearby lawyers (location-dependent)
      Get.put(NearbyLawyersService());
      debugPrint('✅ NearbyLawyersService initialized (background)');

      // FCM for push notifications
      Get.putAsync(() => FCMService().init());
      debugPrint('✅ FCMService initialized (background)');

      // Online status
      Get.put(OnlineStatusService());
      debugPrint('✅ OnlineStatusService initialized (background)');

      // Notification service for in-app notifications
      Get.put(NotificationService());
      debugPrint('✅ NotificationService initialized (background)');

      // Theme controller
      Get.put(ThemeController());
      debugPrint('✅ ThemeController initialized (background)');

      // Setup FCM background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      debugPrint('✅ FCM background handler registered');
    });
  }

  /// Helper to wrap service initialization
  Future<void> _initServiceAsync(Future<void> Function() init) async {
    try {
      await init();
    } catch (e) {
      debugPrint('⚠️ Service init error (non-fatal): $e');
    }
  }
}

/// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📱 Background message received: ${message.messageId}');
}

/// Extension to check if a service is registered
extension GetxServiceCheck on GetInterface {
  bool isServiceReady<T>() {
    try {
      Get.find<T>();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Safely find a service, returning null if not registered
  T? findSafe<T>() {
    try {
      return Get.find<T>();
    } catch (_) {
      return null;
    }
  }

  /// Wait for a service to be available (with timeout)
  Future<T> waitForService<T>({Duration timeout = const Duration(seconds: 10)}) async {
    final completer = Completer<T>();
    final stopwatch = Stopwatch()..start();

    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (isServiceReady<T>()) {
        timer.cancel();
        completer.complete(Get.find<T>());
      } else if (stopwatch.elapsed > timeout) {
        timer.cancel();
        completer.completeError(
          TimeoutException('Service $T not available after ${timeout.inSeconds}s'),
        );
      }
    });

    return completer.future;
  }
}

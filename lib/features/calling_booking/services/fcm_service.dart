import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/incoming_call_screen.dart';
import '../controllers/call_controller.dart';
import '../services/zego_call_service.dart';
import '../../../services/device_registration_service.dart';
import '../../../config/environment_config.dart';
import 'dart:io' show Platform;

/// Local notifications plugin instance (must be top-level)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background FCM message handler (top-level function required)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 Background FCM message: ${message.data}');

  // Handle call-related notifications in background
  if (message.data['type'] == 'incoming_call') {
    debugPrint('📞 Incoming call in background: ${message.data}');

    // Show local notification to open the app
    await _showIncomingCallNotification(message.data);
  }
}

/// Show local notification for incoming call (top-level function)
Future<void> _showIncomingCallNotification(Map<String, dynamic> data) async {
  try {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'incoming_calls',
      'Incoming Calls',
      channelDescription: 'Notifications for incoming voice calls',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Encode the data as JSON for proper parsing later
    final payload = jsonEncode(data);

    await flutterLocalNotificationsPlugin.show(
      0, // notification id
      'Incoming Call',
      '${data['caller_name'] ?? 'Someone'} is calling...',
      notificationDetails,
      payload: payload,
    );

    debugPrint('📱 Local notification shown for incoming call');
  } catch (e) {
    debugPrint('❌ Error showing local notification: $e');
  }
}

class FCMService extends GetxService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final DeviceRegistrationService _deviceService =
      Get.find<DeviceRegistrationService>();
  final FlutterLocalNotificationsPlugin _localNotifications =
      flutterLocalNotificationsPlugin;

  /// Initialize FCM service
  Future<FCMService> init() async {
    debugPrint('🔔 Initializing FCM Service...');

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Request permissions
    await _requestPermissions();

    // Register FCM token with backend
    await registerDeviceToken();

    // Setup FCM listeners
    _setupFCMListeners();

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM token refreshed: $newToken');
      registerDeviceToken();
    });

    debugPrint('✅ FCM Service initialized');
    return this;
  }

  /// Initialize local notifications for heads-up notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      // Android initialization
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android notification channel for incoming calls
      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'incoming_calls',
          'Incoming Calls',
          description: 'Notifications for incoming voice calls',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        debugPrint('✅ Android notification channel created');
      }

      debugPrint('✅ Local notifications initialized');
    } catch (e) {
      debugPrint('❌ Error initializing local notifications: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');

    if (response.payload == null || response.payload!.isEmpty) {
      debugPrint('⚠️ No payload in notification response');
      return;
    }

    try {
      // Parse the JSON payload
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      debugPrint('📱 Parsed notification data: $data');

      // Navigate to incoming call screen
      if (data['type'] == 'incoming_call') {
        _handleIncomingCall(data);
      }
    } catch (e) {
      debugPrint('❌ Error parsing notification payload: $e');
    }
  }

  /// Request FCM permissions
  Future<void> _requestPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ FCM permissions granted');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('⚠️ FCM provisional permission granted');
      } else {
        debugPrint('❌ FCM permissions denied');
      }
    } catch (e) {
      debugPrint('❌ Error requesting FCM permissions: $e');
    }
  }

  /// Register FCM device token with backend
  Future<void> registerDeviceToken() async {
    try {
      final fcmToken = await _firebaseMessaging.getToken();

      if (fcmToken == null) {
        debugPrint('❌ Failed to get FCM token');
        return;
      }

      debugPrint('🔑 FCM Token: ${fcmToken.substring(0, 20)}...');

      // Register with backend using existing device registration service
      // The DeviceRegistrationService will handle storing the FCM token
      await _deviceService.registerDevice(fcmToken: fcmToken);

      debugPrint('✅ FCM token registered with backend');
    } catch (e) {
      debugPrint('❌ Error registering FCM token: $e');
    }
  }

  /// Setup FCM message listeners
  void _setupFCMListeners() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background/terminated: App opened via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check for initial message when app launched from terminated state
    _checkInitialMessage();

    // Check for notification tap when app was in background/terminated
    _checkInitialNotificationResponse();
  }

  /// Check if app was launched by tapping a local notification
  Future<void> _checkInitialNotificationResponse() async {
    try {
      final details =
          await _localNotifications.getNotificationAppLaunchDetails();

      if (details != null && details.didNotificationLaunchApp) {
        debugPrint('📱 App launched from local notification tap');

        if (details.notificationResponse != null) {
          final response = details.notificationResponse!;
          debugPrint('📱 Notification response: ${response.payload}');

          // Handle the notification tap (wait for app to be ready)
          await Future.delayed(const Duration(milliseconds: 500));
          _onNotificationTapped(response);
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking initial notification: $e');
    }
  }

  /// Handle foreground FCM messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 FCM message received (foreground): ${message.data}');

    final messageType = message.data['type'];
    debugPrint('📱 Message type: $messageType');

    switch (messageType) {
      case 'incoming_call':
        _handleIncomingCall(message.data);
        break;
      case 'call_accepted':
        _handleCallAccepted(message.data);
        break;
      case 'call_rejected':
        _handleCallRejected(message.data);
        break;
      case 'call_ended':
        debugPrint('📱 ⚡ Routing to _handleCallEnded');
        _handleCallEnded(message.data);
        break;
      case 'missed_call':
        _handleMissedCall(message.data);
        break;
      default:
        debugPrint('⚠️ Unknown FCM message type: $messageType');
    }
  }

  /// Handle app opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('📱 App opened from notification: ${message.data}');

    if (message.data['type'] == 'incoming_call') {
      _handleIncomingCall(message.data);
    }
  }

  /// Check for initial message when app launched
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('📱 App launched from notification: ${initialMessage.data}');

      if (initialMessage.data['type'] == 'incoming_call') {
        // Delay to ensure app is ready
        await Future.delayed(const Duration(seconds: 1));
        _handleIncomingCall(initialMessage.data);
      }
    }
  }

  /// Handle incoming call notification
  void _handleIncomingCall(Map<String, dynamic> data) {
    try {
      final callId = data['call_id']?.toString() ?? '';
      final channelName = data['channel_name']?.toString() ?? '';
      final callerName = data['caller_name']?.toString() ?? 'Unknown';
      String callerPhoto = data['caller_photo']?.toString() ?? '';
      final callType = data['call_type']?.toString() ?? 'voice';
      final callerId = data['caller_id']?.toString() ?? '';

      // Convert relative/file URLs to absolute URLs
      if (callerPhoto.isNotEmpty) {
        // Check if it's already an absolute URL (starts with http:// or https://)
        if (!callerPhoto.startsWith('http://') &&
            !callerPhoto.startsWith('https://')) {
          // It's a relative path - remove file:// prefix and leading slashes
          callerPhoto = callerPhoto
              .replaceFirst('file:///', '')
              .replaceFirst(RegExp(r'^/+'), '');
          // Prepend base URL
          callerPhoto = '${EnvironmentConfig.baseUrl}/$callerPhoto';
          debugPrint('🖼️ Converted photo URL to: $callerPhoto');
        }
      }

      if (callId.isEmpty || channelName.isEmpty) {
        debugPrint('❌ Invalid incoming call data: $data');
        return;
      }

      debugPrint('📞 Incoming call from $callerName');

      // Navigate to incoming call screen
      Get.to(
        () => IncomingCallScreen(
          callId: callId,
          channelName: channelName,
          callerName: callerName,
          callerPhoto: callerPhoto,
          callType: callType,
          callerId: callerId,
        ),
        fullscreenDialog: true,
      );
    } catch (e) {
      debugPrint('❌ Error handling incoming call: $e');
    }
  }

  /// Handle call accepted notification
  void _handleCallAccepted(Map<String, dynamic> data) {
    debugPrint('✅ Call accepted by consultant');

    Get.snackbar(
      'Call Accepted',
      'Consultant is joining the call...',
      icon: const Icon(Icons.check_circle, color: Colors.white),
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );
  }

  /// Handle call rejected notification
  void _handleCallRejected(Map<String, dynamic> data) {
    debugPrint('❌ Call rejected by consultant');
    debugPrint('📍 Current route: ${Get.currentRoute}');

    Get.snackbar(
      'Call Declined',
      'The consultant is unable to take your call right now.',
      icon: const Icon(Icons.cancel, color: Colors.white),
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );

    // Delay closing the screen so user can see the rejection message
    Future.delayed(const Duration(milliseconds: 500), () {
      debugPrint('🚪 Attempting to close call screens...');

      // Try to end the call via CallController first (proper cleanup)
      if (Get.isRegistered<CallController>()) {
        try {
          final controller = Get.find<CallController>();
          debugPrint('🚪 Ending call via CallController');
          controller.endCall();
          return; // Controller will handle screen closure
        } catch (e) {
          debugPrint('⚠️ Error accessing CallController: $e');
        }
      }

      // Fallback: Close screens directly
      // Use until() to close until we're not on a call-related screen
      Get.until((route) {
        final routeName = route.settings.name ?? '';
        final shouldStop = !routeName.contains('Call') &&
            !routeName.contains('call') &&
            !routeName.contains('Incoming');
        debugPrint('🚪 Route: $routeName, stopping: $shouldStop');
        return shouldStop;
      });
    });
  }

  /// Handle call ended notification
  void _handleCallEnded(Map<String, dynamic> data) {
    debugPrint('📞 ❗ CALL ENDED NOTIFICATION RECEIVED');
    debugPrint('📥 Call ended data: $data');
    debugPrint('📥 Duration: ${data['duration_seconds']} seconds');
    debugPrint('📥 Message: ${data['message']}');

    // IMMEDIATELY try to stop timer via ZegoService first
    try {
      final zegoService = Get.find<ZegoCallService>();
      zegoService.stopDurationTimer();
      debugPrint('⏱️ ✅ Timer stopped via ZegoService immediately');
    } catch (e) {
      debugPrint('⚠️ Could not access ZegoService to stop timer: $e');
    }

    // Close the call properly through the controller
    // This ensures proper cleanup of ZegoCloud resources
    if (Get.isRegistered<CallController>()) {
      debugPrint('🎮 Found CallController, triggering endCall()');
      try {
        final controller = Get.find<CallController>();
        // Call endCall to properly cleanup ZegoCloud, stop timer, and close screen
        controller.endCall();
        debugPrint('✅ Controller endCall() triggered - window will close');
      } catch (e) {
        debugPrint('❌ Error calling controller.endCall(): $e');
        // Fallback: try to close screen directly
        _closeCallScreens();
      }
    } else {
      debugPrint('⚠️ CallController not registered, using fallback navigation');
      // Fallback: Close any call-related screens directly
      _closeCallScreens();
    }
  }

  /// Fallback method to close call screens directly
  void _closeCallScreens() {
    debugPrint('🔍 Current route: ${Get.currentRoute}');

    // Try multiple times to ensure we close the screen
    if (Get.currentRoute.contains('call') ||
        Get.currentRoute.contains('Call')) {
      debugPrint('📱 Closing call screen...');

      // Close the screen multiple times if needed
      int attempts = 0;
      while (attempts < 3 &&
          (Get.currentRoute.contains('call') ||
              Get.currentRoute.contains('Call'))) {
        try {
          Get.back();
          attempts++;
          debugPrint('✅ Closed call screen (attempt $attempts)');
        } catch (e) {
          debugPrint('❌ Error closing call screen: $e');
          break;
        }
      }
    } else {
      debugPrint('ℹ️ Not on call screen, no need to close');
    }
  }

  /// Handle missed call notification
  void _handleMissedCall(Map<String, dynamic> data) {
    debugPrint('📵 Missed call notification');

    final callerName = data['caller_name']?.toString() ?? 'Someone';

    Get.snackbar(
      'Missed Call',
      'You missed a call from $callerName',
      icon: const Icon(Icons.phone_missed, color: Colors.white),
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }
}

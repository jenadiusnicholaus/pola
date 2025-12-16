import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/incoming_call_screen.dart';
import '../../../services/device_registration_service.dart';
import '../../../config/environment_config.dart';

/// Background FCM message handler (top-level function required)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 Background FCM message: ${message.data}');

  // Handle call-related notifications in background
  if (message.data['type'] == 'incoming_call') {
    debugPrint('📞 Incoming call in background: ${message.data}');
    // The FCM notification itself will wake the app
    // When app opens, it will be handled by getInitialMessage
  }
}

class FCMService extends GetxService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final DeviceRegistrationService _deviceService =
      Get.find<DeviceRegistrationService>();

  /// Initialize FCM service
  Future<FCMService> init() async {
    debugPrint('🔔 Initializing FCM Service...');

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
  }

  /// Handle foreground FCM messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 FCM message received (foreground): ${message.data}');

    final messageType = message.data['type'];

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

    Get.snackbar(
      'Call Declined',
      'The consultant is unable to take your call right now.',
      icon: const Icon(Icons.cancel, color: Colors.white),
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );

    // Close call screen if open
    if (Get.currentRoute.contains('call')) {
      Get.back();
    }
  }

  /// Handle call ended notification
  void _handleCallEnded(Map<String, dynamic> data) {
    debugPrint('📞 Call ended by other party');

    // Close call screen if open
    if (Get.currentRoute.contains('call')) {
      Get.back();
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

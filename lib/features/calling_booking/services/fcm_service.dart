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
import '../../notifications/controllers/notification_controller.dart';
import 'dart:io' show Platform;

/// Local notifications plugin instance (must be top-level)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background FCM message handler (top-level function required)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 Background FCM message: ${message.data}');

  final messageType = message.data['type'];

  // Handle call-related notifications in background
  if (messageType == 'incoming_call') {
    debugPrint('📞 Incoming call in background: ${message.data}');
    await _showIncomingCallNotification(message.data);
  } else {
    // Handle general notifications in background
    debugPrint('🔔 General notification in background: ${message.data}');
    await _showBackgroundNotification(message);
  }
}

/// Show local notification for general messages in background (top-level function)
Future<void> _showBackgroundNotification(RemoteMessage message) async {
  try {
    final notification = message.notification;
    final data = message.data;
    
    String title = notification?.title ?? data['title'] ?? 'New Notification';
    String body = notification?.body ?? data['body'] ?? '';
    final messageType = data['type'] ?? 'system';
    
    // Determine notification channel based on type
    String channelId = 'general_notifications';
    String channelName = 'General Notifications';
    if (messageType == 'payment_received') {
      channelId = 'payment_notifications';
      channelName = 'Payment Notifications';
    }
    
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'App notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Generate unique notification ID
    final notificationId = message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;
    
    // Encode data for payload
    final payload = jsonEncode(data);
    
    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
    
    debugPrint('✅ Background notification shown: $title');
  } catch (e) {
    debugPrint('❌ Error showing background notification: $e');
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

    // Mark call as pending
    final callId = data['call_id']?.toString() ?? '';
    if (callId.isNotEmpty) {
      _markCallPending(callId);
    }

    await flutterLocalNotificationsPlugin.show(
      _incomingCallNotificationId, // Use constant ID for cancellation
      'Incoming Call',
      '${data['caller_name'] ?? 'Someone'} is calling...',
      notificationDetails,
      payload: payload,
    );

    debugPrint(
        '📱 Local notification shown for incoming call (id: $_incomingCallNotificationId)');
  } catch (e) {
    debugPrint('❌ Error showing local notification: $e');
  }
}

/// Notification ID for incoming calls (used to cancel it later)
const int _incomingCallNotificationId = 1001;

/// Track pending incoming calls to prevent duplicate handling
/// Key: callId, Value: timestamp when call started
final Map<String, DateTime> _pendingCalls = {};

/// Check if a call is still pending (not yet accepted/rejected/ended)
bool _isCallPending(String callId) {
  if (!_pendingCalls.containsKey(callId)) return false;

  // Consider call expired after 60 seconds
  final startTime = _pendingCalls[callId]!;
  final isExpired = DateTime.now().difference(startTime).inSeconds > 60;
  if (isExpired) {
    _pendingCalls.remove(callId);
    return false;
  }
  return true;
}

/// Mark a call as pending
void _markCallPending(String callId) {
  _pendingCalls[callId] = DateTime.now();
}

/// Clear a pending call (when accepted, rejected, or ended)
void _clearPendingCall(String callId) {
  _pendingCalls.remove(callId);
}

/// Cancel the incoming call notification
Future<void> _cancelIncomingCallNotification() async {
  try {
    await flutterLocalNotificationsPlugin.cancel(_incomingCallNotificationId);
    debugPrint('🔕 Cancelled incoming call notification');
  } catch (e) {
    debugPrint('⚠️ Error cancelling notification: $e');
  }
}

class FCMService extends GetxService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  late final DeviceRegistrationService _deviceService;
  final FlutterLocalNotificationsPlugin _localNotifications =
      flutterLocalNotificationsPlugin;
  
  Timer? _tokenRefreshTimer;
  static const Duration _tokenRefreshInterval = Duration(hours: 12); // Refresh token every 12 hours

  /// Initialize FCM service
  Future<FCMService> init() async {
    debugPrint('🔔 Initializing FCM Service...');
    
    // Get device service (must be registered before FCM service)
    _deviceService = Get.find<DeviceRegistrationService>();
    debugPrint('📱 DeviceRegistrationService found');

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
      debugPrint('🔄 FCM token refreshed automatically: ${newToken.substring(0, 20)}...');
      _registerTokenWithBackend(newToken, isUpdate: true);
    });
    
    // Start periodic token refresh to ensure backend always has valid token
    _startPeriodicTokenRefresh();

    debugPrint('✅ FCM Service initialized');
    return this;
  }
  
  /// Start periodic token refresh
  void _startPeriodicTokenRefresh() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer.periodic(_tokenRefreshInterval, (_) {
      debugPrint('🔄 Periodic FCM token refresh...');
      refreshAndRegisterToken();
    });
  }
  
  /// Force refresh FCM token and register with backend
  Future<void> refreshAndRegisterToken() async {
    try {
      debugPrint('🔄 Force refreshing FCM token...');
      
      // Delete the old token first
      await _firebaseMessaging.deleteToken();
      debugPrint('🗑️ Old FCM token deleted');
      
      // Get a new token
      final newToken = await _firebaseMessaging.getToken();
      
      if (newToken != null) {
        debugPrint('🔑 New FCM Token: ${newToken.substring(0, 20)}...');
        await _registerTokenWithBackend(newToken, isUpdate: true);
      } else {
        debugPrint('❌ Failed to get new FCM token');
      }
    } catch (e) {
      debugPrint('❌ Error refreshing FCM token: $e');
    }
  }
  
  /// Register token with backend via device registration
  /// For initial registration, uses full device registration
  /// For token updates, uses the more efficient PATCH endpoint
  Future<void> _registerTokenWithBackend(String token, {bool isUpdate = false}) async {
    try {
      if (isUpdate) {
        // Use PATCH endpoint for token updates - more efficient
        final success = await _deviceService.updateFcmToken(fcmToken: token);
        if (success) {
          debugPrint('✅ FCM token updated with backend (PATCH)');
        } else {
          debugPrint('⚠️ FCM token update failed, already fell back to full registration');
        }
      } else {
        // Use full device registration for initial setup
        await _deviceService.registerDevice(fcmToken: token);
        debugPrint('✅ FCM token registered with backend (full registration)');
      }
    } catch (e) {
      debugPrint('❌ Error registering FCM token with backend: $e');
    }
  }
  
  @override
  void onClose() {
    _tokenRefreshTimer?.cancel();
    super.onClose();
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

      // Create Android notification channels
      if (Platform.isAndroid) {
        final androidPlugin =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        // Channel for incoming calls (high priority)
        const AndroidNotificationChannel callChannel =
            AndroidNotificationChannel(
          'incoming_calls',
          'Incoming Calls',
          description: 'Notifications for incoming voice calls',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        // Channel for general notifications
        const AndroidNotificationChannel generalChannel =
            AndroidNotificationChannel(
          'general_notifications',
          'General Notifications',
          description: 'Mentions, replies, updates, and other notifications',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        // Channel for payment notifications
        const AndroidNotificationChannel paymentChannel =
            AndroidNotificationChannel(
          'payment_notifications',
          'Payment Notifications',
          description: 'Payment received and transaction updates',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        await androidPlugin?.createNotificationChannel(callChannel);
        await androidPlugin?.createNotificationChannel(generalChannel);
        await androidPlugin?.createNotificationChannel(paymentChannel);

        debugPrint('✅ Android notification channels created');
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

      // Navigate based on notification type
      if (data['type'] == 'incoming_call') {
        // For notification taps on call notifications, check if call is still pending
        final callId = data['call_id']?.toString() ?? '';
        if (callId.isNotEmpty && !_isCallPending(callId)) {
          debugPrint('⚠️ Call $callId is no longer pending, ignoring notification tap');
          _cancelIncomingCallNotification();
          return;
        }
        _handleIncomingCall(data);
      } else {
        // Handle general notifications
        _navigateFromNotification(data);
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
    debugPrint('📱 ====== FCM MESSAGE RECEIVED ======');
    debugPrint('📱 FCM data: ${message.data}');
    debugPrint('📱 FCM notification: ${message.notification?.title} - ${message.notification?.body}');

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
      // Handle general notifications (mentions, replies, etc.)
      case 'mention':
      case 'reply':
      case 'consultation_request':
      case 'consultation_status':
      case 'payment_received':
      case 'document_ready':
      case 'system':
        _handleGeneralNotification(message);
        break;
      default:
        debugPrint('⚠️ Unknown FCM message type: $messageType');
        // Still show notification for unknown types if there's a notification payload
        if (message.notification != null) {
          _handleGeneralNotification(message);
        }
    }
  }

  /// Handle general notifications (mentions, replies, payments, etc.)
  Future<void> _handleGeneralNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final data = message.data;
      
      String title = notification?.title ?? data['title'] ?? 'New Notification';
      String body = notification?.body ?? data['body'] ?? '';
      final messageType = data['type'] ?? 'system';
      
      debugPrint('🔔 Showing notification: $title - $body');
      
      // Determine notification channel based on type
      String channelId = 'general_notifications';
      if (messageType == 'payment_received') {
        channelId = 'payment_notifications';
      }
      
      // Android notification details
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == 'payment_notifications' ? 'Payment Notifications' : 'General Notifications',
        channelDescription: 'App notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );
      
      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Generate unique notification ID from message data
      final notificationId = message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;
      
      // Encode data for payload
      final payload = jsonEncode(data);
      
      await _localNotifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      
      // Refresh notification count in the app
      _refreshNotificationCount();
      
      debugPrint('✅ Local notification shown: $title');
    } catch (e) {
      debugPrint('❌ Error showing general notification: $e');
    }
  }
  
  /// Refresh notification count in the app
  void _refreshNotificationCount() {
    try {
      // Try to refresh notification controller if it exists
      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>().refreshUnreadCount();
      }
    } catch (e) {
      debugPrint('⚠️ Could not refresh notification count: $e');
    }
  }

  /// Handle app opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('📱 App opened from notification: ${message.data}');

    final messageType = message.data['type'];
    
    if (messageType == 'incoming_call') {
      _handleIncomingCall(message.data);
    } else {
      // Navigate based on notification type
      _navigateFromNotification(message.data);
    }
  }
  
  /// Navigate to appropriate screen based on notification data
  void _navigateFromNotification(Map<String, dynamic> data) {
    final actionType = data['action_type'];
    
    debugPrint('🔔 Navigating for action: $actionType');
    
    switch (actionType) {
      case 'open_comment':
        final hubType = data['hub_type']?.toString() ?? 'forum';
        String route;
        switch (hubType.toLowerCase()) {
          case 'forum':
            route = '/forum-hub';
            break;
          case 'advocates':
            route = '/advocates-hub';
            break;
          case 'students':
            route = '/students-hub';
            break;
          default:
            route = '/forum-hub';
        }
        Get.toNamed(route);
        break;
        
      case 'open_consultation':
        Get.toNamed('/my-consultations');
        break;
        
      case 'open_earnings':
        Get.toNamed('/my-consultations');
        break;
        
      case 'open_document':
        Get.toNamed('/my-documents');
        break;
        
      default:
        // Open notifications screen
        Get.toNamed('/notifications');
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

      if (callId.isEmpty || channelName.isEmpty) {
        debugPrint('❌ Invalid incoming call data: $data');
        return;
      }

      // Mark this call as pending (for new incoming calls)
      // If call already exists, this just updates the timestamp
      _markCallPending(callId);

      // Check if we're already on a call screen
      final currentRoute = Get.currentRoute;
      if (currentRoute.contains('Call') || currentRoute.contains('call')) {
        debugPrint(
            '⚠️ Already on a call screen, ignoring duplicate incoming call');
        return;
      }

      // Check if call controller exists and is in a call
      if (Get.isRegistered<CallController>()) {
        final controller = Get.find<CallController>();
        if (controller.isCallConnected.value) {
          debugPrint('⚠️ Already connected to a call, ignoring incoming call');
          return;
        }
      }

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

      debugPrint('📞 Incoming call from $callerName (call pending)');

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

    // Cancel the incoming call notification and clear pending state
    final callId = data['call_id']?.toString() ?? '';
    if (callId.isNotEmpty) {
      _clearPendingCall(callId);
    }
    _cancelIncomingCallNotification();

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

    // Cancel the incoming call notification and clear pending state
    final callId = data['call_id']?.toString() ?? '';
    if (callId.isNotEmpty) {
      _clearPendingCall(callId);
    }
    _cancelIncomingCallNotification();

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

    // Cancel the incoming call notification and clear pending state
    final callId = data['call_id']?.toString() ?? '';
    if (callId.isNotEmpty) {
      _clearPendingCall(callId);
    }
    _cancelIncomingCallNotification();

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

    // Cancel the incoming call notification and clear pending state
    final callId = data['call_id']?.toString() ?? '';
    if (callId.isNotEmpty) {
      _clearPendingCall(callId);
    }
    _cancelIncomingCallNotification();

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

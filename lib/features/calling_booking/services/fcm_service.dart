import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/navigation_helper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import '../../../firebase_options.dart';
import '../controllers/call_controller.dart';
import '../services/nexacon_call_service.dart';
import '../services/call_service.dart';
import '../../../services/device_registration_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/token_storage_service.dart';
import '../../../config/environment_config.dart';
import '../../notifications/controllers/notification_controller.dart';
import 'dart:io' show Platform;

/// Local notifications plugin instance (must be top-level)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Whether local notifications have been initialized in this isolate
bool _localNotificationsInitialized = false;

/// Ensure Firebase and local notifications are ready in the background isolate
Future<void> _ensureBackgroundSetup() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Already initialized
  }

  // Background isolates don't inherit dotenv state from the main isolate.
  // EnvironmentConfig.baseUrl (used by _showCallKitIncoming) reads dotenv.env,
  // which throws NotInitializedError if load() hasn't run in this isolate —
  // silently breaking CallKit display. Load it here before it's needed.
  try {
    if (!dotenv.isInitialized) {
      await dotenv.load(fileName: '.env');
    }
  } catch (e) {
    debugPrint('⚠️ Error loading .env in background isolate: $e');
  }

  if (!_localNotificationsInitialized) {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    if (Platform.isAndroid) {
      final androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      const AndroidNotificationChannel callChannel = AndroidNotificationChannel(
        'incoming_calls',
        'Incoming Calls',
        description: 'Notifications for incoming voice calls',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
      );

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
    }

    _localNotificationsInitialized = true;
    debugPrint('✅ Background isolate: local notifications initialized');
  }
}

/// Background FCM message handler (top-level function required)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 Background FCM message: ${message.data}');

  await _ensureBackgroundSetup();

  final messageType = message.data['type'];

  // Handle call-related notifications in background
  if (messageType == 'incoming_call') {
    if (_isNxCallData(message.data)) {
      // NX backend push — normalize and show CallKit
      debugPrint('📞 NX incoming call in background: ${message.data}');
      final nxData = _normalizeNxCallData(message.data);
      await _showCallKitIncoming(nxData);
    } else {
      // Pola backend push — ignore, NX handles incoming calls now
      debugPrint('📞 Ignoring Pola incoming call (NX-only mode)');
    }
  } else if (messageType == 'call_ended' ||
      messageType == 'call_rejected' ||
      messageType == 'missed_call' ||
      messageType == 'call_accepted') {
    // End the CallKit incoming call — call is no longer active
    debugPrint('📞 Call event in background: $messageType — ending call kit');
    await FlutterCallkitIncoming.endAllCalls();

    // Clear pending call
    final callId = message.data['call_id']?.toString() ?? '';
    if (callId.isNotEmpty) {
      _clearPendingCall(callId);
    }

    // Show a brief notification for missed_call only
    if (messageType == 'missed_call') {
      await _showBackgroundNotification(message);
    }
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
    final notificationId =
        message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

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

/// Normalize NX backend FCM payload to the format the app expects.
/// NX backend sends: type=incoming_call, call_id, room, caller_id, caller_name, call_type, call_url
/// App expects:      call_id, channel_name, caller_name, caller_phone, call_type
/// Detection: NX pushes have 'room' field; Pola pushes have 'channel_name' instead.
Map<String, dynamic> _normalizeNxCallData(Map<String, dynamic> data) {
  final normalized = Map<String, dynamic>.from(data);

  // Map NX 'room' → 'channel_name' (for WebRTC room join)
  if (!normalized.containsKey('channel_name') && data['room'] != null) {
    normalized['channel_name'] = data['room'];
  }

  // Map NX 'caller_id' → 'caller_phone' (for NX SDK acceptFromNotification callerNxId)
  if (!normalized.containsKey('caller_phone') && data['caller_id'] != null) {
    final callerId = data['caller_id'].toString();
    final phone = callerId.contains('@') ? callerId.split('@')[0] : callerId;
    normalized['caller_phone'] = phone;
  }

  // call_id and call_type are already the same field names
  debugPrint('📞 Normalized NX call data: $normalized');
  return normalized;
}

/// Check if an incoming_call push is from NX backend (has 'room' field, no 'channel_name').
bool _isNxCallData(Map<String, dynamic> data) {
  return data['room'] != null && data['channel_name'] == null;
}

/// Show native CallKit incoming call UI with ringtone (top-level function)
Future<void> _showCallKitIncoming(Map<String, dynamic> data) async {
  try {
    final callId = data['call_id']?.toString() ?? '';
    final channelName = data['channel_name']?.toString() ?? '';
    var callerName = data['caller_name']?.toString() ?? 'Unknown';
    final callerPhone = data['caller_phone']?.toString() ?? '';
    String callerPhoto = data['caller_photo']?.toString() ?? '';
    final callType = data['call_type']?.toString() ?? 'voice';
    final callerId = data['caller_id']?.toString() ?? '';

    if (callId.isEmpty) {
      debugPrint('❌ Cannot show call kit without call_id');
      return;
    }

    // Never let the native call screen show 'CallKit' or a blank name.
    final callKitLike = callerName.toLowerCase().contains('callkit') ||
        callerName.trim().isEmpty;
    if (callKitLike) {
      callerName = 'Pola';
    }

    _markCallPending(callId);

    // Convert relative/file URLs to absolute URLs for avatar
    if (callerPhoto.isNotEmpty &&
        !callerPhoto.startsWith('http://') &&
        !callerPhoto.startsWith('https://')) {
      callerPhoto = callerPhoto
          .replaceFirst('file:///', '')
          .replaceFirst(RegExp(r'^/+'), '');
      callerPhoto = '${EnvironmentConfig.baseUrl}/$callerPhoto';
    }

    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: ' ',
      avatar: callerPhoto.isNotEmpty ? callerPhoto : null,
      handle: '',
      type: callType == 'video' ? 1 : 0,
      duration: 60000, // 60s timeout
      textAccept: 'Accept',
      textDecline: 'Decline',
      extra: <String, dynamic>{
        'call_id': callId,
        'channel_name': channelName,
        'caller_name': callerName,
        'caller_photo': callerPhoto,
        'call_type': callType,
        'caller_id': callerId,
        'caller_phone': callerPhone,
      },
      android: AndroidParams(
        isCustomNotification: false,
        isShowLogo: true,
        isShowFullLockedScreen: true,
        isImportant: true,
        isShowCallID: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#2C3E50',
        actionColor: '#2ECC71',
        textColor: '#FFFFFF',
      ),
      ios: const IOSParams(
        iconName: 'AppIcon',
        ringtonePath: 'system_ringtone_default',
        handleType: 'generic',
        supportsVideo: true,
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);

    debugPrint('📱 CallKit incoming shown for $callerName (call: $callId)');

    // Auto end the call after 60 seconds if no response
    Timer(const Duration(seconds: 60), () {
      if (callId.isNotEmpty && _isCallPending(callId)) {
        debugPrint('⏰ Call $callId auto-expiring after 60s — ending CallKit');
        _clearPendingCall(callId);
        FlutterCallkitIncoming.endCall(callId);
      }
    });
  } catch (e) {
    debugPrint('❌ Error showing CallKit incoming: $e');
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

  // Consider call expired after 120 seconds (was 60 — too short for background)
  final startTime = _pendingCalls[callId]!;
  final isExpired = DateTime.now().difference(startTime).inSeconds > 120;
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

/// Cancel the incoming call notification (CallKit + local notification)
Future<void> _cancelIncomingCallNotification() async {
  try {
    // End any active CallKit incoming call
    await FlutterCallkitIncoming.endAllCalls();

    // Also cancel the local fallback notification
    await flutterLocalNotificationsPlugin.cancel(_incomingCallNotificationId);
    debugPrint('🔕 Cancelled incoming call notifications');
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
  static const Duration _tokenRefreshInterval =
      Duration(hours: 12); // Refresh token every 12 hours

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

    // NOTE: Initial device registration is handled by LoginController._registerDevice()
    // which passes the FCM token. We only listen for token refreshes here to update
    // an already-registered device's FCM token.
    debugPrint(
        '📱 Skipping initial registerDeviceToken — handled by login flow');

    // Force re-register with NX backend on every app startup.
    // This handles the case where the user changed devices but is already
    // logged in — the old device's NX registration is revoked and the new
    // device's FCM token is registered so calls are routed correctly.
    _forceNxReRegistration();

    // Setup FCM listeners
    _setupFCMListeners();

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint(
          '🔄 FCM token refreshed automatically: ${newToken.substring(0, 20)}...');
      _registerTokenWithBackend(newToken, isUpdate: true);
      _registerTokenWithNx(newToken);
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
        await _registerTokenWithNx(newToken);
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
  Future<void> _registerTokenWithBackend(String token,
      {bool isUpdate = false}) async {
    try {
      if (isUpdate) {
        // Use PATCH endpoint for token updates - more efficient
        final success = await _deviceService.updateFcmToken(fcmToken: token);
        if (success) {
          debugPrint('✅ FCM token updated with backend (PATCH)');
        } else {
          debugPrint(
              '⚠️ FCM token update failed, already fell back to full registration');
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

  /// Re-register FCM token with NX backend on token refresh
  Future<void> _registerTokenWithNx(String fcmToken) async {
    try {
      final tokenStorage = Get.find<TokenStorageService>();
      final userData = tokenStorage.userData;
      String? myPhone = userData?['phone_number'] as String? ??
          userData?['phone'] as String? ??
          userData?['phoneNumber'] as String?;
      if (myPhone == null || myPhone.isEmpty) {
        final contact = userData?['contact'] as Map<String, dynamic>?;
        myPhone = contact?['phone_number'] as String?;
      }
      if (myPhone == null || myPhone.isEmpty) {
        debugPrint('⚠️ No phone — skipping NX token refresh registration');
        return;
      }

      final digits = myPhone.replaceAll(RegExp(r'[^\d]'), '');
      final formattedPhone = digits.startsWith('255')
          ? '+$digits'
          : digits.startsWith('0')
              ? '+255${digits.substring(1)}'
              : '+255$digits';

      // Extract owner display name for the NX backend to use as caller_name
      String? ownerName;
      if (userData != null) {
        final contact = userData['contact'] as Map<String, dynamic>?;
        final userDetails = userData['user_details'] as Map<String, dynamic>? ??
            userData['userDetails'] as Map<String, dynamic>?;

        ownerName = userData['full_name'] as String? ??
            userData['fullName'] as String? ??
            userData['name'] as String? ??
            userDetails?['full_name'] as String? ??
            userDetails?['fullName'] as String? ??
            contact?['full_name'] as String? ??
            contact?['fullName'] as String?;

        if (ownerName == null || ownerName.isEmpty) {
          final firstName = userData['first_name'] as String? ??
              userData['firstName'] as String? ??
              userDetails?['first_name'] as String?;
          final lastName = userData['last_name'] as String? ??
              userData['lastName'] as String? ??
              userDetails?['last_name'] as String?;
          final parts = <String>[
            if (firstName != null && firstName.isNotEmpty) firstName,
            if (lastName != null && lastName.isNotEmpty) lastName,
          ];
          if (parts.isNotEmpty) {
            ownerName = parts.join(' ');
          }
        }
      }

      if (!Get.isRegistered<NexaconCallService>()) {
        Get.put(NexaconCallService(), permanent: true);
      }
      final nexaconService = Get.find<NexaconCallService>();
      await nexaconService.registerDeviceWithNx(
        fcmToken: fcmToken,
        username: formattedPhone,
        ownerName: ownerName,
      );
      debugPrint('✅ FCM token re-registered with NX backend');
    } catch (e) {
      debugPrint('⚠️ NX token refresh registration failed (non-blocking): $e');
    }
  }

  /// Force re-register the current FCM token with NX backend on app startup.
  /// This revokes old device registrations and registers the current device,
  /// ensuring calls are routed to the correct device after a device change.
  Future<void> _forceNxReRegistration() async {
    try {
      final tokenStorage = Get.find<TokenStorageService>();
      final userData = tokenStorage.userData;
      if (userData == null) {
        debugPrint('⚠️ No user data — skipping NX re-registration');
        return;
      }

      final fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ No FCM token — skipping NX re-registration');
        return;
      }

      debugPrint('🔄 Force NX re-registration with current FCM token...');
      await _registerTokenWithNx(fcmToken);
    } catch (e) {
      debugPrint('⚠️ Force NX re-registration failed (non-blocking): $e');
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
          audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
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
    debugPrint('📱 Action ID: ${response.actionId}');

    if (response.payload == null || response.payload!.isEmpty) {
      debugPrint('⚠️ No payload in notification response');
      return;
    }

    try {
      // Parse the JSON payload
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      debugPrint('📱 Parsed notification data: $data');

      // Handle action buttons from incoming call notification
      if (response.actionId == 'accept_call') {
        debugPrint('✅ Accept button tapped from notification');
        _cancelIncomingCallNotification();
        final callId = data['call_id']?.toString() ?? '';
        if (callId.isNotEmpty) {
          _clearPendingCall(callId);
        }
        _handleIncomingCall(data);
        return;
      }

      if (response.actionId == 'reject_call') {
        debugPrint('❌ Decline button tapped from notification');
        _cancelIncomingCallNotification();
        final callId = data['call_id']?.toString() ?? '';
        if (callId.isNotEmpty) {
          _clearPendingCall(callId);
          _rejectCallFromNotification(callId);
        }
        return;
      }
      // Navigate based on notification type (regular tap, not action button)
      if (data['type'] == 'incoming_call') {
        // For notification taps on call notifications, check if call is still pending
        final callId = data['call_id']?.toString() ?? '';
        if (callId.isNotEmpty && !_isCallPending(callId)) {
          debugPrint(
              '⚠️ Call $callId is no longer pending — navigating anyway in case call is still active');
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

  /// Accept a call directly from the native CallKit UI (Accept button) and
  /// jump straight into CallScreen — do NOT re-show IncomingCallScreen here.
  /// Requiring a second in-app tap after the user already answered natively
  /// was leaving calls "accepted" on the backend with no audio ever
  /// connecting (callerPhone is required by NexaconCallService to join).
  Future<void> _acceptCallFromCallKit(Map<String, dynamic> data) async {
    final callId = data['call_id']?.toString() ?? '';
    final channelName = data['channel_name']?.toString() ?? '';
    final callerName = data['caller_name']?.toString() ?? 'Unknown';
    final callerPhoto = data['caller_photo']?.toString() ?? '';
    final rawCallerPhone = data['caller_phone']?.toString() ?? '';

    if (callId.isEmpty || channelName.isEmpty) {
      debugPrint('❌ Cannot accept CallKit call — missing call_id/channel');
      return;
    }

    try {
      await FlutterCallkitIncoming.setCallConnected(callId);
    } catch (e) {
      debugPrint('⚠️ setCallConnected failed (non-fatal): $e');
    }

    try {
      debugPrint('✅ Accepting CallKit call: $callId');

      // Format caller phone with country code for NX compatibility
      final digits = rawCallerPhone.replaceAll(RegExp(r'[^\d]'), '');
      final formattedCallerPhone = digits.isEmpty
          ? rawCallerPhone
          : digits.startsWith('255')
              ? '+$digits'
              : digits.startsWith('0')
                  ? '+255${digits.substring(1)}'
                  : '+255$digits';

      // Navigate to call screen — CallScreen.joinIncomingCall handles NX SDK acceptance
      final args = <String, dynamic>{
        'callId': callId,
        'channelName': channelName,
        'isIncoming': true,
        'callerName': callerName,
        'callerPhoto': callerPhoto,
        'callerPhone': formattedCallerPhone,
      };

      void navigate() => Get.offAllNamed('/call', arguments: args);

      if (Get.context != null) {
        navigate();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => navigate());
      }
    } catch (e) {
      debugPrint('❌ Error accepting CallKit call: $e');
    }
  }

  /// Reject a call from the notification action button
  void _rejectCallFromNotification(String callId) {
    try {
      final callService = CallService();
      callService.rejectCall(callId: callId, reason: 'declined').then((_) {
        debugPrint('✅ Call $callId rejected from notification');
      }).catchError((e) {
        debugPrint('❌ Error rejecting call from notification: $e');
      });
    } catch (e) {
      debugPrint('❌ Error setting up call rejection: $e');
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
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map &&
            errorData['error'] ==
                'This device is already registered to another account') {
          debugPrint(
              '⚠️ Device already registered to another account — skipping FCM registration');
          return;
        }
      }
      debugPrint('❌ Error registering FCM token: $e');
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

    // Listen to CallKit events (Accept/Decline/Timeout)
    _setupCallKitListener();
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

          // Handle the notification tap (wait for app + GetX to be ready)
          await Future.delayed(const Duration(seconds: 2));
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
    debugPrint(
        '📱 FCM notification: ${message.notification?.title} - ${message.notification?.body}');

    final messageType = message.data['type'];
    debugPrint('📱 Message type: $messageType');

    switch (messageType) {
      case 'incoming_call':
        if (_isNxCallData(message.data)) {
          _handleIncomingCall(_normalizeNxCallData(message.data));
        } else {
          debugPrint('📞 Ignoring Pola incoming call (NX-only mode)');
        }
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
      case 'force_logout':
        _handleForceLogout(message.data);
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
        channelId == 'payment_notifications'
            ? 'Payment Notifications'
            : 'General Notifications',
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
      final notificationId =
          message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

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
      if (_isNxCallData(message.data)) {
        _handleIncomingCall(_normalizeNxCallData(message.data));
      } else {
        debugPrint('📞 Ignoring Pola incoming call (NX-only mode)');
      }
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
        if (_isNxCallData(initialMessage.data)) {
          await Future.delayed(const Duration(seconds: 2));
          _handleIncomingCall(_normalizeNxCallData(initialMessage.data));
        } else {
          debugPrint('📞 Ignoring Pola incoming call (NX-only mode)');
        }
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
      final callerPhone = data['caller_phone']?.toString() ?? '';

      if (callId.isEmpty || channelName.isEmpty) {
        debugPrint('❌ Invalid incoming call data: $data');
        return;
      }

      // Mark this call as pending (for new incoming calls)
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

      // Navigate to incoming call screen using the named route
      final args = <String, dynamic>{
        'callId': callId,
        'channelName': channelName,
        'callerName': callerName,
        'callerPhoto': callerPhoto,
        'callType': callType,
        'callerId': callerId,
        'callerPhone': callerPhone,
      };

      if (Get.context != null) {
        Get.toNamed('/incoming-call', arguments: args);
      } else {
        // App may not be fully rendered (e.g. launched from killed state),
        // wait for the first frame before navigating.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.toNamed('/incoming-call', arguments: args);
        });
      }
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

    // Unblock SDK caller wait — NX call_response may be delayed or missing
    if (Get.isRegistered<NexaconCallService>()) {
      try {
        Get.find<NexaconCallService>().notifyRemoteAccepted();
      } catch (e) {
        debugPrint('⚠️ Could not notify NexaconCallService: $e');
      }
    }

    NavigationHelper.showSafeSnackbar(
      title: 'Call Accepted',
      message: 'Consultant is joining the call...',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
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

    NavigationHelper.showSafeSnackbar(
      title: 'Call Declined',
      message: 'The consultant is unable to take your call right now.',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.cancel, color: Colors.white),
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

    // IMMEDIATELY try to stop timer via NexaconService first
    try {
      final nexaconService = Get.find<NexaconCallService>();
      nexaconService.stopDurationTimer();
      debugPrint('⏱️ ✅ Timer stopped via NexaconService immediately');
    } catch (e) {
      debugPrint('⚠️ Could not access NexaconService to stop timer: $e');
    }

    // Close the call properly through the controller
    // This ensures proper cleanup of Nexacon resources
    if (Get.isRegistered<CallController>()) {
      debugPrint('🎮 Found CallController, triggering endCall()');
      try {
        final controller = Get.find<CallController>();
        // Call endCall to properly cleanup Nexacon, stop timer, and close screen
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

    NavigationHelper.showSafeSnackbar(
      title: 'Missed Call',
      message: 'You missed a call from $callerName',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      icon: const Icon(Icons.phone_missed, color: Colors.white),
    );
  }

  /// Another device verified OTP — force this device out to login
  Future<void> _handleForceLogout(Map<String, dynamic> data) async {
    debugPrint('📱 force_logout received: $data');
    try {
      if (Get.isRegistered<AuthService>()) {
        await Get.find<AuthService>().forceLogoutToLogin(
          message: data['message']?.toString() ??
              'Your account was signed in on another device. Please log in again.',
        );
      } else {
        Get.offAllNamed('/login');
      }
    } catch (e) {
      debugPrint('❌ Error handling force_logout: $e');
      Get.offAllNamed('/login');
    }
  }

  /// Listen to CallKit (flutter_callkit_incoming) events for accept/decline/timeout
  void _setupCallKitListener() {
    FlutterCallkitIncoming.onEvent.listen((event) {
      if (event == null) return;
      _handleCallKitEvent(event);
    });
  }

  /// Handle CallKit events (Accept/Decline/Timeout)
  void _handleCallKitEvent(CallEvent event) {
    debugPrint('📱 CallKit event: ${event.event}');
    debugPrint('📱 CallKit body: ${event.body}');

    final body = event.body;
    if (body == null || body is! Map<String, dynamic>) return;

    // NOTE: body['extra'] arrives as a raw platform-channel map
    // (Map<Object?, Object?> on Android), not Map<String, dynamic> —
    // Map<String, dynamic>.from(...) only shallow-converts the top level.
    // An unsafe `as Map<String, dynamic>?` cast here throws at runtime and
    // silently breaks the whole Accept/Decline handler.
    final rawExtra = body['extra'];
    final extra = rawExtra is Map ? Map<String, dynamic>.from(rawExtra) : null;
    final callId =
        body['id']?.toString() ?? extra?['call_id']?.toString() ?? '';
    final data = extra ?? <String, dynamic>{'call_id': callId};

    switch (event.event) {
      case Event.actionCallAccept:
        debugPrint('✅ CallKit: Accept tapped for call $callId');
        if (callId.isNotEmpty) {
          _clearPendingCall(callId);
        }
        _acceptCallFromCallKit(data);
        break;

      case Event.actionCallDecline:
        debugPrint('❌ CallKit: Decline tapped for call $callId');
        if (callId.isNotEmpty) {
          _clearPendingCall(callId);
          _rejectCallFromNotification(callId);
        }
        break;

      case Event.actionCallTimeout:
        debugPrint('⏰ CallKit: Call $callId timed out (missed)');
        if (callId.isNotEmpty) {
          _clearPendingCall(callId);
        }
        break;

      case Event.actionCallEnded:
        debugPrint('📞 CallKit: Call $callId ended');
        if (callId.isNotEmpty) {
          _clearPendingCall(callId);
        }
        break;

      default:
        debugPrint('📱 CallKit: Unhandled event ${event.event}');
    }
  }
}

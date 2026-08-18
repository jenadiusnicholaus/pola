import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/navigation_helper.dart';
import '../../../services/token_storage_service.dart';
import '../models/consultant_models.dart';
import '../services/call_service.dart';
import '../services/nexacon_call_service.dart';

class CallController extends GetxController {
  final CallService _callService = CallService();
  final NexaconCallService _nexaconService = Get.find<NexaconCallService>();
  final TokenStorageService _tokenStorage = Get.find<TokenStorageService>();

  // Observable state
  var isCheckingCredits = false.obs;
  var isRinging =
      false.obs; // Track if call is ringing (waiting for consultant to accept)
  var isCallConnected = false.obs;
  var isConsultantConnected = false.obs; // NEW: Track if consultant joined
  var error = ''.obs;
  var callDuration = '00:00'.obs;
  var creditsRemaining = 0.obs;
  var isMuted = false.obs;
  var isSpeakerOn = false.obs;
  final List<CreditBundle> _availableBundles = [];
  var showBundlesDialog = false.obs;
  var selectedBundleId = Rxn<int>();

  Consultant? _currentConsultant;
  bool _isEndingCall = false; // Prevent multiple simultaneous endCall() calls
  bool _isEndCallScheduled =
      false; // Prevent multiple scheduled endCall() calls

  // Getters
  List<CreditBundle> get availableBundles => _availableBundles;

  /// Get user's phone number for Nexacon authentication
  String? _getUserPhoneNumber() {
    // Try to get from user data
    final userData = _tokenStorage.userData;
    if (userData != null) {
      // Check for phone_number in contact or directly in user data
      final contact = userData['contact'] as Map<String, dynamic>?;
      String? phone;
      if (contact != null) {
        phone = contact['phone_number'] as String?;
      }
      // Try direct phone_number field
      phone ??= userData['phone_number'] as String?;

      // Format phone number with country code if missing
      if (phone != null && phone.isNotEmpty) {
        return _formatPhoneNumberWithCountryCode(phone);
      }
    }
    return null;
  }

  /// Format phone number with Tanzania country code if missing
  String _formatPhoneNumberWithCountryCode(String phone) {
    // Remove any non-digit characters
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');

    // If already has country code (starts with 255), return as is
    if (digits.startsWith('255')) {
      return '+$digits';
    }

    // If starts with 0, replace with +255
    if (digits.startsWith('0')) {
      return '+255${digits.substring(1)}';
    }

    // If 10 digits (Tanzania format without 0), add +255
    if (digits.length == 10) {
      return '+255$digits';
    }

    // Default: add +255 prefix
    return '+255$digits';
  }

  // Check if current error is related to insufficient credits
  bool get isInsufficientCreditsError {
    return availableBundles.length > 0 ||
        error.value.toLowerCase().contains('credit') ||
        error.value.toLowerCase().contains('insufficient');
  }

  void selectBundle(int bundleId) {
    selectedBundleId.value = bundleId;
  }

  CreditBundle? get selectedBundle {
    if (selectedBundleId.value == null) return null;
    try {
      for (int i = 0; i < _availableBundles.length; i++) {
        if (_availableBundles[i].id == selectedBundleId.value) {
          return _availableBundles[i];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _setupCallbacks();
  }

  void _resetCallState() {
    _isEndingCall = false;
    _isEndCallScheduled = false;
    isConsultantConnected.value = false;
    isCallConnected.value = false;
    isRinging.value = false;
    callDuration.value = '00:00';
  }

  void _setupCallbacks() {
    // Duration update callback
    _nexaconService.onDurationUpdate = (duration) {
      callDuration.value = duration;
    };

    // Call ended callback
    _nexaconService.onCallEnded = (durationSeconds) {
      _handleCallEnded(durationSeconds);
    };

    // Other user joined callback
    _nexaconService.onOtherUserJoined = () {
      print('✅ Other user joined the call, timer started');
      isConsultantConnected.value = true;
      isRinging.value = false; // Stop ringing when consultant joins
    };

    // Other user left callback - end call when other party disconnects
    _nexaconService.onOtherUserLeft = () {
      print('🚪 ❗ OTHER USER LEFT - Triggering endCall IMMEDIATELY');
      print(
          '🚪 isCallConnected: ${isCallConnected.value}, isConsultantConnected: ${isConsultantConnected.value}');
      print('🚪 isRinging: ${isRinging.value}, _isEndingCall: $_isEndingCall');

      // Only end call if the WebRTC peer actually joined (isConsultantConnected = true)
      // isCallConnected is set too early (at call initiation), so we cannot rely on it here
      if (!isConsultantConnected.value) {
        print(
            '⚠️ OTHER USER LEFT but peer never joined via WebRTC - ignoring to prevent premature end');
        return;
      }

      // Prevent multiple scheduled endCall calls
      if (_isEndCallScheduled) {
        print('⚠️ endCall already scheduled, skipping duplicate');
        return;
      }
      _isEndCallScheduled = true;
      // Small delay to ensure Nexacon state is updated
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_isEndingCall) {
          print('🚪 Executing endCall() after other user left');
          endCall();
        } else {
          print('⚠️ endCall already in progress, skipping');
        }
        _isEndCallScheduled = false;
      });
    };

    // Incoming call callback - only used on the consultant/callee side
    // Do NOT set isConsultantConnected here — that is driven by onOtherUserJoined
    _nexaconService.onIncomingCall = (callerName) {
      print('📞 Incoming call signal received from: $callerName');
    };

    // Error callback
    _nexaconService.onError = (errorMessage) {
      error.value = errorMessage;
      if (Get.isRegistered<CallController>()) {
        Get.back();
        Future.delayed(const Duration(milliseconds: 300), () {
          NavigationHelper.showSafeSnackbar(
            title: 'Error',
            message: errorMessage.isNotEmpty
                ? errorMessage
                : 'An error occurred during the call',
            backgroundColor: Colors.red.shade700,
          );
        });
      }
    };
  }

  /// Join an incoming call (when accepting)
  Future<void> joinIncomingCall({
    required String callId,
    required String channelName,
    required String callerName,
    String callerPhone = '',
  }) async {
    _resetCallState();
    error.value = '';
    isCheckingCredits.value = true;

    try {
      debugPrint('📞 Joining incoming call: $callId');
      debugPrint('📡 Channel: $channelName');

      // Set call ID for duration recording
      try {
        final callIdInt = int.parse(callId);
        _nexaconService.setCallId(callIdInt);
        debugPrint('📞 Call ID set for incoming call: $callIdInt');
      } catch (e) {
        debugPrint('⚠️ Could not parse call ID: $callId');
      }

      // Setup callbacks for duration updates and call events
      _setupCallbacks();

      // Get user's phone number for Nexacon authentication
      final phoneNumber = _getUserPhoneNumber();
      if (phoneNumber == null || phoneNumber.isEmpty) {
        debugPrint('❌ No phone number found for user');
        error.value = 'Phone number required for calls';
        isCheckingCredits.value = false;
        NavigationHelper.showSafeSnackbar(
          title: 'Error',
          message: 'Phone number is required to make calls',
          backgroundColor: Colors.red,
        );
        return;
      }

      // Check/Request permissions
      final hasPermission = await _nexaconService.requestPermissions();
      if (!hasPermission) {
        debugPrint('⚠️ Microphone permission not granted');
      }

      isCheckingCredits.value = false;

      // Format phone number with country code for NX ID compatibility
      final formattedPhone = _formatPhoneNumberWithCountryCode(phoneNumber);
      debugPrint(
        '📞 Joining incoming call with formatted phone: $formattedPhone (original: $phoneNumber)',
      );

      // Initialize SDK and accept the incoming call
      await _nexaconService.acceptIncomingCall(
        phoneNumber: formattedPhone,
        channelName: channelName,
        callerPhone: callerPhone,
        name: 'User',
      );

      isCallConnected.value = true;

      debugPrint('✅ Successfully joined incoming call');
    } catch (e) {
      debugPrint('❌ Error joining incoming call: $e');
      isCheckingCredits.value = false;
      NavigationHelper.showSafeSnackbar(
        title: 'Error',
        message: 'Could not join call. Please try again.',
        backgroundColor: Colors.red,
      );
      Get.back();
    }
  }

  Future<void> initiateCall(Consultant consultant) async {
    _resetCallState();
    _currentConsultant = consultant;
    error.value = '';
    isCheckingCredits.value = true;

    try {
      // Step 0: Check microphone permission first
      print('🎤 Checking microphone permission...');
      final hasPermission = await _nexaconService.requestPermissions();
      if (!hasPermission) {
        print('❌ Microphone permission denied');
        isCheckingCredits.value = false;
        NavigationHelper.showSafeSnackbar(
          title: 'Permission Denied',
          message: 'Microphone permission is required for voice calls',
          backgroundColor: Colors.red,
        );
        return;
      }
      print('✅ Microphone permission granted');

      // Step 0.5: Pre-warm NX connection for outgoing call
      final phoneNumber = _getUserPhoneNumber();
      if (phoneNumber == null || phoneNumber.isEmpty) {
        debugPrint('❌ No phone number found for user');
        isCheckingCredits.value = false;
        NavigationHelper.showSafeSnackbar(
          title: 'Error',
          message: 'Phone number is required to make calls',
          backgroundColor: Colors.red,
        );
        return;
      }

      final formattedCallerPhone = _formatPhoneNumberWithCountryCode(
        phoneNumber,
      );
      debugPrint('🔥 Pre-warming XMPP connection for outgoing call...');
      await _nexaconService.prewarmForOutgoing(
        phoneNumber: formattedCallerPhone,
        name: 'User',
      );

      // Step 1: Check if user has credits
      print('💳 ====== INITIATING CALL ======');
      print('💳 Consultant ID (profile): ${consultant.id}');
      print('💳 Consultant name: ${consultant.userDetails.fullName}');
      print('💳 Consultant user ID: ${consultant.userDetails.id}');

      final creditCheck = await _callService.checkCredits(consultant.id);

      print('💳 Credit check result:');
      print('   hasCredits: ${creditCheck.hasCredits}');
      print('   availableMinutes: ${creditCheck.availableMinutes}');
      print(
        '   availableBundles count: ${creditCheck.availableBundles.length}',
      );
      print('   message: ${creditCheck.message}');

      if (!creditCheck.hasCredits && creditCheck.activeCreditsCount == 0) {
        // Store available bundles for display
        _availableBundles.clear();
        _availableBundles.addAll(creditCheck.availableBundles);
        print('📦 Stored ${availableBundles.length} bundles for display');

        error.value = creditCheck.message.isNotEmpty
            ? creditCheck.message
            : 'You don\'t have enough credits to make this call.';
        showBundlesDialog.value = creditCheck.availableBundles.isNotEmpty;
        isCheckingCredits.value = false;
        return;
      }

      creditsRemaining.value = creditCheck.availableMinutes;
      print('Credits available: ${creditCheck.availableMinutes} minutes');

      // Step 2: Notify backend to send FCM to consultant
      print('📞 Notifying backend to send FCM notification...');
      final initiateResult = await _callService.initiateCall(
        consultantId: consultant.id,
        callType: 'voice',
      );

      if (!initiateResult['success']) {
        print('❌ Failed to initiate call: ${initiateResult['error']}');
        isCheckingCredits.value = false;
        error.value = initiateResult['error'] ?? 'Failed to initiate call';
        NavigationHelper.showSafeSnackbar(
          title: 'Error',
          message: initiateResult['error'] ?? 'Failed to initiate call',
          backgroundColor: Colors.red,
        );
        // Delay before going back to avoid snackbar controller issues
        await Future.delayed(const Duration(milliseconds: 100));
        if (Get.isSnackbarOpen) {
          Get.closeCurrentSnackbar();
        }
        Get.back();
        return;
      }

      print('✅ Backend notified, FCM sent to consultant');
      print('📡 Channel: ${initiateResult['channel_name']}');

      // Set call ID for backend recording
      _nexaconService.setCallId(initiateResult['call_id']);

      // Mark as ringing - waiting for consultant to accept
      isRinging.value = true;
      isCheckingCredits.value = false;

      // Fetch consultant's actual registered phone number from backend
      String? consultantPhone;
      try {
        final consultantDetails =
            await _callService.getConsultantDetails(consultant.id);
        consultantPhone = consultantDetails.userDetails.phoneNumber;
        print('📱 Fetched consultant phone from backend: $consultantPhone');
      } catch (e) {
        print('⚠️ Failed to fetch consultant details: $e');
        // Fallback to profile phone number
        consultantPhone = consultant.userDetails.phoneNumber;
      }

      if (consultantPhone == null || consultantPhone.isEmpty) {
        debugPrint(
          '❌ Consultant has no phone number — cannot route Nexacon call',
        );
        isCheckingCredits.value = false;
        NavigationHelper.showSafeSnackbar(
          title: 'Error',
          message: 'Unable to connect call. Consultant contact not available.',
          backgroundColor: Colors.red,
        );
        return;
      }

      // Format consultant phone number with country code for NX ID compatibility
      final formattedConsultantPhone = _formatPhoneNumberWithCountryCode(
        consultantPhone,
      );

      debugPrint('📞 Initiating Nexacon call:');
      debugPrint(
        '   From (username): $formattedCallerPhone (original: $phoneNumber)',
      );
      debugPrint(
        '   To (consultant): $formattedConsultantPhone (original: $consultantPhone)',
      );

      // Initiate Nexacon call using backend channel_name so both sides share the same room
      await _nexaconService.initiateCall(
        username: formattedCallerPhone,
        to: formattedConsultantPhone,
        name: 'User',
        roomId: initiateResult['channel_name'] as String?,
      );

      isCallConnected.value = true;
      isCheckingCredits.value = false;

      print('✅ Call initiated — waiting for consultant to join...');
    } catch (e) {
      print('Error initiating call: $e');
      isCheckingCredits.value = false;
      // Show toast for unexpected errors
      NavigationHelper.showSafeSnackbar(
        title: 'Error',
        message: 'An unexpected error occurred. Please try again.',
        backgroundColor: Colors.red,
      );
      Get.back();
    }
  }

  Future<void> endCall() async {
    // Prevent multiple simultaneous calls
    if (_isEndingCall) {
      print('⚠️ endCall() already in progress, ignoring duplicate call');
      return;
    }

    _isEndingCall = true;
    print('🔴 endCall() called');

    // IMMEDIATELY stop the timer as first action
    _nexaconService.stopDurationTimer();
    print('⏱️ Timer stopped immediately');

    // Check if the call was actually connected (consultant joined)
    final wasConnected = isConsultantConnected.value;
    final callId = _nexaconService.callId;
    print('📞 Was consultant connected: $wasConnected, Call ID: $callId');

    Map<String, dynamic>? callSummary;

    try {
      // Leave the call
      await _nexaconService.leaveRoom();

      // Notify backend based on call state
      if (callId != null) {
        if (wasConnected) {
          // Call was connected - use endCall to record duration
          print('📞 Call was connected, recording duration...');
          callSummary = await _nexaconService.endCall(recordCall: true);
        } else {
          // Call was not answered - try to cancel it so callee gets notified
          print('📵 Call was not answered, attempting to cancel...');
          final cancelResult =
              await _callService.cancelCall(callId: callId.toString());

          if (cancelResult['success'] == true) {
            // Clear call ID since we cancelled
            _nexaconService.clearCallId();
          } else if (cancelResult['is_ended'] == true) {
            // Call is already completed — just clear state, nothing to record
            print('⚠️ Call already completed, skipping API call');
            _nexaconService.clearCallId();
          } else if (cancelResult['is_active'] == true) {
            // Call is active — must use endCall to record duration
            print('⚠️ Call is active, using endCall to record duration...');
            callSummary = await _nexaconService.endCall(recordCall: true);
          } else {
            // Other error - still try to end call
            print('⚠️ Cancel failed with error: ${cancelResult['message']}');
            print('📞 Attempting endCall as fallback...');
            callSummary = await _nexaconService.endCall(recordCall: true);
          }
        }
      } else {
        print('⚠️ No call ID available');
      }

      // Navigate back after call ends
      print('🔙 Attempting to navigate back...');

      bool navigationSuccess = false;

      // For incoming calls (callee), the navigation stack may be empty if the
      // app was cold-started from an FCM notification. Always navigate to /home
      // to avoid a black screen when there is nothing to pop back to.
      final isIncomingCall = _currentConsultant == null;

      if (isIncomingCall) {
        try {
          Get.offAllNamed('/home');
          navigationSuccess = true;
          print('✅ Navigation successful via Get.offAllNamed /home (incoming)');
        } catch (e) {
          print('⚠️ Get.offAllNamed /home failed: $e');
        }
      } else {
        // Outgoing call — pop back to where we came from
        if (Get.context != null) {
          try {
            Navigator.of(Get.context!).pop();
            navigationSuccess = true;
            print('✅ Navigation successful via Navigator.pop()');
          } catch (e) {
            print('⚠️ Navigator.pop() failed: $e');
          }
        }

        if (!navigationSuccess) {
          try {
            Get.back();
            navigationSuccess = true;
            print('✅ Navigation successful via Get.back()');
          } catch (e) {
            print('⚠️ Get.back() failed: $e');
          }
        }

        if (!navigationSuccess) {
          try {
            Get.offAllNamed('/consultants');
            navigationSuccess = true;
            print('✅ Navigation successful via Get.offAllNamed /consultants');
          } catch (e) {
            print('⚠️ Get.offAllNamed failed: $e');
          }
        }
      }

      if (!navigationSuccess) {
        print('❌ All navigation methods failed');
      }

      // Show call summary dialog ONLY on caller side (when we have call summary)
      if (navigationSuccess &&
          _currentConsultant != null &&
          callSummary != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _showCallSummaryDialog(callSummary!);
        });
      }
    } catch (e) {
      print('❌ Error ending call: $e');
      // ALWAYS try to navigate back, even on error
      try {
        if (Get.context != null) {
          Navigator.of(Get.context!).pop();
          print('✅ Emergency navigation successful');
        }
      } catch (navError) {
        print('❌ Emergency navigation failed: $navError');
      }
    } finally {
      // Reset flag after a delay to allow for cleanup
      Future.delayed(const Duration(milliseconds: 500), () {
        _isEndingCall = false;
      });
    }
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
    _nexaconService.toggleMute();
  }

  void toggleSpeaker() {
    isSpeakerOn.value = !isSpeakerOn.value;
    _nexaconService.toggleSpeaker();
  }

  void _handleCallEnded(int durationSeconds) {
    print('Call ended. Duration: $durationSeconds seconds');

    // Navigate back
    if (Get.isRegistered<CallController>()) {
      Get.back();

      // Show summary after navigation
      final minutes = (durationSeconds / 60).ceil();
      Future.delayed(const Duration(milliseconds: 300), () {
        NavigationHelper.showSafeSnackbar(
          title: 'Call Completed',
          message:
              'Call duration: ${callDuration.value}\nCredits used: $minutes minute(s)',
          duration: const Duration(seconds: 4),
        );
      });
    }
  }

  /// Show call summary dialog with duration and remaining credits
  void _showCallSummaryDialog(Map<String, dynamic> callSummary) {
    final summary = callSummary['call_summary'];
    if (summary == null) return;

    final durationMinutes = summary['duration_minutes'] ?? 0.0;
    final creditsDeducted = summary['credits_deducted'] ?? 0.0;
    final creditsRemaining = summary['credits_remaining'] ?? 0.0;
    final durationSeconds = summary['duration_seconds'] ?? 0;

    // Format duration
    final minutes = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    final formattedDuration = '$minutes:$seconds';

    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.call_end, color: Colors.orange),
            SizedBox(width: 8),
            Text('Call Ended'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Call Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
              icon: Icons.timer,
              label: 'Duration',
              value: formattedDuration,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              icon: Icons.remove_circle_outline,
              label: 'Minutes Used',
              value: '${creditsDeducted.toStringAsFixed(1)} min',
              valueColor: Colors.red,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              icon: Icons.account_balance_wallet,
              label: 'Remaining Credits',
              value: '${creditsRemaining.toStringAsFixed(1)} min',
              valueColor: Colors.green,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  void onClose() {
    // Clean up: stop timer and leave call
    // Only cleanup if not already in progress
    if (!_isEndingCall) {
      _nexaconService.stopDurationTimer();
      _nexaconService.leaveRoom();
    }
    // Note: We don't dispose the service - it should persist across calls
    super.onClose();
  }
}

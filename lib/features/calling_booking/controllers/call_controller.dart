import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/consultant_models.dart';
import '../services/call_service.dart';
import '../services/zego_call_service.dart';

class CallController extends GetxController {
  final CallService _callService = CallService();
  final ZegoCallService _zegoService = ZegoCallService();

  // Observable state
  var isCheckingCredits = false.obs;
  var isCallConnected = false.obs;
  var isConsultantConnected = false.obs; // NEW: Track if consultant joined
  var error = ''.obs;
  var callDuration = '00:00'.obs;
  var creditsRemaining = 0.obs;
  var isMuted = false.obs;
  var isSpeakerOn = false.obs;
  var availableBundles = <CreditBundle>[].obs;
  var showBundlesDialog = false.obs;
  var selectedBundleId = Rxn<int>();

  Consultant? _currentConsultant;
  bool _isEndingCall = false; // Prevent multiple simultaneous endCall() calls

  // Check if current error is related to insufficient credits
  bool get isInsufficientCreditsError {
    return availableBundles.isNotEmpty ||
        error.value.toLowerCase().contains('credit') ||
        error.value.toLowerCase().contains('insufficient');
  }

  void selectBundle(int bundleId) {
    selectedBundleId.value = bundleId;
  }

  CreditBundle? get selectedBundle {
    if (selectedBundleId.value == null) return null;
    try {
      return availableBundles.firstWhere((b) => b.id == selectedBundleId.value);
    } catch (e) {
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _setupCallbacks();
  }

  void _setupCallbacks() {
    // Duration update callback
    _zegoService.onDurationUpdate = (duration) {
      callDuration.value = duration;
    };

    // Call ended callback
    _zegoService.onCallEnded = (durationSeconds) {
      _handleCallEnded(durationSeconds);
    };

    // Other user joined callback
    _zegoService.onOtherUserJoined = () {
      print('✅ Other user joined the call, timer started');
      isConsultantConnected.value = true;
    };

    // Other user left callback - end call when other party disconnects
    _zegoService.onOtherUserLeft = () {
      print('🚪 ❗ OTHER USER LEFT - Triggering endCall IMMEDIATELY');
      // Small delay to ensure ZegoCloud state is updated
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_isEndingCall) {
          print('🚪 Executing endCall() after other user left');
          endCall();
        } else {
          print('⚠️ endCall already in progress, skipping');
        }
      });
    };

    // Error callback
    _zegoService.onError = (errorMessage) {
      error.value = errorMessage;
      if (Get.isRegistered<CallController>()) {
        Get.back();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (Get.context != null) {
            ScaffoldMessenger.of(Get.context!).showSnackBar(
              SnackBar(
                content: Text(
                  errorMessage.isNotEmpty
                      ? errorMessage
                      : 'An error occurred during the call',
                ),
                backgroundColor: Colors.red.shade700,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      }
    };
  }

  /// Join an incoming call (when accepting)
  Future<void> joinIncomingCall({
    required String callId,
    required String channelName,
    required String callerName,
  }) async {
    error.value = '';
    isCheckingCredits.value = true;

    try {
      debugPrint('📞 Joining incoming call: $callId');
      debugPrint('📡 Channel: $channelName');

      // Initialize ZegoExpressEngine first
      // TODO: Get actual user info from auth service
      final userId = callId;
      final userName = 'User';
      await _zegoService.initializeZego(userId, userName);

      // Check/Request permissions
      final hasPermission = await _zegoService.requestPermissions();
      if (!hasPermission) {
        debugPrint('⚠️ Microphone permission not granted');
      }

      isCheckingCredits.value = false;

      // Join the Zego room
      await _zegoService.joinRoom(channelName, userId, userName);

      isCallConnected.value = true;
      // Note: isConsultantConnected will be set by onOtherUserJoined callback

      debugPrint(
          '✅ Successfully joined incoming call, waiting for other user...');
    } catch (e) {
      debugPrint('❌ Error joining incoming call: $e');
      isCheckingCredits.value = false;
      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          const SnackBar(
            content: Text('Could not join call. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      Get.back();
    }
  }

  Future<void> initiateCall(Consultant consultant) async {
    _currentConsultant = consultant;
    error.value = '';
    isCheckingCredits.value = true;

    try {
      // Step 1: Check if user has credits
      print('Checking credits for consultant: ${consultant.id}');
      final creditCheck = await _callService.checkCredits(consultant.id);

      if (!creditCheck.hasCredits) {
        // Store available bundles for display
        availableBundles.value = creditCheck.availableBundles;
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
        if (Get.context != null) {
          ScaffoldMessenger.of(Get.context!).showSnackBar(
            SnackBar(
              content:
                  Text(initiateResult['error'] ?? 'Failed to initiate call'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        Get.back();
        return;
      }

      print('✅ Backend notified, FCM sent to consultant');
      print('📡 Channel: ${initiateResult['channel_name']}');

      // Microphone permission should already be granted from ConsultantsScreen
      // Just verify it's still granted
      final hasPermission = await _zegoService.requestPermissions();
      if (!hasPermission) {
        print('❌ Microphone permission denied');
        isCheckingCredits.value = false;
        if (Get.context != null) {
          ScaffoldMessenger.of(Get.context!).showSnackBar(
            const SnackBar(
              content:
                  Text('Microphone permission is required for voice calls'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        Get.back();
        return;
      }

      // Initialize ZegoExpressEngine
      // TODO: Get actual user info from auth service
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final userName = 'User';
      await _zegoService.initializeZego(userId, userName);

      // Set call ID for call recording
      _zegoService.setCallId(initiateResult['call_id']);

      // Join the Zego room
      await _zegoService.joinRoom(
        initiateResult['channel_name'],
        userId,
        userName,
      );

      isCallConnected.value = true;
      // Note: isConsultantConnected will be set when consultant joins (onOtherUserJoined callback)
      isCheckingCredits.value = false;

      print(
          '✅ Call initiated and room joined - waiting for consultant to join...');
    } catch (e) {
      print('Error initiating call: $e');
      isCheckingCredits.value = false;
      // Show toast for unexpected errors
      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
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
    _zegoService.stopDurationTimer();
    print('⏱️ Timer stopped immediately');

    Map<String, dynamic>? callSummary;

    try {
      // Leave the room
      await _zegoService.leaveRoom();

      // Always call endCall on the service to stop timer and optionally record
      // The service will handle recording only if call ID is set (caller side)
      callSummary = await _zegoService.endCall(recordCall: true);

      // Navigate back immediately - try multiple methods to ensure it works
      print('🔙 Attempting to navigate back...');

      bool navigationSuccess = false;

      // Method 1: Direct Navigator pop (most reliable)
      if (Get.context != null) {
        try {
          Navigator.of(Get.context!).pop();
          navigationSuccess = true;
          print('✅ Navigation successful via Navigator.pop()');
        } catch (e) {
          print('⚠️ Navigator.pop() failed: $e');
        }
      }

      // Method 2: Try GetX navigation if first method failed
      if (!navigationSuccess && Get.isRegistered<CallController>()) {
        try {
          Get.back();
          navigationSuccess = true;
          print('✅ Navigation successful via Get.back()');
        } catch (e) {
          print('⚠️ Get.back() failed: $e');
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

  void _handleCallEnded(int durationSeconds) {
    print('Call ended. Duration: $durationSeconds seconds');

    // Navigate back
    if (Get.isRegistered<CallController>()) {
      Get.back();

      // Show summary after navigation
      final minutes = (durationSeconds / 60).ceil();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (Get.context != null) {
          Get.snackbar(
            'Call Completed',
            'Call duration: ${callDuration.value}\nCredits used: $minutes minute(s)',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4),
          );
        }
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
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
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
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
    // Clean up: stop timer and leave room
    _zegoService.stopDurationTimer();
    _zegoService.leaveRoom();
    // Note: We don't destroy the engine - it should persist across calls
    super.onClose();
  }
}

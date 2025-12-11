import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/consultant_models.dart';
import '../services/call_service.dart';
import '../services/agora_call_service.dart';

class CallController extends GetxController {
  final CallService _callService = CallService();
  final AgoraCallService _agoraService = AgoraCallService();

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
  DateTime? _callStartTime; // Track when both parties connected

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
    _agoraService.onDurationUpdate = (duration) {
      callDuration.value = duration;
    };

    // Call ended callback
    _agoraService.onCallEnded = (durationSeconds) {
      _handleCallEnded(durationSeconds);
    };

    // Error callback
    _agoraService.onError = (errorMessage) {
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

    // Join channel callback
    _agoraService.onJoinChannel = () {
      isCallConnected.value = true;
      print('Successfully joined call channel');
    };

    // Consultant joined callback
    _agoraService.onConsultantJoined = () {
      print('👤 Consultant has joined the call');
      isConsultantConnected.value = true;
      _callStartTime = DateTime.now();
      // TODO: Start call recording here once recording is implemented
      print('📞 Both parties connected - ready to record');
    };

    // Consultant left callback
    _agoraService.onConsultantLeft = () {
      print('Consultant has left the call');
      // Auto end call when consultant leaves
      Future.delayed(const Duration(milliseconds: 500), () {
        if (Get.isRegistered<CallController>()) {
          endCall();
        }
      });
    };
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

      // Step 2: Initialize Agora (non-blocking)
      print('Initializing Agora...');
      try {
        await _agoraService.initializeAgora();
      } catch (agoraError) {
        print('Agora initialization failed: $agoraError');
        isCheckingCredits.value = false;
        // Show toast instead of blocking UI
        if (Get.context != null) {
          ScaffoldMessenger.of(Get.context!).showSnackBar(
            const SnackBar(
              content: Text('Failed to initialize call. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        Get.back();
        return;
      }

      // Step 3: Check/Request permissions (non-blocking)
      print('Checking microphone permission...');
      final hasPermission = await _agoraService.requestPermissions();
      if (!hasPermission) {
        print(
            '⚠️ Permission not granted, but continuing - Agora will request it');
        // Don't block - Agora SDK will request permission when joining channel
      }

      // Step 4: Join call channel (Agora will request permission if needed)
      print('Joining call channel...');
      try {
        await _agoraService.joinChannel(consultant.id);
      } catch (joinError) {
        print('Failed to join channel: $joinError');
        if (Get.context != null) {
          ScaffoldMessenger.of(Get.context!).showSnackBar(
            const SnackBar(
              content: Text('Could not connect to call. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        Get.back();
        return;
      }

      isCheckingCredits.value = false;
      print('Call initiated successfully');
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

  void toggleMute() {
    _agoraService.toggleMute();
    isMuted.value = _agoraService.isMuted;
  }

  void toggleSpeaker() {
    _agoraService.toggleSpeaker();
    isSpeakerOn.value = _agoraService.isSpeakerOn;
  }

  Future<void> endCall() async {
    if (_currentConsultant == null) {
      Get.back();
      return;
    }

    try {
      // End call with recording
      await _agoraService.endCall(recordCall: true);

      // Navigate back
      if (Get.isRegistered<CallController>()) {
        Get.back();

        // Show completion message after navigation
        Future.delayed(const Duration(milliseconds: 300), () {
          if (Get.context != null) {
            Get.snackbar(
              'Call Ended',
              'Your call has been recorded and credits have been deducted.',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 3),
            );
          }
        });
      }
    } catch (e) {
      print('Error ending call: $e');
      if (Get.isRegistered<CallController>()) {
        Get.back();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (Get.context != null) {
            Get.snackbar(
              'Error',
              'Failed to properly end call: ${e.toString()}',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 3),
            );
          }
        });
      }
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

  @override
  void onClose() {
    _agoraService.dispose();
    super.onClose();
  }
}

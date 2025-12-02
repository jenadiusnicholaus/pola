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
  var error = ''.obs;
  var callDuration = '00:00'.obs;
  var creditsRemaining = 0.obs;
  var isMuted = false.obs;
  var isSpeakerOn = false.obs;
  var availableBundles = <CreditBundle>[].obs;
  var showBundlesDialog = false.obs;

  Consultant? _currentConsultant;

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
      Get.back();
      Get.snackbar(
        'Call Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    };

    // Join channel callback
    _agoraService.onJoinChannel = () {
      isCallConnected.value = true;
      print('Successfully joined call channel');
    };

    // Consultant joined callback
    _agoraService.onConsultantJoined = () {
      print('Consultant has joined the call');
      Get.snackbar(
        'Connected',
        '${_currentConsultant?.userDetails.fullName ?? "Consultant"} has joined',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    };

    // Consultant left callback
    _agoraService.onConsultantLeft = () {
      print('Consultant has left the call');
      Get.snackbar(
        'Call Ended',
        'The consultant has left the call',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
      // Auto end call when consultant leaves
      Future.delayed(const Duration(seconds: 1), () {
        endCall();
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
        error.value = creditCheck.message ??
            'You don\'t have enough credits to make this call.';
        showBundlesDialog.value = creditCheck.availableBundles.isNotEmpty;
        isCheckingCredits.value = false;
        return;
      }

      creditsRemaining.value = creditCheck.availableMinutes;
      print('Credits available: ${creditCheck.availableMinutes} minutes');

      // Step 2: Initialize Agora
      print('Initializing Agora...');
      await _agoraService.initializeAgora();

      // Step 3: Request permissions
      print('Requesting microphone permission...');
      final hasPermission = await _agoraService.requestPermissions();
      if (!hasPermission) {
        error.value = 'Microphone permission is required to make calls.';
        isCheckingCredits.value = false;
        return;
      }

      // Step 4: Join call channel
      print('Joining call channel...');
      await _agoraService.joinChannel(consultant.id);

      isCheckingCredits.value = false;
      print('Call initiated successfully');
    } catch (e) {
      print('Error initiating call: $e');
      error.value = 'Failed to start call: ${e.toString()}';
      isCheckingCredits.value = false;
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
      Get.back();
      
      // Show completion message
      Get.snackbar(
        'Call Ended',
        'Your call has been recorded and credits have been deducted.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('Error ending call: $e');
      Get.back();
      Get.snackbar(
        'Error',
        'Failed to properly end call: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _handleCallEnded(int durationSeconds) {
    print('Call ended. Duration: $durationSeconds seconds');
    
    // Navigate back
    Get.back();
    
    // Show summary
    final minutes = (durationSeconds / 60).ceil();
    Get.snackbar(
      'Call Completed',
      'Call duration: ${callDuration.value}\nCredits used: $minutes minute(s)',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void onClose() {
    _agoraService.dispose();
    super.onClose();
  }
}

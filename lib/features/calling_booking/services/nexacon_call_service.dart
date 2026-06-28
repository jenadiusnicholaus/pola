import 'dart:async';
import 'package:nexacon_sdk/nexacon_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import '../../../config/nexacon_config.dart';
import 'call_service.dart';

class NexaconCallService extends GetxService {
  Timer? _durationTimer;
  int _callDuration = 0;
  int? _callId;
  bool _isTimerStarted = false;

  NexaconSDK? _sdk;
  Completer<void>? _incomingCallCompleter;

  // Callbacks
  Function(String duration)? onDurationUpdate;
  Function(int durationSeconds)? onCallEnded;
  Function(String error)? onError;
  Function()? onOtherUserJoined;
  Function()? onOtherUserLeft;
  Function(String callerName)? onIncomingCall;

  // State
  bool _isMuted = false;
  bool _isSpeakerOn = true;

  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  int get callDuration => _callDuration;
  int? get callId => _callId;

  /// Create and configure a NexaconSDK instance with all callbacks
  NexaconSDK _createSdk() {
    final sdk = NexaconSDK(
      apiKey: NexaconConfig.apiKey,
      secretKey: NexaconConfig.secretKey,
    );

    sdk.onCallStateChanged = (CallState state) {
      print('📱 Call state changed: $state');
      if (state == CallState.connected) {
        print('✅ Call connected, starting timer');
        if (!_isTimerStarted) {
          startDurationTimer();
          _isTimerStarted = true;
          onOtherUserJoined?.call();
        }
      } else if (state == CallState.ended) {
        print('📞 Call ended');
        onOtherUserLeft?.call();
      } else if (state == CallState.calling) {
        print('📞 Call is ringing...');
      } else if (state == CallState.idle) {
        print('📞 Call is idle');
      }
    };

    sdk.onIncomingCall = (callerName) {
      print('📞 Incoming call from: $callerName');
      // Trigger callback to notify UI of incoming call
      onIncomingCall?.call(callerName);
    };

    sdk.onCallEnded = (reason) {
      print('📞 Call ended: $reason');
      onOtherUserLeft?.call();
    };

    sdk.onError = (error) {
      print('❌ Nexacon error: $error');
      onError?.call('Nexacon error: $error');
    };

    sdk.onLocalStream = () => print('📹 Local stream received');
    sdk.onRemoteStream = () => print('📹 Remote stream received');

    return sdk;
  }

  /// Initiate an outgoing call
  Future<void> initiateCall({
    required String username,
    required String to,
    String? name,
  }) async {
    try {
      print('� Initiating call to: $to');
      // Use pre-warmed SDK if available, otherwise create new
      if (_sdk == null) {
        print("No pre-warmed SDK, creating new instance");
        _sdk = _createSdk();
      } else {
        print("Using pre-warmed SDK instance");
      }
      await _sdk!.startCall(
        to: to,
        username: username,
        name: name,
        audio: true,
        video: false,
      );
      print('✅ Call initiated — waiting for other user to accept...');
    } catch (e) {
      print('❌ Error initiating call: $e');
      rethrow;
    }
  }

  /// Pre-warm the NX connection as soon as the incoming call screen opens.
  /// This connects early so the call invitation is received before user taps Accept.
  /// Call this in the incoming call screen's initState(), not on Accept tap.
  Future<void> prewarmForIncoming({
    required String phoneNumber,
    String? name,
  }) async {
    try {
      print('🔥 Pre-warming NX connection for incoming call: $phoneNumber');
      _incomingCallCompleter = Completer<void>();
      _sdk = _createSdk();

      // Override onIncomingCall to signal when the invitation arrives
      _sdk!.onIncomingCall = (callerName) {
        print('📞 Pre-warm captured incoming call from: $callerName');
        onIncomingCall?.call(callerName);
        if (_incomingCallCompleter != null &&
            !_incomingCallCompleter!.isCompleted) {
          _incomingCallCompleter!.complete();
        }
      };

      // Connect first — then wait for the call invitation to arrive
      await _sdk!.initialize(username: phoneNumber, name: name);
      print(
          '✅ NX pre-warm connection established — waiting for call invitation...');

      await _incomingCallCompleter!.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⚠️ Pre-warm: timed out waiting for call invitation');
        },
      );
      print('✅ Incoming call invitation received');
    } catch (e) {
      print('⚠️ Pre-warm failed (non-fatal): $e');
      if (_incomingCallCompleter != null &&
          !_incomingCallCompleter!.isCompleted) {
        _incomingCallCompleter!.completeError(e);
      }
    }
  }

  /// Pre-warm the NX connection for outgoing calls.
  /// This ensures the connection is established before sending the call invitation.
  Future<void> prewarmForOutgoing({
    required String phoneNumber,
    String? name,
  }) async {
    try {
      print('🔥 Pre-warming NX connection for outgoing call: $phoneNumber');
      _sdk = _createSdk();
      await _sdk!.initialize(username: phoneNumber, name: name);
      print('✅ NX pre-warm complete — ready to initiate call');
    } catch (e) {
      print('⚠️ Pre-warm failed (non-fatal): $e');
      // Not fatal — initiateCall() will re-initialize if needed
    }
  }

  /// Accept an incoming call. Uses pre-warmed SDK if available,
  /// waits for the call invitation signal, then accepts.
  Future<void> acceptIncomingCall({
    required String phoneNumber,
    String? name,
    bool audio = true,
    bool video = false,
  }) async {
    try {
      if (_sdk != null && _incomingCallCompleter != null) {
        print('✅ Using pre-warmed SDK to accept call: $phoneNumber');

        // Wait up to 10s for call invitation to arrive if not yet received
        if (!_incomingCallCompleter!.isCompleted) {
          print('⏳ Waiting for call invitation signal...');
          await _incomingCallCompleter!.future.timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⚠️ Timed out waiting for call invitation signal');
            },
          );
        }

        try {
          await _sdk!.acceptCall(audio: audio, video: video);
          print('✅ Call accepted via pre-warmed SDK');
          return;
        } catch (e) {
          print(
            '⚠️ Direct accept failed ($e), falling back to acceptWhenReady...',
          );
        }
      }

      // Fallback: initialize fresh and wait for invitation
      print('✅ Waiting for incoming call signal (phone: $phoneNumber)...');
      _sdk = _createSdk();
      await _sdk!.acceptWhenReady(
        username: phoneNumber,
        name: name,
        audio: audio,
        video: video,
      );
      print('✅ Call accepted');
    } catch (e) {
      print('❌ Error accepting call: $e');
      rethrow;
    } finally {
      _incomingCallCompleter = null;
    }
  }

  /// End the current call (leaves the room)
  Future<void> leaveRoom() async {
    try {
      if (_sdk == null) {
        print('⚠️ No active call to leave');
        return;
      }
      print('🚪 Leaving call...');
      await _sdk!.endCall();
      _isTimerStarted = false;
      print('✅ Left call successfully');
    } catch (e) {
      print('❌ Error leaving call: $e');
    }
  }

  /// Toggle microphone mute
  Future<void> toggleMute() async {
    try {
      _isMuted = !_isMuted;
      _sdk?.toggleMute(_isMuted);
      print('🎤 Microphone ${_isMuted ? "muted" : "unmuted"}');
    } catch (e) {
      print('⚠️ Cannot toggle mute: $e');
    }
  }

  /// Toggle speaker
  Future<void> toggleSpeaker() async {
    try {
      _isSpeakerOn = !_isSpeakerOn;
      _sdk?.toggleSpeaker(_isSpeakerOn);
      print('🔊 Speaker: ${_isSpeakerOn ? "on" : "off"}');
    } catch (e) {
      print('⚠️ Cannot toggle speaker: $e');
    }
  }

  /// Start call duration timer
  void startDurationTimer() {
    if (_durationTimer != null) {
      stopDurationTimer();
    }
    _callDuration = 0;
    print('⏱️ Starting call duration timer');
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDuration++;
      onDurationUpdate?.call(getFormattedDuration());
    });
  }

  /// Stop call duration timer
  void stopDurationTimer() {
    if (_durationTimer != null) {
      _durationTimer!.cancel();
      _durationTimer = null;
      print('⏱️ Timer stopped');
    }
  }

  /// End the call and record duration to backend
  Future<Map<String, dynamic>?> endCall({bool recordCall = true}) async {
    try {
      print('🛑 Ending call...');
      stopDurationTimer();

      final finalDuration = _callDuration;
      final callId = _callId;

      print('📊 Final duration: $finalDuration seconds | Call ID: $callId');

      Map<String, dynamic>? callSummary;

      if (recordCall && callId != null && finalDuration > 0) {
        try {
          final result = await CallService().endCall(
            callId: callId.toString(),
            durationSeconds: finalDuration,
          );
          print('✅ Call recorded: $finalDuration seconds');
          callSummary = result;
        } catch (e) {
          print('❌ Error recording call: $e');
        }
      } else {
        if (callId == null) print('⚠️ No call ID — cannot record');
        if (finalDuration <= 0) print('⚠️ Duration is 0 — nothing to record');
      }

      _callDuration = 0;
      _callId = null;
      onCallEnded?.call(finalDuration);

      return callSummary;
    } catch (e) {
      print('❌ Error ending call: $e');
      onError?.call('Error ending call: ${e.toString()}');
      return null;
    }
  }

  /// Set call ID from backend
  void setCallId(int callId) {
    _callId = callId;
    print('📞 Call ID set: $callId');
  }

  /// Clear call ID (when call is cancelled before being answered)
  void clearCallId() {
    _callId = null;
    _callDuration = 0;
    print('📞 Call ID cleared');
  }

  /// Get formatted duration as MM:SS
  String getFormattedDuration() {
    final minutes = _callDuration ~/ 60;
    final seconds = _callDuration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Release all resources
  Future<void> dispose() async {
    try {
      stopDurationTimer();
      await leaveRoom();
      await _sdk?.dispose();
      _sdk = null;
      _callDuration = 0;
      _isMuted = false;
      _isSpeakerOn = true;
      _isTimerStarted = false;
      print('✅ Nexacon service disposed');
    } catch (e) {
      print('❌ Error disposing Nexacon service: $e');
    }
  }

  /// Request microphone permissions
  Future<bool> requestPermissions() async {
    try {
      print('🎤 Checking microphone permission...');
      var status = await Permission.microphone.status;

      if (status.isGranted) {
        print('✅ Microphone permission granted');
        return true;
      }

      if (status.isDenied) {
        status = await Permission.microphone.request();
      }

      if (status.isPermanentlyDenied) {
        print('❌ Microphone permanently denied — opening settings');
        onError?.call(
          'Microphone permission denied. Please enable it in app settings.',
        );
        await openAppSettings();
        return false;
      }

      return status.isGranted;
    } catch (e) {
      print('❌ Permission error: $e');
      onError?.call('Permission error: ${e.toString()}');
      return false;
    }
  }
}

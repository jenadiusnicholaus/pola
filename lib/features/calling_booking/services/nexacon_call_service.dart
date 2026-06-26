import 'dart:async';
import 'package:nexacon_sdk/nexacon_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import '../../../config/nexacon_config.dart';
import 'call_service.dart';

class NexaconCallService extends GetxService {
  Timer? _durationTimer;
  int _callDuration = 0; // in seconds
  int? _callId; // Backend call ID for recording
  String? _currentRoomId;
  NexaconClient? _client;
  CallManager? _callManager;

  // Callbacks
  Function(String duration)? onDurationUpdate;
  Function(int durationSeconds)? onCallEnded;
  Function(String error)? onError;
  Function()? onOtherUserJoined; // Called when the other person joins
  Function()? onOtherUserLeft; // Called when the other person disconnects

  // State
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isTimerStarted = false;

  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  int get callDuration => _callDuration;
  int? get callId => _callId; // Expose call ID for checking

  /// Initialize Nexacon SDK
  Future<void> initializeNexacon({
    required String nxid,
    required String nxtoken,
    required String wsUrl,
    String? name,
  }) async {
    try {
      final apiKey = NexaconConfig.apiKey;
      final secretKey = NexaconConfig.secretKey;

      print('🔑 Initializing Nexacon SDK');
      print('📝 NX ID: $nxid');
      print('� WS URL: $wsUrl');

      // Create NexaconClient instance
      _client = NexaconClient(
        apiKey: apiKey,
        secretKey: secretKey,
      );

      // Create CallManager with callbacks
      _callManager = await _client!.createCallManager(
        nxtoken: nxtoken,
        nxid: nxid,
        wsUrl: wsUrl,
        name: name,
        onCallStateChanged: (CallState state) {
          print('📱 Call state changed: $state');
          if (state == CallState.connected) {
            print('✅ Call connected, starting timer');
            if (!_isTimerStarted) {
              startDurationTimer();
              _isTimerStarted = true;
              onOtherUserJoined?.call();
            }
          } else if (state == CallState.ended) {
            print('� Call ended');
            onOtherUserLeft?.call();
          }
        },
        onIncomingCall: (callerName) {
          print('� Incoming call from: $callerName');
        },
        onCallEnded: (reason) {
          print('� Call ended: $reason');
          onOtherUserLeft?.call();
        },
        onError: (error) {
          print('❌ Nexacon error: $error');
          onError?.call('Nexacon error: $error');
        },
        onLocalStream: (stream) {
          print('📹 Local stream received');
        },
        onRemoteStream: (stream) {
          print('� Remote stream received');
        },
      );

      print('✅ Nexacon SDK initialized successfully');
    } catch (e) {
      print('❌ Nexacon initialization error: $e');
      onError?.call('Failed to initialize Nexacon: ${e.toString()}');
      rethrow;
    }
  }

  /// Join a call room (initiate outgoing call)
  Future<void> joinRoom(String roomId, String userId, String userName) async {
    try {
      _currentRoomId = roomId;

      print('🔑 Initiating call to room: $roomId as $userName ($userId)');

      if (_callManager == null) {
        throw Exception(
            'CallManager not initialized. Please call initializeNexacon() first.');
      }

      // Initiate P2P call
      await _callManager!.initiateCall(
        to: userId,
        audio: true,
        video: false, // Voice call only
      );

      print('✅ Call initiated');
      print('⏳ Waiting for other user to accept...');
    } catch (e) {
      print('❌ Error initiating call: $e');
      _currentRoomId = null;
      rethrow;
    }
  }

  /// Accept an incoming call
  Future<void> acceptCall({
    required String roomId,
    bool audio = true,
    bool video = false,
  }) async {
    try {
      _currentRoomId = roomId;

      print('✅ Accepting incoming call: $roomId');

      if (_callManager == null) {
        throw Exception(
            'CallManager not initialized. Please call initializeNexacon() first.');
      }

      await _callManager!.acceptCall(
        audio: audio,
        video: video,
      );

      print('✅ Call accepted');
    } catch (e) {
      print('❌ Error accepting call: $e');
      _currentRoomId = null;
      rethrow;
    }
  }

  /// Leave the current call room
  Future<void> leaveRoom() async {
    try {
      if (_currentRoomId == null) {
        print('⚠️ No active call to leave');
        return;
      }

      print('🚪 Leaving call...');

      if (_callManager != null) {
        await _callManager!.endCall();
      }

      _currentRoomId = null;
      _isTimerStarted = false;

      print('✅ Left call successfully');
    } catch (e) {
      print('❌ Error leaving call: $e');
      _currentRoomId = null;
    }
  }

  /// Toggle microphone mute
  Future<void> toggleMute() async {
    try {
      _isMuted = !_isMuted;
      if (_callManager != null) {
        _callManager!.toggleAudio(!_isMuted);
      }
      print('🎤 Microphone ${_isMuted ? "muted" : "unmuted"}');
    } catch (e) {
      print('⚠️ Cannot toggle mute: $e');
    }
  }

  /// Toggle speaker (audio routing)
  Future<void> toggleSpeaker() async {
    try {
      _isSpeakerOn = !_isSpeakerOn;
      // Note: Audio routing is handled by the system
      print('🔊 Speaker toggle: ${_isSpeakerOn ? "on" : "off"}');
    } catch (e) {
      print('⚠️ Cannot toggle speaker: $e');
    }
  }

  /// Start call duration timer
  void startDurationTimer() {
    if (_durationTimer != null) {
      print('⚠️ Timer already running, stopping previous timer');
      stopDurationTimer();
    }

    _callDuration = 0;
    print('⏱️ Starting call duration timer at 00:00');
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDuration++;
      final formatted = getFormattedDuration();
      print('⏱️ Timer tick: $formatted ($_callDuration seconds)');
      onDurationUpdate?.call(formatted);
    });
    print('✅ Call duration timer started successfully');
  }

  /// Stop call duration timer
  void stopDurationTimer() {
    if (_durationTimer != null) {
      _durationTimer!.cancel();
      _durationTimer = null;
      print('⏱️ ✅ Timer KILLED - stopped immediately');
    } else {
      print('⏱️ Timer already stopped or not started');
    }
  }

  /// End the call and record duration
  Future<Map<String, dynamic>?> endCall({bool recordCall = true}) async {
    try {
      print('🛑 Ending call...');
      stopDurationTimer();

      final finalDuration = _callDuration;
      final callId = _callId;

      print('📊 Final call duration: $finalDuration seconds');
      print('📞 Call ID: $callId');
      print('💾 Should record: $recordCall');

      Map<String, dynamic>? callSummary;

      // Record call if duration > 0 and recording is enabled
      if (recordCall && callId != null && finalDuration > 0) {
        try {
          print('📞 Ending call and recording to backend API...');
          final callService = CallService();
          final result = await callService.endCall(
            callId: callId.toString(), // Convert int to String
            durationSeconds: finalDuration,
          );
          print(
              '✅ Call ended and recorded successfully: $finalDuration seconds');
          callSummary = result;
        } catch (e) {
          print('❌ Error ending call: $e');
        }
      } else {
        if (!recordCall) {
          print('⚠️ Recording disabled');
        }
        if (callId == null) {
          print('⚠️ No call ID - cannot record');
        }
        if (finalDuration <= 0) {
          print('⚠️ Call duration is 0 - nothing to record');
        }
      }

      // Cleanup
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

  /// Clear call ID (used when call is cancelled)
  void clearCallId() {
    _callId = null;
    _callDuration = 0;
    print('📞 Call ID cleared');
  }

  /// Get formatted duration as MM:SS
  String getFormattedDuration() {
    int minutes = _callDuration ~/ 60;
    int seconds = _callDuration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Release resources and cleanup
  Future<void> dispose() async {
    try {
      stopDurationTimer();
      _callDuration = 0;
      _isMuted = false;
      _isSpeakerOn = true;

      // Leave call if currently in one
      if (_currentRoomId != null) {
        await leaveRoom();
      }

      // Dispose CallManager
      try {
        _callManager?.dispose();
        _callManager = null;
      } catch (e) {
        print('⚠️ Error disposing CallManager: $e');
      }

      // Close NexaconClient
      try {
        _client?.close();
        _client = null;
      } catch (e) {
        print('⚠️ Error closing NexaconClient: $e');
      }

      print('✅ Nexacon service disposed');
    } catch (e) {
      print('❌ Error disposing Nexacon service: $e');
    }
  }

  /// Request microphone permissions
  Future<bool> requestPermissions() async {
    try {
      print('🎤 Checking microphone permission status...');

      var status = await Permission.microphone.status;
      print('🎤 Current permission status: $status');

      if (status.isGranted) {
        print('✅ Microphone permission already granted');
        return true;
      }

      if (status.isDenied) {
        print('❓ Requesting microphone permission...');
        status = await Permission.microphone.request();
        print('🎤 Permission request result: $status');
      }

      if (status.isPermanentlyDenied) {
        print(
            '❌ Microphone permission permanently denied. Opening app settings...');
        onError?.call(
            'Microphone permission denied. Please enable it in app settings.');
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

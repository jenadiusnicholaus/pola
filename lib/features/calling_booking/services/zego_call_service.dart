import 'dart:async';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import '../../../config/zego_config.dart';
import 'call_service.dart';

class ZegoCallService extends GetxService {
  Timer? _durationTimer;
  int _callDuration = 0; // in seconds
  int? _callId; // Backend call ID for recording
  String? _currentRoomId;

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
  int _userCountInRoom = 0;

  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  int get callDuration => _callDuration;
  int? get callId => _callId; // Expose call ID for checking

  /// Initialize ZegoCloud Express Engine
  Future<void> initializeZego(String userId, String userName) async {
    try {
      final appId = ZegoConfig.appId;
      final appSign = ZegoConfig.appSign;

      print('🔑 Initializing ZegoCloud Express Engine with App ID: $appId');

      // Always destroy existing engine first to ensure clean state
      try {
        print('⚠️ Destroying existing engine before reinitializing');
        await ZegoExpressEngine.destroyEngine();
        // Wait a bit for engine to be fully destroyed
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('⚠️ Error destroying existing engine (may not exist): $e');
      }

      // Create ZegoExpressEngine instance
      print('🔨 Creating new ZegoExpressEngine instance...');
      print('📝 App ID: $appId');
      print(
          '📝 App Sign (first 10 chars): ${appSign.substring(0, appSign.length > 10 ? 10 : appSign.length)}...');
      print('📝 Scenario: Communication');

      await ZegoExpressEngine.createEngineWithProfile(
        ZegoEngineProfile(
          appId,
          ZegoScenario.Communication,
          appSign: appSign,
        ),
      );

      print('⏳ Waiting for engine initialization to complete...');
      // Wait longer for engine to be fully initialized on native side
      await Future.delayed(const Duration(milliseconds: 1500));

      // Verify engine was actually created by trying to access it
      try {
        // This will throw if engine is null on native side
        final version = await ZegoExpressEngine.getVersion();
        print('✅ Engine verified - SDK Version: $version');
      } catch (e) {
        print('❌ Engine verification failed: $e');
        throw Exception(
            'Engine creation failed on native side. Check credentials and SDK setup.');
      }

      // Set up event handlers
      ZegoExpressEngine.onRoomUserUpdate = (roomID, updateType, userList) {
        print('📱 Room users updated in room $roomID');
        print('📱 Update type: $updateType');
        print('📱 Users in update: ${userList.length}');
        for (var user in userList) {
          print('   - User: ${user.userID} (${user.userName})');
        }

        if (updateType == ZegoUpdateType.Add) {
          _userCountInRoom += userList.length;
          print('👥 User(s) joined! Total users in room: $_userCountInRoom');

          // Start timer when second user joins (both parties connected)
          if (_userCountInRoom >= 2 && !_isTimerStarted) {
            print('⏱️ Both parties connected, starting call timer NOW!');
            startDurationTimer();
            _isTimerStarted = true;
            onOtherUserJoined?.call();
          } else if (_userCountInRoom >= 2 && _isTimerStarted) {
            print('ℹ️ More users joined, but timer already started');
          } else {
            print(
                '⏳ Waiting for more users... (need 2, have $_userCountInRoom)');
          }
        } else if (updateType == ZegoUpdateType.Delete) {
          _userCountInRoom -= userList.length;
          if (_userCountInRoom < 0) _userCountInRoom = 0;
          print('👥 ❗ User(s) LEFT! Remaining users: $_userCountInRoom');
          print('👥 Timer started: $_isTimerStarted');

          // If other user left and we're still in a call, notify controller
          if (_userCountInRoom < 2 && _isTimerStarted) {
            print('🚪 ❗ OTHER PARTY DISCONNECTED - Calling onOtherUserLeft!');
            onOtherUserLeft?.call();
          } else {
            print(
                '⚠️ User left but not triggering callback: userCount=$_userCountInRoom, timerStarted=$_isTimerStarted');
          }
        }
      };

      // Also listen for stream updates (when someone starts/stops publishing)
      ZegoExpressEngine.onRoomStreamUpdate =
          (roomID, updateType, streamList, extendedData) {
        print(
            '📡 Room streams updated: $updateType, streams: ${streamList.length}');

        if (updateType == ZegoUpdateType.Add) {
          for (var stream in streamList) {
            print('   📤 New stream from user: ${stream.user.userID}');

            // IMPORTANT: Start playing the remote user's stream to hear them
            try {
              ZegoExpressEngine.instance.startPlayingStream(stream.streamID);
              print('🔊 Started playing stream: ${stream.streamID}');
            } catch (e) {
              print('❌ Error starting to play stream: $e');
            }
          }

          // If someone else is publishing and timer not started, start it
          if (streamList.isNotEmpty && !_isTimerStarted) {
            print('⏱️ Other user is publishing audio, starting timer!');
            _userCountInRoom = 2; // Ensure count is correct
            startDurationTimer();
            _isTimerStarted = true;
            onOtherUserJoined?.call();
          }
        } else if (updateType == ZegoUpdateType.Delete) {
          // User stopped publishing or left
          for (var stream in streamList) {
            print('   ❌ Stream removed from user: ${stream.user.userID}');

            // Stop playing the remote stream
            try {
              ZegoExpressEngine.instance.stopPlayingStream(stream.streamID);
              print('🔇 Stopped playing stream: ${stream.streamID}');
            } catch (e) {
              print('❌ Error stopping stream: $e');
            }
          }

          // If other user's stream was removed and we're in a call, end it
          if (streamList.isNotEmpty && _isTimerStarted) {
            print(
                '🚪 ❗ OTHER USER STOPPED PUBLISHING - Calling onOtherUserLeft!');
            onOtherUserLeft?.call();
          }
        }
      };

      ZegoExpressEngine.onRoomStateUpdate =
          (roomID, state, errorCode, extendedData) {
        print('📱 Room state: $state, error: $errorCode');
        if (errorCode != 0) {
          print('⚠️ Room state error code: $errorCode');
        }

        // When connected to room, check if we should start timer
        if (state == ZegoRoomState.Connected && !_isTimerStarted) {
          print('🔗 Connected to room, checking user count...');
          // Give callback time to fire for existing users
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (_userCountInRoom >= 2 && !_isTimerStarted) {
              print('⏱️ Timer start triggered by room connection');
              startDurationTimer();
              _isTimerStarted = true;
              onOtherUserJoined?.call();
            }
          });
        }
      };

      print('✅ ZegoCloud Express Engine initialized and verified successfully');
    } catch (e) {
      print('❌ ZegoCloud initialization error: $e');
      onError?.call('Failed to initialize ZegoCloud: ${e.toString()}');
      rethrow;
    }
  }

  /// Join a call room
  Future<void> joinRoom(String roomId, String userId, String userName) async {
    try {
      _currentRoomId = roomId;

      print('🔑 Joining room: $roomId as $userName ($userId)');
      print('🔍 Attempting to access ZegoExpressEngine.instance...');

      // Verify engine is accessible before using it
      try {
        final version = await ZegoExpressEngine.getVersion();
        print('✅ Engine is accessible, version: $version');
      } catch (e) {
        print('❌ Engine is not accessible: $e');
        throw Exception(
            'ZegoExpressEngine not properly initialized. Please call initializeZego() first and ensure it completes successfully.');
      }

      // Login to room
      print('📞 Calling loginRoom...');
      await ZegoExpressEngine.instance.loginRoom(
        roomId,
        ZegoUser(userId, userName),
      );

      print('✅ Logged into room');

      // Enable speaker for audio output (so you can hear the other person)
      await ZegoExpressEngine.instance.setAudioRouteToSpeaker(true);
      print('🔊 Audio route set to speaker');

      // Set initial user count to 1 (yourself)
      _userCountInRoom = 1;
      print('👤 You joined the room, user count: $_userCountInRoom');

      // Start publishing audio stream
      await ZegoExpressEngine.instance.startPublishingStream(userId);

      print('✅ Started publishing stream');
      print('⏳ Waiting for other user to join before starting timer...');
      print('✅ Joined room successfully: $roomId');
    } catch (e) {
      print('❌ Error joining room: $e');
      _currentRoomId = null;
      rethrow;
    }
  }

  /// Leave the current call room
  Future<void> leaveRoom() async {
    try {
      if (_currentRoomId == null) {
        print('⚠️ No active room to leave');
        return;
      }

      final roomId = _currentRoomId;
      _currentRoomId = null; // Clear room ID first to prevent re-entry
      _isTimerStarted = false; // Reset timer state
      _userCountInRoom = 0; // Reset user count

      // Stop publishing stream (safe call)
      try {
        await ZegoExpressEngine.instance.stopPublishingStream();
        print('✅ Stopped publishing stream');
      } catch (e) {
        print('⚠️ Could not stop publishing stream: $e');
      }

      // Logout from room (safe call)
      try {
        await ZegoExpressEngine.instance.logoutRoom(roomId!);
        print('✅ Logged out from room: $roomId');
      } catch (e) {
        print('⚠️ Could not logout from room: $e');
      }

      print('✅ Left room successfully');
    } catch (e) {
      print('❌ Error leaving room: $e');
      _currentRoomId = null; // Ensure room ID is cleared
    }
  }

  /// Toggle microphone mute
  Future<void> toggleMute() async {
    try {
      _isMuted = !_isMuted;
      await ZegoExpressEngine.instance.muteMicrophone(_isMuted);
      print('🎤 Microphone ${_isMuted ? "muted" : "unmuted"}');
    } catch (e) {
      print('⚠️ Cannot toggle mute: $e');
    }
  }

  /// Toggle speaker (audio routing handled by system)
  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    // Note: ZegoExpressEngine handles audio routing automatically for voice calls
    print('🔊 Speaker toggle: ${_isSpeakerOn ? "on" : "off"}');
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

      // Leave room if currently in one
      if (_currentRoomId != null) {
        await leaveRoom();
      }

      // Destroy ZegoExpressEngine (with null safety)
      try {
        await ZegoExpressEngine.destroyEngine();
      } catch (e) {
        print('⚠️ Engine already destroyed or not initialized: $e');
      }

      print('✅ ZegoCloud service disposed');
    } catch (e) {
      print('❌ Error disposing ZegoCloud service: $e');
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

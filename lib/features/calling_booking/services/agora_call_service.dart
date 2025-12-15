import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../config/agora_config.dart';
import 'call_service.dart';

class AgoraCallService {
  RtcEngine? _engine;
  Timer? _durationTimer;
  int _callDuration = 0; // in seconds
  int? _userId;
  String? _channelName;
  int? _consultantId;

  // Callbacks
  Function(String duration)? onDurationUpdate;
  Function(int durationSeconds)? onCallEnded;
  Function(String error)? onError;
  Function()? onJoinChannel;
  Function()? onConsultantJoined;
  Function()? onConsultantLeft;

  // State
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _isSpeakerOn = true;

  bool get isInitialized => _isInitialized;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  int get callDuration => _callDuration;

  /// Request microphone permissions
  Future<bool> requestPermissions() async {
    try {
      print('🎤 Checking microphone permission status...');

      // Check current status
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

  /// Initialize Agora RTC engine
  Future<void> initializeAgora() async {
    try {
      if (_isInitialized) {
        return;
      }

      // Check Agora App ID
      final appId = AgoraConfig.APP_ID;
      if (appId.isEmpty || appId == 'YOUR_AGORA_APP_ID_HERE') {
        throw Exception(
            'Agora App ID not configured. Please check your .env file.');
      }

      print('🔑 Using Agora App ID: ${appId.substring(0, 8)}...');
      print('🔑 App ID length: ${appId.length}');
      print('🔑 Full App ID: $appId');

      // Create engine
      _engine = createAgoraRtcEngine();

      print('📱 Created Agora RTC Engine');

      await _engine!.initialize(RtcEngineContext(
        appId: appId,
      ));

      print('✅ Agora RTC Engine initialized successfully');

      // Register event handlers
      try {
        print('📝 Registering event handlers...');
        _engine!.registerEventHandler(
          RtcEngineEventHandler(
            onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
              print('✅ Successfully joined channel: ${connection.channelId}');
              onJoinChannel?.call();
            },
            onUserJoined:
                (RtcConnection connection, int remoteUid, int elapsed) {
              print('👤 Consultant joined the call (UID: $remoteUid)');
              onConsultantJoined?.call();
              // Start timer only when consultant joins
              _startDurationTimer();
            },
            onUserOffline: (RtcConnection connection, int remoteUid,
                UserOfflineReasonType reason) {
              print('👤 Consultant left the call');
              onConsultantLeft?.call();
            },
            onLeaveChannel: (RtcConnection connection, RtcStats stats) {
              print('📞 Left channel');
            },
            onError: (ErrorCodeType err, String msg) {
              final errorMsg = msg.isNotEmpty ? msg : err.toString();
              print('❌ Call error: $errorMsg (Error code: $err)');
              onError?.call('Call error: $errorMsg');
            },
            onConnectionLost: (RtcConnection connection) {
              print('📡 Connection lost');
              onError?.call('Connection lost. Please check your internet.');
            },
            onAudioQuality: (RtcConnection connection, int remoteUid,
                QualityType quality, int delay, int lost) {
              if (quality == QualityType.qualityBad ||
                  quality == QualityType.qualityPoor) {
                print('⚠️ Poor audio quality detected');
              }
            },
          ),
        );
        print('✅ Event handlers registered');
      } catch (e) {
        print('❌ Event handler registration failed: $e');
        throw Exception('Event handler registration failed: $e');
      }

      // Configure audio settings
      try {
        print('🔊 Enabling audio...');
        await _engine!.enableAudio();
        print('✅ Audio enabled');
      } catch (e) {
        print('❌ Enable audio failed: $e');
        throw Exception('Enable audio failed: $e');
      }

      try {
        print('📢 Setting speaker mode...');
        await _engine!.setEnableSpeakerphone(_isSpeakerOn);
        print('✅ Speaker mode set');
      } catch (e) {
        print('⚠️ Set speaker mode failed (non-critical): $e');
        // Non-blocking - speaker mode can be adjusted later
      }

      _isInitialized = true;
      print('🎉 Agora initialization complete!');
    } catch (e) {
      print('❌ Agora initialization error: $e');
      onError?.call('Failed to initialize Agora: ${e.toString()}');
      rethrow;
    }
  }

  /// Join a channel directly with channel name (for incoming calls)
  Future<void> joinChannelDirect(String channelName) async {
    try {
      if (!_isInitialized) {
        await initializeAgora();
      }

      _channelName = channelName;
      _userId = AgoraConfig.generateUserId();

      print('📞 Joining channel directly: $_channelName with UID: $_userId');

      await _engine!.joinChannel(
        token: AgoraConfig.TOKEN,
        channelId: _channelName!,
        uid: _userId!,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
        ),
      );

      print('✅ Joined channel for incoming call');
    } catch (e) {
      print('❌ Failed to join channel: $e');
      onError?.call('Failed to join call channel');
      rethrow;
    }
  }

  /// Join a voice call channel
  Future<void> joinChannel(int consultantId) async {
    try {
      if (!_isInitialized) {
        await initializeAgora();
      }

      _consultantId = consultantId;
      _channelName = AgoraConfig.generateChannelName(consultantId);
      _userId = AgoraConfig.generateUserId();

      print('📞 Joining channel: $_channelName with UID: $_userId');

      await _engine!.joinChannel(
        token: AgoraConfig.TOKEN,
        channelId: _channelName!,
        uid: _userId!,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
        ),
      );

      // Don't start timer yet - wait for consultant to join
      print('⏳ Waiting for consultant to join before starting timer...');
    } catch (e) {
      onError?.call('Failed to join channel: ${e.toString()}');
      rethrow;
    }
  }

  /// Start call duration timer
  void _startDurationTimer() {
    _callDuration = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDuration++;
      onDurationUpdate?.call(getFormattedDuration());
    });
  }

  /// End the call and cleanup
  Future<void> endCall({bool recordCall = true}) async {
    try {
      // Stop timer
      _durationTimer?.cancel();
      _durationTimer = null;

      final finalDuration = _callDuration;
      final consultantId = _consultantId;

      // Leave channel
      if (_engine != null) {
        await _engine!.leaveChannel();
      }

      // Record call if duration > 0 and recording is enabled
      if (recordCall && consultantId != null && finalDuration > 0) {
        try {
          final callService = CallService();
          await callService.recordCall(
            consultantId: consultantId,
            durationSeconds: finalDuration,
          );
          print('✅ Call recorded: $finalDuration seconds');
        } catch (e) {
          print('❌ Error recording call: $e');
        }
      }

      // Cleanup
      _callDuration = 0;
      _consultantId = null;
      _channelName = null;
      _userId = null;

      onCallEnded?.call(finalDuration);
    } catch (e) {
      print('❌ Error ending call: $e');
      onError?.call('Error ending call: ${e.toString()}');
    }
  }

  /// Toggle microphone mute
  Future<void> toggleMute() async {
    try {
      _isMuted = !_isMuted;
      await _engine?.muteLocalAudioStream(_isMuted);
    } catch (e) {
      onError?.call('Failed to toggle mute: ${e.toString()}');
    }
  }

  /// Toggle speaker on/off
  Future<void> toggleSpeaker() async {
    try {
      _isSpeakerOn = !_isSpeakerOn;
      await _engine?.setEnableSpeakerphone(_isSpeakerOn);
    } catch (e) {
      onError?.call('Failed to toggle speaker: ${e.toString()}');
    }
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
      _durationTimer?.cancel();
      _durationTimer = null;

      if (_engine != null) {
        await _engine!.leaveChannel();
        await _engine!.release();
        _engine = null;
      }

      _isInitialized = false;
      _callDuration = 0;
      _isMuted = false;
      _isSpeakerOn = true;
    } catch (e) {
      print('❌ Error disposing Agora service: $e');
    }
  }
}

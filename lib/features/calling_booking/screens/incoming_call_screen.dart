import 'dart:async';
import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../services/token_storage_service.dart';
import '../services/call_service.dart';
import '../services/nexacon_call_service.dart';
import 'call_screen.dart';

/// Notification ID for incoming calls (must match fcm_service.dart)
const int _incomingCallNotificationId = 1001;

/// Cancel the incoming call notification when call is handled
Future<void> _cancelIncomingCallNotification() async {
  try {
    final FlutterLocalNotificationsPlugin plugin =
        FlutterLocalNotificationsPlugin();
    await plugin.cancel(_incomingCallNotificationId);
    debugPrint(
      '🔕 Cancelled incoming call notification from IncomingCallScreen',
    );
  } catch (e) {
    debugPrint('⚠️ Error cancelling notification: $e');
  }
}

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String channelName;
  final String callerName;
  final String callerPhoto;
  final String callType;
  final String callerId;
  final String callerPhone;

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.channelName,
    required this.callerName,
    required this.callerPhoto,
    required this.callType,
    required this.callerId,
    this.callerPhone = '',
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final CallService _callService = CallService();
  late Timer _timeoutTimer;
  bool _isProcessing = false;
  String _processingAction = ''; // Track which action is being processed

  /// Format phone number with +255 prefix for NX JID compatibility
  String _formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('255')) return '+$digits';
    if (digits.startsWith('0')) return '+255${digits.substring(1)}';
    return '+255$digits';
  }

  /// Show snackbar safely without overlay issues
  void _showSnackBar(
    String title,
    String message, {
    Color? backgroundColor,
    IconData? icon,
  }) {
    // Use a global key or delayed execution to avoid overlay issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(message, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: backgroundColor ?? Colors.grey[800],
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();

    debugPrint('📞 IncomingCallScreen initialized for ${widget.callerName}');

    // Pre-warm NX connection immediately so SDK is ready when user taps Accept
    Future.microtask(() async {
      try {
        final tokenStorage = Get.find<TokenStorageService>();
        final userData = tokenStorage.userData;
        String? rawPhone;
        if (userData != null) {
          final contact = userData['contact'] as Map<String, dynamic>?;
          rawPhone = contact?['phone_number'] as String? ??
              userData['phone_number'] as String?;
        }
        if (rawPhone != null && rawPhone.isNotEmpty) {
          final phone = _formatPhone(rawPhone);
          debugPrint('🔥 Pre-warming NX for incoming call: $phone');
          final nexaconService = Get.find<NexaconCallService>();
          await nexaconService.prewarmForIncoming(phoneNumber: phone);
        }
      } catch (e) {
        debugPrint('⚠️ Pre-warm error (non-fatal): $e');
      }
    });

    // Start playing device ringtone with slight delay to ensure screen is mounted
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _playRingtone();
      }
    });

    // Auto-timeout after 60 seconds (silently terminate if not answered)
    _timeoutTimer = Timer(const Duration(seconds: 60), () {
      if (mounted && !_isProcessing) {
        _handleTimeout();
      }
    });
  }

  /// Play device's default ringtone for incoming call
  void _playRingtone() {
    try {
      debugPrint('🔔 Attempting to play ringtone...');
      FlutterRingtonePlayer().play(
        android: AndroidSounds.ringtone,
        ios: IosSounds.electronic,
        looping: true,
        volume: 1.0,
      );
      debugPrint(
        '🔔 Ringtone play() method called successfully with looping: true',
      );
    } catch (e) {
      debugPrint('❌ Error playing ringtone: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
    }
  }

  /// Stop ringtone
  void _stopRingtone() {
    try {
      FlutterRingtonePlayer().stop();
      debugPrint('🔕 Ringtone stopped');
    } catch (e) {
      debugPrint('❌ Error stopping ringtone: $e');
    }
  }

  @override
  void dispose() {
    _stopRingtone();
    _timeoutTimer.cancel();
    super.dispose();
  }

  /// Handle call timeout (missed)
  Future<void> _handleTimeout() async {
    debugPrint('⏰ Call timeout - marking as missed');

    try {
      await _callService.markCallMissed(callId: widget.callId);
    } catch (e) {
      debugPrint('Error marking call as missed: $e');
    }

    if (mounted) {
      // Navigate to home screen to avoid black screen
      Get.offAllNamed('/home');

      _showSnackBar(
        'Missed Call',
        'You missed a call from ${widget.callerName}',
        backgroundColor: Colors.orange,
        icon: Icons.phone_missed,
      );
    }
  }

  /// Accept the incoming call
  Future<void> _acceptCall() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _processingAction = 'accept';
    });
    _stopRingtone();
    _timeoutTimer.cancel();

    // Cancel the notification immediately
    _cancelIncomingCallNotification();

    try {
      debugPrint('✅ Accepting call: ${widget.callId}');

      // Format caller phone with country code for NX compatibility
      final formattedCallerPhone = widget.callerPhone.isNotEmpty
          ? _formatPhone(widget.callerPhone)
          : widget.callerPhone;

      debugPrint(
          '📞 Caller phone formatted: $formattedCallerPhone (original: ${widget.callerPhone})');

      // Navigate to call screen — CallScreen.joinIncomingCall handles NX SDK acceptance
      Get.off(
        () => CallScreen(
          consultant: null,
          callId: widget.callId,
          channelName: widget.channelName,
          isIncoming: true,
          callerName: widget.callerName,
          callerPhoto: widget.callerPhoto,
          callerPhone: formattedCallerPhone,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error accepting call: $e');
      _showSnackBar(
        'Error',
        'Failed to accept call. Please try again.',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
      Get.back();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Reject the incoming call
  Future<void> _rejectCall() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _processingAction = 'reject';
    });
    _stopRingtone();
    _timeoutTimer.cancel();

    // Cancel the notification immediately
    _cancelIncomingCallNotification();

    try {
      debugPrint('❌ Rejecting call: ${widget.callId}');

      await _callService.rejectCall(callId: widget.callId, reason: 'declined');

      debugPrint('✅ Call rejected successfully');

      // Navigate to home screen to avoid black screen
      if (mounted) {
        Get.offAllNamed('/home');
      }

      // Show snackbar after navigation
      _showSnackBar(
        'Call Declined',
        'You declined the call from ${widget.callerName}',
        backgroundColor: Colors.grey[800],
        icon: Icons.call_end,
      );
    } catch (e) {
      debugPrint('❌ Error rejecting call: $e');

      // Check if call was already rejected/ended (graceful handling)
      if (e.toString().contains('invalid_status') ||
          e.toString().contains('already') ||
          e.toString().contains('rejected') ||
          e.toString().contains('ended') ||
          e.toString().contains('400')) {
        debugPrint(
            'ℹ️ Call already ended/rejected, navigating to home gracefully');
        // Navigate to home screen instead of just popping
        if (mounted) {
          Get.offAllNamed('/home');
        }
      } else {
        // Show error for other types of failures
        if (mounted) {
          Get.offAllNamed('/home');
        }
        _showSnackBar(
          'Error',
          'Failed to decline call',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String get _avatarLetter {
    final name = widget.callerName.trim();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Color(0xFF1B2B34),
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 48),

              // ── Status label ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.callType == 'video'
                        ? Icons.videocam_rounded
                        : Icons.phone_rounded,
                    color: Colors.white54,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Connecting...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 40),

              // ── Avatar ────────────────────────────────────────────────
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF2C3E50),
                  border: Border.all(color: Colors.white24, width: 2.5),
                  image: widget.callerPhoto.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(widget.callerPhoto),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: widget.callerPhoto.isEmpty
                    ? Text(
                        _avatarLetter,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),

              SizedBox(height: 28),

              // ── Caller name ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  widget.callerName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              SizedBox(height: 12),

              // ── Status ────────────────────────────────────────────────
              if (_isProcessing)
                Text(
                  _processingAction == 'accept'
                      ? 'Connecting...'
                      : 'Declining...',
                  style: TextStyle(fontSize: 15, color: Colors.white60),
                )
              else
                CallStatusDots(
                  label: 'Connecting',
                  color: Colors.white60,
                ),

              Spacer(),

              // ── Action buttons ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(48, 0, 48, 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ActionButton(
                      icon: Icons.call_end_rounded,
                      label: 'Decline',
                      color: Colors.redAccent.shade700,
                      enabled: !_isProcessing,
                      onTap: _rejectCall,
                    ),
                    _ActionButton(
                      icon: Icons.phone_rounded,
                      label: tr('Accept'),
                      color: const Color(0xFF2ECC71),
                      enabled: !_isProcessing,
                      onTap: _acceptCall,
                    ),
                  ],
                ),
              ),

              const Text(
                'Powered by nexacon.africa',
                style: TextStyle(fontSize: 11, color: Colors.white24),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? color : color.withValues(alpha: 0.4),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: enabled ? Colors.white70 : Colors.white30,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../services/call_service.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String channelName;
  final String callerName;
  final String callerPhoto;
  final String callType;
  final String callerId;

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.channelName,
    required this.callerName,
    required this.callerPhoto,
    required this.callType,
    required this.callerId,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  final CallService _callService = CallService();
  late Timer _timeoutTimer;
  late AnimationController _pulseController;
  bool _isProcessing = false;
  String _processingAction = ''; // Track which action is being processed

  @override
  void initState() {
    super.initState();

    debugPrint('📞 IncomingCallScreen initialized for ${widget.callerName}');

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

    // Pulse animation for call icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
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
          '🔔 Ringtone play() method called successfully with looping: true');
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
    _pulseController.dispose();
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
      Get.snackbar(
        'Missed Call',
        'You missed a call from ${widget.callerName}',
        icon: const Icon(Icons.phone_missed, color: Colors.white),
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      Get.back();
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

    try {
      debugPrint('✅ Accepting call: ${widget.callId}');

      final response = await _callService.acceptCall(callId: widget.callId);

      debugPrint('📥 Accept response: $response');

      if (response['success'] == true) {
        debugPrint('✅ Call accepted successfully');
        debugPrint('📡 Channel name: ${response['channel_name']}');

        // Navigate to call screen
        Get.off(
          () => CallScreen(
            consultant: null, // We're the receiver, not calling a consultant
            callId: widget.callId,
            channelName: response['channel_name'] ?? widget.channelName,
            isIncoming: true,
            callerName: widget.callerName,
            callerPhoto: widget.callerPhoto,
          ),
        );
      } else {
        debugPrint('❌ Accept failed: ${response['message']}');
        Get.snackbar(
          'Error',
          response['message'] ?? 'Failed to accept call',
          icon: const Icon(Icons.error, color: Colors.white),
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        Get.back();
      }
    } catch (e) {
      debugPrint('❌ Error accepting call: $e');
      Get.snackbar(
        'Error',
        'Failed to accept call. Please try again.',
        icon: const Icon(Icons.error, color: Colors.white),
        backgroundColor: Colors.red,
        colorText: Colors.white,
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

    try {
      debugPrint('❌ Rejecting call: ${widget.callId}');

      await _callService.rejectCall(
        callId: widget.callId,
        reason: 'declined',
      );

      debugPrint('✅ Call rejected successfully');

      // Close screen first, then show snackbar so it doesn't block
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show snackbar after closing
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.snackbar(
          'Call Declined',
          'You declined the call from ${widget.callerName}',
          icon: const Icon(Icons.call_end, color: Colors.white),
          backgroundColor: Colors.grey[800],
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      });
    } catch (e) {
      debugPrint('❌ Error rejecting call: $e');

      // Check if call was already rejected/ended (graceful handling)
      if (e.toString().contains('invalid_status') ||
          e.toString().contains('already') ||
          e.toString().contains('rejected') ||
          e.toString().contains('ended') ||
          e.toString().contains('400')) {
        debugPrint('ℹ️ Call already ended/rejected, closing screen gracefully');
        // Just close the screen without showing error
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Show error for other types of failures
        if (mounted) {
          Navigator.of(context).pop();
        }
        Future.delayed(const Duration(milliseconds: 100), () {
          Get.snackbar(
            'Error',
            'Failed to decline call',
            icon: const Icon(Icons.error, color: Colors.white),
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top section - Call type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.callType == 'video'
                            ? Icons.videocam
                            : Icons.phone,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Incoming ${widget.callType == 'video' ? 'Video' : 'Voice'} Call',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Middle section - Animated caller avatar
                Column(
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 1.08).animate(
                        CurvedAnimation(
                          parent: _pulseController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withOpacity(0.6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 80,
                            backgroundColor: theme.colorScheme.surface,
                            backgroundImage: widget.callerPhoto.isNotEmpty
                                ? NetworkImage(widget.callerPhoto)
                                : null,
                            child: widget.callerPhoto.isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: 80,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Caller name
                    Text(
                      widget.callerName,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 16),

                    // Ringing indicator with animation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Ringing...',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(flex: 2),

                // Processing indicator above buttons
                if (_isProcessing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _processingAction == 'accept'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _processingAction == 'accept'
                              ? 'Connecting...'
                              : 'Declining...',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Bottom section - Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Reject button
                    _buildActionButton(
                      icon: Icons.call_end_rounded,
                      label: 'Decline',
                      color: Colors.red,
                      onTap: _isProcessing ? null : _rejectCall,
                    ),

                    const SizedBox(width: 60),

                    // Accept button
                    _buildActionButton(
                      icon: Icons.phone_rounded,
                      label: 'Accept',
                      color: Colors.green,
                      onTap: _isProcessing ? null : _acceptCall,
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 12,
          shadowColor: color.withOpacity(0.4),
          shape: const CircleBorder(),
          color: isDisabled ? color.withOpacity(0.5) : color,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(isDisabled ? 0.4 : 0.8)
                : Colors.black87.withOpacity(isDisabled ? 0.4 : 1.0),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

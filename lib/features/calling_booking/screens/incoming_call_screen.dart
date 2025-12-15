import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  @override
  void initState() {
    super.initState();

    // Auto-timeout after 60 seconds
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

  @override
  void dispose() {
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

    setState(() => _isProcessing = true);
    _timeoutTimer.cancel();

    try {
      debugPrint('✅ Accepting call: ${widget.callId}');

      final response = await _callService.acceptCall(callId: widget.callId);

      if (response['success'] == true) {
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

    setState(() => _isProcessing = true);
    _timeoutTimer.cancel();

    try {
      debugPrint('❌ Rejecting call: ${widget.callId}');

      await _callService.rejectCall(callId: widget.callId, reason: 'busy');

      Get.snackbar(
        'Call Declined',
        'You declined the call from ${widget.callerName}',
        icon: const Icon(Icons.call_end, color: Colors.white),
        backgroundColor: Colors.grey[800],
        colorText: Colors.white,
      );

      Get.back();
    } catch (e) {
      debugPrint('❌ Error rejecting call: $e');
      Get.back();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        // Prevent back button, must explicitly reject
        return false;
      },
      child: Scaffold(
        backgroundColor: theme.brightness == Brightness.dark
            ? Colors.black87
            : theme.colorScheme.surface,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top section - Call type
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'Incoming ${widget.callType == 'video' ? 'Video' : 'Voice'} Call',
                      style: TextStyle(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white70
                            : theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Middle section - Caller info
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated caller avatar
                    ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 1.1).animate(
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
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 70,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage: widget.callerPhoto.isNotEmpty
                              ? NetworkImage(widget.callerPhoto)
                              : null,
                          child: widget.callerPhoto.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 70,
                                  color: theme.colorScheme.onPrimaryContainer,
                                )
                              : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Caller name
                    Text(
                      widget.callerName,
                      style: TextStyle(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Ringing text
                    Text(
                      'Ringing...',
                      style: TextStyle(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white70
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom section - Action buttons
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Reject button
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          elevation: 8,
                          shape: const CircleBorder(),
                          color: Colors.red,
                          child: InkWell(
                            onTap: _isProcessing ? null : _rejectCall,
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 70,
                              height: 70,
                              alignment: Alignment.center,
                              child: _isProcessing
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.call_end,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Decline',
                          style: TextStyle(
                            color: theme.brightness == Brightness.dark
                                ? Colors.white70
                                : theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    // Accept button
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          elevation: 8,
                          shape: const CircleBorder(),
                          color: Colors.green,
                          child: InkWell(
                            onTap: _isProcessing ? null : _acceptCall,
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 70,
                              height: 70,
                              alignment: Alignment.center,
                              child: _isProcessing
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.call,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Accept',
                          style: TextStyle(
                            color: theme.brightness == Brightness.dark
                                ? Colors.white70
                                : theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/call_controller.dart';
import '../models/consultant_models.dart';

class CallScreen extends StatefulWidget {
  final Consultant? consultant;
  final String? callId;
  final String? channelName;
  final bool isIncoming;
  final String? callerName;
  final String? callerPhoto;
  final String? callerPhone;

  const CallScreen({
    super.key,
    this.consultant,
    this.callId,
    this.channelName,
    this.isIncoming = false,
    this.callerName,
    this.callerPhoto,
    this.callerPhone,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  CallController? controller;
  bool _hasError = false;
  String _errorMessage = '';

  static const Color _kBg = Color(0xFF1B2B34);
  static const Color _kAccent = Color(0xFF2ECC71);

  @override
  void initState() {
    super.initState();

    try {
      if (widget.isIncoming) {
        if (widget.callId == null || widget.channelName == null) {
          _hasError = true;
          _errorMessage = 'Missing call information';
          return;
        }
      } else {
        if (widget.consultant == null) {
          _hasError = true;
          _errorMessage = 'No consultant data provided';
          return;
        }
      }

      controller = Get.put(CallController());

      if (widget.isIncoming) {
        controller!.joinIncomingCall(
          callId: widget.callId!,
          channelName: widget.channelName!,
          callerName: widget.callerName ?? 'Unknown',
          callerPhone: widget.callerPhone ?? '',
        );
      } else {
        controller!.initiateCall(widget.consultant!);
      }
    } catch (e) {
      debugPrint('Error initializing call screen: $e');
      _hasError = true;
      _errorMessage = 'Failed to initialize call: ${e.toString()}';
    }
  }

  @override
  void dispose() {
    controller = null;
    super.dispose();
  }

  String get _displayName {
    if (widget.isIncoming) return widget.callerName ?? 'Unknown';
    return widget.consultant?.userDetails.fullName ?? 'Unknown';
  }

  String get _avatarLetter {
    if (widget.isIncoming) {
      final n = widget.callerName ?? '';
      return n.isNotEmpty ? n[0].toUpperCase() : '?';
    }
    final f = widget.consultant?.userDetails.firstName ?? '';
    return f.isNotEmpty ? f[0].toUpperCase() : '?';
  }

  String get _subtitle {
    if (!widget.isIncoming) {
      return widget.consultant?.consultantType ?? '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || controller == null) {
      return _ErrorScaffold(message: _errorMessage);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller?.endCall();
      },
      child: Scaffold(
        backgroundColor: _kBg,
        body: Obx(() {
          final hasError = controller!.error.value.isNotEmpty;
          if (hasError) return _buildErrorBody();
          return _buildCallBody();
        }),
      ),
    );
  }

  Widget _buildCallBody() {
    final connected = controller!.isConsultantConnected.value;

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 56),

          // ── Avatar ──────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2C3E50),
                border: Border.all(
                  color: connected ? _kAccent : Colors.white24,
                  width: 2.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _avatarLetter,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Name ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),

          if (_subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _subtitle.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Status / Duration ───────────────────────────────────────
          Obx(() {
            final c = controller!;
            if (c.isConsultantConnected.value) {
              return Column(
                children: [
                  Text(
                    c.callDuration.value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kAccent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Connected',
                        style: TextStyle(
                          fontSize: 14,
                          color: _kAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
            if (c.isRinging.value) {
              return CallStatusDots(
                label: 'Ringing',
                color: Colors.white70,
              );
            }
            return CallStatusDots(
              label: 'Calling',
              color: Colors.white54,
            );
          }),

          const Spacer(),

          // ── Credits badge (only when connected) ─────────────────────
          Obx(() {
            if (!controller!.isConsultantConnected.value) {
              return const SizedBox.shrink();
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Obx(() => Text(
                    '${controller!.creditsRemaining.value} min remaining',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  )),
            );
          }),

          // ── Controls row ─────────────────────────────────────────────
          Obx(() {
            final connected = controller!.isConsultantConnected.value;
            return Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ControlButton(
                    icon: controller!.isMuted.value
                        ? Icons.mic_off_rounded
                        : Icons.mic_rounded,
                    label: controller!.isMuted.value ? 'Unmute' : 'Mute',
                    enabled: connected,
                    active: controller!.isMuted.value,
                    activeColor: Colors.white24,
                    onTap: connected ? () => controller?.toggleMute() : null,
                  ),
                  _EndCallButton(
                    onTap: () => controller?.endCall(),
                  ),
                  _ControlButton(
                    icon: controller!.isSpeakerOn.value
                        ? Icons.volume_up_rounded
                        : Icons.volume_down_rounded,
                    label: 'Speaker',
                    enabled: connected,
                    active: controller!.isSpeakerOn.value,
                    activeColor: _kAccent.withValues(alpha: 0.25),
                    onTap: connected ? () => controller?.toggleSpeaker() : null,
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          const Text(
            'Powered by nexacon.africa',
            style: TextStyle(fontSize: 11, color: Colors.white24),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildErrorBody() {
    final isCredits = controller!.isInsufficientCreditsError;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCredits
                    ? Icons.account_balance_wallet_outlined
                    : Icons.error_outline,
                size: 80,
                color: isCredits ? _kAccent : Colors.redAccent,
              ),
              const SizedBox(height: 24),
              Text(
                isCredits ? 'Insufficient Credits' : 'Call Failed',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                controller!.error.value,
                style: const TextStyle(fontSize: 14, color: Colors.white60),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  'Go Back',
                  style: TextStyle(color: _kAccent, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouncing-dots status label — "Calling" / "Ringing" with 3 animated dots.
/// Public so it can be reused from incoming_call_screen.dart.
class CallStatusDots extends StatefulWidget {
  final String label;
  final Color color;

  const CallStatusDots({super.key, required this.label, required this.color});

  @override
  State<CallStatusDots> createState() => _CallStatusDotsState();
}

class _CallStatusDotsState extends State<CallStatusDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 17,
            color: widget.color,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 4),
        _BounceDot(controller: _ctrl, delay: 0.0, color: widget.color),
        const SizedBox(width: 3),
        _BounceDot(controller: _ctrl, delay: 0.2, color: widget.color),
        const SizedBox(width: 3),
        _BounceDot(controller: _ctrl, delay: 0.4, color: widget.color),
      ],
    );
  }
}

class _BounceDot extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final Color color;

  const _BounceDot({
    required this.controller,
    required this.delay,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = ((controller.value - delay) % 1.0);
        final dy = t < 0.5 ? -6.0 * (t / 0.5) : -6.0 * (1.0 - (t - 0.5) / 0.5);
        return Transform.translate(
          offset: Offset(0, dy),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

// ─── Control button (mute / speaker) ────────────────────────────────────────
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool active;
  final Color activeColor;
  final VoidCallback? onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.active,
    required this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? activeColor
                  : Colors.white.withValues(alpha: enabled ? 0.12 : 0.05),
            ),
            child: Icon(
              icon,
              color: enabled ? Colors.white : Colors.white30,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: enabled ? Colors.white60 : Colors.white24,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── End call button ─────────────────────────────────────────────────────────
class _EndCallButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EndCallButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.redAccent.shade700,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.call_end_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'End',
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

// ─── Error scaffold ───────────────────────────────────────────────────────────
class _ErrorScaffold extends StatelessWidget {
  final String message;
  const _ErrorScaffold({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2B34),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  message.isNotEmpty ? message : 'Failed to load call',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(color: Color(0xFF2ECC71), fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

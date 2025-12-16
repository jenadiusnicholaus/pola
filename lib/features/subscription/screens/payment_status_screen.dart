import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/subscription_models.dart';
import '../services/subscription_service.dart';
import '../../../features/profile/services/profile_service.dart';

class PaymentStatusScreen extends StatefulWidget {
  final String transactionId;
  final SubscriptionPlan plan;

  const PaymentStatusScreen({
    super.key,
    required this.transactionId,
    required this.plan,
  });

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen>
    with SingleTickerProviderStateMixin {
  final SubscriptionService _subscriptionService =
      Get.find<SubscriptionService>();
  String status = 'pending';
  String message = 'Processing your payment...';
  Timer? _pollTimer;
  int _pollCount = 0;
  final int _maxPolls = 60; // Poll for 3 minutes (60 * 3 seconds)
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _startPolling();
  }

  void _startPolling() {
    // Initial check immediately
    _checkPaymentStatus();

    // Then poll every 3 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      _pollCount++;

      if (_pollCount >= _maxPolls) {
        timer.cancel();
        setState(() {
          status = 'timeout';
          message =
              'Payment verification timed out. Please check your transaction status or contact support.';
        });
        return;
      }

      await _checkPaymentStatus();

      // Stop polling on terminal states
      if (status == 'completed' ||
          status == 'success' ||
          status == 'failed' ||
          status == 'cancelled' ||
          status == 'error') {
        timer.cancel();
        _animationController.stop();
      }
    });
  }

  Future<void> _checkPaymentStatus() async {
    try {
      final paymentStatus =
          await _subscriptionService.checkPaymentStatus(widget.transactionId);

      if (mounted) {
        setState(() {
          status = paymentStatus.status;
          message = paymentStatus.message;
        });

        // Handle different status values from unified payment API
        if (status == 'completed' || status == 'success') {
          _onPaymentSuccess();
        } else if (status == 'failed' || status == 'cancelled') {
          _animationController.stop();
        }
      }
    } catch (e) {
      debugPrint('Polling error: $e');
      // Don't update state on error to avoid disrupting the flow
    }
  }

  void _onPaymentSuccess() {
    // Refresh profile to get updated subscription
    try {
      final profileService = Get.find<ProfileService>();
      profileService.fetchProfile(forceRefresh: true);
    } catch (e) {
      debugPrint('Error refreshing profile: $e');
    }

    // Show success dialog after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _showSuccessDialog();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: status != 'pending',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payment Status'),
          automaticallyImplyLeading: status != 'pending',
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatusIcon(theme),
                const SizedBox(height: 32),
                _buildStatusTitle(theme),
                const SizedBox(height: 16),
                _buildStatusMessage(theme),
                const SizedBox(height: 32),
                _buildActionButtons(theme),
                const SizedBox(height: 24),
                _buildTransactionInfo(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ThemeData theme) {
    switch (status) {
      case 'pending':
        return RotationTransition(
          turns: _animationController,
          child: Icon(
            Icons.sync,
            size: 100,
            color: theme.colorScheme.primary,
          ),
        );
      case 'success':
        return const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 100,
        );
      case 'failed':
      case 'error':
        return const Icon(
          Icons.error,
          color: Colors.red,
          size: 100,
        );
      case 'timeout':
        return Icon(
          Icons.schedule,
          color: Colors.orange.shade700,
          size: 100,
        );
      default:
        return Icon(
          Icons.help_outline,
          color: Colors.grey.shade400,
          size: 100,
        );
    }
  }

  Widget _buildStatusTitle(ThemeData theme) {
    String title;
    Color? color;

    switch (status) {
      case 'pending':
        title = 'Processing Payment';
        color = theme.colorScheme.primary;
        break;
      case 'success':
        title = 'Payment Successful!';
        color = Colors.green;
        break;
      case 'failed':
        title = 'Payment Failed';
        color = Colors.red;
        break;
      case 'error':
        title = 'Payment Error';
        color = Colors.red;
        break;
      case 'timeout':
        title = 'Verification Timeout';
        color = Colors.orange.shade700;
        break;
      default:
        title = 'Unknown Status';
        color = Colors.grey;
    }

    return Text(
      title,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStatusMessage(ThemeData theme) {
    Widget messageWidget = Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: theme.colorScheme.onSurface.withOpacity(0.8),
      ),
    );

    if (status == 'pending') {
      return Column(
        children: [
          messageWidget,
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.phone_android, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Please check your phone and enter your PIN to complete the payment',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return messageWidget;
  }

  Widget _buildActionButtons(ThemeData theme) {
    if (status == 'pending') {
      return const SizedBox.shrink();
    }

    if (status == 'success') {
      return const SizedBox.shrink(); // Success dialog will handle navigation
    }

    return Column(
      children: [
        if (status == 'failed' || status == 'error') ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => Get.until((route) => route.isFirst),
            icon: const Icon(Icons.home),
            label: const Text('Go to Home'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Plan:',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                widget.plan.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaction ID:',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                widget.transactionId,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    Get.dialog(
      PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.celebration, color: Colors.amber, size: 32),
              SizedBox(width: 12),
              Expanded(child: Text('Welcome to Premium!')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your subscription is now active!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'You can now:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildSuccessFeature('Apply for consultation services'),
                      _buildSuccessFeature('Access all premium features'),
                      _buildSuccessFeature('Earn from consultations'),
                      _buildSuccessFeature('Unlimited access to legal library'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Start using your premium features right away!',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Get.until((route) => route.isFirst); // Go back to home
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Get Started'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildSuccessFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          const Text('•', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

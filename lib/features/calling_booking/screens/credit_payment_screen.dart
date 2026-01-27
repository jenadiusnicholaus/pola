import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/consultant_models.dart';
import '../services/credit_service.dart';
import 'dart:async';

class CreditPaymentScreen extends StatefulWidget {
  const CreditPaymentScreen({super.key});

  @override
  State<CreditPaymentScreen> createState() => _CreditPaymentScreenState();
}

class _CreditPaymentScreenState extends State<CreditPaymentScreen> {
  final CreditService _creditService = CreditService();
  final _phoneController = TextEditingController();

  CreditBundle? _bundle;
  String _selectedProvider = 'Mpesa';
  String _paymentStatus = 'idle'; // idle, pending, completed, failed
  int? _transactionId;
  Timer? _pollTimer;
  int _pollAttempts = 0;
  final int _maxPollAttempts = 60; // 5 minutes (60 * 5 seconds)

  final List<Map<String, dynamic>> _providers = [
    {'value': 'Mpesa', 'label': 'M-Pesa', 'icon': Icons.phone_android},
    {'value': 'Airtel', 'label': 'Airtel Money', 'icon': Icons.phone_iphone},
    {'value': 'Tigo', 'label': 'Tigo Pesa', 'icon': Icons.phone},
    {
      'value': 'Halopesa',
      'label': 'Halo Pesa',
      'icon': Icons.account_balance_wallet
    },
    {'value': 'Azampesa', 'label': 'Azam Pesa', 'icon': Icons.account_balance},
  ];

  @override
  void initState() {
    super.initState();
    _bundle = Get.arguments?['bundle'] as CreditBundle?;

    if (_bundle == null) {
      Get.back();
      Get.snackbar('Error', 'Invalid bundle selected');
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _initiatePayment() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      _showSnackBar('Please enter your phone number');
      return;
    }

    final formattedPhone = _formatPhoneNumber(phone);
    if (!_validatePhoneNumber(formattedPhone)) {
      _showSnackBar('Invalid phone number format');
      return;
    }

    setState(() {
      _paymentStatus = 'pending';
    });

    try {
      final result = await _creditService.purchaseBundle(
        bundleId: _bundle!.id,
        phoneNumber: formattedPhone,
        provider: _selectedProvider,
      );

      if (result['success'] == true) {
        _transactionId = result['transactionId'];

        // Show next steps to user
        final nextSteps = result['nextSteps'] as List<String>? ?? [];
        if (nextSteps.isNotEmpty) {
          _showSnackBar('Payment Initiated: ${nextSteps.join(', ')}', isError: false);
        }

        // Start polling for payment status
        _startPollingPaymentStatus();
      } else {
        setState(() {
          _paymentStatus = 'failed';
        });
        _showSnackBar(result['message'] ?? 'Payment failed');
      }
    } catch (e) {
      setState(() {
        _paymentStatus = 'failed';
      });
      _showSnackBar('Failed to initiate payment: $e');
    }
  }

  void _startPollingPaymentStatus() {
    _pollAttempts = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_pollAttempts >= _maxPollAttempts) {
        timer.cancel();
        setState(() {
          _paymentStatus = 'failed';
        });
        _showSnackBar('Payment verification timed out');
        return;
      }

      try {
        final status =
            await _creditService.checkPaymentStatus(_transactionId.toString());
        final paymentStatus = (status['status'] as String?)?.toLowerCase();

        if (paymentStatus == 'completed') {
          timer.cancel();
          setState(() {
            _paymentStatus = 'completed';
          });

          // Refresh credit balance
          Future.delayed(const Duration(seconds: 2), () {
            Get.back(result: {
              'success': true,
              'minutesAdded': status['minutes_added']
            });
          });
        } else if (paymentStatus == 'failed' || paymentStatus == 'cancelled') {
          timer.cancel();
          setState(() {
            _paymentStatus = 'failed';
          });
        }
      } catch (e) {
        // Continue polling on error
        debugPrint('Polling error: $e');
      }

      _pollAttempts++;
    });
  }

  String _formatPhoneNumber(String phone) {
    // Remove spaces and dashes
    phone = phone.replaceAll(RegExp(r'[\s-]'), '');

    // Convert to international format
    if (phone.startsWith('0')) {
      return '255${phone.substring(1)}';
    } else if (phone.startsWith('+255')) {
      return phone.substring(1);
    } else if (phone.startsWith('255')) {
      return phone;
    }

    // If phone is just the local number (9 digits starting with 6, 7, or 8)
    // prepend 255 country code
    if (phone.length == 9 && RegExp(r'^[6-8]\d{8}$').hasMatch(phone)) {
      return '255$phone';
    }

    return phone;
  }

  bool _validatePhoneNumber(String phone) {
    return RegExp(r'^255\d{9}$').hasMatch(phone);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_bundle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: const Center(child: Text('Invalid bundle')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
      ),
      body: _paymentStatus == 'pending'
          ? _buildPendingView(theme)
          : _paymentStatus == 'completed'
              ? _buildSuccessView(theme)
              : _paymentStatus == 'failed'
                  ? _buildFailedView(theme)
                  : _buildPaymentForm(theme),
    );
  }

  Widget _buildPaymentForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bundle Summary - Clean card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                // Package details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _bundle!.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_bundle!.minutes} min • Valid ${_bundle!.validityDays} days',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Price
                Text(
                  'TSh ${_bundle!.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Payment Provider Selection
          Text(
            'Payment Method',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          ..._providers.map((provider) {
            final isSelected = _selectedProvider == provider['value'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedProvider = provider['value'];
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withOpacity(0.2),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withOpacity(0.5),
                            width: isSelected ? 6 : 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          provider['label'],
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Phone Number Input
          Text(
            'Phone Number',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: '712 345 678',
              hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
              prefixText: '+255  ',
              prefixStyle: theme.textTheme.bodyLarge,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Pay Button - Subtle but clear
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _initiatePayment,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Pay TSh ${_bundle!.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Info Notice - Subtle
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You\'ll receive a prompt on your phone. Enter your PIN to confirm.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Processing Payment',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Check your phone for the payment prompt.\nEnter your PIN to complete.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 40,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment Successful',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+${_bundle!.minutes} minutes added',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Get.back(result: {'success': true}),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 40,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment Failed',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to complete the transaction',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  setState(() {
                    _paymentStatus = 'idle';
                  });
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
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

  Future<void> _initiatePayment() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      Get.snackbar('Error', 'Please enter your phone number');
      return;
    }

    final formattedPhone = _formatPhoneNumber(phone);
    if (!_validatePhoneNumber(formattedPhone)) {
      Get.snackbar('Error', 'Invalid phone number format');
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
          Get.snackbar(
            'Payment Initiated',
            nextSteps.join('\n'),
            duration: const Duration(seconds: 5),
            snackPosition: SnackPosition.BOTTOM,
          );
        }

        // Start polling for payment status
        _startPollingPaymentStatus();
      } else {
        setState(() {
          _paymentStatus = 'failed';
        });
        Get.snackbar('Error', result['message'] ?? 'Payment failed');
      }
    } catch (e) {
      setState(() {
        _paymentStatus = 'failed';
      });
      Get.snackbar('Error', 'Failed to initiate payment: $e');
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
        Get.snackbar('Timeout', 'Payment verification timed out');
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bundle Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.primaryContainer.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bundle!.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_bundle!.minutes} minutes',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          'Valid for ${_bundle!.validityDays} days',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _bundle!.priceFormatted,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Payment Provider Selection
          Text(
            'Select Payment Provider',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ..._providers.map((provider) {
            final isSelected = _selectedProvider == provider['value'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedProvider = provider['value'];
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        provider['icon'],
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          provider['label'],
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
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
            decoration: InputDecoration(
              hintText: '0712345678',
              prefixText: '+255 ',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              helperText: 'Enter your mobile money number',
            ),
          ),

          const SizedBox(height: 32),

          // Pay Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _initiatePayment,
              icon: const Icon(Icons.payment),
              label: Text('Pay ${_bundle!.priceFormatted}'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Info Notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You will receive a payment prompt on your phone. Enter your PIN to complete the transaction.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
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
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Processing Payment',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Check your phone for the payment prompt',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your PIN to complete the transaction',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.timer,
                    color: theme.colorScheme.secondary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we verify your payment',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Payment Successful!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Credits Added Successfully',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '+${_bundle!.minutes} minutes',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.access_time,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your credits are now available',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'You can start making calls!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Get.back(result: {'success': true}),
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Payment Failed',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to complete the transaction',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  setState(() {
                    _paymentStatus = 'idle';
                  });
                },
                child: const Text('Try Again'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

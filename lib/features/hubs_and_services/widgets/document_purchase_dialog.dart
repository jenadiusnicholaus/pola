import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../services/document_payment_service.dart';
import 'dart:async';

class DocumentPurchaseDialog extends StatefulWidget {
  final int documentId;
  final String documentTitle;
  final String price;
  final String currency;
  final String paymentCategory; // 'document' or 'material'

  const DocumentPurchaseDialog({
    super.key,
    required this.documentId,
    required this.documentTitle,
    required this.price,
    required this.currency,
    this.paymentCategory = 'document',
  });

  @override
  State<DocumentPurchaseDialog> createState() => _DocumentPurchaseDialogState();
}

class _DocumentPurchaseDialogState extends State<DocumentPurchaseDialog> {
  final DocumentPaymentService _paymentService = DocumentPaymentService();
  final _phoneController = TextEditingController();

  String _selectedProvider = 'Mpesa';
  String _paymentStatus = 'idle'; // idle, pending, completed, failed
  int? _transactionId;
  Timer? _pollTimer;
  int _pollAttempts = 0;
  final int _maxPollAttempts = 60;

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
    debugPrint('💳 DocumentPurchaseDialog opened');
    debugPrint('   Document ID: ${widget.documentId}');
    debugPrint('   Title: ${widget.documentTitle}');
    debugPrint('   Price: ${widget.currency} ${widget.price}');
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
      final result = await _paymentService.purchaseDocument(
        documentId: widget.documentId,
        phoneNumber: formattedPhone,
        provider: _selectedProvider,
        paymentCategory: widget.paymentCategory,
      );

      debugPrint('🔍 Payment Dialog - Received result from service');
      debugPrint('   Result keys: ${result.keys}');
      debugPrint('   Success value: ${result['success']}');
      debugPrint('   Success type: ${result['success'].runtimeType}');
      debugPrint('   Success == true: ${result['success'] == true}');

      if (result['success'] == true) {
        debugPrint('✅ Inside success block');

        try {
          _transactionId = result['transactionId'];
          debugPrint('   Got transaction ID: $_transactionId');
        } catch (e) {
          debugPrint('❌ Error getting transactionId: $e');
          throw e;
        }

        // Check if transaction is already completed in the initial response
        final transaction = result['transaction'] as Map<String, dynamic>?;
        final initialStatus =
            (transaction?['status'] as String?)?.toLowerCase();

        debugPrint('📊 Payment Dialog - Checking initial status');
        debugPrint('   Transaction ID: $_transactionId');
        debugPrint('   Transaction object exists: ${transaction != null}');
        debugPrint('   Initial status: $initialStatus');
        debugPrint('   Is completed: ${initialStatus == 'completed'}');

        if (initialStatus == 'completed') {
          // Payment completed immediately (test/instant payment)
          debugPrint('✅ Payment completed immediately! About to set state...');

          try {
            if (!mounted) {
              debugPrint('⚠️ Widget not mounted, cannot setState');
              return;
            }

            setState(() {
              debugPrint('   Setting _paymentStatus to completed...');
              _paymentStatus = 'completed';
            });

            debugPrint('   ✅ setState completed successfully');
            debugPrint('   Current payment status: $_paymentStatus');
          } catch (e) {
            debugPrint('❌ Error in setState: $e');
            rethrow;
          }

          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) {
              debugPrint('⚠️ Widget not mounted, cannot close dialog');
              return;
            }
            debugPrint('🚪 Closing dialog with success result');
            Get.back(
                result: {'success': true, 'documentId': widget.documentId});
          });
        } else {
          // Payment pending - start polling
          final nextSteps = result['nextSteps'] as List<String>? ?? [];
          if (nextSteps.isNotEmpty) {
            Get.snackbar(
              'Payment Initiated',
              nextSteps.join('\n'),
              duration: const Duration(seconds: 5),
              snackPosition: SnackPosition.BOTTOM,
            );
          }

          _startPollingPaymentStatus();
        }
      } else {
        setState(() {
          _paymentStatus = 'failed';
        });
        Get.snackbar('Error', result['message'] ?? 'Payment failed');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ EXCEPTION in payment dialog: $e');
      debugPrint('📚 Stack trace: $stackTrace');
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
            await _paymentService.checkPaymentStatus(_transactionId.toString());
        final paymentStatus = (status['status'] as String?)?.toLowerCase();

        if (paymentStatus == 'completed') {
          timer.cancel();
          setState(() {
            _paymentStatus = 'completed';
          });

          Future.delayed(const Duration(seconds: 2), () {
            Get.back(
                result: {'success': true, 'documentId': widget.documentId});
          });
        } else if (paymentStatus == 'failed' || paymentStatus == 'cancelled') {
          timer.cancel();
          setState(() {
            _paymentStatus = 'failed';
          });
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      }

      _pollAttempts++;
    });
  }

  String _formatPhoneNumber(String phone) {
    phone = phone.replaceAll(RegExp(r'[\s-]'), '');

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

    debugPrint(
        '🎨 Building DocumentPurchaseDialog with status: $_paymentStatus');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: _paymentStatus == 'pending'
            ? _buildPendingView(theme)
            : _paymentStatus == 'completed'
                ? _buildSuccessView(theme)
                : _paymentStatus == 'failed'
                    ? _buildFailedView(theme)
                    : _buildPaymentForm(theme),
      ),
    );
  }

  Widget _buildPaymentForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Purchase Document',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Document Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.documentTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Price:',
                      style: theme.textTheme.bodyLarge,
                    ),
                    Text(
                      '${widget.currency} ${widget.price}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Benefits
          Text(
            'What you\'ll get:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...[
            'Full document access without watermark',
            'Download anytime, anywhere',
            'Lifetime access to the document',
            'Print-ready format',
          ].map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 24),

          // Payment Provider
          Text(
            'Select Payment Provider',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
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
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        provider['icon'],
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        provider['label'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Phone Number
          Text(
            'Phone Number',
            style: theme.textTheme.titleSmall?.copyWith(
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
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Pay Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _initiatePayment,
              child: Text('Pay ${widget.currency} ${widget.price}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingView(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 5,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Processing Payment',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Check your phone for the payment prompt',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your PIN to complete the transaction',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 48,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Purchase Complete!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You can now access this document',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Get.back(result: {'success': true}),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedView(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Payment Failed',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to complete the transaction',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

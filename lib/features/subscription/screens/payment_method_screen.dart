import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/subscription_models.dart';
import '../services/subscription_service.dart';
import 'payment_status_screen.dart';

class PaymentMethodScreen extends StatefulWidget {
  final SubscriptionPlan plan;

  const PaymentMethodScreen({super.key, required this.plan});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String? selectedProvider;
  bool isProcessing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Method'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan summary card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            color: Colors.amber,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Selected Plan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.plan.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.plan.nameSwahili,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${widget.plan.currency} ${widget.plan.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Payment method selection
              Text(
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose your preferred mobile money service',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),

              ...PaymentMethod.availableMethods.map(
                (method) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selectedProvider == method.provider
                          ? theme.colorScheme.primary
                          : Colors.grey.shade300,
                      width: selectedProvider == method.provider ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: selectedProvider == method.provider
                        ? theme.colorScheme.primary.withOpacity(0.05)
                        : null,
                  ),
                  child: RadioListTile<String>(
                    value: method.provider,
                    groupValue: selectedProvider,
                    onChanged: (value) =>
                        setState(() => selectedProvider = value),
                    title: Text(
                      method.name,
                      style: TextStyle(
                        fontWeight: selectedProvider == method.provider
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    secondary: Icon(
                      method.icon,
                      color: selectedProvider == method.provider
                          ? theme.colorScheme.primary
                          : Colors.grey,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Phone number input
              Text(
                'Phone Number',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Mobile Money Number',
                  hintText: '+255 XXX XXX XXX or 07XX XXX XXX',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: theme.brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade50,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  // Remove spaces and check format
                  final cleaned = value.replaceAll(' ', '');
                  if (!cleaned.startsWith('+255') && !cleaned.startsWith('0')) {
                    return 'Enter a valid Tanzanian phone number';
                  }
                  if (cleaned.startsWith('0') && cleaned.length != 10) {
                    return 'Phone number must be 10 digits (07XX XXX XXX)';
                  }
                  if (cleaned.startsWith('+255') && cleaned.length != 13) {
                    return 'Phone number must be 13 digits (+255 XXX XXX XXX)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You will receive a USSD prompt on your phone to complete the payment',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Subscribe button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isProcessing ? null : _handlePayment,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Pay Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Security note
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Secure payment powered by AzamPay',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
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

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedProvider == null) {
      Get.snackbar(
        'Payment Method Required',
        'Please select a payment method to continue',
        icon: const Icon(Icons.warning_amber, color: Colors.white),
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => isProcessing = true);

    try {
      final subscriptionService = Get.find<SubscriptionService>();
      final result = await subscriptionService.subscribe(
        planId: widget.plan.id,
        phoneNumber: _phoneController.text.trim(),
        paymentMethod: selectedProvider!,
      );

      setState(() => isProcessing = false);

      if (result.success && result.transactionId != null) {
        // Navigate to payment status screen
        Get.off(
          () => PaymentStatusScreen(
            transactionId: result.transactionId!,
            plan: widget.plan,
          ),
        );
      } else {
        Get.snackbar(
          'Payment Failed',
          result.message,
          icon: const Icon(Icons.error_outline, color: Colors.white),
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      setState(() => isProcessing = false);

      debugPrint('Payment error: $e');
      Get.snackbar(
        'Error',
        'An error occurred while processing your payment. Please try again.',
        icon: const Icon(Icons.error_outline, color: Colors.white),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }
}

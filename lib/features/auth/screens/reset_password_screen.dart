import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/reset_password_controller.dart';
import '../../../constants/app_colors.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<ResetPasswordController>()) {
      Get.delete<ResetPasswordController>();
    }
    final controller = Get.put(ResetPasswordController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Reset Code'),
        backgroundColor: AppColors.primaryAmber,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 8),
              Text(
                'Code sent to',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.65),
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                controller.email,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Enter the 6-digit code from your email to continue.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.65),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 28),
              TextFormField(
                controller: controller.otpController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: controller.validateOtp,
                onFieldSubmitted: (_) => controller.submit(),
                decoration: InputDecoration(
                  labelText: tr('6-digit OTP'),
                  hintText: 'Enter code',
                  prefixIcon: Icon(Icons.pin_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Obx(
                () => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAmber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(tr('Verify Code'),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => TextButton(
                  onPressed:
                      controller.isResending.value ? null : controller.resendOtp,
                  child: controller.isResending.value
                      ? const Text('Resending...')
                      : const Text('Resend code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import '../controllers/set_new_password_controller.dart';
import '../../../constants/app_colors.dart';

class SetNewPasswordScreen extends StatelessWidget {
  const SetNewPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<SetNewPasswordController>()) {
      Get.delete<SetNewPasswordController>();
    }
    final controller = Get.put(SetNewPasswordController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Set New Password')),
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
                'Create a new password for your account.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.65),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 28),
              Obx(
                () => TextFormField(
                  controller: controller.passwordController,
                  obscureText: controller.obscurePassword.value,
                  textInputAction: TextInputAction.next,
                  validator: controller.validatePassword,
                  decoration: InputDecoration(
                    labelText: tr('New Password'),
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.obscurePassword.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => controller.obscurePassword.toggle(),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Obx(
                () => TextFormField(
                  controller: controller.confirmPasswordController,
                  obscureText: controller.obscureConfirm.value,
                  textInputAction: TextInputAction.done,
                  validator: controller.validateConfirmPassword,
                  onFieldSubmitted: (_) => controller.submit(),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.obscureConfirm.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => controller.obscureConfirm.toggle(),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                      : Text(tr('Reset Password'),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

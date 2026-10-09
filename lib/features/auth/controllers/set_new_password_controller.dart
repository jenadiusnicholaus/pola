import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/navigation_helper.dart';

/// Step 2: set new password after OTP was verified.
class SetNewPasswordController extends GetxController {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxBool obscureConfirm = true.obs;

  late final String email;
  late final String otp;

  AuthService get _authService => Get.find<AuthService>();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      email = (args['email'] ?? '').toString();
      otp = (args['otp'] ?? '').toString();
    } else {
      email = '';
      otp = '';
    }
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (email.isEmpty || otp.isEmpty) {
      NavigationHelper.showSafeSnackbar(
        title: tr('Error'),
        message: 'Missing reset details. Start again from forgot password.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      final result = await _authService.confirmPasswordReset(
        email: email,
        otp: otp,
        newPassword: passwordController.text,
        newPasswordConfirm: confirmPasswordController.text,
      );

      if (result['success'] == true) {
        NavigationHelper.showSafeSnackbar(
          title: tr('Success'),
          message: result['message']?.toString() ??
              'Password reset successful. Please log in.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.offAllNamed(AppRoutes.login);
      } else {
        NavigationHelper.showSafeSnackbar(
          title: tr('Error'),
          message: result['error']?.toString() ?? 'Reset failed',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}

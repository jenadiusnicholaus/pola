import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/navigation_helper.dart';

/// Step 1: enter OTP only (no password fields, no autofill).
class ResetPasswordController extends GetxController {
  final otpController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final RxBool isLoading = false.obs;
  final RxBool isResending = false.obs;

  late final String email;

  AuthService get _authService => Get.find<AuthService>();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    email = args is Map ? (args['email'] ?? '').toString() : '';
  }

  String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) return 'OTP is required';
    if (value.trim().length != 6 || int.tryParse(value.trim()) == null) {
      return 'Enter the 6-digit code';
    }
    return null;
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (email.isEmpty) {
      NavigationHelper.showSafeSnackbar(
        title: tr('Error'),
        message: 'Missing email. Go back and try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      final otp = otpController.text.trim();
      final result = await _authService.verifyPasswordResetOtp(
        email: email,
        otp: otp,
      );

      if (result['success'] == true) {
        Get.toNamed(
          AppRoutes.setNewPassword,
          arguments: {'email': email, 'otp': otp},
        );
      } else {
        NavigationHelper.showSafeSnackbar(
          title: tr('Error'),
          message: result['error']?.toString() ?? 'Invalid or expired code',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (email.isEmpty || isResending.value) return;
    isResending.value = true;
    try {
      final result = await _authService.requestPasswordReset(email);
      if (result['success'] == true) {
        otpController.clear();
        NavigationHelper.showSafeSnackbar(
          title: 'Code sent',
          message: 'A new reset code has been sent to your email.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        NavigationHelper.showSafeSnackbar(
          title: tr('Error'),
          message: result['error']?.toString() ?? 'Could not resend code',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isResending.value = false;
    }
  }

  @override
  void onClose() {
    otpController.dispose();
    super.onClose();
  }
}

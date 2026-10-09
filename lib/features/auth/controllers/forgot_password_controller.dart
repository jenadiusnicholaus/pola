import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/navigation_helper.dart';

class ForgotPasswordController extends GetxController {
  final emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final RxBool isLoading = false.obs;

  AuthService get _authService => Get.find<AuthService>();

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;
    try {
      final email = emailController.text.trim();
      final result = await _authService.requestPasswordReset(email);

      if (result['success'] == true) {
        NavigationHelper.showSafeSnackbar(
          title: tr('Check your email'),
          message: result['message']?.toString() ??
              'If an account exists, a reset code was sent.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        Get.toNamed(
          AppRoutes.resetPassword,
          arguments: {
            'email': email,
          },
        );
      } else {
        NavigationHelper.showSafeSnackbar(
          title: tr('Error'),
          message: result['error']?.toString() ?? 'Request failed',
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
    emailController.dispose();
    super.onClose();
  }
}

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import '../../../services/device_registration_service.dart';
import '../../../services/auth_service.dart';
import '../../../routes/app_routes.dart';

class DeviceVerificationController extends GetxController {
  final DeviceRegistrationService _deviceService =
      Get.find<DeviceRegistrationService>();

  final RxBool isLoading = false.obs;
  final RxBool isVerifying = false.obs;
  final RxBool isResending = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;

  late final String deviceId;
  late final String deviceName;
  late final bool isTakeover;
  late final String newUserEmail;
  late final String takeoverMessage;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    deviceId = args?['device_id'] as String? ?? '';
    deviceName = args?['device_name'] as String? ?? 'this device';
    isTakeover = args?['is_takeover'] as bool? ?? false;
    newUserEmail = args?['new_user_email'] as String? ?? '';
    takeoverMessage = args?['takeover_message'] as String? ?? '';

    // Fallback: if deviceId is empty, try reading from the service
    // (handles navigation race conditions where Get.arguments is lost)
    if (deviceId.isEmpty) {
      debugPrint(
          '⚠️ DeviceVerificationController: Get.arguments empty, trying service fallback...');
      if (_deviceService.isTakeoverFlow) {
        isTakeover = true;
        deviceId = _deviceService.pendingTakeoverDeviceId ?? '';
        newUserEmail = _deviceService.pendingTakeoverNewUserEmail ?? '';
      } else {
        deviceId = _deviceService.pendingDevicePk ?? '';
      }
      deviceName = _deviceService.pendingDeviceName ?? 'this device';
    }

    debugPrint(
        '📱 DeviceVerificationController: deviceId=$deviceId, isTakeover=$isTakeover');
  }

  Future<void> verifyOtp(String otp) async {
    if (deviceId.isEmpty) {
      errorMessage.value =
          'Device ID is missing. Please logout and login again.';
      return;
    }
    if (otp.length != 6) {
      errorMessage.value = 'Please enter the 6-digit code';
      return;
    }

    isVerifying.value = true;
    errorMessage.value = '';
    successMessage.value = '';

    try {
      bool success;
      if (isTakeover) {
        success = await _deviceService.verifyOtpForTakeover(
          otp: otp,
          deviceId: deviceId,
          newUserEmail: newUserEmail,
        );
      } else {
        success = await _deviceService.verifyOtp(deviceId, otp);
      }

      if (success) {
        successMessage.value = 'Device verified successfully!';
        debugPrint('✅ Device verified, navigating to home');
        _deviceService.pendingDevicePk = null;
        _deviceService.pendingDeviceName = null;
        _deviceService.pendingTakeoverDeviceId = null;
        _deviceService.pendingTakeoverNewUserEmail = null;
        _deviceService.isTakeoverFlow = false;

        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(AppRoutes.home);
      } else {
        errorMessage.value =
            'Verification failed. Please check your code and try again.';
      }
    } catch (e) {
      debugPrint('❌ Error verifying OTP: $e');
      errorMessage.value = 'An error occurred. Please try again.';
    } finally {
      isVerifying.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (deviceId.isEmpty) {
      errorMessage.value =
          'Device ID is missing. Please logout and login again.';
      return;
    }
    isResending.value = true;
    errorMessage.value = '';
    successMessage.value = '';

    try {
      bool success;
      if (isTakeover) {
        // For takeover, re-register the device to trigger a new OTP to the current owner
        String? fcmToken;
        try {
          fcmToken = await FirebaseMessaging.instance.getToken();
        } catch (_) {}
        final result = await _deviceService.registerDevice(fcmToken: fcmToken);
        success =
            result?.deviceTakeoverRequired == true && result?.otpSent == true;
      } else {
        success = await _deviceService.sendVerificationOtp(deviceId);
      }

      if (success) {
        successMessage.value = isTakeover
            ? 'OTP sent to the current device owner'
            : 'OTP sent to your email';
      } else {
        errorMessage.value = 'Failed to resend OTP. Please try again.';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred. Please try again.';
    } finally {
      isResending.value = false;
    }
  }

  Future<void> logout() async {
    try {
      if (Get.isRegistered<AuthService>()) {
        final authService = Get.find<AuthService>();
        await authService.logout();
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      debugPrint('❌ Error during logout: $e');
      Get.offAllNamed(AppRoutes.login);
    }
  }
}

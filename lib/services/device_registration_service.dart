import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/device_model.dart';
import 'api_service.dart';
import 'device_info_service.dart';
import '../config/environment_config.dart';

class DeviceRegistrationService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();
  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  /// Stores the pending device PK that needs OTP verification.
  /// Used as fallback if Get.arguments is lost during navigation.
  String? pendingDevicePk;
  String? pendingDeviceName;
  // Device takeover fields
  String? pendingTakeoverDeviceId;
  String? pendingTakeoverNewUserEmail;
  bool isTakeoverFlow = false;

  /// Register or update device with the backend.
  /// Returns a [DeviceRegistrationResult] that includes verification status.
  Future<DeviceRegistrationResult?> registerDevice({String? fcmToken}) async {
    try {
      debugPrint('📱 Starting device registration...');

      // Collect device information
      var deviceInfo = await _deviceInfoService.collectDeviceInfo();

      // Create new DeviceInfo with FCM token if provided
      if (fcmToken != null) {
        deviceInfo = DeviceInfo(
          deviceId: deviceInfo.deviceId,
          deviceName: deviceInfo.deviceName,
          deviceType: deviceInfo.deviceType,
          osName: deviceInfo.osName,
          osVersion: deviceInfo.osVersion,
          browserName: deviceInfo.browserName,
          browserVersion: deviceInfo.browserVersion,
          appVersion: deviceInfo.appVersion,
          deviceModel: deviceInfo.deviceModel,
          deviceManufacturer: deviceInfo.deviceManufacturer,
          fcmToken: fcmToken,
          latitude: deviceInfo.latitude,
          longitude: deviceInfo.longitude,
        );
      }

      debugPrint('📱 Device Info collected:');
      debugPrint('  - Device ID: ${deviceInfo.deviceId}');
      debugPrint('  - Device Name: ${deviceInfo.deviceName}');
      debugPrint('  - Device Type: ${deviceInfo.deviceType}');
      debugPrint('  - OS: ${deviceInfo.osName} ${deviceInfo.osVersion}');
      debugPrint('  - Model: ${deviceInfo.deviceModel}');
      debugPrint(
          '  - FCM Token: ${deviceInfo.fcmToken != null ? "${deviceInfo.fcmToken?.substring(0, 20)}..." : "null"}');
      debugPrint(
          '  - Location: ${deviceInfo.latitude}, ${deviceInfo.longitude}');

      // If location is missing, note it but continue (location is optional)
      if (deviceInfo.latitude == null || deviceInfo.longitude == null) {
        debugPrint(
            '⚠️ Location not available, registering without it (can update later)');
      }

      // Register device with backend
      final response = await _apiService.post(
        EnvironmentConfig.deviceRegistrationUrl,
        data: deviceInfo.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = DeviceRegistrationResult.fromJson(
            response.data as Map<String, dynamic>);

        debugPrint('✅ Device registered successfully!');
        debugPrint('  - Is Verified: ${result.isVerified}');
        debugPrint('  - Verification Required: ${result.verificationRequired}');
        debugPrint('  - OTP Sent: ${result.otpSent}');
        debugPrint('  - Device PK: ${result.devicePkForVerification}');

        // Store pending device info for OTP verification fallback
        if (result.verificationRequired && !result.isVerified) {
          pendingDevicePk = result.devicePkForVerification;
          pendingDeviceName = result.deviceNameForVerification;
          debugPrint('📱 Stored pending device PK: $pendingDevicePk');
        }

        // Store takeover info if device takeover is required
        if (result.deviceTakeoverRequired) {
          isTakeoverFlow = true;
          pendingTakeoverDeviceId =
              result.rawDeviceId ?? result.currentDeviceId;
          pendingTakeoverNewUserEmail = result.newUserEmail;
          debugPrint(
              '📱 Stored takeover info: deviceId=$pendingTakeoverDeviceId, newUserEmail=$pendingTakeoverNewUserEmail');
        }

        // Check for missing fields and update them
        final missingFields = response.data['missing_fields'];
        if (missingFields != null &&
            missingFields is List &&
            missingFields.isNotEmpty &&
            result.device != null) {
          debugPrint('⚠️ Missing fields detected: $missingFields');
          await _updateMissingFields(
              result.device!.id, List<String>.from(missingFields));
        }

        // If location is missing, try to update it even if not in missing_fields
        if (deviceInfo.latitude == null || deviceInfo.longitude == null) {
          debugPrint('📍 Location data missing, attempting to update...');
          await updateLocation();
        }

        return result;
      } else {
        debugPrint('❌ Device registration failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Check if this is a device takeover response (may come as DioException
      // with non-200 status, or as a 200 with device_takeover_required: true)
      if (e is DioException && e.response != null) {
        final responseData = e.response!.data;
        Map<String, dynamic>? parsed;
        if (responseData is Map<String, dynamic>) {
          parsed = responseData;
        } else if (responseData is String) {
          try {
            final decoded = jsonDecode(responseData);
            if (decoded is Map<String, dynamic>) parsed = decoded;
          } catch (_) {}
        }

        if (parsed != null) {
          // Check for device takeover response
          if (parsed['device_takeover_required'] == true) {
            debugPrint('🔄 Device takeover required (from error response)');
            final result = DeviceRegistrationResult.fromJson(parsed);
            isTakeoverFlow = true;
            pendingTakeoverDeviceId =
                result.rawDeviceId ?? result.currentDeviceId;
            pendingTakeoverNewUserEmail = result.newUserEmail;
            debugPrint(
                '📱 Stored takeover info: deviceId=$pendingTakeoverDeviceId, newUserEmail=$pendingTakeoverNewUserEmail');
            return result;
          }

          // Check for "already registered to another account" error
          // or duplicate key constraint error, and retry with a fresh device ID
          final errorMessage = parsed['error']?.toString();
          if (errorMessage ==
                  'This device is already registered to another account' ||
              (errorMessage != null &&
                  errorMessage.contains('duplicate key value') &&
                  errorMessage.contains('device_id'))) {
            debugPrint(
                '🔄 Device already registered to another account — generating new device ID and retrying...');
            _deviceInfoService.clearDeviceId();
            return _registerWithRetry(fcmToken: fcmToken);
          }
        }
      }
      debugPrint('❌ Error registering device: $e');
      return null;
    }
  }

  /// Internal retry after clearing device ID
  Future<DeviceRegistrationResult?> _registerWithRetry(
      {String? fcmToken}) async {
    try {
      var deviceInfo = await _deviceInfoService.collectDeviceInfo();

      if (fcmToken != null) {
        deviceInfo = DeviceInfo(
          deviceId: deviceInfo.deviceId,
          deviceName: deviceInfo.deviceName,
          deviceType: deviceInfo.deviceType,
          osName: deviceInfo.osName,
          osVersion: deviceInfo.osVersion,
          browserName: deviceInfo.browserName,
          browserVersion: deviceInfo.browserVersion,
          appVersion: deviceInfo.appVersion,
          deviceModel: deviceInfo.deviceModel,
          deviceManufacturer: deviceInfo.deviceManufacturer,
          fcmToken: fcmToken,
          latitude: deviceInfo.latitude,
          longitude: deviceInfo.longitude,
        );
      }

      debugPrint(
          '📱 Retrying device registration with new device ID: ${deviceInfo.deviceId}');

      final response = await _apiService.post(
        EnvironmentConfig.deviceRegistrationUrl,
        data: deviceInfo.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = DeviceRegistrationResult.fromJson(
            response.data as Map<String, dynamic>);

        debugPrint('✅ Device registered on retry!');
        debugPrint('  - Is Verified: ${result.isVerified}');
        debugPrint('  - Verification Required: ${result.verificationRequired}');
        debugPrint('  - Device PK: ${result.devicePkForVerification}');

        if (result.verificationRequired && !result.isVerified) {
          pendingDevicePk = result.devicePkForVerification;
          pendingDeviceName = result.deviceNameForVerification;
          debugPrint('📱 Stored pending device PK: $pendingDevicePk');
        }

        return result;
      }
      return null;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final responseData = e.response!.data;
        Map<String, dynamic>? parsed;
        if (responseData is Map<String, dynamic>) {
          parsed = responseData;
        } else if (responseData is String) {
          try {
            final decoded = jsonDecode(responseData);
            if (decoded is Map<String, dynamic>) parsed = decoded;
          } catch (_) {}
        }

        if (parsed != null) {
          if (parsed['device_takeover_required'] == true) {
            debugPrint('🔄 Device takeover required (from retry response)');
            final result = DeviceRegistrationResult.fromJson(parsed);
            isTakeoverFlow = true;
            pendingTakeoverDeviceId =
                result.rawDeviceId ?? result.currentDeviceId;
            pendingTakeoverNewUserEmail = result.newUserEmail;
            return result;
          }
        }
      }
      debugPrint('❌ Retry also failed: $e');
      return null;
    }
  }

  /// Update missing fields for a registered device
  Future<void> _updateMissingFields(
      int deviceId, List<String> missingFields) async {
    try {
      debugPrint('🔄 Updating missing fields: $missingFields');

      final Map<String, dynamic> updateData = {};

      // Get missing location
      if (missingFields.contains('latitude') ||
          missingFields.contains('longitude')) {
        final position = await _deviceInfoService.getLocation();
        if (position != null) {
          updateData['latitude'] = position.latitude;
          updateData['longitude'] = position.longitude;
          debugPrint(
              '✅ Added location data: ${position.latitude}, ${position.longitude}');
        } else {
          debugPrint('⚠️ Could not get location data');
        }
      }

      // Get missing device name
      if (missingFields.contains('device_name')) {
        final deviceInfo = await _deviceInfoService.collectDeviceInfo();
        if (deviceInfo.deviceName != null) {
          updateData['device_name'] = deviceInfo.deviceName;
          debugPrint('✅ Added device name: ${deviceInfo.deviceName}');
        }
      }

      // Get missing FCM token
      if (missingFields.contains('fcm_token')) {
        final fcmToken = await _deviceInfoService.getFcmToken();
        if (fcmToken != null) {
          updateData['fcm_token'] = fcmToken;
          debugPrint('✅ Added FCM token');
        }
      }

      // Send PATCH request if we have data to update
      if (updateData.isNotEmpty) {
        final response = await _apiService.patch(
          '${EnvironmentConfig.deviceRegistrationUrl}$deviceId/',
          data: updateData,
        );

        if (response.statusCode == 200) {
          debugPrint('✅ Missing fields updated successfully');
        } else {
          debugPrint(
              '⚠️ Failed to update missing fields: ${response.statusCode}');
        }
      } else {
        debugPrint('⚠️ No data available to update missing fields');
      }
    } catch (e) {
      debugPrint('❌ Error updating missing fields: $e');
    }
  }

  /// Update FCM token for the current device using PATCH endpoint
  /// Uses /api/v1/security/devices/update_current_device_token/ which is simpler
  /// as it automatically finds the current device based on the authenticated user
  Future<bool> updateFcmToken({String? fcmToken}) async {
    try {
      debugPrint('🔔 Updating FCM token via PATCH...');

      final token = fcmToken ?? await _deviceInfoService.getFcmToken();

      if (token == null) {
        debugPrint('⚠️ No FCM token available');
        return false;
      }

      debugPrint('🔑 FCM Token: ${token.substring(0, 20)}...');

      // Use the update_current_device_token endpoint - simpler, no device_id needed
      final response = await _apiService.patch(
        EnvironmentConfig.deviceUpdateCurrentFcmTokenUrl,
        data: {
          'fcm_token': token,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM token updated successfully via PATCH');
        return true;
      } else if (response.statusCode == 404) {
        // Device not registered yet, do full registration
        debugPrint('⚠️ No current device found, doing full registration...');
        final result = await registerDevice(fcmToken: token);
        return result != null;
      } else {
        debugPrint('⚠️ FCM token PATCH failed: ${response.statusCode}');
        // Fall back to full device registration
        debugPrint('🔄 Falling back to full device registration...');
        final result = await registerDevice(fcmToken: token);
        return result != null;
      }
    } catch (e) {
      debugPrint('❌ Error updating FCM token: $e');
      // Fall back to full device registration on error
      try {
        final token = fcmToken ?? await _deviceInfoService.getFcmToken();
        if (token != null) {
          debugPrint('🔄 Falling back to full device registration...');
          final result = await registerDevice(fcmToken: token);
          return result != null;
        }
      } catch (_) {}
      return false;
    }
  }

  /// Send (or resend) verification OTP for a device.
  /// [deviceId] is the string device_id (not the numeric primary key).
  /// [method] defaults to 'email'.
  Future<bool> sendVerificationOtp(String deviceId,
      {String method = 'email'}) async {
    try {
      debugPrint('📧 Sending verification OTP for device $deviceId...');

      final response = await _apiService.post(
        EnvironmentConfig.getSendVerificationOtpUrl(deviceId),
        data: {'method': method},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Verification OTP sent successfully');
        return true;
      } else {
        debugPrint('⚠️ Failed to send OTP: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending verification OTP: $e');
      return false;
    }
  }

  /// Verify OTP for a device. On success the device becomes the current device.
  /// [deviceId] is the string device_id (not the numeric primary key).
  Future<bool> verifyOtp(String deviceId, String otp) async {
    try {
      debugPrint('🔐 Verifying OTP for device $deviceId...');

      final response = await _apiService.post(
        EnvironmentConfig.getVerifyOtpUrl(deviceId),
        data: {'otp': otp},
      );

      if (response.statusCode == 200) {
        final success = response.data['success'] as bool? ?? true;
        debugPrint('✅ Device verified: $success');
        return success;
      } else {
        debugPrint('❌ OTP verification failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error verifying OTP: $e');
      return false;
    }
  }

  /// Verify OTP for device takeover.
  /// Requires the string device_id, OTP, and new_user_email.
  Future<bool> verifyOtpForTakeover({
    required String otp,
    required String deviceId,
    required String newUserEmail,
  }) async {
    try {
      debugPrint(
          '🔐 Verifying OTP for device takeover: device=$deviceId, newUser=$newUserEmail...');

      final response = await _apiService.post(
        EnvironmentConfig.verifyOtpForTakeoverUrl,
        data: {
          'otp': otp,
          'device_id': deviceId,
          'new_user_email': newUserEmail,
        },
      );

      if (response.statusCode == 200) {
        final message = response.data['message'] as String? ?? '';
        final isVerified = response.data['is_verified'] as bool? ?? true;
        debugPrint('✅ Device takeover successful: $message');
        // Clear takeover state
        isTakeoverFlow = false;
        pendingTakeoverDeviceId = null;
        pendingTakeoverNewUserEmail = null;
        return isVerified;
      } else {
        debugPrint(
            '❌ Device takeover verification failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error verifying OTP for takeover: $e');
      return false;
    }
  }

  /// Update FCM token for a specific device by device_id
  /// Uses /api/v1/security/devices/{id}/update_fcm_token/
  Future<bool> updateFcmTokenForDevice(String deviceId, String fcmToken) async {
    try {
      debugPrint('🔔 Updating FCM token for device $deviceId...');

      final response = await _apiService.patch(
        EnvironmentConfig.getDeviceUpdateFcmTokenUrl(deviceId),
        data: {
          'fcm_token': fcmToken,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM token updated for device $deviceId');
        return true;
      } else {
        debugPrint('⚠️ FCM token update failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error updating FCM token for device: $e');
      return false;
    }
  }

  /// Update device location (can be called periodically)
  Future<void> updateLocation() async {
    try {
      debugPrint('📍 Attempting to update device location...');

      final deviceId = await _deviceInfoService.getDeviceId();
      final position = await _deviceInfoService.getLocation();

      if (position == null) {
        debugPrint('⚠️ Location permission denied or unavailable');
        // Still try to register device with available info
        debugPrint('📍 Registering device info without location...');
        await _apiService.post(
          EnvironmentConfig.deviceRegistrationUrl,
          data: {
            'device_id': deviceId,
          },
        );
        return;
      }

      debugPrint(
          '📍 Location obtained: ${position.latitude}, ${position.longitude}');

      final response = await _apiService.post(
        EnvironmentConfig.deviceRegistrationUrl,
        data: {
          'device_id': deviceId,
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Location updated successfully');
        debugPrint('  - Latitude: ${position.latitude}');
        debugPrint('  - Longitude: ${position.longitude}');
      } else {
        debugPrint('⚠️ Failed to update location: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error updating location: $e');
      // Don't throw error, location update is non-critical
    }
  }

  /// Retry location update with retry mechanism
  Future<void> retryLocationUpdate({int maxRetries = 3}) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      attempts++;
      debugPrint('📍 Location update attempt $attempts of $maxRetries');

      try {
        final position = await _deviceInfoService.getLocation();

        if (position != null) {
          await updateLocation();
          debugPrint('✅ Location update successful on attempt $attempts');
          return;
        }

        // Wait before retry (exponential backoff)
        if (attempts < maxRetries) {
          final waitTime = Duration(seconds: attempts * 5);
          debugPrint('⏳ Waiting ${waitTime.inSeconds}s before retry...');
          await Future.delayed(waitTime);
        }
      } catch (e) {
        debugPrint('❌ Location update attempt $attempts failed: $e');
        if (attempts >= maxRetries) {
          debugPrint('⚠️ Max retries reached, giving up on location update');
        }
      }
    }
  }

  /// Get list of all registered devices
  Future<List<RegisteredDevice>> getDevices() async {
    try {
      debugPrint('📱 Fetching registered devices...');

      final response =
          await _apiService.get(EnvironmentConfig.deviceRegistrationUrl);

      if (response.statusCode == 200) {
        final List<dynamic> devicesJson =
            response.data['results'] ?? response.data;
        final devices =
            devicesJson.map((json) => RegisteredDevice.fromJson(json)).toList();

        debugPrint('✅ Found ${devices.length} registered devices');
        return devices;
      } else {
        debugPrint('❌ Failed to fetch devices: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching devices: $e');
      return [];
    }
  }

  /// Remove/deactivate a device
  Future<bool> removeDevice(int deviceId) async {
    try {
      debugPrint('🗑️ Removing device $deviceId...');

      final response = await _apiService.delete(
        '${EnvironmentConfig.deviceRegistrationUrl}$deviceId/',
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        debugPrint('✅ Device removed successfully');
        return true;
      } else {
        debugPrint('❌ Failed to remove device: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error removing device: $e');
      return false;
    }
  }

  /// Check device status via the check_device endpoint.
  /// Returns a [DeviceCheckResult] indicating what action is needed.
  Future<DeviceCheckResult> checkDevice() async {
    try {
      final deviceInfo = await _deviceInfoService.collectDeviceInfo();
      final deviceId = deviceInfo.deviceId;

      debugPrint('🔍 Checking device status for: $deviceId');

      final response = await _apiService.post(
        EnvironmentConfig.checkDeviceUrl,
        data: {
          'device_id': deviceId,
          'device_name': deviceInfo.deviceName,
          'device_type': deviceInfo.deviceType,
          'os_name': deviceInfo.osName,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final result = DeviceCheckResult.fromJson(data);
        debugPrint(
            '📱 Device check result: actionRequired=${result.actionRequired}, isVerified=${result.isVerified}, isCurrentDevice=${result.isCurrentDevice}');
        return result;
      } else {
        debugPrint('❌ Device check failed: ${response.statusCode}');
        return DeviceCheckResult(
          deviceRegistered: false,
          isVerified: false,
          isCurrentDevice: false,
          actionRequired: 'register',
          message: 'Device check failed',
        );
      }
    } catch (e) {
      debugPrint('❌ Error checking device: $e');
      return DeviceCheckResult(
        deviceRegistered: false,
        isVerified: false,
        isCurrentDevice: false,
        actionRequired: 'register',
        message: 'Device check error: $e',
      );
    }
  }

  /// Full device check + action flow for returning users.
  /// 1. Calls check_device
  /// 2. If action_required == "register" → registers the device
  /// 3. If action_required == "verify_otp" → returns result for OTP screen
  /// 4. If action_required == "verify_otp_for_takeover" → returns result for takeover OTP screen
  /// 5. If action_required == null → device is fine, proceed
  Future<DeviceCheckResult> checkAndHandleDevice() async {
    final checkResult = await checkDevice();

    switch (checkResult.actionRequired) {
      case null:
        debugPrint('✅ Device is verified and current — no action needed');
        return checkResult;

      case 'register':
        debugPrint('📱 Device not registered — registering...');
        String? fcmToken;
        try {
          fcmToken = await FirebaseMessaging.instance.getToken();
        } catch (_) {}
        final regResult = await registerDevice(fcmToken: fcmToken);
        if (regResult != null && regResult.deviceTakeoverRequired) {
          return DeviceCheckResult(
            deviceRegistered: true,
            isVerified: false,
            isCurrentDevice: false,
            actionRequired: 'verify_otp_for_takeover',
            deviceId: regResult.rawDeviceId,
            newUserEmail: regResult.newUserEmail,
            currentOwnerEmail: regResult.currentOwnerEmail,
            message: regResult.message,
          );
        }
        if (regResult != null &&
            regResult.verificationRequired &&
            !regResult.isVerified) {
          return DeviceCheckResult(
            deviceRegistered: true,
            isVerified: false,
            isCurrentDevice: false,
            actionRequired: 'verify_otp',
            deviceId: regResult.devicePkForVerification,
            message: regResult.message,
          );
        }
        // Reclaim: verified device that is no longer current
        if (regResult != null &&
            regResult.verificationRequired &&
            regResult.isVerified) {
          return DeviceCheckResult(
            deviceRegistered: true,
            isVerified: true,
            isCurrentDevice: false,
            actionRequired: 'device_replaced',
            deviceId: regResult.devicePkForVerification,
            message: regResult.message,
            deviceReplaced: true,
          );
        }
        return checkResult;

      case 'verify_otp':
        debugPrint('🔐 Device needs OTP verification');
        return checkResult;

      case 'device_replaced':
        debugPrint('📱 Device was replaced — force logout to login');
        return checkResult;

      case 'verify_otp_for_takeover':
        debugPrint('🔄 Device takeover required');
        isTakeoverFlow = true;
        pendingTakeoverDeviceId = checkResult.deviceId;
        pendingTakeoverNewUserEmail = checkResult.newUserEmail;
        return checkResult;

      default:
        debugPrint('⚠️ Unknown action_required: ${checkResult.actionRequired}');
        return checkResult;
    }
  }
}

/// Result from the check_device endpoint.
class DeviceCheckResult {
  final bool deviceRegistered;
  final bool isVerified;
  final bool isCurrentDevice;
  final String? actionRequired;
  final String? deviceId;
  final String? newUserEmail;
  final String? currentOwnerEmail;
  final String message;
  final bool deviceReplaced;

  DeviceCheckResult({
    required this.deviceRegistered,
    required this.isVerified,
    required this.isCurrentDevice,
    required this.actionRequired,
    this.deviceId,
    this.newUserEmail,
    this.currentOwnerEmail,
    required this.message,
    this.deviceReplaced = false,
  });

  factory DeviceCheckResult.fromJson(Map<String, dynamic> json) {
    final action = json['action_required'] as String?;
    final replacedFlag = json['device_replaced'] as bool?;
    final replaced = replacedFlag == true ||
        action == 'device_replaced' ||
        (json['is_verified'] == true &&
            json['is_current_device'] == false &&
            action == 'verify_otp');
    return DeviceCheckResult(
      deviceRegistered: json['device_registered'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      isCurrentDevice: json['is_current_device'] as bool? ?? false,
      actionRequired: action,
      deviceId: json['device_id']?.toString(),
      newUserEmail: json['new_user_email'] as String?,
      currentOwnerEmail: json['current_owner_email'] as String?,
      message: json['message'] as String? ?? '',
      deviceReplaced: replaced,
    );
  }

  /// Whether the device needs any action (verification, takeover, or registration)
  bool get needsAction => actionRequired != null && actionRequired != 'null';

  /// Whether another device took over — app should force logout to login
  bool get wasReplacedByAnotherDevice =>
      deviceReplaced || actionRequired == 'device_replaced';

  /// Whether the device needs OTP verification (normal or takeover — not replace logout)
  bool get needsVerification =>
      !wasReplacedByAnotherDevice &&
      (actionRequired == 'verify_otp' ||
          actionRequired == 'verify_otp_for_takeover');

  /// Whether the device needs takeover verification specifically
  bool get needsTakeover => actionRequired == 'verify_otp_for_takeover';
}

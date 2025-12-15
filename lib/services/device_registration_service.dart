import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../models/device_model.dart';
import 'api_service.dart';
import 'device_info_service.dart';
import '../config/environment_config.dart';

class DeviceRegistrationService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();
  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  /// Register or update device with the backend
  Future<RegisteredDevice?> registerDevice({String? fcmToken}) async {
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
        // Check if response has nested device data or direct data
        final deviceData = response.data['device'] ?? response.data;
        final registeredDevice = RegisteredDevice.fromJson(deviceData);

        debugPrint('✅ Device registered successfully!');
        debugPrint('  - Device ID: ${registeredDevice.id}');
        debugPrint('  - Is Trusted: ${registeredDevice.isTrusted}');
        debugPrint('  - Is Current: ${registeredDevice.isCurrentDevice}');

        // Check for missing fields and update them
        final missingFields = response.data['missing_fields'];
        if (missingFields != null &&
            missingFields is List &&
            missingFields.isNotEmpty) {
          debugPrint('⚠️ Missing fields detected: $missingFields');
          await _updateMissingFields(
              registeredDevice.id, List<String>.from(missingFields));
        }

        // If location is missing, try to update it even if not in missing_fields
        if (deviceInfo.latitude == null || deviceInfo.longitude == null) {
          debugPrint('📍 Location data missing, attempting to update...');
          await updateLocation();
        }

        return registeredDevice;
      } else {
        debugPrint('❌ Device registration failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error registering device: $e');
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

  /// Update FCM token for the current device
  Future<void> updateFcmToken() async {
    try {
      debugPrint('🔔 Updating FCM token...');

      final deviceId = await _deviceInfoService.getDeviceId();
      final fcmToken = await _deviceInfoService.getFcmToken();

      if (fcmToken == null) {
        debugPrint('⚠️ No FCM token available');
        return;
      }

      await _apiService.post(
        EnvironmentConfig.deviceRegistrationUrl,
        data: {
          'device_id': deviceId,
          'fcm_token': fcmToken,
        },
      );

      debugPrint('✅ FCM token updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating FCM token: $e');
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
}

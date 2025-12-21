import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/device_model.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final GetStorage _storage = GetStorage();
  final Uuid _uuid = const Uuid();

  static const String _deviceIdKey = 'device_id';

  /// Get or generate a unique device ID
  Future<String> getDeviceId() async {
    // Check if device ID is already stored
    String? storedDeviceId = _storage.read<String>(_deviceIdKey);

    if (storedDeviceId != null && storedDeviceId.isNotEmpty) {
      return storedDeviceId;
    }

    // Generate new device ID
    String newDeviceId = _uuid.v4();
    await _storage.write(_deviceIdKey, newDeviceId);

    return newDeviceId;
  }

  /// Get FCM token for push notifications
  Future<String?> getFcmToken() async {
    try {
      // Request permission for iOS
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get FCM token
      String? token = await _firebaseMessaging.getToken();
      debugPrint('🔔 FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Get device location (with optional auto-request of permission)
  /// Set requestPermission=false to only get location if already granted
  Future<Position?> getLocation({
    int maxRetries = 1,
    bool requestPermission = true,
  }) async {
    try {
      debugPrint('📍 Checking location availability...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services are disabled');
        return null;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('📍 Current permission status: $permission');

      if (permission == LocationPermission.denied) {
        if (requestPermission) {
          debugPrint('📍 Requesting location permission...');
          permission = await Geolocator.requestPermission();
          debugPrint('📍 Permission after request: $permission');

          if (permission == LocationPermission.denied) {
            debugPrint('⚠️ Location permission denied by user');
            return null;
          }
        } else {
          debugPrint('⚠️ Location permission not granted, skipping request');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission permanently denied');
        return null;
      }

      debugPrint('📍 Fetching current location...');

      // Get current position with 10 second timeout (reduced for performance)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      );

      debugPrint(
          '✅ Location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('⚠️ Could not get location: $e');
      // Don't throw error, just return null - location is optional
      return null;
    }
  }

  /// Collect complete device information
  Future<DeviceInfo> collectDeviceInfo() async {
    try {
      final deviceId = await getDeviceId();
      final fcmToken = await getFcmToken();
      final position = await getLocation();

      String? deviceName;
      String deviceType = 'unknown';
      String osName = 'unknown';
      String? osVersion;
      String? deviceModel;
      String? deviceManufacturer;
      String? browserName;
      String? browserVersion;
      String appVersion = '1.0.0'; // Get from package_info_plus if needed

      if (kIsWeb) {
        // Web platform
        deviceType = 'desktop';
        osName = 'web';
        final webInfo = await _deviceInfo.webBrowserInfo;
        browserName = webInfo.browserName.name;
        browserVersion = webInfo.appVersion;
        deviceName = '${webInfo.browserName.name} Browser';
      } else if (Platform.isAndroid) {
        // Android platform
        final androidInfo = await _deviceInfo.androidInfo;
        deviceType = androidInfo.isPhysicalDevice ? 'mobile' : 'emulator';
        osName = 'android';
        osVersion = androidInfo.version.release;
        deviceModel = androidInfo.model;
        deviceManufacturer = androidInfo.manufacturer;
        deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        // iOS platform
        final iosInfo = await _deviceInfo.iosInfo;
        deviceType = iosInfo.isPhysicalDevice ? 'mobile' : 'emulator';
        osName = 'ios';
        osVersion = iosInfo.systemVersion;
        deviceModel = iosInfo.model;
        deviceManufacturer = 'Apple';
        deviceName = '${iosInfo.name}\'s ${iosInfo.model}';
      } else if (Platform.isMacOS) {
        // macOS platform
        final macInfo = await _deviceInfo.macOsInfo;
        deviceType = 'desktop';
        osName = 'macos';
        osVersion = macInfo.osRelease;
        deviceModel = macInfo.model;
        deviceManufacturer = 'Apple';
        deviceName = '${macInfo.computerName}';
      } else if (Platform.isWindows) {
        // Windows platform
        final windowsInfo = await _deviceInfo.windowsInfo;
        deviceType = 'desktop';
        osName = 'windows';
        osVersion = windowsInfo.productName;
        deviceModel = windowsInfo.computerName;
        deviceName = windowsInfo.computerName;
      } else if (Platform.isLinux) {
        // Linux platform
        final linuxInfo = await _deviceInfo.linuxInfo;
        deviceType = 'desktop';
        osName = 'linux';
        osVersion = linuxInfo.version;
        deviceModel = linuxInfo.name;
        deviceName = linuxInfo.name;
      }

      return DeviceInfo(
        deviceId: deviceId,
        deviceName: deviceName,
        deviceType: deviceType,
        osName: osName,
        osVersion: osVersion,
        browserName: browserName,
        browserVersion: browserVersion,
        appVersion: appVersion,
        deviceModel: deviceModel,
        deviceManufacturer: deviceManufacturer,
        fcmToken: fcmToken,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
    } catch (e) {
      debugPrint('❌ Error collecting device info: $e');
      // Return minimal device info on error
      return DeviceInfo(
        deviceId: await getDeviceId(),
        deviceType: 'unknown',
        osName: 'unknown',
      );
    }
  }
}

import 'package:flutter/foundation.dart';

class DeviceInfo {
  final String deviceId;
  final String? deviceName;
  final String? deviceType;
  final String? osName;
  final String? osVersion;
  final String? browserName;
  final String? browserVersion;
  final String? appVersion;
  final String? deviceModel;
  final String? deviceManufacturer;
  final String? fcmToken;
  final double? latitude;
  final double? longitude;

  DeviceInfo({
    required this.deviceId,
    this.deviceName,
    this.deviceType,
    this.osName,
    this.osVersion,
    this.browserName,
    this.browserVersion,
    this.appVersion,
    this.deviceModel,
    this.deviceManufacturer,
    this.fcmToken,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'device_id': deviceId,
    };

    if (deviceName != null) map['device_name'] = deviceName;
    if (deviceType != null) map['device_type'] = deviceType;
    if (osName != null) map['os_name'] = osName;
    if (osVersion != null) map['os_version'] = osVersion;
    if (browserName != null) map['browser_name'] = browserName;
    if (browserVersion != null) map['browser_version'] = browserVersion;
    if (appVersion != null) map['app_version'] = appVersion;
    if (deviceModel != null) map['device_model'] = deviceModel;
    if (deviceManufacturer != null)
      map['device_manufacturer'] = deviceManufacturer;
    if (fcmToken != null) map['fcm_token'] = fcmToken;
    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;

    return map;
  }
}

class RegisteredDevice {
  final int id;
  final String deviceId;
  final String? deviceName;
  final String? deviceType;
  final String? osName;
  final String? osVersion;
  final String? browserName;
  final String? browserVersion;
  final String? appVersion;
  final String? deviceModel;
  final String? deviceManufacturer;
  final bool isTrusted;
  final bool isActive;
  final String firstSeen;
  final String lastSeen;
  final String? lastIp;
  final bool isCurrentDevice;
  final int daysSinceLastSeen;

  RegisteredDevice({
    required this.id,
    required this.deviceId,
    this.deviceName,
    this.deviceType,
    this.osName,
    this.osVersion,
    this.browserName,
    this.browserVersion,
    this.appVersion,
    this.deviceModel,
    this.deviceManufacturer,
    required this.isTrusted,
    required this.isActive,
    required this.firstSeen,
    required this.lastSeen,
    this.lastIp,
    required this.isCurrentDevice,
    required this.daysSinceLastSeen,
  });

  factory RegisteredDevice.fromJson(Map<String, dynamic> json) {
    return RegisteredDevice(
      id: json['id'] as int,
      deviceId: json['device_id'] as String,
      deviceName: json['device_name'] as String?,
      deviceType: json['device_type'] as String?,
      osName: json['os_name'] as String?,
      osVersion: json['os_version'] as String?,
      browserName: json['browser_name'] as String?,
      browserVersion: json['browser_version'] as String?,
      appVersion: json['app_version'] as String?,
      deviceModel: json['device_model'] as String?,
      deviceManufacturer: json['device_manufacturer'] as String?,
      isTrusted: json['is_trusted'] as bool,
      isActive: json['is_active'] as bool,
      firstSeen: json['first_seen'] as String,
      lastSeen: json['last_seen'] as String,
      lastIp: json['last_ip'] as String?,
      isCurrentDevice: json['is_current_device'] as bool,
      daysSinceLastSeen: json['days_since_last_seen'] as int,
    );
  }

  String getDeviceTypeIcon() {
    switch (deviceType?.toLowerCase()) {
      case 'mobile':
        return '📱';
      case 'tablet':
        return '📱';
      case 'desktop':
        return '💻';
      default:
        return '📱';
    }
  }

  String getOsIcon() {
    switch (osName?.toLowerCase()) {
      case 'android':
        return '🤖';
      case 'ios':
        return '🍎';
      case 'macos':
        return '🍎';
      case 'windows':
        return '🪟';
      case 'linux':
        return '🐧';
      default:
        return '❓';
    }
  }
}

class DeviceRegistrationResult {
  final RegisteredDevice? device;
  final int? rawDevicePk;
  final String? rawDeviceId;
  final String? rawDeviceName;
  final bool isRegistered;
  final bool isVerified;
  final bool verificationRequired;
  final bool otpSent;
  final String message;
  final String? currentDeviceId;
  final String? currentDeviceName;
  // Device takeover fields
  final bool deviceTakeoverRequired;
  final String? actionRequired;
  final String? newUserEmail;
  final String? currentOwnerEmail;

  DeviceRegistrationResult({
    this.device,
    this.rawDevicePk,
    this.rawDeviceId,
    this.rawDeviceName,
    required this.isRegistered,
    required this.isVerified,
    this.verificationRequired = false,
    this.otpSent = false,
    required this.message,
    this.currentDeviceId,
    this.currentDeviceName,
    this.deviceTakeoverRequired = false,
    this.actionRequired,
    this.newUserEmail,
    this.currentOwnerEmail,
  });

  /// The string device_id (UUID) to use in OTP verification URLs.
  /// The backend's UserDeviceViewSet uses lookup_field = 'device_id',
  /// so detail actions (verify_otp, trust, untrust, etc.) expect the
  /// UUID device_id, not the numeric pk.
  String get devicePkForVerification {
    if (device != null) return device!.deviceId;
    if (rawDeviceId != null) return rawDeviceId!;
    return '';
  }

  String get deviceNameForVerification =>
      device?.deviceName ?? rawDeviceName ?? 'this device';

  factory DeviceRegistrationResult.fromJson(Map<String, dynamic> json) {
    final isTakeover = json['device_takeover_required'] as bool? ?? false;

    // For takeover responses, don't try to parse a RegisteredDevice —
    // the response is flat (device_id, new_user_email, etc.) not a device object
    final deviceData = isTakeover ? json : (json['device'] ?? json);
    RegisteredDevice? device;
    if (!isTakeover) {
      try {
        device = RegisteredDevice.fromJson(deviceData as Map<String, dynamic>);
      } catch (e) {
        debugPrint('⚠️ RegisteredDevice.fromJson failed: $e');
        device = null;
      }
    }

    // Extract id (numeric pk), device_id, and device_name directly from raw JSON as fallback
    final rawDevicePk = (deviceData is Map<String, dynamic>)
        ? (deviceData['id'] as int?)
        : null;
    final rawDeviceId = (deviceData is Map<String, dynamic>)
        ? deviceData['device_id']?.toString()
        : null;
    final rawDeviceName = (deviceData is Map<String, dynamic>)
        ? deviceData['device_name']?.toString()
        : null;

    debugPrint(
        '📱 DeviceRegistrationResult: device=${device != null}, rawDevicePk=$rawDevicePk, rawDeviceId=$rawDeviceId, rawDeviceName=$rawDeviceName, isTakeover=$isTakeover');

    final currentDevice = json['current_device'] as Map<String, dynamic>?;

    return DeviceRegistrationResult(
      device: device,
      rawDevicePk: rawDevicePk,
      rawDeviceId: rawDeviceId,
      rawDeviceName: rawDeviceName,
      isRegistered: json['is_registered'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? (isTakeover ? false : true),
      verificationRequired: json['verification_required'] as bool? ?? false,
      otpSent: json['otp_sent'] as bool? ?? false,
      message: json['message'] as String? ?? 'Device registered',
      currentDeviceId: currentDevice?['device_id'] as String?,
      currentDeviceName: currentDevice?['device_name'] as String?,
      deviceTakeoverRequired: isTakeover,
      actionRequired: json['action_required'] as String?,
      newUserEmail: json['new_user_email'] as String?,
      currentOwnerEmail: json['current_owner_email'] as String?,
    );
  }
}

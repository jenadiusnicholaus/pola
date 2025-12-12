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

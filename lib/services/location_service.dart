import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

import '../config/dio_config.dart';
import '../config/environment_config.dart';
import 'auth_service.dart';
import 'token_storage_service.dart';
import 'device_info_service.dart';

/// Service that periodically sends the user's live GPS coordinates to the
/// backend so the "Nearby Lawyers" feature can find them.
class LocationService extends GetxService {
  final Dio _dio = DioConfig.instance;
  Timer? _updateTimer;
  bool _isRunning = false;
  int _consecutiveFailures = 0;

  static const Duration _updateInterval = Duration(seconds: 45);
  static const double _minDistanceMeters = 50.0;

  Position? _lastSentPosition;

  @override
  void onInit() {
    super.onInit();
    debugPrint('📍 LocationService.onInit() called');
    _checkAuthAndStart();

    // Delayed retry: if tokens weren't ready during onInit, try again
    // after 3 seconds. This handles the race where TokenStorageService
    // hasn't finished loading from secure storage yet.
    Future.delayed(const Duration(seconds: 3), () {
      if (!_isRunning && _isUserLoggedIn()) {
        debugPrint(
            '📍 Late start: user is logged in, starting location updates');
        startLocationUpdates();
      }
    });
  }

  void _checkAuthAndStart() {
    try {
      final isLoggedIn = _isUserLoggedIn();
      debugPrint('📍 _checkAuthAndStart: isLoggedIn=$isLoggedIn');
      if (isLoggedIn) {
        startLocationUpdates();
      }

      if (Get.isRegistered<TokenStorageService>()) {
        final tokenStorage = Get.find<TokenStorageService>();
        ever(tokenStorage.isLoggedInRx, (isLoggedIn) {
          debugPrint('📍 isLoggedInRx changed: $isLoggedIn');
          if (isLoggedIn) {
            startLocationUpdates();
          } else {
            stopLocationUpdates();
          }
        });
      } else {
        debugPrint(
            '⚠️ TokenStorageService not registered, cannot watch login state');
      }
    } catch (e) {
      debugPrint('⚠️ Could not check auth state for location service: $e');
    }
  }

  bool _isUserLoggedIn() {
    if (Get.isRegistered<AuthService>()) {
      return Get.find<AuthService>().isLoggedIn;
    }
    if (Get.isRegistered<TokenStorageService>()) {
      return Get.find<TokenStorageService>().isLoggedIn;
    }
    return false;
  }

  /// Start sending location updates every 45 seconds.
  void startLocationUpdates() {
    if (_isRunning) return;

    debugPrint('📍 Starting live location updates');
    _isRunning = true;

    _updateLocation();
    _updateTimer = Timer.periodic(_updateInterval, (_) => _updateLocation());
  }

  /// Stop sending location updates.
  void stopLocationUpdates() {
    if (!_isRunning) return;

    debugPrint('📍 Stopping live location updates');
    _updateTimer?.cancel();
    _updateTimer = null;
    _isRunning = false;
  }

  /// Get current position and send it to the backend.
  Future<void> _updateLocation({bool force = false}) async {
    try {
      if (Get.isRegistered<TokenStorageService>()) {
        final tokenStorage = Get.find<TokenStorageService>();
        if (!tokenStorage.isLoggedIn) {
          debugPrint('📍 Skipping location update — user not logged in');
          return;
        }
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services disabled, skipping update');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission permanently denied');
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (e) {
        debugPrint(
            '⚠️ getCurrentPosition timed out or failed ($e), trying getLastKnownPosition');
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        debugPrint('⚠️ Could not obtain position (both live and cached null)');
        return;
      }

      // Skip if we haven't moved much since the last successful update (unless forced).
      if (!force && _lastSentPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastSentPosition!.latitude,
          _lastSentPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        if (distance < _minDistanceMeters) {
          debugPrint(
              '📍 Skipped update — moved only ${distance.toStringAsFixed(1)}m');
          return;
        }
      }

      await _sendLocation(position);
      _lastSentPosition = position;
      _consecutiveFailures = 0;
    } catch (e) {
      debugPrint('❌ Location update error: $e');
    }
  }

  /// POST location to the backend.
  Future<void> _sendLocation(Position position) async {
    try {
      final deviceId = await DeviceInfoService().getDeviceId();

      final data = <String, dynamic>{
        'latitude': position.latitude,
        'longitude': position.longitude,
        'device_id': deviceId,
      };

      debugPrint('📤 Sending location update: $data');

      final response = await _dio.post(
        EnvironmentConfig.updateLocationUrl,
        data: data,
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Location updated: ${response.data}');
      } else {
        debugPrint(
            '⚠️ Location update returned ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        debugPrint('📍 Stopping location updates — authentication failed');
        stopLocationUpdates();
        return;
      }

      _consecutiveFailures++;
      final backoffSeconds = _consecutiveFailures * 15;
      debugPrint('❌ Location update failed (attempt $_consecutiveFailures), '
          'backing off for ${backoffSeconds}s');

      _updateTimer?.cancel();
      _updateTimer = Timer(Duration(seconds: backoffSeconds), () {
        if (_isRunning) startLocationUpdates();
      });
    }
  }

  bool get isRunning => _isRunning;

  /// Manually trigger a single location update (e.g. from a UI button or screen open).
  /// Also starts the periodic timer if it wasn't running.
  Future<void> triggerLocationUpdate({bool force = true}) async {
    debugPrint('📍 Manual location update triggered (force: $force)');
    if (!_isRunning) {
      startLocationUpdates();
    } else {
      await _updateLocation(force: force);
    }
  }

  @override
  void onClose() {
    stopLocationUpdates();
    super.onClose();
  }
}

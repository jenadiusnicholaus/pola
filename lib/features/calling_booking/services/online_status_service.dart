import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/dio_config.dart';
import '../../../services/auth_service.dart';
import '../../../services/token_storage_service.dart';

/// Service to maintain user's online status via periodic heartbeat
class OnlineStatusService extends GetxService {
  final Dio _dio = DioConfig.instance;
  Timer? _heartbeatTimer;
  bool _isRunning = false;
  int _consecutiveFailures = 0;

  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const int _maxBackoffMultiplier = 8; // max ~4min backoff

  @override
  void onInit() {
    super.onInit();
    // Start heartbeat if user is already authenticated
    _checkAuthAndStart();
  }

  /// Check if user is authenticated and start heartbeat
  void _checkAuthAndStart() {
    try {
      if (Get.isRegistered<AuthService>()) {
        final authService = Get.find<AuthService>();
        if (authService.isLoggedIn) {
          startHeartbeat();
        }
      }

      // Listen to the persistent RxBool in TokenStorageService so
      // login/logout actually triggers start/stop of the heartbeat.
      // Using authService.isLoggedIn.obs would create a fresh RxBool
      // each call and never fire.
      if (Get.isRegistered<TokenStorageService>()) {
        final tokenStorage = Get.find<TokenStorageService>();
        ever(tokenStorage.isLoggedInRx, (isLoggedIn) {
          if (isLoggedIn) {
            startHeartbeat();
          } else {
            stopHeartbeat();
          }
        });
      }
    } catch (e) {
      debugPrint('⚠️ Could not check auth state for heartbeat: $e');
    }
  }

  /// Start sending heartbeat every 30 seconds
  void startHeartbeat() {
    if (_isRunning) {
      debugPrint('⚠️ Heartbeat already running');
      return;
    }

    debugPrint('💓 Starting heartbeat service');
    _isRunning = true;

    // Send immediately
    _sendHeartbeat();

    // Then every 30 seconds
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _sendHeartbeat();
    });
  }

  /// Stop sending heartbeat
  void stopHeartbeat() {
    if (!_isRunning) return;

    debugPrint('💔 Stopping heartbeat service');
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _isRunning = false;
  }

  /// Send heartbeat to backend
  Future<void> _sendHeartbeat() async {
    // Bail out early if the user is not authenticated — sending
    // just generates 401 noise and triggers pointless refresh attempts.
    try {
      if (Get.isRegistered<TokenStorageService>()) {
        final tokenStorage = Get.find<TokenStorageService>();
        if (!tokenStorage.isLoggedIn) {
          debugPrint('💓 Skipping heartbeat — user not logged in');
          return;
        }
      }
    } catch (_) {}

    try {
      await _dio.post(
        '/api/v1/notification/heartbeat/',
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 15),
        ),
      );
      debugPrint('💓 Heartbeat sent');
      _consecutiveFailures = 0;
    } on DioException catch (e) {
      // If we get a 401, the interceptor already tried to refresh
      // and failed. Stop the heartbeat to avoid an endless loop of
      // 401 → refresh-fail → 401.
      if (e.response?.statusCode == 401) {
        debugPrint('💓 Stopping heartbeat — authentication failed');
        stopHeartbeat();
        return;
      }

      // Network errors — back off to avoid spamming logs
      _consecutiveFailures++;
      final backoff = _heartbeatInterval *
          (_consecutiveFailures > _maxBackoffMultiplier
              ? _maxBackoffMultiplier
              : _consecutiveFailures);
      debugPrint('❌ Heartbeat error (attempt $_consecutiveFailures), '
          'backing off for ${backoff.inSeconds}s: ${e.type}');

      // Reset timer with backoff interval
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(backoff, (_) {
        _sendHeartbeat();
      });
    } catch (e) {
      debugPrint('❌ Heartbeat error: $e');
    }
  }

  /// Check if heartbeat is running
  bool get isRunning => _isRunning;

  @override
  void onClose() {
    stopHeartbeat();
    super.onClose();
  }
}

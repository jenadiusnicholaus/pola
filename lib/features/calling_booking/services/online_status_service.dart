import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/dio_config.dart';
import '../../../services/auth_service.dart';

/// Service to maintain user's online status via periodic heartbeat
class OnlineStatusService extends GetxService {
  final Dio _dio = DioConfig.instance;
  Timer? _heartbeatTimer;
  bool _isRunning = false;

  static const Duration _heartbeatInterval = Duration(seconds: 30);

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
        // Listen for login/logout changes
        ever(authService.isLoggedIn.obs, (isLoggedIn) {
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
    try {
      await _dio.post('/api/v1/notification/heartbeat/');
      debugPrint('💓 Heartbeat sent');
    } catch (e) {
      debugPrint('❌ Heartbeat error: $e');
      // Don't stop the timer on error - continue trying
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

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/dio_config.dart';

/// Service to maintain user's online status via periodic heartbeat
class OnlineStatusService extends GetxService {
  final Dio _dio = DioConfig.instance;
  Timer? _heartbeatTimer;
  bool _isRunning = false;

  static const Duration _heartbeatInterval = Duration(seconds: 30);

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
      await _dio.post('/api/v1/notifications/heartbeat/');
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

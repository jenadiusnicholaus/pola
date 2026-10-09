import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' as getx;
import '../services/token_storage_service.dart';
import '../services/auth_service.dart';
import '../services/device_info_service.dart';

class ApiInterceptors {
  // Concurrent refresh lock — ensures only one refresh runs at a time.
  // Multiple 401s will await the same Completer instead of each firing
  // their own refreshAccessToken() call.
  static Completer<bool>? _refreshCompleter;
  static bool _handlingDeviceReplaced = false;

  // Add comprehensive interceptors to Dio instance
  static void addInterceptors(Dio dio) {
    final interceptorList = dio.interceptors as List<Interceptor>;

    // Request/Response logging interceptor (only in debug mode)
    if (kDebugMode) {
      interceptorList.add(createLoggingInterceptor());
    }

    // Auth interceptor
    interceptorList.add(createAuthInterceptor());

    // Error handling interceptor with retry capability
    interceptorList.add(createErrorInterceptor(dio));
  }

  /// Shared refresh helper. If a refresh is already in progress, awaits
  /// its result instead of starting a second one. Includes a timeout so
  /// concurrent callers don't hang forever if the first refresh is stuck.
  static Future<bool> _refreshToken() async {
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      debugPrint('🔄 Token refresh already in progress, awaiting...');
      try {
        return await _refreshCompleter!.future
            .timeout(const Duration(seconds: 10), onTimeout: () {
          debugPrint('⏰ Timed out waiting for in-progress refresh');
          return false;
        });
      } catch (e) {
        return false;
      }
    }
    _refreshCompleter = Completer<bool>();
    try {
      final authService = getx.Get.find<AuthService>();
      final result = await authService
          .refreshAccessToken()
          .timeout(const Duration(seconds: 15), onTimeout: () {
        debugPrint('⏰ refreshAccessToken itself timed out');
        return false;
      });
      _refreshCompleter!.complete(result);
      return result;
    } catch (e) {
      debugPrint('❌ Error during shared token refresh: $e');
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  // Comprehensive logging interceptor
  static Interceptor createLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        _logRequest(options);
        handler.next(options);
      },
      onResponse: (response, handler) {
        _logResponse(response);
        handler.next(response);
      },
      onError: (error, handler) {
        _logError(error);
        handler.next(error);
      },
    );
  }

  // Auth interceptor
  static Interceptor createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // These endpoints are public and must never carry an Authorization
        // header or trigger a token refresh, even if an old token happens
        // to be in storage (e.g. a user registering a new account).
        final isPublicAuthEndpoint = _isPublicAuthEndpoint(options);

        // Attach stable device id for single-device enforcement
        try {
          final deviceId = await DeviceInfoService().getDeviceId();
          if (deviceId.isNotEmpty) {
            options.headers['X-Device-Id'] = deviceId;
          }
        } catch (e) {
          debugPrint('⚠️ Could not attach X-Device-Id: $e');
        }

        // Public endpoints never need an access token.
        if (isPublicAuthEndpoint) {
          options.headers.remove('Authorization');
          debugPrint(
              '🔓 Public auth endpoint — skipping token attach: ${options.uri}');
          handler.next(options);
          return;
        }

        // Get TokenStorageService instance
        try {
          final tokenStorage = getx.Get.find<TokenStorageService>();

          // IMPORTANT: Wait for token service to fully initialize
          await tokenStorage.waitForInitialization();

          // If the access token is expired but the refresh token is still
          // valid, refresh proactively before sending the request. This
          // avoids a round-trip 401 → refresh → retry and keeps the user
          // logged in as long as the refresh token hasn't expired.
          //
          // CRITICAL: Skip this for refresh token requests themselves,
          // otherwise we deadlock (refresh request → interceptor tries
          // to refresh → waits for same refresh to complete → hang).
          final isRefreshRequest =
              options.path.contains('/authentication/refresh') ||
                  options.path.contains('/auth/refresh');

          if (!isRefreshRequest &&
              tokenStorage.isLoggedIn &&
              tokenStorage.accessToken.isNotEmpty &&
              tokenStorage.isAccessTokenExpired() &&
              !tokenStorage.isRefreshTokenExpired()) {
            debugPrint(
                '🔄 Access token expired, proactively refreshing before request: ${options.uri}');
            await _refreshToken();
          }

          final token = tokenStorage.accessToken;

          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint('🔑 Added auth token to request: ${options.uri}');
            debugPrint(
                '🔑 Token length: ${token.length}, starts with: ${token.substring(0, 20)}...');

            // Special logging for bookmarked endpoint
            if (options.uri.toString().contains('bookmarked')) {
              debugPrint('🔖 BOOKMARK REQUEST - Token added successfully');
            }
          } else {
            debugPrint(
                '⚠️ No access token in memory for request: ${options.uri}');

            // Try to recover tokens from storage (may have been cleared
            // from memory by a race condition or errant 401 handler)
            await tokenStorage.reloadFromStorage();
            final recoveredToken = tokenStorage.accessToken;
            if (recoveredToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $recoveredToken';
              debugPrint('🔄 Recovered token from storage for: ${options.uri}');
            } else {
              debugPrint(
                  '⚠️ No token in storage either — request will go unauthenticated: ${options.uri}');
            }
          }
        } catch (e) {
          debugPrint('❌ Error getting token: $e');
        }

        handler.next(options);
      },
    );
  }

  /// Whether the request targets a public authentication endpoint that
  /// should never carry an Authorization header.
  static bool _isPublicAuthEndpoint(RequestOptions options) {
    final path = options.uri.path.toLowerCase();
    final fullUri = options.uri.toString().toLowerCase();
    return path.contains('/authentication/register') ||
        path.contains('/auth/register') ||
        path.contains('/authentication/login') ||
        path.contains('/auth/login') ||
        path.contains('/authentication/refresh') ||
        path.contains('/auth/refresh') ||
        path.contains('/authentication/password') ||
        path.contains('/auth/password') ||
        path.contains('/authentication/reset') ||
        path.contains('/auth/reset') ||
        path.contains('/authentication/verify') ||
        path.contains('/auth/verify') ||
        path.contains('/authentication/devices/register') ||
        path.contains('/auth/devices/register') ||
        fullUri.contains('/authentication/register') ||
        fullUri.contains('/auth/register') ||
        fullUri.contains('/authentication/login') ||
        fullUri.contains('/auth/login') ||
        fullUri.contains('/authentication/refresh') ||
        fullUri.contains('/auth/refresh');
  }

  static bool _isDeviceReplacedError(dynamic errorData) {
    if (errorData is! Map) return false;
    final code = errorData['code']?.toString() ?? '';
    final error = errorData['error']?.toString() ?? '';
    return code == 'device_replaced' || error == 'device_replaced';
  }

  static Future<void> _forceLogoutDeviceReplaced() async {
    if (_handlingDeviceReplaced) return;
    _handlingDeviceReplaced = true;
    try {
      debugPrint('📱 Device replaced — forcing logout to login screen');
      try {
        final authService = getx.Get.find<AuthService>();
        await authService.forceLogoutToLogin();
      } catch (_) {
        try {
          final tokenStorage = getx.Get.find<TokenStorageService>();
          await tokenStorage.clearTokens();
        } catch (_) {}
        getx.Get.offAllNamed('/login');
      }
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        _handlingDeviceReplaced = false;
      });
    }
  }

  static Interceptor createErrorInterceptor(Dio dio) {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        // Handle specific error cases
        if (error.response != null) {
          // Check for device registration error globally
          try {
            final errorData = error.response!.data is String
                ? jsonDecode(error.response!.data)
                : error.response!.data;
            if (errorData is Map &&
                errorData['error'] ==
                    'This device is already registered to another account') {
              debugPrint(
                  '🔴 Device already registered to another account. User should contact support.');
            }
          } catch (_) {
            // Ignore parse errors
          }

          switch (error.response!.statusCode) {
            case 401:
              // Single-device: another device took over — do not refresh token
              try {
                final errorData = error.response!.data is String
                    ? jsonDecode(error.response!.data)
                    : error.response!.data;
                if (_isDeviceReplacedError(errorData)) {
                  await _forceLogoutDeviceReplaced();
                  break;
                }
              } catch (_) {}

              debugPrint(
                  '🔒 Authentication failed - Attempting token refresh...');

              // Don't try to refresh if this is a public auth endpoint
              // (login, register, refresh) — a 401 there means bad
              // credentials or invalid refresh token, not an expired
              // access token that can be refreshed.
              final path = error.requestOptions.path;
              final isAuthEndpoint = path.contains('/authentication/refresh') ||
                  path.contains('/auth/refresh') ||
                  path.contains('/authentication/login') ||
                  path.contains('/auth/login') ||
                  path.contains('/authentication/register') ||
                  path.contains('/auth/register');

              if (isAuthEndpoint) {
                debugPrint(
                    '❌ Auth endpoint returned 401 — not attempting token refresh');
                break;
              }

              // If tokens are completely gone, try reloading from storage
              // (they may have been cleared by a race condition)
              try {
                final tokenStorage = getx.Get.find<TokenStorageService>();
                if (tokenStorage.accessToken.isEmpty &&
                    tokenStorage.refreshToken.isEmpty) {
                  debugPrint(
                      '🔄 Tokens empty in memory — attempting reload from storage...');
                  await tokenStorage.reloadFromStorage();

                  // If still empty after reload, no point retrying
                  if (tokenStorage.accessToken.isEmpty &&
                      tokenStorage.refreshToken.isEmpty) {
                    debugPrint(
                        '❌ No tokens in storage either — 401 will propagate');
                    break;
                  }
                  debugPrint('✅ Tokens reloaded from storage');
                }
              } catch (_) {}

              // Try to refresh the token (shared lock prevents concurrent refreshes)
              try {
                final tokenRefreshed = await _refreshToken();

                if (tokenRefreshed) {
                  debugPrint(
                      '✅ Token refreshed successfully, retrying request...');

                  // Get the new token
                  final tokenStorage = getx.Get.find<TokenStorageService>();
                  final newToken = tokenStorage.accessToken;

                  // Update the failed request with new token
                  error.requestOptions.headers['Authorization'] =
                      'Bearer $newToken';

                  // Retry the request with the same Dio instance
                  final response = await dio.fetch(error.requestOptions);

                  // Return the successful response
                  return handler.resolve(response);
                } else {
                  debugPrint('❌ Token refresh failed - 401 will propagate');
                }
              } catch (e) {
                debugPrint('❌ Error during token refresh: $e');
              }
              break;
            case 403:
              debugPrint('🚫 Access forbidden - Insufficient permissions');
              try {
                final errorData = error.response!.data is String
                    ? jsonDecode(error.response!.data)
                    : error.response!.data;
                if (errorData is Map) {
                  if (errorData['error'] == 'Subscription required' ||
                      errorData['upgrade_required'] == true) {
                    debugPrint(
                        '💳 Subscription required - Showing subscription modal');
                    _showSubscriptionModal(errorData['message'] ??
                        'You need an active subscription to access this content.');
                  } else if ((errorData['detail'] as String? ?? '')
                      .toLowerCase()
                      .contains('verified')) {
                    debugPrint(
                        '✅ Verification required - Showing verification modal');
                    _showVerificationModal(errorData['detail'] as String? ??
                        'You must be verified to access this content.');
                  }
                }
              } catch (_) {
                // Ignore parse errors
              }
              break;
            case 404:
              debugPrint('❌ Resource not found - ${error.requestOptions.uri}');
              break;
            case 422:
              debugPrint('📝 Validation errors occurred');
              break;
            case 500:
              debugPrint('🔥 Server error - Please try again later');
              break;
          }
        } else {
          debugPrint('🌐 Network error - Check internet connection');
        }
        handler.next(error);
      },
    );
  }

  // Log request details
  static void _logRequest(RequestOptions options) {
    debugPrint('🚀 REQUEST: ${options.method} ${options.uri}');
    debugPrint('📤 Headers: ${options.headers}');

    if (options.data != null) {
      // Check if it's FormData (for file uploads)
      if (options.data is FormData) {
        debugPrint('📦 Body: [FormData - File Upload]');
      } else {
        // Mask sensitive data in logs
        final data = _maskSensitiveData(options.data);
        debugPrint('📦 Body: ${jsonEncode(data)}');
      }
    }

    if (options.queryParameters.isNotEmpty) {
      debugPrint('🔍 Query Params: ${options.queryParameters}');
    }
  }

  // Log response details
  static void _logResponse(Response response) {
    final status = response.statusCode;
    final emoji = status! < 300
        ? '✅'
        : status < 400
            ? '⚠️'
            : '❌';

    debugPrint('$emoji RESPONSE: ${response.requestOptions.method} '
        '${response.requestOptions.uri} → $status');
    debugPrint('📥 Headers: ${response.headers.map}');

    if (response.data != null) {
      // Pretty print JSON response
      try {
        final jsonData =
            response.data is String ? jsonDecode(response.data) : response.data;
        debugPrint('📄 Response Data: ${jsonEncode(jsonData)}');
      } catch (e) {
        debugPrint('📄 Response Data: ${response.data}');
      }
    }
  }

  // Log error details
  static void _logError(DioException error) {
    debugPrint('💥 ERROR: ${error.type} - ${error.message}');
    debugPrint(
        '🎯 Request: ${error.requestOptions.method} ${error.requestOptions.uri}');

    if (error.response != null) {
      debugPrint('📊 Status Code: ${error.response!.statusCode}');
      debugPrint('📋 Response Headers: ${error.response!.headers.map}');

      if (error.response!.data != null) {
        try {
          final errorData = error.response!.data is String
              ? jsonDecode(error.response!.data)
              : error.response!.data;
          debugPrint('🔴 Error Response: ${jsonEncode(errorData)}');
        } catch (e) {
          debugPrint('🔴 Error Response: ${error.response!.data}');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('📚 Stack Trace: ${error.stackTrace}');
    }
  }

  // Mask sensitive data for logging
  static dynamic _maskSensitiveData(dynamic data) {
    if (data is Map<String, dynamic>) {
      final maskedData = Map<String, dynamic>.from(data);

      // List of sensitive fields to mask
      const sensitiveFields = [
        'password',
        'password_confirm',
        'token',
        'api_key',
        'secret',
        'private_key',
      ];

      for (final field in sensitiveFields) {
        if (maskedData.containsKey(field)) {
          maskedData[field] = '***MASKED***';
        }
      }

      return maskedData;
    }

    return data;
  }

  // Update auth token - now handled by TokenStorageService
  static Future<void> updateAuthToken(String token) async {
    try {
      // Token is already stored by TokenStorageService.storeTokens()
      debugPrint('✅ Auth token updated in TokenStorageService');
    } catch (e) {
      debugPrint('❌ Error updating auth token: $e');
    }
  }

  // Clear auth token - now handled by TokenStorageService
  static Future<void> clearAuthToken() async {
    try {
      final tokenStorage = getx.Get.find<TokenStorageService>();
      await tokenStorage.clearTokens();
      debugPrint('✅ Auth token cleared from TokenStorageService');
    } catch (e) {
      debugPrint('❌ Error clearing auth token: $e');
    }
  }

  // Show subscription modal when subscription is required
  static void _showSubscriptionModal(String message) {
    try {
      // Get current context from GetX
      final context = getx.Get.context;
      if (context == null) {
        debugPrint('⚠️ No context available to show subscription modal');
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.amber.shade700),
              const SizedBox(width: 12),
              const Flexible(
                child: Text('Subscription Required'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              const Text(
                'Upgrade your subscription to access this premium content.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                getx.Get.toNamed('/subscription-plans');
              },
              icon: const Icon(Icons.upgrade),
              label: const Text('View Plans'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('❌ Error showing subscription modal: $e');
    }
  }

  // Show verification modal when account verification is required
  static void _showVerificationModal(String message) {
    try {
      final context = getx.Get.context;
      if (context == null) {
        debugPrint('⚠️ No context available to show verification modal');
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.verified_user_outlined, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              const Flexible(
                child: Text('Verification Required'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              const Text(
                'Complete your account verification to access this hub.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                getx.Get.toNamed('/profile');
              },
              icon: const Icon(Icons.verified_user),
              label: const Text('Go to Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('❌ Error showing verification modal: $e');
    }
  }
}

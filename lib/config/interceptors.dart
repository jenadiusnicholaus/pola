import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' as getx;
import '../services/token_storage_service.dart';
import '../services/auth_service.dart';

class ApiInterceptors {
  // Add comprehensive interceptors to Dio instance
  static void addInterceptors(Dio dio) {
    // Request/Response logging interceptor (only in debug mode)
    if (kDebugMode) {
      dio.interceptors.add(createLoggingInterceptor());
    }

    // Auth interceptor
    dio.interceptors.add(createAuthInterceptor());

    // Error handling interceptor with retry capability
    dio.interceptors.add(createErrorInterceptor(dio));
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
        // Get TokenStorageService instance
        try {
          final tokenStorage = getx.Get.find<TokenStorageService>();

          // IMPORTANT: Wait for token service to fully initialize
          await tokenStorage.waitForInitialization();

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
            debugPrint('⚠️ No access token found for request: ${options.uri}');
            debugPrint(
                '⚠️ TokenStorageService state - isLoggedIn: ${tokenStorage.isLoggedIn}');

            // Special logging for bookmarked endpoint
            if (options.uri.toString().contains('bookmarked')) {
              debugPrint('🔖 BOOKMARK REQUEST - NO TOKEN AVAILABLE!');
            }
          }
        } catch (e) {
          debugPrint('❌ Error getting token: $e');
        }

        handler.next(options);
      },
    );
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
                errorData['error'] == 'This device is already registered to another account') {
              debugPrint('🔴 Device already registered error detected. Redirecting to verification screen.');
              // Use string route to avoid circular dependency, or assume it's valid
              if (getx.Get.currentRoute != '/device-verification') {
                // Short delay to ensure navigation stack is ready
                Future.delayed(const Duration(milliseconds: 100), () {
                  getx.Get.offAllNamed('/device-verification');
                });
              }
            }
          } catch (_) {
            // Ignore parse errors
          }

          switch (error.response!.statusCode) {
            case 401:
              debugPrint(
                  '🔒 Authentication failed - Attempting token refresh...');

              // Don't try to refresh if this IS the refresh token request (prevents infinite loop)
              final isRefreshRequest = error.requestOptions.path
                  .contains('/authentication/refresh/');

              if (isRefreshRequest) {
                debugPrint(
                    '❌ Refresh token request failed - User needs to login again');
                break;
              }

              // Try to refresh the token
              try {
                final authService = getx.Get.find<AuthService>();
                final tokenRefreshed = await authService.refreshAccessToken();

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
                  debugPrint(
                      '❌ Token refresh failed - User needs to login again');
                }
              } catch (e) {
                debugPrint('❌ Error during token refresh: $e');
              }
              break;
            case 403:
              debugPrint('🚫 Access forbidden - Insufficient permissions');
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
}

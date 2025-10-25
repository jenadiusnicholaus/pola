import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';

class ApiInterceptors {
  static final GetStorage _storage = GetStorage();

  // Add comprehensive interceptors to Dio instance
  static void addInterceptors(Dio dio) {
    // Request/Response logging interceptor (only in debug mode)
    if (kDebugMode) {
      dio.interceptors.add(createLoggingInterceptor());
    }

    // Auth interceptor
    dio.interceptors.add(createAuthInterceptor());

    // Error handling interceptor
    dio.interceptors.add(createErrorInterceptor());
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
      onRequest: (options, handler) {
        // Add auth token to requests
        final token = _storage.read('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    );
  }

  // Error handling interceptor
  static Interceptor createErrorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        // Handle specific error cases
        if (error.response != null) {
          switch (error.response!.statusCode) {
            case 401:
              debugPrint('🔒 Authentication failed - Token may be expired');
              // Could trigger auto logout here
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
      // Mask sensitive data in logs
      final data = _maskSensitiveData(options.data);
      debugPrint('📦 Body: ${jsonEncode(data)}');
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

  // Update auth token
  static void updateAuthToken(String token) {
    _storage.write('auth_token', token);
  }

  // Clear auth token
  static void clearAuthToken() {
    _storage.remove('auth_token');
  }
}

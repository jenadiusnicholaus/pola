import 'package:flutter/foundation.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:dio/dio.dart' as dio;
import '../config/environment_config.dart';

/// Background API loader that runs heavy API calls in isolates
/// This keeps the main UI thread responsive during startup
class BackgroundApiLoader {
  
  /// Fetch multiple API endpoints in parallel using isolates
  /// Returns a map of endpoint names to their responses
  static Future<Map<String, dynamic>> fetchMultipleInBackground(
    List<ApiRequest> requests,
  ) async {
    final results = <String, dynamic>{};
    
    // Run all requests in parallel
    final futures = requests.map((req) async {
      try {
        final result = await flutterCompute(_fetchInIsolate, req.toMap());
        results[req.name] = result;
      } catch (e) {
        debugPrint('⚠️ Background fetch failed for ${req.name}: $e');
        results[req.name] = {'error': e.toString()};
      }
    });
    
    await Future.wait(futures);
    return results;
  }
  
  /// Prefetch common data in background during app startup
  /// Call this after authentication is verified
  static Future<void> prefetchStartupData({
    required String accessToken,
    String? refreshToken,
  }) async {
    debugPrint('🔄 Starting background data prefetch...');
    
    final requests = [
      ApiRequest(
        name: 'profile',
        endpoint: EnvironmentConfig.profileUrl,
        token: accessToken,
      ),
      ApiRequest(
        name: 'notifications_count',
        endpoint: '/api/v1/notifications/unread-count/',
        token: accessToken,
      ),
    ];
    
    // Run in background - don't await
    fetchMultipleInBackground(requests).then((results) {
      debugPrint('✅ Background prefetch complete: ${results.keys.join(', ')}');
    }).catchError((e) {
      debugPrint('⚠️ Background prefetch error: $e');
    });
  }
}

/// Request configuration for background API calls
class ApiRequest {
  final String name;
  final String endpoint;
  final String? token;
  final String method;
  final Map<String, dynamic>? queryParams;
  final dynamic body;
  
  ApiRequest({
    required this.name,
    required this.endpoint,
    this.token,
    this.method = 'GET',
    this.queryParams,
    this.body,
  });
  
  Map<String, dynamic> toMap() => {
    'name': name,
    'endpoint': endpoint,
    'token': token,
    'method': method,
    'queryParams': queryParams,
    'body': body,
    'baseUrl': EnvironmentConfig.baseUrl,
    'apiKey': EnvironmentConfig.apiKey,
  };
}

/// Top-level function for isolate execution
/// Must be annotated with @pragma('vm:entry-point')
@pragma('vm:entry-point')
Future<Map<String, dynamic>> _fetchInIsolate(Map<String, dynamic> params) async {
  final endpoint = params['endpoint'] as String;
  final token = params['token'] as String?;
  final method = params['method'] as String;
  final queryParams = params['queryParams'] as Map<String, dynamic>?;
  final body = params['body'];
  final baseUrl = params['baseUrl'] as String;
  final apiKey = params['apiKey'] as String;
  
  // Create Dio instance in isolate
  final dioInstance = dio.Dio(dio.BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-API-Key': apiKey,
      if (token != null) 'Authorization': 'Bearer $token',
    },
  ));
  
  try {
    dio.Response response;
    
    switch (method.toUpperCase()) {
      case 'POST':
        response = await dioInstance.post(
          endpoint,
          data: body,
          queryParameters: queryParams,
        );
        break;
      case 'PUT':
        response = await dioInstance.put(
          endpoint,
          data: body,
          queryParameters: queryParams,
        );
        break;
      case 'PATCH':
        response = await dioInstance.patch(
          endpoint,
          data: body,
          queryParameters: queryParams,
        );
        break;
      case 'DELETE':
        response = await dioInstance.delete(
          endpoint,
          queryParameters: queryParams,
        );
        break;
      default: // GET
        response = await dioInstance.get(
          endpoint,
          queryParameters: queryParams,
        );
    }
    
    return {
      'success': true,
      'statusCode': response.statusCode,
      'data': response.data,
    };
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

/// Extension for running API service methods in background
extension BackgroundApiExtension on Future<dio.Response> {
  /// Wrap an API call to run in the current context
  /// (actual isolate usage requires the flutterCompute pattern)
  Future<dio.Response> get inBackground => this;
}

import 'package:dio/dio.dart';
import '../config/environment_config.dart';
import '../config/interceptors.dart';

class DioConfig {
  static late Dio _dio;

  // Private constructor
  DioConfig._();

  // Initialize Dio with configuration
  static Dio initialize() {
    _dio = Dio();

    // Base configuration
    _dio.options = BaseOptions(
      baseUrl: EnvironmentConfig.completeApiUrl,
      connectTimeout:
          Duration(milliseconds: EnvironmentConfig.connectionTimeout),
      receiveTimeout: Duration(milliseconds: EnvironmentConfig.receiveTimeout),
      sendTimeout: Duration(milliseconds: EnvironmentConfig.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-Key': EnvironmentConfig.apiKey,
      },
      validateStatus: (status) {
        return status! < 500;
      },
    );

    // Add interceptors using the dedicated interceptor class
    ApiInterceptors.addInterceptors(_dio);

    return _dio;
  }

  // Get configured Dio instance
  static Dio get instance => _dio;

  // Create custom Dio instance for specific base URL
  static Dio createCustomInstance(String baseUrl) {
    final customDio = Dio();
    customDio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout:
          Duration(milliseconds: EnvironmentConfig.connectionTimeout),
      receiveTimeout: Duration(milliseconds: EnvironmentConfig.receiveTimeout),
      sendTimeout: Duration(milliseconds: EnvironmentConfig.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    return customDio;
  }

  // Update auth token
  static void updateAuthToken(String token) {
    ApiInterceptors.updateAuthToken(token);
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Clear auth token
  static void clearAuthToken() {
    ApiInterceptors.clearAuthToken();
    _dio.options.headers.remove('Authorization');
  }
}

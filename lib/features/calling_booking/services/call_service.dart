import 'package:dio/dio.dart';
import '../../../config/dio_config.dart';
import '../../../services/token_storage_service.dart';
import '../models/consultant_models.dart';
import 'package:get/get.dart' as getx;

class CallService {
  final Dio _dio = DioConfig.instance;
  final TokenStorageService _tokenService =
      getx.Get.find<TokenStorageService>();

  // Consultant Endpoints

  /// Get list of all consultants
  Future<List<Consultant>> getConsultants({
    String? type, // 'mobile' or 'physical'
    String? consultantType, // 'advocate', 'lawyer', 'paralegal'
    String? specialization,
    String? city,
    double? minRating,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;
      if (consultantType != null) {
        queryParams['consultant_type'] = consultantType;
      }
      if (specialization != null)
        queryParams['specialization'] = specialization;
      if (city != null) queryParams['city'] = city;
      if (minRating != null) queryParams['min_rating'] = minRating;

      final response = await _dio.get(
        '/api/v1/subscriptions/calls/consultants/',
        queryParameters: queryParams,
      );

      final consultantsList = response.data['consultants'] as List;
      return consultantsList.map((json) => Consultant.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Search consultants
  Future<List<Consultant>> searchConsultants({
    String? query,
    String? type,
    String? consultantType,
    String? city,
    double? minRating,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (query != null && query.isNotEmpty) queryParams['q'] = query;
      if (type != null) queryParams['type'] = type;
      if (consultantType != null) {
        queryParams['consultant_type'] = consultantType;
      }
      if (city != null) queryParams['city'] = city;
      if (minRating != null) queryParams['min_rating'] = minRating;

      final response = await _dio.get(
        '/api/v1/subscriptions/calls/consultants/search/',
        queryParameters: queryParams,
      );

      final consultantsList = response.data['consultants'] as List;
      return consultantsList.map((json) => Consultant.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get consultant details
  Future<Consultant> getConsultantDetails(int consultantId) async {
    try {
      final response = await _dio.get(
        '/api/v1/subscriptions/calls/consultants/$consultantId/',
      );

      return Consultant.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Call Credit Endpoints

  /// Check if user has credits before calling
  Future<CreditCheckResponse> checkCredits(int consultantId) async {
    try {
      final response = await _dio.post(
        '/api/v1/subscriptions/calls/check-credits/',
        data: {
          'consultant_id': consultantId,
        },
      );

      return CreditCheckResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Record call and deduct credits
  Future<RecordCallResponse> recordCall({
    required int consultantId,
    required int durationSeconds,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/subscriptions/calls/record-call/',
        data: {
          'consultant_id': consultantId,
          'duration_seconds': durationSeconds,
        },
      );

      return RecordCallResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user's call history
  Future<List<CallSession>> getCallHistory() async {
    try {
      final response = await _dio.get(
        '/api/v1/subscriptions/calls/my-calls/',
      );

      final callsList = response.data['calls'] as List;
      return callsList.map((json) => CallSession.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get current user's credit balance
  Future<Map<String, dynamic>> getMyCredits() async {
    try {
      final response = await _dio.get(
        '/api/v1/subscriptions/calls/my-credits/',
      );

      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final statusCode = error.response!.statusCode;

        // Check if response is HTML (API endpoint not implemented)
        final contentType = error.response!.headers.value('content-type') ?? '';
        if (contentType.contains('text/html')) {
          return 'Call service is not yet available on the server. Please contact support.';
        }

        final message = error.response!.data is Map
            ? (error.response!.data['detail'] ??
                error.response!.data['message'] ??
                error.response!.data['error'] ??
                '')
            : '';

        switch (statusCode) {
          case 400:
            return message.isNotEmpty
                ? message
                : 'Invalid request. Please try again.';
          case 401:
            return 'Please log in to access call services';
          case 402:
            return message.isNotEmpty
                ? message
                : 'Insufficient credits. Please purchase a bundle.';
          case 403:
            return message.isNotEmpty
                ? message
                : 'You don\'t have permission to perform this action';
          case 404:
            return message.isNotEmpty
                ? message
                : 'Call service not found. Please check back later.';
          case 429:
            return 'Too many requests. Please wait a moment.';
          default:
            return message.isNotEmpty
                ? message
                : 'Something went wrong. Please try again.';
        }
      } else {
        return 'Network error. Please check your connection.';
      }
    }

    return 'An unexpected error occurred';
  }
}

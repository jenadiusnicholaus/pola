import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../config/dio_config.dart';
import '../models/consultant_models.dart';
import '../../../config/zego_config.dart';

class CallService {
  final Dio _dio = DioConfig.instance;

  // Call Management Endpoints

  /// Initiate a call to a consultant
  Future<Map<String, dynamic>> initiateCall({
    required int consultantId,
    String callType = 'voice',
  }) async {
    try {
      // Generate call ID in app
      final callId = ZegoConfig.generateCallId(consultantId);

      debugPrint('📞 Initiating call to consultant $consultantId');
      debugPrint('📡 Call ID: $callId');
      debugPrint('🌐 Base URL: ${_dio.options.baseUrl}');
      debugPrint(
          '🎯 Full URL: ${_dio.options.baseUrl}/api/v1/subscriptions/calls/initiate/');

      final response = await _dio.post(
        '/api/v1/subscriptions/calls/initiate/',
        data: {
          'consultant_id': consultantId,
          'channel_name': callId,
          'call_type': callType,
        },
      );

      debugPrint('✅ Backend response: ${response.data}');
      debugPrint('📞 Call ID: ${response.data['call_id']}');

      return {
        'success': true,
        'call_id': response.data['call_id'],
        'channel_name': response.data['channel_name'],
        'message': response.data['message'] ?? 'Call initiated successfully',
      };
    } catch (e) {
      debugPrint('❌ Error initiating call: $e');
      if (e is DioException) {
        debugPrint('Status code: ${e.response?.statusCode}');
        debugPrint('Response data: ${e.response?.data}');
      }
      return {
        'success': false,
        'error': _handleError(e),
      };
    }
  }

  /// Accept an incoming call
  Future<Map<String, dynamic>> acceptCall({required String callId}) async {
    try {
      debugPrint('✅ Accepting call: $callId');

      final response = await _dio.post(
        '/api/v1/subscriptions/calls/$callId/accept/',
      );

      debugPrint('📥 Accept call response: ${response.data}');

      // Check if response has the expected structure
      if (response.data == null) {
        debugPrint('⚠️ Response data is null');
        return {
          'success': false,
          'message': 'Invalid response from server',
        };
      }

      return {
        'success': response.data['success'] ?? true,
        'call_id': response.data['call_id'],
        'channel_name': response.data['channel_name'] ?? '',
        'caller': response.data['caller'],
        'message': response.data['message'] ?? 'Call accepted',
      };
    } catch (e) {
      debugPrint('❌ Error accepting call: $e');
      return {
        'success': false,
        'message': _handleError(e),
      };
    }
  }

  /// Reject an incoming call
  Future<void> rejectCall({
    required String callId,
    String? reason,
  }) async {
    try {
      debugPrint('❌ Rejecting call: $callId');

      await _dio.post(
        '/api/v1/subscriptions/calls/$callId/reject/',
        data: {
          'reason': reason ?? 'busy',
        },
      );
    } catch (e) {
      debugPrint('Error rejecting call: $e');
      throw _handleError(e);
    }
  }

  /// Cancel a call before it's answered (caller hangs up during ringing)
  Future<Map<String, dynamic>> cancelCall({required String callId}) async {
    try {
      debugPrint('📵 Cancelling call: $callId');

      final response = await _dio.post(
        '/api/v1/subscriptions/calls/$callId/cancel/',
      );

      return {
        'success': true,
        'message': response.data['message'] ?? 'Call cancelled',
      };
    } catch (e) {
      debugPrint('❌ Error cancelling call: $e');
      return {
        'success': false,
        'message': _handleError(e),
      };
    }
  }

  /// End an active call
  Future<Map<String, dynamic>> endCall({
    required String callId,
    required int durationSeconds,
  }) async {
    try {
      debugPrint(
          '📞 Ending call: $callId (duration: $durationSeconds seconds)');

      final response = await _dio.post(
        '/api/v1/subscriptions/calls/$callId/end/',
        data: {
          'duration_seconds': durationSeconds,
        },
      );

      return {
        'success': true,
        'call_summary': response.data['call_summary'],
        'message': response.data['message'] ?? 'Call ended successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': _handleError(e),
      };
    }
  }

  /// Mark call as missed
  Future<void> markCallMissed({required String callId}) async {
    try {
      debugPrint('📵 Marking call as missed: $callId');

      await _dio.post(
        '/api/v1/subscriptions/calls/$callId/missed/',
      );
    } catch (e) {
      debugPrint('Error marking call as missed: $e');
      throw _handleError(e);
    }
  }

  /// Get consultant online status
  Future<Map<String, dynamic>> getConsultantStatus(int consultantId) async {
    try {
      final response = await _dio.get(
        '/api/v1/subscriptions/calls/consultants/$consultantId/status/',
      );

      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Consultant Endpoints

  /// Get list of all consultants with pagination
  Future<Map<String, dynamic>> getConsultants({
    String? type, // 'mobile' or 'physical'
    String? consultantType, // 'advocate', 'lawyer', 'paralegal'
    String? specialization,
    String? city,
    double? minRating,
    int? page,
    int? pageSize,
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
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;

      final response = await _dio.get(
        '/api/v1/subscriptions/calls/consultants/',
        queryParameters: queryParams,
      );

      final consultants = (response.data['consultants'] ??
          response.data['results'] ??
          []) as List;
      final consultantsList =
          consultants.map((json) => Consultant.fromJson(json)).toList();

      return {
        'count': response.data['count'] ?? consultantsList.length,
        'next': response.data['next'],
        'previous': response.data['previous'],
        'results': consultantsList,
      };
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
      debugPrint('💳 ====== CHECKING CREDITS ======');
      debugPrint('💳 consultant_id being sent: $consultantId');
      debugPrint('💳 Endpoint: /api/v1/subscriptions/call-history/check-credits/');
      
      final response = await _dio.post(
        '/api/v1/subscriptions/call-history/check-credits/',
        data: {
          'consultant_id': consultantId,
        },
        options: Options(
          // Accept 402 and 404 as valid responses to handle them properly
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugPrint('💳 Credit check response status: ${response.statusCode}');
      debugPrint('💳 Credit check response: ${response.data}');

      // Handle 404 - consultant not found in subscriptions system
      if (response.statusCode == 404) {
        debugPrint('❌ 404 Error: Consultant ID $consultantId not found in subscriptions system');
        debugPrint('   This may indicate an ID mismatch between Nearby Lawyers and Subscriptions APIs');
        return CreditCheckResponse(
          hasCredits: false,
          availableMinutes: 0,
          activeCreditsCount: 0,
          creditsBreakdown: [],
          availableBundles: [],
          message: 'Consultant not found. Please try from Talk to Lawyer section.',
        );
      }

      // Both 200 (has credits) and 402 (no credits but has bundles) are valid
      return CreditCheckResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error checking credits: $e');
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

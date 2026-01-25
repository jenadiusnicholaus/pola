import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../services/api_service.dart';
import '../../../config/environment_config.dart';

class ConsultationService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  /// Check if user can apply for consultant status
  Future<ConsultationEligibility> checkEligibility() async {
    try {
      debugPrint('🔍 Checking consultation eligibility...');
      final response = await _apiService.get(
        EnvironmentConfig.consultationApplicationStatusUrl,
      );

      debugPrint('📥 API Response Status: ${response.statusCode}');
      debugPrint('📥 API Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final eligibility = ConsultationEligibility.fromJson(response.data);
        debugPrint(
            '✅ Eligibility parsed: canApply=${eligibility.canApply}, status=${eligibility.status}');
        return eligibility;
      }

      debugPrint('⚠️ Non-200 status code: ${response.statusCode}');
      return ConsultationEligibility(
        canApply: false,
        isConsultant: false,
        status: 'error',
        message: 'Failed to check eligibility',
      );
    } catch (e) {
      debugPrint('❌ Error checking consultation eligibility: $e');
      if (e is dio.DioException) {
        debugPrint('   Response data: ${e.response?.data}');
        debugPrint('   Status code: ${e.response?.statusCode}');
      }
      return ConsultationEligibility(
        canApply: false,
        isConsultant: false,
        status: 'error',
        message: 'Error checking eligibility: $e',
      );
    }
  }

  /// Submit consultant application
  Future<ConsultationApplicationResult> submitApplication({
    bool? offersPhysicalConsultations,
    required bool termsAccepted,
  }) async {
    try {
      debugPrint('📤 Submitting consultant application...');
      final data = {
        'terms_accepted': termsAccepted,
      };

      // Only include physical consultations if explicitly provided (for law firms)
      if (offersPhysicalConsultations != null) {
        data['offers_physical_consultations'] = offersPhysicalConsultations;
      }

      final response = await _apiService.post(
        EnvironmentConfig.consultationApplyUrl,
        data: data,
      );

      debugPrint('📥 Application Response: ${response.statusCode}');

      if (response.statusCode == 201) {
        return ConsultationApplicationResult(
          success: true,
          message:
              response.data['message'] ?? 'Application submitted successfully',
          nextSteps: response.data['next_steps'] != null
              ? List<String>.from(response.data['next_steps'])
              : null,
          registration: response.data['registration'],
        );
      }

      return ConsultationApplicationResult(
        success: false,
        message: response.data['error'] ?? 'Failed to submit application',
      );
    } catch (e) {
      debugPrint('❌ Error submitting consultation application: $e');
      if (e is dio.DioException && e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map) {
          // Handle validation errors
          if (errorData.containsKey('error')) {
            return ConsultationApplicationResult(
              success: false,
              message: errorData['error'].toString(),
            );
          }
          // Handle field-specific errors
          final firstError = errorData.values.first;
          return ConsultationApplicationResult(
            success: false,
            message: firstError is List
                ? firstError.first.toString()
                : firstError.toString(),
          );
        }
      }
      return ConsultationApplicationResult(
        success: false,
        message: 'Error submitting application: $e',
      );
    }
  }

  /// Get consultant profile (for approved consultants)
  Future<ConsultantProfile?> getMyProfile() async {
    try {
      debugPrint('🔍 Fetching consultant profile...');
      final response = await _apiService.get(
        EnvironmentConfig.consultationMyProfileUrl,
      );

      if (response.statusCode == 200) {
        return ConsultantProfile.fromJson(response.data);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error fetching consultant profile: $e');
      return null;
    }
  }

  /// Update consultant profile availability and other fields
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      debugPrint('📤 Updating consultant profile...');
      final response = await _apiService.patch(
        EnvironmentConfig.consultationMyProfileUrl,
        data: data,
      );

      debugPrint('📥 Update Response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      return false;
    }
  }

  /// Get consultant reviews
  Future<ConsultantReviewsResponse?> getMyReviews({
    int? rating,
    bool? responded,
  }) async {
    try {
      debugPrint('🔍 Fetching consultant reviews...');
      final queryParams = <String, dynamic>{};
      if (rating != null) queryParams['rating'] = rating;
      if (responded != null) queryParams['responded'] = responded;

      final response = await _apiService.get(
        EnvironmentConfig.consultationMyReviewsUrl,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return ConsultantReviewsResponse.fromJson(response.data);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error fetching reviews: $e');
      return null;
    }
  }

  /// Respond to a review
  Future<bool> respondToReview(int reviewId, String responseText) async {
    try {
      debugPrint('📤 Responding to review $reviewId...');
      final response = await _apiService.post(
        '${EnvironmentConfig.consultantRespondToReviewUrl}$reviewId/respond-to-review/',
        data: {'response': responseText},
      );

      debugPrint('📥 Response submitted: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error responding to review: $e');
      return false;
    }
  }

  /// Get list of available consultants for booking
  /// For advocates, lawyers, and paralegals: only mobile consultations
  /// For other users: all consultation types
  Future<List<ConsultantProfile>> getAvailableConsultants({
    bool mobileOnly = false,
    String? specialization,
  }) async {
    try {
      debugPrint(
          '🔍 Fetching available consultants (mobileOnly: $mobileOnly)...');
      final queryParams = <String, dynamic>{};
      if (mobileOnly) {
        queryParams['offers_mobile'] = true;
      }
      if (specialization != null) {
        queryParams['specialization'] = specialization;
      }

      final response = await _apiService.get(
        EnvironmentConfig.consultantListUrl,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'] ?? response.data;
        return data.map((json) => ConsultantProfile.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('❌ Error fetching consultants: $e');
      return [];
    }
  }

  /// Get my consultations (unified: bookings + calls)
  /// This returns ALL consultations (scheduled bookings + instant calls) for this consultant
  Future<MyConsultationsResponse?> getMyConsultations({
    int page = 1,
    int pageSize = 20,
    String?
        status, // For bookings: 'pending', 'confirmed', 'in_progress', 'completed', 'cancelled'
    // For calls: 'ringing', 'active', 'completed', 'rejected', 'missed', 'cancelled'
    String? type, // Filter by type: 'booking', 'call', 'mobile', or 'physical'
  }) async {
    try {
      debugPrint('📋 Fetching my consultations (unified)...');

      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      final response = await _apiService.get(
        EnvironmentConfig.consultationMyConsultationsUrl,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Consultations fetched: ${response.data['count']} total');
        return MyConsultationsResponse.fromJson(response.data);
      }

      debugPrint('⚠️ Failed to fetch consultations: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching my consultations: $e');
      return null;
    }
  }

  /// Get my bookings as a CLIENT (physical consultations I've booked)
  /// API: GET /api/v1/subscriptions/physical-consultations/
  Future<MyBookingsResponse?> getMyBookings({
    int page = 1,
    int pageSize = 20,
    String? status, // 'pending', 'confirmed', 'completed', 'cancelled'
  }) async {
    try {
      debugPrint('📋 Fetching my bookings as client... status filter: $status');

      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      debugPrint('📤 Query params: $queryParams');

      final response = await _apiService.get(
        '/api/v1/subscriptions/physical-consultations/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ My bookings fetched: ${response.data['count']} total (filter: $status)');
        return MyBookingsResponse.fromJson(response.data);
      }

      debugPrint('⚠️ Failed to fetch my bookings: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching my bookings: $e');
      return null;
    }
  }

  /// Get client's call history
  /// API: GET /api/v1/subscriptions/call-history/my-history/
  Future<CallHistoryResponse?> getMyCallHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      debugPrint('📞 Fetching my call history...');

      final response = await _apiService.get(
        '/api/v1/subscriptions/call-history/my-history/',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Call history fetched: ${response.data['count']} calls');
        return CallHistoryResponse.fromJson(response.data);
      }

      debugPrint('⚠️ Failed to fetch call history: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching call history: $e');
      return null;
    }
  }

  /// Get client's call credits
  /// API: GET /api/v1/subscriptions/call-history/my-credits/
  Future<CallCreditsResponse?> getMyCallCredits() async {
    try {
      debugPrint('💳 Fetching my call credits...');

      final response = await _apiService.get(
        '/api/v1/subscriptions/call-history/my-credits/',
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Call credits fetched: ${response.data['total_minutes']} minutes');
        return CallCreditsResponse.fromJson(response.data);
      }

      debugPrint('⚠️ Failed to fetch call credits: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching call credits: $e');
      return null;
    }
  }

  /// Update consultation status (accept, reject, complete)
  Future<bool> updateConsultationStatus({
    required int consultationId,
    required String status, // 'confirmed', 'rejected', 'completed'
    String? notes,
  }) async {
    try {
      debugPrint('📤 Updating consultation status to: $status');

      final data = <String, dynamic>{
        'status': status,
      };

      if (notes != null && notes.isNotEmpty) {
        data['notes'] = notes;
      }

      final response = await _apiService.patch(
        '${EnvironmentConfig.consultationUpdateStatusUrl}$consultationId/status/',
        data: data,
      );

      debugPrint('📥 Status update response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error updating consultation status: $e');
      return false;
    }
  }

  /// Create a new physical consultation booking (Law Firms only)
  /// API: POST /api/v1/consultations/book/
  /// Note: Only Law Firms can be booked for physical consultations
  Future<ConsultationBooking?> createBooking({
    required int consultantProfileId,
    required String topic,
    required String description,
    required DateTime scheduledDate,
    required String scheduledTime,
    required String location,
    required String phoneNumber,
    int durationMinutes = 60,
    String paymentMethod = 'mobile_money',
  }) async {
    try {
      debugPrint('📤 Creating physical consultation booking for law firm profile $consultantProfileId');

      final data = <String, dynamic>{
        'consultant_id': consultantProfileId,  // API expects consultant_id
        'booking_type': 'physical',  // API requires booking_type
        'topic': topic,
        'description': description,
        'scheduled_date': scheduledDate.toIso8601String().split('T')[0], // YYYY-MM-DD
        'scheduled_time': scheduledTime, // HH:MM:SS
        'duration_minutes': durationMinutes,
        'location': location,
        'payment_method': paymentMethod,
        'phone_number': phoneNumber,
      };

      final response = await _apiService.post(
        EnvironmentConfig.consultationCreateUrl,
        data: data,
      );

      debugPrint('📥 Create booking response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Handle the new response format with booking and payment info
        if (response.data is Map && response.data['booking'] != null) {
          return ConsultationBooking.fromJson(response.data['booking']);
        }
        return ConsultationBooking.fromJson(response.data);
      }

      debugPrint('⚠️ Failed to create booking: ${response.statusCode}');
      debugPrint('⚠️ Response: ${response.data}');
      return null;
    } catch (e) {
      debugPrint('❌ Error creating booking: $e');
      return null;
    }
  }

  /// Step 1: Create a physical booking (pending status)
  /// API: POST /api/v1/subscriptions/physical-consultations/book/
  Future<PhysicalBookingResponse?> createPhysicalBooking({
    required int consultantId,
    required DateTime scheduledDate,
    required int durationMinutes,
    required String meetingLocation,
    String? clientNotes,
  }) async {
    try {
      debugPrint('');
      debugPrint('========== PHYSICAL BOOKING REQUEST ==========');
      debugPrint('📤 Consultant ID being sent: $consultantId');
      debugPrint('📤 Scheduled Date: ${scheduledDate.toUtc().toIso8601String()}');
      debugPrint('📤 Duration: $durationMinutes minutes');
      debugPrint('📤 Location: $meetingLocation');
      debugPrint('📤 Notes: $clientNotes');

      final data = <String, dynamic>{
        'consultant_id': consultantId,
        'scheduled_date': scheduledDate.toUtc().toIso8601String(),
        'scheduled_duration_minutes': durationMinutes,
        'meeting_location': meetingLocation,
        'booking_type': 'physical',
        if (clientNotes != null && clientNotes.isNotEmpty)
          'client_notes': clientNotes,
      };

      debugPrint('📤 Full Request Body: $data');
      debugPrint('📤 Endpoint: /api/v1/subscriptions/physical-consultations/book/');
      debugPrint('===============================================');
      debugPrint('');

      final response = await _apiService.post(
        '/api/v1/subscriptions/physical-consultations/book/',
        data: data,
      );

      debugPrint('📥 Create booking response: ${response.statusCode}');
      debugPrint('📥 Response data: ${response.data}');
      
      // Debug: Print booking details
      if (response.data is Map) {
        final bookingData = response.data['booking'];
        if (bookingData != null) {
          debugPrint('📥 Booking data:');
          debugPrint('   total_amount: ${bookingData['total_amount']}');
          debugPrint('   platform_commission: ${bookingData['platform_commission']}');
          debugPrint('   consultant_earnings: ${bookingData['consultant_earnings']}');
        }
        debugPrint('📥 payment_info: ${response.data['payment_info']}');
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        return PhysicalBookingResponse.fromJson(response.data);
      }

      // Handle error response
      if (response.data is Map) {
        final errors = <String>[];
        response.data.forEach((key, value) {
          if (value is List) {
            errors.addAll(value.map((e) => '$key: $e'));
          } else {
            errors.add('$key: $value');
          }
        });
        return PhysicalBookingResponse(
          success: false,
          message: errors.join(', '),
        );
      }

      return PhysicalBookingResponse(
        success: false,
        message: 'Failed to create booking: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('❌ Error creating physical booking: $e');
      return PhysicalBookingResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// Step 2: Initiate payment for a booking via Unified Payment API
  /// API: POST /api/v1/subscriptions/unified-payments/initiate/
  Future<Map<String, dynamic>?> initiateBookingPayment({
    required int bookingId,
    required String phoneNumber,
    String provider = 'Mpesa',
  }) async {
    try {
      debugPrint('📤 Initiating payment for booking $bookingId');

      final data = <String, dynamic>{
        'payment_category': 'consultation',
        'item_id': bookingId,
        'phone_number': phoneNumber,
        'payment_method': 'mobile_money',
        'provider': provider,
      };

      debugPrint('📤 Payment request: $data');

      final response = await _apiService.post(
        '/api/v1/subscriptions/unified-payments/initiate/',
        data: data,
      );

      debugPrint('📥 Payment response: ${response.statusCode}');
      debugPrint('📥 Response data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          ...response.data,
        };
      }

      return {
        'success': false,
        'error': response.data['error'] ?? 'Payment initiation failed',
      };
    } catch (e) {
      debugPrint('❌ Error initiating payment: $e');
      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }

  /// Check booking status
  /// API: GET /api/v1/subscriptions/physical-consultations/{booking_id}/
  Future<String> checkBookingStatus(int bookingId) async {
    try {
      final response = await _apiService.get(
        '/api/v1/subscriptions/physical-consultations/$bookingId/',
      );

      if (response.statusCode == 200 && response.data is Map) {
        return response.data['status'] ?? 'pending';
      }
      return 'pending';
    } catch (e) {
      debugPrint('❌ Error checking booking status: $e');
      return 'pending';
    }
  }
}

/// Response from creating a physical booking
class PhysicalBookingResponse {
  final bool success;
  final String? message;
  final PhysicalBooking? booking;
  final Map<String, dynamic>? paymentInfo;
  final Map<String, dynamic>? nextStep;

  PhysicalBookingResponse({
    required this.success,
    this.message,
    this.booking,
    this.paymentInfo,
    this.nextStep,
  });

  factory PhysicalBookingResponse.fromJson(Map<String, dynamic> json) {
    return PhysicalBookingResponse(
      success: json['success'] ?? true,
      message: json['message'],
      booking: json['booking'] != null
          ? PhysicalBooking.fromJson(json['booking'])
          : null,
      paymentInfo: json['payment_info'],
      nextStep: json['next_step'],
    );
  }
}

/// Physical booking model
class PhysicalBooking {
  final int id;
  final int client;
  final int consultant;
  final String bookingType;
  final String status;
  final DateTime? scheduledDate;
  final int scheduledDurationMinutes;
  final String totalAmount;
  final String platformCommission;
  final String consultantEarnings;
  final String? meetingLocation;
  final String? clientNotes;
  final DateTime createdAt;

  PhysicalBooking({
    required this.id,
    required this.client,
    required this.consultant,
    required this.bookingType,
    required this.status,
    this.scheduledDate,
    required this.scheduledDurationMinutes,
    required this.totalAmount,
    required this.platformCommission,
    required this.consultantEarnings,
    this.meetingLocation,
    this.clientNotes,
    required this.createdAt,
  });

  factory PhysicalBooking.fromJson(Map<String, dynamic> json) {
    return PhysicalBooking(
      id: json['id'] ?? 0,
      client: json['client'] ?? 0,
      consultant: json['consultant'] ?? 0,
      bookingType: json['booking_type'] ?? 'physical',
      status: json['status'] ?? 'pending',
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.tryParse(json['scheduled_date'])
          : null,
      scheduledDurationMinutes: json['scheduled_duration_minutes'] ?? 60,
      totalAmount: json['total_amount']?.toString() ?? '0',
      platformCommission: json['platform_commission']?.toString() ?? '0',
      consultantEarnings: json['consultant_earnings']?.toString() ?? '0',
      meetingLocation: json['meeting_location'],
      clientNotes: json['client_notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

class ConsultationEligibility {
  final bool canApply;
  final bool isConsultant;
  final String status;
  final String? message;
  final Map<String, dynamic>? application;
  final int? profileId;
  final String? consultantType;
  final bool? isAvailable;

  ConsultationEligibility({
    required this.canApply,
    required this.isConsultant,
    required this.status,
    this.message,
    this.application,
    this.profileId,
    this.consultantType,
    this.isAvailable,
  });

  factory ConsultationEligibility.fromJson(Map<String, dynamic> json) {
    return ConsultationEligibility(
      canApply: json['can_apply'] ?? false,
      isConsultant: json['is_consultant'] ?? false,
      status: json['status'] ?? 'unknown',
      message: json['message'],
      application: json['application'],
      profileId: json['profile_id'],
      consultantType: json['consultant_type'],
      isAvailable: json['is_available'],
    );
  }
}

class ConsultationApplicationResult {
  final bool success;
  final String message;
  final List<String>? nextSteps;
  final Map<String, dynamic>? registration;

  ConsultationApplicationResult({
    required this.success,
    required this.message,
    this.nextSteps,
    this.registration,
  });
}

class ConsultantProfile {
  final int id;
  final int user;
  final Map<String, dynamic>? userDetails;
  final String consultantType;
  final String? specialization;
  final int? yearsOfExperience;
  final bool offersMobileConsultations;
  final bool offersPhysicalConsultations;
  final String? city;
  final bool isAvailable;
  final int totalConsultations;
  final double totalEarnings;
  final double? averageRating;
  final int totalReviews;
  final Map<String, dynamic>? statistics;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ConsultantProfile({
    required this.id,
    required this.user,
    this.userDetails,
    required this.consultantType,
    this.specialization,
    this.yearsOfExperience,
    required this.offersMobileConsultations,
    required this.offersPhysicalConsultations,
    this.city,
    required this.isAvailable,
    required this.totalConsultations,
    required this.totalEarnings,
    this.averageRating,
    required this.totalReviews,
    this.statistics,
    required this.createdAt,
    this.updatedAt,
  });

  factory ConsultantProfile.fromJson(Map<String, dynamic> json) {
    return ConsultantProfile(
      id: json['id'],
      user: json['user'],
      userDetails: json['user_details'],
      consultantType: json['consultant_type'] ?? '',
      specialization: json['specialization'],
      yearsOfExperience: json['years_of_experience'],
      offersMobileConsultations: json['offers_mobile_consultations'] ?? true,
      offersPhysicalConsultations:
          json['offers_physical_consultations'] ?? false,
      city: json['city'],
      isAvailable: json['is_available'] ?? true,
      totalConsultations: json['total_consultations'] ?? 0,
      totalEarnings:
          double.tryParse(json['total_earnings']?.toString() ?? '0') ?? 0.0,
      averageRating: json['average_rating'] != null
          ? double.tryParse(json['average_rating'].toString())
          : null,
      totalReviews: json['total_reviews'] ?? 0,
      statistics: json['statistics'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // Helper methods to access statistics
  int get consultationsThisMonth =>
      statistics?['consultations']?['this_month'] ?? 0;
  int get consultationsThisWeek =>
      statistics?['consultations']?['this_week'] ?? 0;
  double get earningsThisMonth =>
      (statistics?['earnings']?['this_month'] as num?)?.toDouble() ?? 0.0;
  double get completionRate =>
      (statistics?['performance']?['completion_rate'] as num?)?.toDouble() ??
      0.0;
}

class ConsultantReview {
  final int id;
  final Map<String, dynamic>? client;
  final int bookingId;
  final String bookingType;
  final DateTime bookingDate;
  final int rating;
  final String? reviewText;
  final int? professionalismRating;
  final int? communicationRating;
  final int? expertiseRating;
  final String? consultantResponse;
  final DateTime? responseDate;
  final DateTime createdAt;

  ConsultantReview({
    required this.id,
    this.client,
    required this.bookingId,
    required this.bookingType,
    required this.bookingDate,
    required this.rating,
    this.reviewText,
    this.professionalismRating,
    this.communicationRating,
    this.expertiseRating,
    this.consultantResponse,
    this.responseDate,
    required this.createdAt,
  });

  factory ConsultantReview.fromJson(Map<String, dynamic> json) {
    return ConsultantReview(
      id: json['id'],
      client: json['client'],
      bookingId: json['booking_id'],
      bookingType: json['booking_type'],
      bookingDate: DateTime.parse(json['booking_date']),
      rating: json['rating'],
      reviewText: json['review_text'],
      professionalismRating: json['professionalism_rating'],
      communicationRating: json['communication_rating'],
      expertiseRating: json['expertise_rating'],
      consultantResponse: json['consultant_response'],
      responseDate: json['response_date'] != null
          ? DateTime.parse(json['response_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ConsultantReviewsResponse {
  final int count;
  final List<ConsultantReview> reviews;
  final Map<String, dynamic>? summary;

  ConsultantReviewsResponse({
    required this.count,
    required this.reviews,
    this.summary,
  });

  factory ConsultantReviewsResponse.fromJson(Map<String, dynamic> json) {
    return ConsultantReviewsResponse(
      count: json['count'] ?? 0,
      reviews: (json['reviews'] as List<dynamic>? ?? [])
          .map((r) => ConsultantReview.fromJson(r))
          .toList(),
      summary: json['summary'],
    );
  }
}

class MyConsultationsResponse {
  final int count;
  final int page;
  final int pageSize;
  final int totalPages;
  final ConsultationSummary? summary;
  final List<ConsultationBooking> consultations;

  MyConsultationsResponse({
    required this.count,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    this.summary,
    required this.consultations,
  });

  factory MyConsultationsResponse.fromJson(Map<String, dynamic> json) {
    return MyConsultationsResponse(
      count: json['count'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 20,
      totalPages: json['total_pages'] ?? 1,
      summary: json['summary'] != null
          ? ConsultationSummary.fromJson(json['summary'])
          : null,
      consultations: (json['consultations'] as List<dynamic>? ?? [])
          .map((item) => ConsultationBooking.fromJson(item))
          .toList(),
    );
  }

  // Legacy compatibility - map consultations to results
  List<ConsultationBooking> get results => consultations;
}

/// Response for client's own bookings (physical consultations)
class MyBookingsResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<ClientBooking> results;

  MyBookingsResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory MyBookingsResponse.fromJson(Map<String, dynamic> json) {
    return MyBookingsResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List<dynamic>? ?? [])
          .map((item) => ClientBooking.fromJson(item))
          .toList(),
    );
  }

  int get totalPages => (count / 20).ceil();
}

/// Booking model for client view
class ClientBooking {
  final int id;
  final String? reference;
  final String status;
  final String bookingType;
  final DateTime? scheduledDate;
  final String? meetingLocation;
  final String totalAmount;
  final int? consultantId;
  final Map<String, dynamic>? consultantDetails;
  final int scheduledDurationMinutes;
  final String? clientNotes;
  final DateTime createdAt;

  ClientBooking({
    required this.id,
    this.reference,
    required this.status,
    required this.bookingType,
    this.scheduledDate,
    this.meetingLocation,
    required this.totalAmount,
    this.consultantId,
    this.consultantDetails,
    required this.scheduledDurationMinutes,
    this.clientNotes,
    required this.createdAt,
  });

  factory ClientBooking.fromJson(Map<String, dynamic> json) {
    // Handle consultant field - can be int ID or Map object
    int? consultantId;
    Map<String, dynamic>? consultantDetails;
    
    final consultantData = json['consultant'];
    if (consultantData is int) {
      consultantId = consultantData;
    } else if (consultantData is Map<String, dynamic>) {
      consultantDetails = consultantData;
      consultantId = consultantData['id'];
    }
    
    // Also check consultant_details field
    if (consultantDetails == null && json['consultant_details'] != null) {
      consultantDetails = json['consultant_details'];
    }

    return ClientBooking(
      id: json['id'] ?? 0,
      reference: json['reference'],
      status: json['status'] ?? 'pending',
      bookingType: json['booking_type'] ?? 'physical',
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.tryParse(json['scheduled_date'])
          : null,
      meetingLocation: json['meeting_location'],
      totalAmount: json['total_amount']?.toString() ?? '0',
      consultantId: consultantId,
      consultantDetails: consultantDetails,
      scheduledDurationMinutes: json['scheduled_duration_minutes'] ?? 
          json['duration_minutes'] ?? 60,
      clientNotes: json['client_notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  // Convenience getters
  String get consultantName => consultantDetails?['name'] ?? 
      consultantDetails?['full_name'] ?? 
      'Consultant #$consultantId';
}

class ConsultationSummary {
  final int totalBookings;
  final int totalCalls;
  final int totalCombined;

  ConsultationSummary({
    required this.totalBookings,
    required this.totalCalls,
    required this.totalCombined,
  });

  factory ConsultationSummary.fromJson(Map<String, dynamic> json) {
    return ConsultationSummary(
      totalBookings: json['total_bookings'] ?? 0,
      totalCalls: json['total_calls'] ?? 0,
      totalCombined: json['total_combined'] ?? 0,
    );
  }
}

class ConsultationBooking {
  final String type; // 'call' or 'booking'
  final int id;
  final Map<String, dynamic> client; // Client who booked/called

  // Common fields
  final String status;
  final DateTime createdAt;

  // Booking-specific fields (null for calls)
  final String? bookingType; // 'mobile' or 'physical' (for bookings)
  final String? topic;
  final DateTime? scheduledDate;
  final double? amount;

  // Call-specific fields (null for bookings)
  final String? callType; // 'voice' or 'video' (for calls)
  final String? channelName;
  final DateTime? initiatedAt;
  final DateTime? acceptedAt;
  final DateTime? endedAt;
  final int? durationMinutes;
  final double? creditsDeducted;

  ConsultationBooking({
    required this.type,
    required this.id,
    required this.client,
    required this.status,
    required this.createdAt,
    // Booking fields
    this.bookingType,
    this.topic,
    this.scheduledDate,
    this.amount,
    // Call fields
    this.callType,
    this.channelName,
    this.initiatedAt,
    this.acceptedAt,
    this.endedAt,
    this.durationMinutes,
    this.creditsDeducted,
  });

  factory ConsultationBooking.fromJson(Map<String, dynamic> json) {
    return ConsultationBooking(
      type: json['type'] ?? 'booking',
      id: json['id'] ?? 0,
      client: (json['client'] as Map<String, dynamic>?) ?? {},
      status: json['status'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      // Booking-specific fields
      bookingType: json['booking_type'],
      topic: json['topic'],
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'])
          : null,
      amount: json['amount'] != null
          ? double.tryParse(json['amount'].toString())
          : null,
      // Call-specific fields
      callType: json['call_type'],
      channelName: json['channel_name'],
      initiatedAt: json['initiated_at'] != null
          ? DateTime.parse(json['initiated_at'])
          : null,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
      endedAt:
          json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      durationMinutes: json['duration_minutes'],
      creditsDeducted: json['credits_deducted'] != null
          ? double.tryParse(json['credits_deducted'].toString())
          : null,
    );
  }

  // Helper getters for client info
  String get clientName {
    final name = client['name'];
    if (name != null && name.isNotEmpty) return name;

    final firstName = client['first_name'] ?? '';
    final lastName = client['last_name'] ?? '';
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    return client['email']?.split('@').first ?? 'Unknown Client';
  }

  String get clientEmail => client['email'] ?? '';
  int get clientId => client['id'] ?? 0;

  // Type checking helpers
  bool get isCall => type == 'call';
  bool get isBooking => type == 'booking';

  // Status helpers for bookings
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  bool get isInProgress => status.toLowerCase() == 'in_progress';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  // Status helpers for calls
  bool get isRinging => status.toLowerCase() == 'ringing';
  bool get isActive => status.toLowerCase() == 'active';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isMissed => status.toLowerCase() == 'missed';

  // Display helpers
  String get consultationType {
    if (isCall) {
      return callType ?? 'call';
    }
    return bookingType ?? 'booking';
  }

  String get statusLabel {
    if (isCall) {
      switch (status.toLowerCase()) {
        case 'completed':
          return 'Call Completed';
        case 'missed':
          return 'Missed Call';
        case 'rejected':
          return 'Call Rejected';
        case 'active':
          return 'Ongoing Call';
        case 'ringing':
          return 'Incoming Call';
        default:
          return status;
      }
    } else {
      switch (status.toLowerCase()) {
        case 'confirmed':
          return 'Confirmed';
        case 'pending':
          return 'Pending';
        case 'completed':
          return 'Completed';
        case 'in_progress':
          return 'In Progress';
        case 'cancelled':
          return 'Cancelled';
        default:
          return status;
      }
    }
  }

  // Legacy compatibility
  @deprecated
  String get scheduledTime =>
      scheduledDate?.toIso8601String().split('T').last.substring(0, 5) ?? '';

  @deprecated
  double? get price => amount;

  @deprecated
  DateTime? get updatedAt => endedAt ?? acceptedAt;

  @deprecated
  String? get notes => topic;
}

/// Response for client's call history
class CallHistoryResponse {
  final int count;
  final int limit;
  final int offset;
  final int totalMinutesUsed;
  final List<ClientCallRecord> calls;

  CallHistoryResponse({
    required this.count,
    required this.limit,
    required this.offset,
    required this.totalMinutesUsed,
    required this.calls,
  });

  factory CallHistoryResponse.fromJson(Map<String, dynamic> json) {
    return CallHistoryResponse(
      count: json['count'] ?? 0,
      limit: json['limit'] ?? 20,
      offset: json['offset'] ?? 0,
      totalMinutesUsed: json['total_minutes_used'] ?? 0,
      calls: (json['calls'] as List<dynamic>? ?? [])
          .map((item) => ClientCallRecord.fromJson(item))
          .toList(),
    );
  }
}

/// Call record model for client view
class ClientCallRecord {
  final int id;
  final Map<String, dynamic>? consultant;
  final int durationMinutes;
  final DateTime? startTime;
  final DateTime? endTime;
  final String date;
  final int? callQualityRating;

  ClientCallRecord({
    required this.id,
    this.consultant,
    required this.durationMinutes,
    this.startTime,
    this.endTime,
    required this.date,
    this.callQualityRating,
  });

  factory ClientCallRecord.fromJson(Map<String, dynamic> json) {
    return ClientCallRecord(
      id: json['id'] ?? 0,
      consultant: json['consultant'],
      durationMinutes: json['duration_minutes'] ?? 0,
      startTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'])
          : null,
      endTime: json['end_time'] != null
          ? DateTime.tryParse(json['end_time'])
          : null,
      date: json['date'] ?? '',
      callQualityRating: json['call_quality_rating'],
    );
  }

  String get consultantName => consultant?['name'] ?? 'Unknown Consultant';
}

/// Response for client's call credits
class CallCreditsResponse {
  final int totalMinutes;
  final List<ActiveCredit> activeCredits;

  CallCreditsResponse({
    required this.totalMinutes,
    required this.activeCredits,
  });

  factory CallCreditsResponse.fromJson(Map<String, dynamic> json) {
    return CallCreditsResponse(
      totalMinutes: json['total_minutes'] ?? 0,
      activeCredits: (json['active_credits'] as List<dynamic>? ?? [])
          .map((item) => ActiveCredit.fromJson(item))
          .toList(),
    );
  }
}

/// Active credit bundle for client
class ActiveCredit {
  final int id;
  final String bundleName;
  final int remainingMinutes;
  final DateTime? expiresAt;

  ActiveCredit({
    required this.id,
    required this.bundleName,
    required this.remainingMinutes,
    this.expiresAt,
  });

  factory ActiveCredit.fromJson(Map<String, dynamic> json) {
    return ActiveCredit(
      id: json['id'] ?? 0,
      bundleName: json['bundle_name'] ?? 'Bundle',
      remainingMinutes: json['remaining_minutes'] ?? 0,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'])
          : null,
    );
  }
}

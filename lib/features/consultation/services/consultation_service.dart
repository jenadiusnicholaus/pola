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

  /// Get my consultations/bookings as a consultant
  /// This returns bookings made TO this consultant by other users
  Future<MyConsultationsResponse?> getMyConsultations({
    int page = 1,
    int pageSize = 20,
    String? status, // 'pending', 'confirmed', 'completed', 'cancelled'
  }) async {
    try {
      debugPrint('📋 Fetching my consultations as consultant...');

      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _apiService.get(
        EnvironmentConfig.consultationMyConsultationsUrl,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return MyConsultationsResponse.fromJson(response.data);
      }

      debugPrint('⚠️ Failed to fetch consultations: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching my consultations: $e');
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
  final String? next;
  final String? previous;
  final List<ConsultationBooking> results;

  MyConsultationsResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory MyConsultationsResponse.fromJson(Map<String, dynamic> json) {
    return MyConsultationsResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List<dynamic>? ?? [])
          .map((item) => ConsultationBooking.fromJson(item))
          .toList(),
    );
  }
}

class ConsultationBooking {
  final int id;
  final Map<String, dynamic> client; // Client who booked
  final String consultationType; // 'mobile' or 'physical'
  final DateTime scheduledDate;
  final String scheduledTime;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final String? notes;
  final double? price;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ConsultationBooking({
    required this.id,
    required this.client,
    required this.consultationType,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.status,
    this.notes,
    this.price,
    required this.createdAt,
    this.updatedAt,
  });

  factory ConsultationBooking.fromJson(Map<String, dynamic> json) {
    return ConsultationBooking(
      id: json['id'],
      client: json['client'] as Map<String, dynamic>,
      consultationType: json['consultation_type'] ?? 'mobile',
      scheduledDate: DateTime.parse(json['scheduled_date']),
      scheduledTime: json['scheduled_time'] ?? '',
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  String get clientName {
    final firstName = client['first_name'] ?? '';
    final lastName = client['last_name'] ?? '';
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    return client['email']?.split('@').first ?? 'Unknown Client';
  }

  String get clientEmail => client['email'] ?? '';
  String? get clientPhone => client['phone_number'];

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
}

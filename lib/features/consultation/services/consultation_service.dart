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
        '${EnvironmentConfig.baseUrl}/api/v1/consultants/application-status/',
      );

      debugPrint('📥 API Response Status: ${response.statusCode}');
      debugPrint('📥 API Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final eligibility = ConsultationEligibility.fromJson(response.data);
        debugPrint('✅ Eligibility parsed: canApply=${eligibility.canApply}, status=${eligibility.status}');
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
    required String consultantType,
    required dio.MultipartFile idDocument,
    dio.MultipartFile? licenseDocument,
    dio.MultipartFile? cvDocument,
    dio.MultipartFile? additionalDocuments,
    bool offersMobileConsultations = true,
    bool offersPhysicalConsultations = false,
    String? preferredConsultationCity,
    required bool termsAccepted,
  }) async {
    try {
      final formData = dio.FormData.fromMap({
        'consultant_type': consultantType,
        'id_document': idDocument,
        'offers_mobile_consultations': offersMobileConsultations,
        'offers_physical_consultations': offersPhysicalConsultations,
        'terms_accepted': termsAccepted,
      });

      if (licenseDocument != null) {
        formData.files.add(MapEntry('license_document', licenseDocument));
      }
      if (cvDocument != null) {
        formData.files.add(MapEntry('cv_document', cvDocument));
      }
      if (additionalDocuments != null) {
        formData.files
            .add(MapEntry('additional_documents', additionalDocuments));
      }
      if (offersPhysicalConsultations && preferredConsultationCity != null) {
        formData.fields.add(
            MapEntry('preferred_consultation_city', preferredConsultationCity));
      }

      final response = await _apiService.post(
        '${EnvironmentConfig.baseUrl}/api/v1/consultants/apply/',
        data: formData,
      );

      if (response.statusCode == 201) {
        return ConsultationApplicationResult(
          success: true,
          message:
              response.data['message'] ?? 'Application submitted successfully',
          nextSteps: List<String>.from(response.data['next_steps'] ?? []),
        );
      }

      return ConsultationApplicationResult(
        success: false,
        message: response.data['error'] ?? 'Failed to submit application',
      );
    } catch (e) {
      debugPrint('❌ Error submitting consultation application: $e');
      return ConsultationApplicationResult(
        success: false,
        message: 'Error submitting application: $e',
      );
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

  ConsultationApplicationResult({
    required this.success,
    required this.message,
    this.nextSteps,
  });
}

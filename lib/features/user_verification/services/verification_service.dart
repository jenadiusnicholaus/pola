import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/verification_models.dart';
import '../../../services/api_service.dart';
import '../../../config/environment_config.dart';

class VerificationService {
  final ApiService _apiService = ApiService();

  Options get _defaultOptions => Options(
        headers: {
          'Content-Type': 'application/json',
        },
      );

  /// Get current user's verification status
  Future<VerificationStatus?> getMyVerificationStatus() async {
    try {
      debugPrint('🔍 Fetching user verification status...');

      final response = await _apiService.get<Map<String, dynamic>>(
        EnvironmentConfig.verificationStatusUrl,
        options: _defaultOptions,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Verification status retrieved successfully');
        return VerificationStatus.fromJson(response.data!);
      } else {
        debugPrint('⚠️ Unexpected status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching verification status: $e');
      if (e is DioException) {
        debugPrint('Response data: ${e.response?.data}');
        debugPrint('Status code: ${e.response?.statusCode}');
      }
      return null;
    }
  }

  /// Get uploaded documents
  Future<List<VerificationDocument>?> getUploadedDocuments() async {
    try {
      debugPrint('📋 Fetching uploaded documents...');

      final response = await _apiService.post<Map<String, dynamic>>(
        EnvironmentConfig.verificationDocumentsUrl,
        options: _defaultOptions,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Documents retrieved successfully');
        final List<dynamic> documentsJson = response.data!['results'] ?? [];
        return documentsJson
            .map((json) => VerificationDocument.fromJson(json))
            .toList();
      } else {
        debugPrint('⚠️ Unexpected status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching documents: $e');
      if (e is DioException) {
        debugPrint('Response data: ${e.response?.data}');
        debugPrint('Status code: ${e.response?.statusCode}');
      }
      return null;
    }
  }

  /// Update user verification information
  Future<bool> updateVerificationInfo({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String? additionalInfo,
  }) async {
    try {
      debugPrint('📝 Updating verification info...');

      final requestData = {
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        if (additionalInfo != null) 'additional_info': additionalInfo,
      };

      final response = await _apiService.patch<Map<String, dynamic>>(
        EnvironmentConfig.verificationUpdateInfoUrl,
        data: requestData,
        options: _defaultOptions,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Verification info updated successfully');
        return true;
      } else {
        debugPrint('⚠️ Unexpected status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error updating verification info: $e');
      if (e is DioException) {
        debugPrint('Response data: ${e.response?.data}');
        debugPrint('Status code: ${e.response?.statusCode}');
      }
      return false;
    }
  }

  /// Submit verification for review
  Future<bool> submitForReview() async {
    try {
      debugPrint('🔍 Submitting verification for review...');

      final response = await _apiService.post<Map<String, dynamic>>(
        EnvironmentConfig.verificationSubmitReviewUrl,
        options: _defaultOptions,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Verification submitted for review successfully');
        return true;
      } else {
        debugPrint('⚠️ Unexpected status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error submitting for review: $e');
      if (e is DioException) {
        debugPrint('Response data: ${e.response?.data}');
        debugPrint('Status code: ${e.response?.statusCode}');
      }
      return false;
    }
  }

  /// Delete a document
  Future<bool> deleteDocument(int documentId) async {
    try {
      debugPrint('🗑️ Deleting document with ID: $documentId');

      final response = await _apiService.delete<Map<String, dynamic>>(
        EnvironmentConfig.verificationDeleteDocumentUrl(documentId),
        options: _defaultOptions,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('✅ Document deleted successfully');
        return true;
      } else {
        debugPrint('⚠️ Unexpected status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error deleting document: $e');
      if (e is DioException) {
        debugPrint('Response data: ${e.response?.data}');
        debugPrint('Status code: ${e.response?.statusCode}');
      }
      return false;
    }
  }

  /// Get required documents for verification
  Future<List<RequiredDocument>?> getRequiredDocuments() async {
    try {
      debugPrint('📋 Fetching required documents...');

      final response = await _apiService.get<Map<String, dynamic>>(
        EnvironmentConfig.verificationRequiredDocumentsUrl,
        options: _defaultOptions,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Required documents retrieved successfully');
        final List<dynamic> documentsJson = response.data!['results'] ?? [];
        return documentsJson
            .map((json) => RequiredDocument.fromJson(json))
            .toList();
      } else {
        debugPrint('⚠️ Unexpected status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching required documents: $e');
      if (e is DioException) {
        debugPrint('Response data: ${e.response?.data}');
        debugPrint('Status code: ${e.response?.statusCode}');
      }
      return null;
    }
  }

  // ============ COMPATIBILITY METHODS ============
  // These maintain backward compatibility with existing controller code

  /// Upload document with title (compatibility wrapper)
  Future<bool> uploadDocument({
    required String documentType,
    required File file,
    required String title,
    String? description,
  }) async {
    final result = await _uploadDocumentInternal(
      file: file,
      documentType: documentType,
      description: description ??
          title, // Use title as description if no description provided
    );
    return result != null && result.success;
  }

  /// Internal upload method (renamed from original)
  Future<DocumentUploadResult?> _uploadDocumentInternal({
    required File file,
    required String documentType,
    String? description,
  }) async {
    try {
      debugPrint('📤 Uploading document: $documentType');

      final formData = FormData.fromMap({
        'document_type': documentType,
        if (description != null) 'description': description,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _apiService.post<Map<String, dynamic>>(
        EnvironmentConfig.verificationUploadDocumentUrl,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Document uploaded successfully');
        return DocumentUploadResult.fromJson(response.data!);
      } else {
        debugPrint('⚠️ Unexpected status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error uploading document: $e');
      if (e is DioException) {
        debugPrint('Response data: ${e.response?.data}');
        debugPrint('Status code: ${e.response?.statusCode}');
      }
      return null;
    }
  }

  /// Alias for updateVerificationInfo with extended parameters
  Future<bool> updateUserInformation({
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? gender,
    String? phoneNumber,
    String? officeAddress,
    String? ward,
    String? district,
    String? region,
    Map<String, dynamic>? roleSpecificData,
  }) async {
    // Map the extended parameters to what the service expects
    return updateVerificationInfo(
      firstName: firstName ?? '',
      lastName: lastName ?? '',
      phoneNumber: phoneNumber ?? '',
      additionalInfo: [
        if (dateOfBirth != null) 'Date of Birth: $dateOfBirth',
        if (gender != null) 'Gender: $gender',
        if (officeAddress != null) 'Office Address: $officeAddress',
        if (ward != null) 'Ward: $ward',
        if (district != null) 'District: $district',
        if (region != null) 'Region: $region',
        if (roleSpecificData != null)
          'Role Data: ${roleSpecificData.toString()}',
      ].join(', '),
    );
  }

  /// Upload document with base64 encoding (compatibility method)
  Future<bool> uploadDocumentBase64({
    required String documentType,
    required String base64Data,
    required String fileName,
    String? description,
  }) async {
    // This would need to be implemented if base64 upload is supported
    throw UnimplementedError('Base64 upload not implemented in current API');
  }

  /// Check if role needs verification (static method compatibility)
  static bool roleNeedsVerification(String roleName) {
    // Define roles that need verification
    const verificationRequiredRoles = [
      'advocate',
      'student',
      'paralegal',
      'law_firm',
      'legal_aid_provider'
    ];

    return verificationRequiredRoles.contains(roleName.toLowerCase());
  }
}

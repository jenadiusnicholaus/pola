import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/verification_models.dart';
import '../../../services/token_storage_service.dart';

class VerificationService {
  final dio.Dio _dio;
  final TokenStorageService _tokenStorage = Get.find<TokenStorageService>();

  VerificationService() : _dio = dio.Dio() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to requests
          final token = _tokenStorage.accessToken;
          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Content-Type'] = 'application/json';
          handler.next(options);
        },
        onError: (error, handler) {
          debugPrint('❌ Verification API Error: ${error.message}');
          if (error.response != null) {
            debugPrint('Response data: ${error.response?.data}');
            debugPrint('Status code: ${error.response?.statusCode}');
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Get current user's verification status
  Future<VerificationStatus?> getMyVerificationStatus() async {
    try {
      debugPrint('🔍 Fetching user verification status...');

      final response = await _dio.get(
        'http://localhost:8000/api/v1/authentication/verifications/my_status/',
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Verification status fetched successfully');
        return VerificationStatus.fromJson(response.data);
      } else {
        debugPrint(
            '❌ Failed to fetch verification status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      if (e is dio.DioException) {
        if (e.response?.statusCode == 404) {
          debugPrint('ℹ️ No verification record found for user');
          return null;
        }
        debugPrint('❌ dio.DioException in getMyVerificationStatus: ${e.message}');
      } else {
        debugPrint('❌ Exception in getMyVerificationStatus: $e');
      }
      return null;
    }
  }

  /// Upload a document for verification
  Future<bool> uploadDocument({
    required String documentType,
    required File file,
    required String title,
    String? description,
  }) async {
    try {
      debugPrint('📄 Uploading document: $documentType');

      final formData = dio.FormData.fromMap({
        'document_type': documentType,
        'title': title,
        'description': description ?? '',
        'file': await dio.MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        'http://localhost:8000/api/v1/authentication/verifications/upload_document/',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('✅ Document uploaded successfully');
        return true;
      } else {
        debugPrint('❌ Failed to upload document: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      if (e is dio.DioException) {
        debugPrint('❌ dio.DioException in uploadDocument: ${e.message}');
        if (e.response?.data != null) {
          debugPrint('Error details: ${e.response?.data}');
        }
      } else {
        debugPrint('❌ Exception in uploadDocument: $e');
      }
      return false;
    }
  }

  /// Upload a document using base64 encoding (as per API documentation)
  Future<bool> uploadDocumentBase64({
    required String documentType,
    required String title,
    required String description,
    required String fileData, // base64 data with mime type prefix
  }) async {
    try {
      debugPrint('📄 Uploading document (base64): $documentType');

      final requestData = {
        'document_type': documentType,
        'title': title,
        'description': description,
        'file': fileData,
      };

      final response = await _dio.post(
        'http://localhost:8000/api/v1/authentication/documents/',
        data: requestData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('✅ Document uploaded successfully (base64)');
        return true;
      } else {
        debugPrint('❌ Failed to upload document: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      if (e is dio.DioException) {
        debugPrint('❌ dio.DioException in uploadDocumentBase64: ${e.message}');
        if (e.response?.data != null) {
          debugPrint('Error details: ${e.response?.data}');
        }
      } else {
        debugPrint('❌ Exception in uploadDocumentBase64: $e');
      }
      return false;
    }
  }

  /// Update user information for verification
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
    try {
      debugPrint('🔄 Updating user information for verification...');

      final data = <String, dynamic>{};

      // Add basic info if provided
      if (firstName != null) data['first_name'] = firstName;
      if (lastName != null) data['last_name'] = lastName;
      if (dateOfBirth != null) data['date_of_birth'] = dateOfBirth;
      if (gender != null) data['gender'] = gender;

      // Add contact info if provided
      if (phoneNumber != null) data['phone_number'] = phoneNumber;

      // Add address info if provided
      final address = <String, dynamic>{};
      if (officeAddress != null) address['office_address'] = officeAddress;
      if (ward != null) address['ward'] = ward;
      if (district != null) address['district'] = district;
      if (region != null) address['region'] = region;
      if (address.isNotEmpty) data['address'] = address;

      // Add role-specific data if provided
      if (roleSpecificData != null) {
        data.addAll(roleSpecificData);
      }

      final response = await _dio.patch(
        'http://localhost:8000/api/v1/authentication/verifications/update_info/',
        data: data,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ User information updated successfully');
        return true;
      } else {
        debugPrint(
            '❌ Failed to update user information: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      if (e is dio.DioException) {
        debugPrint('❌ dio.DioException in updateUserInformation: ${e.message}');
        if (e.response?.data != null) {
          debugPrint('Error details: ${e.response?.data}');
        }
      } else {
        debugPrint('❌ Exception in updateUserInformation: $e');
      }
      return false;
    }
  }

  /// Submit verification for admin review
  Future<bool> submitForReview() async {
    try {
      debugPrint('📋 Submitting verification for admin review...');

      final response = await _dio.post(
        'http://localhost:8000/api/v1/authentication/verifications/submit_for_review/',
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Verification submitted for review successfully');
        return true;
      } else {
        debugPrint('❌ Failed to submit for review: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      if (e is dio.DioException) {
        debugPrint('❌ dio.DioException in submitForReview: ${e.message}');
        if (e.response?.data != null) {
          debugPrint('Error details: ${e.response?.data}');
        }
      } else {
        debugPrint('❌ Exception in submitForReview: $e');
      }
      return false;
    }
  }

  /// Delete a document
  Future<bool> deleteDocument(int documentId) async {
    try {
      debugPrint('🗑️ Deleting document: $documentId');

      final response = await _dio.delete(
        'http://localhost:8000/api/v1/authentication/verifications/documents/$documentId/',
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        debugPrint('✅ Document deleted successfully');
        return true;
      } else {
        debugPrint('❌ Failed to delete document: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      if (e is dio.DioException) {
        debugPrint('❌ dio.DioException in deleteDocument: ${e.message}');
      } else {
        debugPrint('❌ Exception in deleteDocument: $e');
      }
      return false;
    }
  }

  /// Get required document types for user's role
  Future<List<RequiredDocument>> getRequiredDocuments() async {
    try {
      debugPrint('📋 Fetching required documents...');

      final response = await _dio.get(
        'http://localhost:8000/api/v1/authentication/verifications/required_documents/',
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Required documents fetched successfully');
        final List<dynamic> data = response.data['documents'] ?? [];
        return data.map((doc) => RequiredDocument.fromJson(doc)).toList();
      } else {
        debugPrint(
            '❌ Failed to fetch required documents: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      if (e is dio.DioException) {
        debugPrint('❌ dio.DioException in getRequiredDocuments: ${e.message}');
      } else {
        debugPrint('❌ Exception in getRequiredDocuments: $e');
      }
      return [];
    }
  }

  /// Check if user role requires verification
  static bool roleNeedsVerification(String roleName) {
    return ['advocate', 'lawyer', 'law_firm', 'paralegal'].contains(roleName);
  }
}

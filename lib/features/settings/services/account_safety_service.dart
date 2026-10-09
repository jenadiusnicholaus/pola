import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../config/environment_config.dart';
import '../../../services/api_service.dart';
import '../models/safety_models.dart';

/// Handles block/report user actions and account & data deletion requests.
/// Backed by the endpoints documented in lib/docs/user_data_freedom.md.
class AccountSafetyService extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // ---------------- Block / Unblock ----------------

  Future<bool> blockUser({required int userId, String? reason}) async {
    try {
      final response = await _apiService.post(
        EnvironmentConfig.blockUserUrl,
        data: {
          'user_id': userId,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ blockUser failed: $e');
      rethrow;
    }
  }

  Future<bool> unblockUser(int userId) async {
    try {
      final response = await _apiService.post(
        EnvironmentConfig.getUnblockUserUrl(userId),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ unblockUser failed: $e');
      rethrow;
    }
  }

  Future<bool> isUserBlocked(int userId) async {
    try {
      final response = await _apiService.get(
        EnvironmentConfig.getCheckBlockedUrl(userId),
      );
      return response.data?['is_blocked'] == true;
    } catch (e) {
      debugPrint('❌ isUserBlocked failed: $e');
      return false;
    }
  }

  Future<List<BlockedUser>> listBlockedUsers() async {
    try {
      final response =
          await _apiService.get(EnvironmentConfig.blockedUsersListUrl);
      final results = (response.data?['results'] as List?) ?? [];
      return results
          .map((e) => BlockedUser.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ listBlockedUsers failed: $e');
      rethrow;
    }
  }

  // ---------------- Report ----------------

  Future<bool> reportUser({
    required int reportedUserId,
    required ReportType type,
    required String description,
  }) async {
    try {
      final response = await _apiService.post(
        EnvironmentConfig.reportUserUrl,
        data: {
          'reported_user_id': reportedUserId,
          'report_type': type.apiValue,
          'description': description,
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ reportUser failed: $e');
      rethrow;
    }
  }

  Future<bool> reportContent({
    required ReportType type,
    required String contentType,
    required String contentId,
    required String description,
  }) async {
    try {
      final response = await _apiService.post(
        EnvironmentConfig.reportUserUrl,
        data: {
          'report_type': type.apiValue,
          'content_type': contentType,
          'content_id': contentId,
          'description': description,
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ reportContent failed: $e');
      rethrow;
    }
  }

  Future<List<UserReport>> listMyReports() async {
    try {
      final response = await _apiService.get(EnvironmentConfig.myReportsUrl);
      final results = (response.data?['results'] as List?) ??
          (response.data as List?) ??
          [];
      return results
          .map((e) => UserReport.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ listMyReports failed: $e');
      rethrow;
    }
  }

  // ---------------- Account & Data Deletion ----------------

  Future<Map<String, dynamic>> deleteAccount({String? reason}) async {
    try {
      final response = await _apiService.post(
        EnvironmentConfig.deleteAccountUrl,
        data: {
          'deletion_type': 'account',
          'confirm': true,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      debugPrint('❌ deleteAccount failed: $e');
      rethrow;
    }
  }

  Future<bool> cancelDeletion(int requestId) async {
    try {
      final response = await _apiService.post(
        EnvironmentConfig.getCancelDeletionUrl(requestId),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ cancelDeletion failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteData(
      List<DataCategory> categories) async {
    try {
      final response = await _apiService.post(
        EnvironmentConfig.deleteDataUrl,
        data: {
          'data_categories': categories.map((c) => c.apiValue).toList(),
        },
      );
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      debugPrint('❌ deleteData failed: $e');
      rethrow;
    }
  }

  Future<List<DeletionRequest>> listDeletionRequests() async {
    try {
      final response =
          await _apiService.get(EnvironmentConfig.deletionRequestsUrl);
      final results = (response.data?['results'] as List?) ??
          (response.data as List?) ??
          [];
      return results
          .map((e) => DeletionRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ listDeletionRequests failed: $e');
      rethrow;
    }
  }
}

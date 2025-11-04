import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../models/legal_education_models.dart';
import '../../../../services/api_service.dart';
import '../../../../config/environment_config.dart';

class LegalEducationService extends GetxService {
  late final ApiService _apiService;

  LegalEducationService() {
    _apiService = Get.find<ApiService>();
  }

  // Get all topics
  Future<TopicsResponse> getTopics({
    String? search,
    String? language,
    bool? isActive = true,
    String? ordering = 'display_order',
    int? page,
    int? pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (search != null) queryParams['search'] = search;
      if (language != null) queryParams['language'] = language;
      if (isActive != null) queryParams['is_active'] = isActive;
      if (ordering != null) queryParams['ordering'] = ordering;
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;

      final response = await _apiService.get(
        EnvironmentConfig.legalEducationTopicsUrl,
        queryParameters: queryParams,
      );

      return TopicsResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e, 'Failed to fetch topics');
    }
  }

  // Get topic by slug
  Future<Topic> getTopicBySlug(String slug) async {
    try {
      final response = await _apiService
          .get('${EnvironmentConfig.legalEducationTopicsUrl}$slug/');
      return Topic.fromJson(response.data);
    } catch (e) {
      throw _handleError(e, 'Failed to fetch topic details');
    }
  }

  // Get materials for a topic (new direct approach)
  Future<MaterialsResponse> getTopicMaterials(
    String topicSlug, {
    String? language,
    String? contentType,
    String? uploaderType,
    String? search,
    bool? isFree,
    bool? isLectureMaterial,
    bool? isVerified,
    String? ordering = '-created_at',
    int? page,
    int? pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (language != null) queryParams['language'] = language;
      if (contentType != null) queryParams['content_type'] = contentType;
      if (uploaderType != null) queryParams['uploader_type'] = uploaderType;
      if (search != null) queryParams['search'] = search;
      if (isFree != null) queryParams['is_free'] = isFree;
      if (isLectureMaterial != null)
        queryParams['is_lecture_material'] = isLectureMaterial;
      if (isVerified != null) queryParams['is_verified'] = isVerified;
      if (ordering != null) queryParams['ordering'] = ordering;
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;

      final response = await _apiService.get(
        '${EnvironmentConfig.legalEducationTopicsUrl}$topicSlug/materials/',
        queryParameters: queryParams,
      );

      return MaterialsResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e, 'Failed to fetch topic materials');
    }
  }

  // Get all subtopics
  Future<SubtopicsResponse> getSubtopics({
    int? topicId,
    String? topicSlug,
    String? search,
    String? language,
    bool? isActive = true,
    String? ordering = 'display_order',
    int? page,
    int? pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (topicId != null) queryParams['topic'] = topicId;
      if (topicSlug != null) queryParams['topic__slug'] = topicSlug;
      if (search != null) queryParams['search'] = search;
      if (language != null) queryParams['language'] = language;
      if (isActive != null) queryParams['is_active'] = isActive;
      if (ordering != null) queryParams['ordering'] = ordering;
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;

      final response = await _apiService.get(
        EnvironmentConfig.legalEducationSubtopicsUrl,
        queryParameters: queryParams,
      );

      return SubtopicsResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e, 'Failed to fetch subtopics');
    }
  }

  // Get subtopic by slug
  Future<Subtopic> getSubtopicBySlug(String slug) async {
    try {
      final response = await _apiService
          .get('${EnvironmentConfig.legalEducationSubtopicsUrl}$slug/');
      return Subtopic.fromJson(response.data);
    } catch (e) {
      throw _handleError(e, 'Failed to fetch subtopic details');
    }
  }

  String _handleError(dynamic error, String defaultMessage) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please check your internet connection.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 401) {
            return 'Authentication required. Please log in again.';
          } else if (statusCode == 403) {
            return 'Access denied. You don\'t have permission to view this content.';
          } else if (statusCode == 404) {
            return 'Content not found.';
          } else if (statusCode != null && statusCode >= 500) {
            return 'Server error. Please try again later.';
          }
          return error.response?.data['message'] ?? defaultMessage;
        case DioExceptionType.cancel:
          return 'Request cancelled.';
        case DioExceptionType.unknown:
          return 'Network error. Please check your connection.';
        default:
          return defaultMessage;
      }
    }
    return error.toString();
  }
}

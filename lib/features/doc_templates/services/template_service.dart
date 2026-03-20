import 'package:dio/dio.dart';
import '../../../config/dio_config.dart';
import '../models/template_model.dart';
import '../models/generated_document_model.dart';

class TemplateService {
  final Dio _dio = DioConfig.instance;

  Future<Map<String, dynamic>> getTemplates({
    int? page,
    int? pageSize,
    String language = 'en',
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/doc-templates/templates/',
        queryParameters: {
          if (page != null) 'page': page,
          if (pageSize != null) 'page_size': pageSize,
          'language': language,
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = response.data;
        List<dynamic> results = [];
        int count = 0;
        dynamic next;
        dynamic previous;

        if (responseData is Map<String, dynamic>) {
          results = (responseData['results'] ?? []) as List<dynamic>;
          count = responseData['count'] as int? ?? results.length;
          next = responseData['next'];
          previous = responseData['previous'];
        } else if (responseData is List<dynamic>) {
          results = responseData;
          count = results.length;
        }

        final templates =
            results.map((json) => DocumentTemplate.fromJson(json)).toList();

        return {
          'count': count,
          'next': next,
          'previous': previous,
          'templates': templates,
        };
      } else {
        throw Exception('Failed to load templates');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            'Error: ${e.response?.data['message'] ?? e.response?.data['detail'] ?? 'Failed to load templates'}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  Future<Map<String, dynamic>> getTemplateDetail({
    required int templateId,
    String language = 'en',
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/doc-templates/templates/$templateId/',
        queryParameters: {'language': language},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load template details');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final dynamic errorData = e.response?.data;
        String errorMessage = 'Failed to load template details';
        
        if (errorData is Map) {
          errorMessage = errorData['error'] ?? errorData['message'] ?? errorData['detail'] ?? errorMessage;
        } else if (errorData is String && errorData.isNotEmpty) {
          // If it's a string (like HTML), don't try to use it as a map
          errorMessage = 'Server error (${e.response?.statusCode})';
        }
        
        throw Exception('Error: $errorMessage');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  Future<Map<String, dynamic>> generatePDF({
    required int templateId,
    required Map<String, dynamic> formData,
    String language = 'en',
    String? documentTitle,
  }) async {
    try {
      final payload = {
        'template_id': templateId,
        'language': language,
        'data': formData,
      };

      if (documentTitle != null && documentTitle.isNotEmpty) {
        payload['document_title'] = documentTitle;
      }

      final response = await _dio.post(
        '/api/v1/doc-templates/documents/generate/',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to generate document');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            'Error: ${e.response?.data['message'] ?? 'Failed to generate document'}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  Future<Map<String, dynamic>> getGeneratedDocuments({
    int page = 1,
    String language = 'en',
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/doc-templates/documents/',
        queryParameters: {
          'page': page,
          'language': language,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>;
        final documents =
            results.map((json) => GeneratedDocument.fromJson(json)).toList();

        return {
          'count': data['count'] as int,
          'next': data['next'],
          'previous': data['previous'],
          'documents': documents,
        };
      } else {
        throw Exception('Failed to load generated documents');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            'Error: ${e.response?.data['message'] ?? 'Failed to load generated documents'}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }
}

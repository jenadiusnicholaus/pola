import 'package:dio/dio.dart';
import '../../../config/dio_config.dart';
import '../models/template_model.dart';
import '../models/generated_document_model.dart';

class TemplateService {
  final Dio _dio = DioConfig.instance;

  Future<Map<String, dynamic>> getTemplates() async {
    // TODO: Replace with actual API endpoint when backend is ready
    // Endpoint should be: /api/v1/document-templates/

    // MOCK DATA - Remove this when backend is ready
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    final mockTemplates = [
      {
        "id": 16,
        "name": "Employment Questionnaire",
        "name_sw": "Dodoso la Ajira",
        "description":
            "Comprehensive employment questionnaire form for contract creation",
        "description_sw":
            "Fomu kamili ya dodoso la ajira kwa kutengeneza mkataba",
        "category": "questionnaire",
        "is_free": true,
        "price": "0.00",
        "icon": "📋",
        "usage_count": 15
      },
      {
        "id": 15,
        "name": "Notice of Termination",
        "name_sw": "Taarifa ya Kusitisha Ajira",
        "description":
            "Formal notice of employment termination from employer to employee",
        "description_sw":
            "Taarifa rasmi ya kusitisha ajira kutoka kwa mwajiri kwa mfanyakazi",
        "category": "legal_notice",
        "is_free": true,
        "price": "0.00",
        "icon": "📢",
        "usage_count": 16
      },
      {
        "id": 13,
        "name": "Employment Contract",
        "name_sw": "Mkataba wa Ajira",
        "description":
            "Official employment contract document extracted from Word template",
        "description_sw":
            "Mkataba rasmi wa ajira uliochukuliwa kutoka kwenye template ya Word",
        "category": "employment",
        "is_free": true,
        "price": "0.00",
        "icon": "📄",
        "usage_count": 17
      },
      {
        "id": 14,
        "name": "Resignation Letter",
        "name_sw": "Barua ya Kujiuzulu",
        "description":
            "Professional resignation letter for employees leaving their position",
        "description_sw":
            "Barua rasmi ya kujiuzulu kwa wafanyakazi wanaoondoka kazini",
        "category": "resignation",
        "is_free": true,
        "price": "0.00",
        "icon": "📝",
        "usage_count": 22
      }
    ];

    final templates =
        mockTemplates.map((json) => DocumentTemplate.fromJson(json)).toList();

    return {
      'count': mockTemplates.length,
      'next': null,
      'previous': null,
      'templates': templates,
    };

    /* UNCOMMENT THIS WHEN BACKEND IS READY:
    try {
      final response = await _dio.get('/api/v1/document-templates/');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>;
        final templates = results.map((json) => DocumentTemplate.fromJson(json)).toList();
        
        return {
          'count': data['count'] as int,
          'next': data['next'],
          'previous': data['previous'],
          'templates': templates,
        };
      } else {
        throw Exception('Failed to load templates');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Error: ${e.response?.data['message'] ?? 'Failed to load templates'}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
    */
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
        throw Exception(
            'Error: ${e.response?.data['message'] ?? 'Failed to load template details'}');
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

  Future<Map<String, dynamic>> getGeneratedDocuments({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/api/v1/doc-templates/documents/',
        queryParameters: {'page': page},
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

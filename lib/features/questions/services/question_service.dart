import 'package:dio/dio.dart';
import '../../../config/dio_config.dart';
import '../../../services/token_storage_service.dart';
import '../models/question_models.dart';
import 'package:get/get.dart' as getx;

class QuestionService {
  final Dio _dio = DioConfig.instance;
  final TokenStorageService _tokenService =
      getx.Get.find<TokenStorageService>();

  // User Endpoints

  /// Ask a new question
  Future<Question> askQuestion({
    required String questionText,
    int? materialId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/hubs/questions/',
        data: {
          'question_text': questionText,
          if (materialId != null) 'material': materialId,
        },
      );

      return Question.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get my questions with pagination
  Future<Map<String, dynamic>> getMyQuestions({
    String? status,
    int? materialId,
    String ordering = '-created_at',
    int? page,
    int? pageSize,
  }) async {
    try {
      final userId = _tokenService.getUserId();

      final response = await _dio.get(
        '/api/v1/hubs/questions/',
        queryParameters: {
          'asker_id': userId,
          if (status != null) 'status': status,
          if (materialId != null) 'material_id': materialId,
          'ordering': ordering,
          if (page != null) 'page': page,
          if (pageSize != null) 'page_size': pageSize,
        },
      );

      final results = response.data['results'] as List;
      return {
        'count': response.data['count'],
        'next': response.data['next'],
        'previous': response.data['previous'],
        'results': results.map((json) => Question.fromJson(json)).toList(),
      };
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get question details
  Future<Question> getQuestionDetails(int questionId) async {
    try {
      final response = await _dio.get('/api/v1/hubs/questions/$questionId/');
      return Question.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark answer as helpful
  Future<void> markHelpful(int questionId) async {
    try {
      await _dio.post('/api/v1/hubs/questions/$questionId/mark_helpful/');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get questions for a specific material
  Future<List<Question>> getQuestionsForMaterial(int materialId) async {
    try {
      final response = await _dio.get(
        '/api/v1/hubs/questions/',
        queryParameters: {
          'material_id': materialId,
        },
      );

      final results = response.data['results'] as List;
      return results.map((json) => Question.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Admin Endpoints

  /// Get all questions (admin only)
  Future<List<Question>> getAllQuestions({
    String? status,
    int? materialId,
    bool? unanswered,
    String ordering = '-created_at',
  }) async {
    try {
      final response = await _dio.get(
        '/admin/hubs/questions/',
        queryParameters: {
          if (status != null) 'status': status,
          if (materialId != null) 'material_id': materialId,
          if (unanswered != null) 'unanswered': unanswered,
          'ordering': ordering,
        },
      );

      final results = response.data['results'] as List;
      return results.map((json) => Question.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Answer a question (admin only)
  Future<Question> answerQuestion(int questionId, String answerText) async {
    try {
      final response = await _dio.post(
        '/admin/hubs/questions/$questionId/answer/',
        data: {
          'answer_text': answerText,
        },
      );

      return Question.fromJson(response.data['question']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Close a question (admin only)
  Future<Question> closeQuestion(int questionId) async {
    try {
      final response =
          await _dio.post('/admin/hubs/questions/$questionId/close/');

      return Question.fromJson(response.data['question']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Reopen a question (admin only)
  Future<Question> reopenQuestion(int questionId) async {
    try {
      final response =
          await _dio.post('/admin/hubs/questions/$questionId/reopen/');

      return Question.fromJson(response.data['question']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get question statistics (admin only)
  Future<QuestionStats> getQuestionStats() async {
    try {
      final response = await _dio.get('/admin/hubs/questions/stats/');
      return QuestionStats.fromJson(response.data);
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
          return 'Questions feature is not yet available on the server. Please contact support.';
        }

        final message = error.response!.data['detail'] ??
            error.response!.data['message'] ??
            '';

        switch (statusCode) {
          case 400:
            return message.isNotEmpty
                ? message
                : 'Question text is required (min 10 characters)';
          case 401:
            return 'Please log in to ask questions';
          case 403:
            return message.isNotEmpty
                ? message
                : 'You don\'t have permission to perform this action';
          case 404:
            return message.isNotEmpty
                ? message
                : 'Questions feature is not yet available. Please check back later.';
          case 429:
            return 'You\'ve asked too many questions. Please wait.';
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

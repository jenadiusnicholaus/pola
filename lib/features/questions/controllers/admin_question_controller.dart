import 'package:get/get.dart';
import '../models/question_models.dart';
import '../services/question_service.dart';

class AdminQuestionController extends GetxController {
  final QuestionService _service = QuestionService();

  // State
  final questions = <Question>[].obs;
  final stats = Rx<QuestionStats?>(null);
  final isLoading = false.obs;
  final isAnswering = false.obs;
  final error = ''.obs;
  final selectedStatus = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchQuestions();
    fetchStats();
  }

  /// Fetch all questions (admin)
  Future<void> fetchQuestions({String? status}) async {
    try {
      isLoading.value = true;
      error.value = '';

      final questionsList = await _service.getAllQuestions(
        status: status,
        ordering: '-created_at',
      );

      questions.value = questionsList;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch statistics
  Future<void> fetchStats() async {
    try {
      final questionStats = await _service.getQuestionStats();
      stats.value = questionStats;
    } catch (e) {
      print('Error fetching stats: $e');
    }
  }

  /// Answer a question
  Future<bool> answerQuestion(int questionId, String answerText) async {
    try {
      isAnswering.value = true;
      error.value = '';

      final answeredQuestion =
          await _service.answerQuestion(questionId, answerText);

      // Update local state
      final index = questions.indexWhere((q) => q.id == questionId);
      if (index != -1) {
        questions[index] = answeredQuestion;
      }

      // Refresh stats
      await fetchStats();

      Get.back(); // Close answer screen
      Get.snackbar(
        'Success',
        'Question answered successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primaryContainer,
      );

      return true;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
      return false;
    } finally {
      isAnswering.value = false;
    }
  }

  /// Close a question
  Future<void> closeQuestion(int questionId) async {
    try {
      final closedQuestion = await _service.closeQuestion(questionId);

      // Update local state
      final index = questions.indexWhere((q) => q.id == questionId);
      if (index != -1) {
        questions[index] = closedQuestion;
      }

      // Refresh stats
      await fetchStats();

      Get.snackbar(
        'Success',
        'Question closed successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Reopen a question
  Future<void> reopenQuestion(int questionId) async {
    try {
      final reopenedQuestion = await _service.reopenQuestion(questionId);

      // Update local state
      final index = questions.indexWhere((q) => q.id == questionId);
      if (index != -1) {
        questions[index] = reopenedQuestion;
      }

      // Refresh stats
      await fetchStats();

      Get.snackbar(
        'Success',
        'Question reopened successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Filter by status
  void filterByStatus(String status) {
    selectedStatus.value = status;
    fetchQuestions(status: status == 'all' ? null : status);
  }

  /// Get open questions count
  int get openQuestionsCount {
    return stats.value?.open ?? 0;
  }

  /// Get answered questions count
  int get answeredQuestionsCount {
    return stats.value?.answered ?? 0;
  }

  /// Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      fetchQuestions(
        status: selectedStatus.value == 'all' ? null : selectedStatus.value,
      ),
      fetchStats(),
    ]);
  }
}

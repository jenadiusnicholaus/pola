import 'package:get/get.dart';
import '../models/question_models.dart';
import '../services/question_service.dart';

class QuestionController extends GetxController {
  final QuestionService _service = QuestionService();

  // State
  final myQuestions = <Question>[].obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final error = ''.obs;
  final selectedStatus = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyQuestions();
  }

  /// Fetch my questions
  Future<void> fetchMyQuestions({String? status}) async {
    try {
      isLoading.value = true;
      error.value = '';

      final questions = await _service.getMyQuestions(
        status: status,
        ordering: '-created_at',
      );

      myQuestions.value = questions;
    } catch (e) {
      error.value = e.toString();
      // Don't show snackbar on initial load, let the UI handle the error display
    } finally {
      isLoading.value = false;
    }
  }

  /// Ask a new question
  Future<bool> askQuestion({
    required String questionText,
    int? materialId,
  }) async {
    try {
      isSubmitting.value = true;
      error.value = '';

      final question = await _service.askQuestion(
        questionText: questionText,
        materialId: materialId,
      );

      // Add to list
      myQuestions.insert(0, question);

      Get.back(); // Close the ask question screen
      Get.snackbar(
        'Success',
        'Question submitted successfully!',
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
      isSubmitting.value = false;
    }
  }

  /// Mark answer as helpful
  Future<void> markHelpful(int questionId) async {
    try {
      await _service.markHelpful(questionId);

      // Update local state
      final index = myQuestions.indexWhere((q) => q.id == questionId);
      if (index != -1) {
        final question = myQuestions[index];
        myQuestions[index] = Question(
          id: question.id,
          material: question.material,
          asker: question.asker,
          questionText: question.questionText,
          answerText: question.answerText,
          answeredBy: question.answeredBy,
          answeredAt: question.answeredAt,
          status: question.status,
          helpfulCount: question.helpfulCount + 1,
          createdAt: question.createdAt,
          updatedAt: question.updatedAt,
        );
      }

      Get.snackbar(
        'Thank you!',
        'Marked as helpful',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to mark as helpful',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Filter questions by status
  void filterByStatus(String status) {
    selectedStatus.value = status;
    fetchMyQuestions(status: status == 'all' ? null : status);
  }

  /// Get question by ID
  Question? getQuestionById(int id) {
    try {
      return myQuestions.firstWhere((q) => q.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Refresh questions
  Future<void> refresh() async {
    await fetchMyQuestions(
      status: selectedStatus.value == 'all' ? null : selectedStatus.value,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/question_models.dart';
import '../services/question_service.dart';
import '../../../services/permission_service.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/navigation_helper.dart';

class QuestionController extends GetxController {
  final QuestionService _service = QuestionService();

  // State
  final myQuestions = <Question>[].obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final error = ''.obs;
  final selectedStatus = 'all'.obs;

  // Pagination
  final ScrollController scrollController = ScrollController();
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  int currentPage = 1;
  final int pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_scrollListener);
    fetchMyQuestions();
  }

  @override
  void onClose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.onClose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore.value && hasMore.value) {
        loadMore();
      }
    }
  }

  /// Fetch my questions
  Future<void> fetchMyQuestions({String? status}) async {
    try {
      isLoading.value = true;
      error.value = '';
      currentPage = 1;
      hasMore.value = true;

      final response = await _service.getMyQuestions(
        status: status,
        ordering: '-created_at',
        page: currentPage,
        pageSize: pageSize,
      );

      myQuestions.value = response['results'] as List<Question>;
      hasMore.value = response['next'] != null;
    } catch (e) {
      error.value = e.toString();
      // Don't show snackbar on initial load, let the UI handle the error display
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more questions
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;

    try {
      isLoadingMore.value = true;
      currentPage++;

      final response = await _service.getMyQuestions(
        status: selectedStatus.value == 'all' ? null : selectedStatus.value,
        ordering: '-created_at',
        page: currentPage,
        pageSize: pageSize,
      );

      final newQuestions = response['results'] as List<Question>;
      myQuestions.addAll(newQuestions);
      hasMore.value = response['next'] != null;
    } catch (e) {
      debugPrint('Error loading more questions: $e');
      currentPage--;
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Ask a new question
  Future<bool> askQuestion({
    required String questionText,
    int? materialId,
    BuildContext? context,
  }) async {
    // Check permission to ask questions
    try {
      final permissionService = Get.find<PermissionService>();
      if (!permissionService.canAccess(PermissionFeature.askQuestions)) {
        final message = permissionService.getPermissionDeniedMessage(
            PermissionFeature.askQuestions);
        NavigationHelper.showSafeSnackbar(
          title: 'Upgrade Required',
          message: message,
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          mainButton: TextButton(
            onPressed: () => Get.toNamed(AppRoutes.subscriptionPlans),
            child: const Text('Upgrade', style: TextStyle(color: Colors.white)),
          ),
        );
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ Permission check failed: $e');
    }

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
      NavigationHelper.showSafeSnackbar(
        title: 'Success',
        message: 'Question submitted successfully',
        backgroundColor: Get.theme.colorScheme.primaryContainer,
        colorText: Get.theme.colorScheme.onPrimaryContainer,
      );

      return true;
    } catch (e) {
      error.value = e.toString();
      NavigationHelper.showSafeSnackbar(
        title: 'Error',
        message: e.toString(),
        backgroundColor: Get.theme.colorScheme.errorContainer,
        colorText: Get.theme.colorScheme.onErrorContainer,
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

      NavigationHelper.showSafeSnackbar(
        title: 'Thank you!',
        message: 'Marked as helpful',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      NavigationHelper.showSafeSnackbar(
        title: 'Error',
        message: 'Failed to mark as helpful',
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

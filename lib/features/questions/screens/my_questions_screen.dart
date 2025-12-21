import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/question_controller.dart';
import '../widgets/question_card.dart';
import 'ask_question_screen.dart';
import 'question_detail_screen.dart';

class MyQuestionsScreen extends StatelessWidget {
  const MyQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(QuestionController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Questions'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          // Status Filter Tabs
          Container(
            color: theme.colorScheme.surfaceContainer,
            child: Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _buildFilterChip(
                      context,
                      'All',
                      'all',
                      controller.selectedStatus.value == 'all',
                      () => controller.filterByStatus('all'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context,
                      'Open',
                      'open',
                      controller.selectedStatus.value == 'open',
                      () => controller.filterByStatus('open'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context,
                      'Answered',
                      'answered',
                      controller.selectedStatus.value == 'answered',
                      () => controller.filterByStatus('answered'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context,
                      'Closed',
                      'closed',
                      controller.selectedStatus.value == 'closed',
                      () => controller.filterByStatus('closed'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Questions List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.error.value.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load questions',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: controller.refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                );
              }

              if (controller.myQuestions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.question_answer_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No questions yet',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ask your first legal question',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () =>
                            Get.to(() => const AskQuestionScreen()),
                        icon: const Icon(Icons.add),
                        label: const Text('Ask a Question'),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView.builder(
                  controller: controller.scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.myQuestions.length +
                      (controller.hasMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == controller.myQuestions.length) {
                      return Obx(() => controller.isLoadingMore.value
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : const SizedBox.shrink());
                    }
                    final question = controller.myQuestions[index];
                    return QuestionCard(
                      question: question,
                      onTap: () => Get.to(
                        () => QuestionDetailScreen(questionId: question.id),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const AskQuestionScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Ask Question'),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String value,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

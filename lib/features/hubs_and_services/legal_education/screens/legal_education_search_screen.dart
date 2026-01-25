import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/legal_education_controller.dart';
import '../widgets/professional_search_bar.dart';
import '../widgets/topic_card.dart';
import 'topic_materials_screen.dart';

class LegalEducationSearchScreen extends StatelessWidget {
  const LegalEducationSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LegalEducationController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Legal Topics'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: ProfessionalSearchBar(
            controller: controller,
            hintText: 'Search legal topics...',
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Results
          Expanded(
            child: Obx(() {
              if (controller.isLoadingTopics) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (controller.topics.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.searchQuery.isNotEmpty
                            ? 'No topics found for "${controller.searchQuery}"'
                            : 'Start searching for legal topics',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try different keywords or browse all topics',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await controller.fetchTopics(refresh: true);
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Results count
                    if (controller.searchQuery.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                theme.colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Found ${controller.topics.length} topics matching "${controller.searchQuery}"',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Topic cards
                    ...controller.topics.map((topic) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TopicCard(
                          topic: topic,
                          onLanguageTap: (language) => Get.to(
                            () => const TopicMaterialsScreen(),
                            arguments: {
                              'topic': topic,
                              'language': language == 'english' ? 'en' : 'sw',
                            },
                          ),
                        ),
                      );
                    }),

                    // Load more button
                    if (!controller.isLoadingTopics &&
                        controller.topics.isNotEmpty &&
                        controller.hasMoreTopics)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: OutlinedButton.icon(
                            onPressed: () => controller.fetchTopics(),
                            icon: const Icon(Icons.arrow_downward),
                            label: const Text('Load More Topics'),
                          ),
                        ),
                      ),

                    // Loading indicator
                    if (controller.isLoadingTopics &&
                        controller.topics.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

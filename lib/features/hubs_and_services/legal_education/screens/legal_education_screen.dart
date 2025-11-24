import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/legal_education_controller.dart';
import '../widgets/common_sliver_widgets.dart';
import '../widgets/professional_search_bar.dart';
import '../widgets/topic_card.dart';
import 'topic_materials_screen.dart';
import '../../../../services/token_storage_service.dart';

class LegalEducationScreen extends StatelessWidget {
  const LegalEducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Check authentication status
    final tokenService = Get.find<TokenStorageService>();
    if (!tokenService.isLoggedIn) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Please Log In',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You need to be logged in to access legal education content',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.toNamed('/login'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    // Get or create controller and ensure topics are loaded
    final controller = Get.put(LegalEducationController(), permanent: false);

    // Reload topics when screen is accessed (in case user just logged in)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.topics.isEmpty && !controller.isLoadingTopics) {
        controller.fetchTopics(refresh: true);
      }
    });

    return Scaffold(
      body: Obx(() => CustomScrollView(
            controller: controller.topicsScrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Common SliverAppBar with clean design
              const CommonSliverAppBar(
                title: 'Legal Education',
                expandedHeight: 120,
              ),

              // Professional Search Bar
              SliverToBoxAdapter(
                child: ProfessionalSearchBar(
                  controller: controller,
                  hintText: 'Search legal topics, laws, cases...',
                ),
              ),

              // Statistics Section
              if (controller.topics.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.searchQuery.isNotEmpty
                                ? 'Found ${controller.topics.length} topics matching "${controller.searchQuery}"'
                                : 'Showing ${controller.topics.length} legal topics',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7),
                                    ),
                          ),
                        ),
                        if (controller.languageFilter !=
                            LanguageFilter.both) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: controller.languageFilter ==
                                      LanguageFilter.english
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              controller.languageFilter ==
                                      LanguageFilter.english
                                  ? 'EN'
                                  : 'SW',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: controller.languageFilter ==
                                        LanguageFilter.english
                                    ? Colors.blue
                                    : Colors.amber.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Content based on state
              if (controller.error.isNotEmpty && controller.topics.isEmpty)
                SliverFillRemaining(
                  child: CommonErrorWidget(
                    message: controller.error,
                    onRetry: () => controller.fetchTopics(refresh: true),
                  ),
                )
              else if (controller.topics.isEmpty && controller.isLoadingTopics)
                const SliverFillRemaining(
                  child: CommonLoadingWidget(message: 'Loading topics...'),
                )
              else if (controller.topics.isEmpty)
                SliverFillRemaining(
                  child: CommonEmptyWidget(
                    title: 'No legal topics found',
                    message: 'Try adjusting your search or language filter',
                    action: ElevatedButton.icon(
                      onPressed: () => controller.fetchTopics(refresh: true),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                )
              else ...[
                // Topics list
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < controller.topics.length) {
                        final topic = controller.topics[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: index == 0 ? 8 : 4,
                            bottom: 4,
                          ),
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
                      } else {
                        // Loading indicator at the end
                        if (controller.hasMoreTopics) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                    },
                    childCount: controller.topics.length +
                        (controller.hasMoreTopics ? 1 : 0),
                  ),
                ),

                // Add bottom padding for better scrolling
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ],
          )),
    );
  }
}

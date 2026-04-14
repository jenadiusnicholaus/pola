import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/legal_education_controller.dart';
import '../models/legal_education_models.dart';
import '../widgets/subtopic_card.dart';
import '../widgets/common_sliver_widgets.dart';
import 'topic_materials_screen.dart';

class TopicDetailScreen extends StatefulWidget {
  const TopicDetailScreen({super.key});

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  late LegalEducationController controller;
  late Topic topic;
  String? initialLanguage;
  final ScrollController _scrollController = ScrollController();

  String get _topicTitle {
    if (initialLanguage == 'sw' && topic.nameSw.isNotEmpty) {
      return topic.nameSw;
    }
    return topic.name;
  }

  String get _topicDescription {
    if (initialLanguage == 'sw' && topic.descriptionSw.isNotEmpty) {
      return topic.descriptionSw;
    }
    return topic.description;
  }

  @override
  void initState() {
    super.initState();
    controller = Get.find<LegalEducationController>();

    final args = Get.arguments;
    if (args is Map) {
      topic = args['topic'] as Topic;
      initialLanguage = args['language'] as String?;
    } else {
      topic = args as Topic;
    }

    // Fetch subtopics for this topic
    print(
        '🌍 TopicDetailScreen: initialLanguage=$initialLanguage, topic=${topic.name}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🌍 Fetching subtopics with language=$initialLanguage');
      controller.fetchSubtopics(topic.slug, language: initialLanguage);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Obx(() => CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                title: Text(_topicTitle),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                floating: true,
                pinned: true,
              ),

              // Topic Header Info
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About ${_topicTitle}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _topicDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Subtopics Header
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Browse Subtopics',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Subtopics Content
              if (controller.isLoadingSubtopics && controller.subtopics.isEmpty)
                const SliverFillRemaining(
                  child: CommonLoadingWidget(message: 'Loading subtopics...'),
                )
              else if (controller.subtopics.isEmpty)
                const SliverFillRemaining(
                  child: CommonEmptyWidget(
                    title: 'No subtopics found',
                    message: 'Check back later for content in this topic.',
                    icon: Icons.category_outlined,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final subtopic = controller.subtopics[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SubtopicCard(
                            subtopic: subtopic,
                            language: initialLanguage,
                            onTap: () => Get.to(
                              () => const TopicMaterialsScreen(),
                              arguments: {
                                'subtopic': subtopic,
                                'language': initialLanguage,
                              },
                            ),
                          ),
                        );
                      },
                      childCount: controller.subtopics.length,
                    ),
                  ),
                ),

              // Bottom Padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          )),
    );
  }
}

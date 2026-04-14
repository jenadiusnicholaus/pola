import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/legal_education_controller.dart';
import '../models/legal_education_models.dart';
import '../widgets/common_sliver_widgets.dart';
import '../widgets/material_card.dart';
import 'material_viewer_screen.dart';
import '../../hub_content/widgets/content_creation_fab.dart';
import '../../hub_content/utils/user_role_manager.dart';
import '../../../../services/permission_service.dart';
import '../../../../routes/app_routes.dart';

class TopicMaterialsScreen extends StatefulWidget {
  final Topic? topic;
  final Subtopic? subtopic;

  const TopicMaterialsScreen({
    super.key,
    this.topic,
    this.subtopic,
  });

  @override
  State<TopicMaterialsScreen> createState() => _TopicMaterialsScreenState();
}

class _TopicMaterialsScreenState extends State<TopicMaterialsScreen> {
  late LegalEducationController controller;
  Topic? currentTopic;
  Subtopic? currentSubtopic;
  bool get isSubtopicMode => currentSubtopic != null;
  String? selectedLanguage;
  final ScrollController _scrollController = ScrollController();

  // Helper getters to access correct controller properties
  List<LearningMaterial> get materials =>
      isSubtopicMode ? controller.subtopicMaterials : controller.materials;
  bool get isLoadingMaterials => isSubtopicMode
      ? controller.isLoadingSubtopicMaterials
      : controller.isLoadingMaterials;
  bool get hasMoreMaterials => isSubtopicMode
      ? controller.hasMoreSubtopicMaterials
      : controller.hasMoreMaterials;
  String get materialsError => isSubtopicMode
      ? controller.subtopicMaterialsError
      : controller.materialsError;

  @override
  void initState() {
    super.initState();

    // Ensure controller is available - use existing instance if available
    try {
      controller = Get.find<LegalEducationController>();
    } catch (e) {
      controller = Get.put(LegalEducationController());
    }

    // Get topic/subtopic and language from arguments or use the provided widget params
    if (widget.topic != null) {
      // Topic passed directly (fallback)
      currentTopic = widget.topic!;
      selectedLanguage = null;
    } else if (widget.subtopic != null) {
      // Subtopic passed directly
      currentSubtopic = widget.subtopic!;
      selectedLanguage = null;
    } else {
      // Get from arguments
      final args = Get.arguments;
      if (args is Map<String, dynamic>) {
        if (args.containsKey('subtopic')) {
          // Subtopic mode
          currentSubtopic = args['subtopic'] as Subtopic;
          selectedLanguage = args['language'] as String?;
        } else {
          // Topic mode
          currentTopic = args['topic'] as Topic;
          selectedLanguage = args['language'] as String?;
        }
      } else {
        // Old format with just topic
        currentTopic = args as Topic;
        selectedLanguage = null;
      }
    }

    // Load materials when screen is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.addListener(() {
        controller.onMaterialsScroll(_scrollController);
      });

      if (isSubtopicMode) {
        // Fetch subtopic materials
        controller.fetchSubtopicMaterials(
          currentSubtopic!.slug,
          language: selectedLanguage,
          refresh: true,
        );
      } else {
        // Fetch topic materials
        controller.fetchMaterials(
          currentTopic!.slug,
          language: selectedLanguage,
          refresh: true,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _changeLanguage(String? language) {
    setState(() {
      selectedLanguage = language;
    });
    if (isSubtopicMode) {
      controller.fetchSubtopicMaterials(
        currentSubtopic!.slug,
        language: language,
        refresh: true,
      );
    } else {
      controller.fetchMaterials(
        currentTopic!.slug,
        language: language,
        refresh: true,
      );
    }
  }

  String _getTitle() {
    if (isSubtopicMode) {
      // Subtopic title
      if (selectedLanguage == 'en') {
        return currentSubtopic!.name;
      } else if (selectedLanguage == 'sw') {
        return currentSubtopic!.nameSw.isNotEmpty
            ? currentSubtopic!.nameSw
            : currentSubtopic!.name;
      } else {
        return currentSubtopic!.name;
      }
    } else {
      // Topic title
      if (selectedLanguage == 'en') {
        return currentTopic!.name;
      } else if (selectedLanguage == 'sw') {
        return currentTopic!.nameSw;
      } else {
        return currentTopic!.name;
      }
    }
  }

  String _getDescription() {
    if (isSubtopicMode) {
      // Subtopic description
      if (selectedLanguage == 'en') {
        return currentSubtopic!.description;
      } else if (selectedLanguage == 'sw') {
        return currentSubtopic!.descriptionSw.isNotEmpty
            ? currentSubtopic!.descriptionSw
            : currentSubtopic!.description;
      } else {
        return currentSubtopic!.description;
      }
    } else {
      // Topic description
      if (selectedLanguage == 'en') {
        return currentTopic!.description;
      } else if (selectedLanguage == 'sw') {
        return currentTopic!.descriptionSw;
      } else {
        return currentTopic!.description;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Obx(() => CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Simple compact header
              SliverAppBar(
                title: Text(
                  _getTitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                floating: true,
                pinned: true,
                elevation: 0,
                actions: [
                  // Language toggle buttons
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // English Button
                        ElevatedButton(
                          onPressed: () => _changeLanguage('en'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedLanguage == 'en'
                                ? Colors.blue
                                : Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withOpacity(0.2),
                            foregroundColor: selectedLanguage == 'en'
                                ? Colors.white
                                : Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withOpacity(0.9),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: const Size(50, 32),
                            elevation: 2,
                          ),
                          child: Text('EN',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: selectedLanguage == 'en'
                                    ? Colors.white
                                    : Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withOpacity(0.9),
                              )),
                        ),
                        const SizedBox(width: 4),
                        // Swahili Button
                        ElevatedButton(
                          onPressed: () => _changeLanguage('sw'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedLanguage == 'sw'
                                ? Colors.amber.shade700
                                : Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withOpacity(0.2),
                            foregroundColor: selectedLanguage == 'sw'
                                ? Colors.black
                                : Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withOpacity(0.9),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: const Size(50, 32),
                            elevation: 2,
                          ),
                          child: Text('SW',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: selectedLanguage == 'sw'
                                    ? Colors
                                        .black // Black text on amber background
                                    : Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withOpacity(0.9),
                              )),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Content based on state
              if (materialsError.isNotEmpty && materials.isEmpty)
                SliverFillRemaining(
                  child: CommonErrorWidget(
                    message: materialsError,
                    onRetry: () {
                      if (isSubtopicMode) {
                        controller.fetchSubtopicMaterials(
                          currentSubtopic!.slug,
                          language: selectedLanguage,
                          refresh: true,
                        );
                      } else {
                        controller.fetchMaterials(
                          currentTopic!.slug,
                          language: selectedLanguage,
                          refresh: true,
                        );
                      }
                    },
                  ),
                )
              else if (materials.isEmpty && isLoadingMaterials)
                const SliverFillRemaining(
                  child: CommonLoadingWidget(message: 'Loading materials...'),
                )
              else if (materials.isEmpty)
                SliverFillRemaining(
                  child: CommonEmptyWidget(
                    title: 'No materials found',
                    message: selectedLanguage != null
                        ? 'No learning materials available in ${selectedLanguage == 'en' ? 'English' : 'Kiswahili'}'
                        : 'No learning materials available',
                    icon: Icons.library_books_outlined,
                  ),
                )
              else ...[
                // Materials list
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < materials.length) {
                          final material = materials[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: MaterialCard(
                              material: material,
                              onTap: () => _openMaterial(context, material),
                            ),
                          );
                        } else {
                          // Loading indicator at the end
                          if (hasMoreMaterials) {
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
                      childCount: materials.length + (hasMoreMaterials ? 1 : 0),
                    ),
                  ),
                ),

                // Add bottom padding for better scrolling
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ],
          )),

      // Floating Action Button - Content creation for admins (topics only), refresh for others
      floatingActionButton: isSubtopicMode
          // Subtopic mode - just show refresh button
          ? FloatingActionButton(
              onPressed: () => controller.fetchSubtopicMaterials(
                currentSubtopic!.slug,
                language: selectedLanguage,
                refresh: true,
              ),
              child: const Icon(Icons.refresh),
              tooltip: 'Refresh Materials',
            )
          // Topic mode - show content creation or refresh
          : UserRoleManager.canCreateContentInHub('legal_ed')
              ? ContentCreationMenu(
                  hubType: 'legal_ed',
                  heroTag: 'topic_materials_fab',
                  presetData: {
                    'currentTopic': {
                      'id': currentTopic!.id,
                      'name': currentTopic!.name,
                      'name_sw': currentTopic!.nameSw,
                      'slug': currentTopic!.slug,
                      'description': currentTopic!.description,
                      'description_sw': currentTopic!.descriptionSw,
                      'display_order': currentTopic!.displayOrder,
                      'subtopics_count': currentTopic!.subtopicsCount,
                      'materials_count': currentTopic!.materialsCount,
                    },
                    'selectedLanguage': selectedLanguage,
                  },
                  onContentCreated: () {
                    // Refresh materials after successful content creation
                    print(
                        '🔄 TopicMaterialsScreen: onContentCreated callback triggered');
                    print('🔄 Controller instance: $controller');
                    controller.refreshMaterials();
                  },
                )
              : FloatingActionButton(
                  onPressed: () => controller.fetchMaterials(
                    currentTopic!.slug,
                    language: selectedLanguage,
                    refresh: true,
                  ),
                  child: const Icon(Icons.refresh),
                  tooltip: 'Refresh Materials',
                ),
    );
  }

  void _openMaterial(BuildContext context, LearningMaterial material) {
    // Check if user has permission to read legal education content
    try {
      final permissionService = Get.find<PermissionService>();

      // Check if user can read legal education content
      if (!permissionService.canReadLegalEducation) {
        // Show limit reached dialog
        _showLimitReachedDialog(context, permissionService);
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Permission check failed: $e');
      // If permission service not available, allow access (fallback)
    }

    // Always open the material - MaterialViewerScreen handles both file and text-only content
    if (material.fileUrl.isNotEmpty || material.description.isNotEmpty) {
      Get.to(
        () => const MaterialViewerScreen(),
        arguments: {'material': material},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No content available for this material'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showLimitReachedDialog(
      BuildContext context, PermissionService permissionService) {
    final theme = Theme.of(context);
    final isTrial = permissionService.isTrialSubscription;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: theme.colorScheme.error,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isTrial ? 'Trial Limit Reached' : 'Reading Limit Reached',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTrial
                  ? 'You have used all ${permissionService.legalEducationLimit} free reads available in your trial period.'
                  : 'You have reached your legal education reading limit for this period.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upgrade to Premium for unlimited access to all legal education materials!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Later',
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to subscription page
              Get.toNamed(AppRoutes.subscriptionPlans);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
}

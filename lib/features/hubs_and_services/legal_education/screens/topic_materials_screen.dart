import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import '../controllers/legal_education_controller.dart';
import '../models/legal_education_models.dart';
import '../widgets/common_sliver_widgets.dart';
import '../widgets/material_card.dart';
import '../widgets/shimmer_widgets.dart';
import 'material_viewer_screen.dart';
import '../../hub_content/widgets/content_creation_fab.dart';
import '../../hub_content/utils/user_role_manager.dart';
import '../../../../services/language_service.dart';
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
  final ScrollController _scrollController = ScrollController();
  Worker? _languageWorker;

  /// Materials language always follows the global app language.
  String get selectedLanguage => Get.find<LanguageService>().apiCode;

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

    // Get topic/subtopic from arguments or use the provided widget params
    if (widget.topic != null) {
      // Topic passed directly (fallback)
      currentTopic = widget.topic!;
    } else if (widget.subtopic != null) {
      // Subtopic passed directly
      currentSubtopic = widget.subtopic!;
    } else {
      // Get from arguments
      final args = Get.arguments;
      if (args is Map<String, dynamic>) {
        if (args.containsKey('subtopic')) {
          // Subtopic mode
          currentSubtopic = args['subtopic'] as Subtopic;
        } else {
          // Topic mode
          currentTopic = args['topic'] as Topic;
        }
      } else {
        // Old format with just topic
        currentTopic = args as Topic;
      }
    }

    // Refetch materials when the app language changes.
    _languageWorker = ever(Get.find<LanguageService>().languageObs, (_) {
      _refetchMaterials();
    });

    // Load materials when screen is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.addListener(() {
        controller.onMaterialsScroll(_scrollController);
      });

      if (isSubtopicMode) {
        controller.fetchSubtopicMaterials(
          currentSubtopic!.id,
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
    _languageWorker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _refetchMaterials() {
    if (isSubtopicMode) {
      controller.fetchSubtopicMaterials(
        currentSubtopic!.id,
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
            physics: AlwaysScrollableScrollPhysics(
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
              ),

              // Content based on state
              if (materialsError.isNotEmpty && materials.isEmpty)
                SliverFillRemaining(
                  child: CommonErrorWidget(
                    message: materialsError,
                    onRetry: () {
                      if (isSubtopicMode) {
                        controller.fetchSubtopicMaterials(
                          currentSubtopic!.id,
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
                  child: MaterialsShimmer(),
                )
              else if (materials.isEmpty)
                SliverFillRemaining(
                  child: CommonEmptyWidget(
                    title: tr('No materials found'),
                    message: tr('No learning materials available in {language}')
                        .replaceAll(
                            '{language}',
                            selectedLanguage == 'en'
                                ? tr('English')
                                : tr('Kiswahili')),
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
                SliverToBoxAdapter(
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
                currentSubtopic!.id,
                language: selectedLanguage,
                refresh: true,
              ),
              child: Icon(Icons.refresh),
              tooltip: tr('Refresh Materials'),
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
                  child: Icon(Icons.refresh),
                  tooltip: tr('Refresh Materials'),
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
        SnackBar(
          content: Text(tr('No content available for this material')),
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
            SizedBox(width: 12),
            Expanded(
              child: Text(
                isTrial
                    ? tr('Trial Limit Reached')
                    : tr('Reading Limit Reached'),
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
                  ? tr('You have used all {limit} free reads available in your trial period.')
                      .replaceAll(
                          '{limit}', '${permissionService.legalEducationLimit}')
                  : tr(
                      'You have reached your legal education reading limit for this period.'),
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: 16),
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
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr('Upgrade to Premium for unlimited access to all legal education materials!'),
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
              tr('Later'),
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
            child: Text(tr('Upgrade Now')),
          ),
        ],
      ),
    );
  }
}

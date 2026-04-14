import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/legal_education_controller.dart';
import '../models/legal_education_models.dart';
import '../widgets/material_card.dart';
import '../widgets/common_sliver_widgets.dart';
import 'material_viewer_screen.dart';
import '../../../../services/permission_service.dart';
import '../../../../routes/app_routes.dart';

class SubtopicDetailScreen extends StatefulWidget {
  const SubtopicDetailScreen({super.key});

  @override
  State<SubtopicDetailScreen> createState() => _SubtopicDetailScreenState();
}

class _SubtopicDetailScreenState extends State<SubtopicDetailScreen> {
  late LegalEducationController controller;
  late Subtopic subtopic;
  String? selectedLanguage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Get subtopic from navigation arguments
    subtopic = Get.arguments as Subtopic;
    controller = Get.find<LegalEducationController>();

    // Add scroll listener for infinite scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.8) {
        if (!controller.isLoadingSubtopicMaterials &&
            controller.hasMoreSubtopicMaterials) {
          controller.fetchSubtopicMaterials(subtopic.slug,
              language: selectedLanguage, refresh: false);
        }
      }
    });

    // Load materials for this subtopic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchSubtopicMaterials(
        subtopic.slug,
        language: selectedLanguage,
        refresh: true,
      );
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
    controller.fetchSubtopicMaterials(
      subtopic.slug,
      language: language,
      refresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Obx(() => CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Custom App Bar
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                stretch: true,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                actions: [
                  // Language toggle buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLanguageToggleButton('EN', 'en'),
                      const SizedBox(width: 4),
                      _buildLanguageToggleButton('SW', 'sw'),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    _getLocalizedTitle(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.1,
                            child: Icon(
                              _getSubtopicIconData(),
                              size: 100,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Description Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About This Subtopic',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getLocalizedDescription(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Learning Materials',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Materials Content
              if (controller.subtopicMaterialsError.isNotEmpty && controller.subtopicMaterials.isEmpty)
                SliverFillRemaining(
                  child: controller.subtopicMaterialsError.toLowerCase().contains('subscription') 
                    ? CommonEmptyWidget(
                        title: 'Subscription Required',
                        message: controller.subtopicMaterialsError,
                        icon: Icons.workspace_premium,
                        action: ElevatedButton.icon(
                          onPressed: () => Get.toNamed(AppRoutes.subscriptionPlans),
                          icon: const Icon(Icons.star),
                          label: const Text('Go to Subscription Page'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      )
                    : CommonErrorWidget(
                        message: controller.subtopicMaterialsError,
                        onRetry: () => controller.fetchSubtopicMaterials(
                          subtopic.slug,
                          language: selectedLanguage,
                          refresh: true,
                        ),
                      ),
                )
              else if (controller.isLoadingSubtopicMaterials &&
                  controller.subtopicMaterials.isEmpty)
                const SliverFillRemaining(
                  child: CommonLoadingWidget(message: 'Loading materials...'),
                )
              else if (controller.subtopicMaterials.isEmpty)
                SliverFillRemaining(
                  child: CommonEmptyWidget(
                    title: 'No materials found',
                    message: selectedLanguage != null
                        ? 'No learning materials available in ${selectedLanguage == 'en' ? 'English' : 'Kiswahili'}'
                        : 'No learning materials available for this subtopic.',
                    icon: Icons.library_books_outlined,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < controller.subtopicMaterials.length) {
                          final material = controller.subtopicMaterials[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: MaterialCard(
                              material: material,
                              onTap: () => _openMaterial(context, material),
                            ),
                          );
                        } else {
                          if (controller.hasMoreSubtopicMaterials) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                      },
                      childCount: controller.subtopicMaterials.length +
                          (controller.hasMoreSubtopicMaterials ? 1 : 0),
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

  Widget _buildLanguageToggleButton(String label, String code) {
    final isSelected = selectedLanguage == code;
    return ElevatedButton(
      onPressed: () => _changeLanguage(isSelected ? null : code),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? (code == 'en' ? Colors.blue : Colors.amber.shade700)
            : Colors.white.withOpacity(0.2),
        foregroundColor: isSelected ? Colors.white : Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(50, 32),
        elevation: isSelected ? 2 : 0,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected && code == 'sw' ? Colors.black : Colors.white,
        ),
      ),
    );
  }

  void _openMaterial(BuildContext context, LearningMaterial material) {
    try {
      final permissionService = Get.find<PermissionService>();
      if (!permissionService.canReadLegalEducation) {
        _showLimitReachedDialog(context, permissionService);
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Permission check failed: $e');
    }

    if (material.fileUrl.isNotEmpty || material.description.isNotEmpty) {
      Get.to(
        () => const MaterialViewerScreen(),
        arguments: {'material': material},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No content available for this material')),
      );
    }
  }

  void _showLimitReachedDialog(
      BuildContext context, PermissionService permissionService) {
    final isTrial = permissionService.isTrialSubscription;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isTrial ? 'Trial Limit Reached' : 'Limit Reached'),
        content: Text(isTrial
            ? 'You have used all free reads in your trial.'
            : 'You have reached your reading limit.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Get.toNamed(AppRoutes.subscriptionPlans);
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  String _getLocalizedTitle() {
    const locale = 'en';
    if (locale.startsWith('sw') && subtopic.nameSw.isNotEmpty) {
      return subtopic.nameSw;
    }
    return subtopic.name.isNotEmpty ? subtopic.name : subtopic.slug;
  }

  String _getLocalizedDescription() {
    const locale = 'en';
    if (locale.startsWith('sw') && subtopic.descriptionSw.isNotEmpty) {
      return subtopic.descriptionSw;
    }
    return subtopic.description.isNotEmpty
        ? subtopic.description
        : 'Detailed information about this subtopic.';
  }

  IconData _getSubtopicIconData() {
    final slug = subtopic.slug.toLowerCase();
    if (slug.contains('right')) return Icons.security;
    if (slug.contains('procedure')) return Icons.format_list_numbered;
    if (slug.contains('case')) return Icons.folder;
    if (slug.contains('law')) return Icons.gavel;
    return Icons.article;
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/legal_education_controller.dart';
import '../models/legal_education_models.dart';
import '../widgets/material_card.dart';
import 'material_viewer_screen.dart';

class TopicMaterialsScreen extends StatefulWidget {
  final Topic? topic;

  const TopicMaterialsScreen({
    super.key,
    this.topic,
  });

  @override
  State<TopicMaterialsScreen> createState() => _TopicMaterialsScreenState();
}

class _TopicMaterialsScreenState extends State<TopicMaterialsScreen> {
  late LegalEducationController controller;
  late Topic currentTopic;
  String? selectedLanguage;

  @override
  void initState() {
    super.initState();

    // Ensure controller is available
    controller = Get.put(LegalEducationController());

    // Get topic and language from arguments or use the provided topic
    if (widget.topic != null) {
      // Topic passed directly (fallback)
      currentTopic = widget.topic!;
      selectedLanguage = null;
    } else {
      // Get from arguments
      final args = Get.arguments;
      if (args is Map<String, dynamic>) {
        // New format with topic and language
        currentTopic = args['topic'] as Topic;
        selectedLanguage = args['language'] as String?;
      } else {
        // Old format with just topic
        currentTopic = args as Topic;
        selectedLanguage = null;
      }
    }

    // Load materials when screen is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchMaterials(
        currentTopic.slug,
        language: selectedLanguage,
        refresh: true,
      );
    });
  }

  void _changeLanguage(String? language) {
    setState(() {
      selectedLanguage = language;
    });
    controller.fetchMaterials(
      currentTopic.slug,
      language: language,
      refresh: true,
    );
  }

  String _getTopicTitle() {
    if (selectedLanguage == 'en') {
      return currentTopic.name; // English name
    } else if (selectedLanguage == 'sw') {
      return currentTopic.nameSw; // Swahili name
    } else {
      // When no specific language is selected, default to English
      return currentTopic.name;
    }
  }

  String _getTopicDescription() {
    if (selectedLanguage == 'en') {
      return currentTopic.description; // English description
    } else if (selectedLanguage == 'sw') {
      return currentTopic.descriptionSw; // Swahili description
    } else {
      // When no specific language is selected, default to English
      return currentTopic.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => CustomScrollView(
            controller: controller.materialsScrollController,
            slivers: [
              // Topic-specific header
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                titleSpacing: 0,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.95),
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                actions: [
                  // Language toggle buttons as prominent action
                  Container(
                    margin: const EdgeInsets.only(right: 8, top: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // English Button
                        ElevatedButton(
                          onPressed: () => _changeLanguage('en'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedLanguage == 'en'
                                ? Colors.blue
                                : Colors.white.withOpacity(0.2),
                            foregroundColor: selectedLanguage == 'en'
                                ? Colors.white
                                : Colors.white.withOpacity(0.9),
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
                                    : Colors.white.withOpacity(0.9),
                              )),
                        ),
                        const SizedBox(width: 4),
                        // Swahili Button
                        ElevatedButton(
                          onPressed: () => _changeLanguage('sw'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedLanguage == 'sw'
                                ? Colors.amber.shade700
                                : Colors.white.withOpacity(0.2),
                            foregroundColor: selectedLanguage == 'sw'
                                ? Colors.black
                                : Colors.white.withOpacity(0.9),
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
                                    : Colors.white.withOpacity(0.9),
                              )),
                        ),
                      ],
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding:
                      const EdgeInsets.only(left: 16, right: 140, bottom: 16),
                  title: Text(
                    _getTopicTitle(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 3,
                          color: Theme.of(context)
                              .colorScheme
                              .shadow
                              .withOpacity(0.5),
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
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_getTopicDescription().isNotEmpty) ...[
                              const SizedBox(height: 60),
                              Text(
                                _getTopicDescription(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.library_books,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${controller.materials.length} materials',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                if (selectedLanguage != null) ...[
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: selectedLanguage == 'en'
                                          ? Colors.blue
                                          : Colors.amber.shade700,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      selectedLanguage == 'en'
                                          ? 'English'
                                          : 'Kiswahili',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(
                                height: 48), // Space for pinned title
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content based on state
              if (controller.materialsError.isNotEmpty &&
                  controller.materials.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(controller.materialsError,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => controller.fetchMaterials(
                            currentTopic.slug,
                            language: selectedLanguage,
                            refresh: true,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (controller.materials.isEmpty &&
                  controller.isLoadingMaterials)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading materials...'),
                      ],
                    ),
                  ),
                )
              else if (controller.materials.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.library_books_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No materials found',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          selectedLanguage != null
                              ? 'No learning materials available for this topic in ${selectedLanguage == 'en' ? 'English' : 'Kiswahili'}'
                              : 'No learning materials available for this topic',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Materials list
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < controller.materials.length) {
                          final material = controller.materials[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: MaterialCard(
                              material: material,
                              onTap: () => _openMaterial(context, material),
                            ),
                          );
                        } else {
                          // Loading indicator at the end
                          if (controller.hasMoreMaterials) {
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
                      childCount: controller.materials.length +
                          (controller.hasMoreMaterials ? 1 : 0),
                    ),
                  ),
                ),
              ],
            ],
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.fetchMaterials(
          currentTopic.slug,
          language: selectedLanguage,
          refresh: true,
        ),
        tooltip: 'Refresh Materials',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _openMaterial(BuildContext context, LearningMaterial material) {
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
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/hub_content_controller.dart';
import '../models/hub_content_models.dart';
import 'hub_content_card.dart';

class HubContentSearchDelegate extends SearchDelegate {
  final HubContentController controller;
  final RxList<HubContentItem> searchResults = <HubContentItem>[].obs;
  final RxBool isSearching = false.obs;

  HubContentSearchDelegate(this.controller);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          if (query.isEmpty) {
            close(context, null);
          } else {
            query = '';
            searchResults.clear();
          }
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildSearchHistory();
    }
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(
        child: Text(
          'Enter search terms to find content',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    // Trigger search when query changes
    _performSearch();

    return Obx(() {
      if (isSearching.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Searching...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      }

      if (searchResults.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'No results found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try different keywords or check your spelling',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: searchResults.length,
        itemBuilder: (context, index) {
          final content = searchResults[index];
          return HubContentCard(
            content: content,
            hubType: controller.hubType,
            controller: controller,
            onTap: () {
              controller.trackView(content);
              _navigateToMaterialViewer(content);
            },
            onLike: () => controller.toggleLike(content),
            onBookmark: () => controller.toggleBookmark(content),
            onRate: (rating, review) =>
                controller.rateContent(content, rating, review),
            onView: () => controller.trackView(content),
          );
        },
      );
    });
  }

  Widget _buildSearchHistory() {
    // TODO: Implement search history from local storage
    final recentSearches = [
      'legal research',
      'case studies',
      'constitutional law',
      'contract law',
    ];

    return Builder(
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Recent Searches',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...recentSearches.map((search) => ListTile(
                leading: const Icon(Icons.history),
                title: Text(search),
                trailing: IconButton(
                  icon: const Icon(Icons.north_west),
                  onPressed: () {
                    query = search;
                    showResults(context);
                  },
                ),
                onTap: () {
                  query = search;
                  showResults(context);
                },
              )),
          const SizedBox(height: 24),
          const Text(
            'Popular Searches',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'human rights',
              'environmental law',
              'corporate law',
              'criminal procedure',
              'civil rights',
              'international law',
            ]
                .map((tag) => ActionChip(
                      label: Text(tag),
                      onPressed: () {
                        query = tag;
                        showResults(context);
                      },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  void _performSearch() {
    if (query.length < 2) return;

    if (!isSearching.value) {
      isSearching.value = true;
      controller.searchContent(query).then((_) {
        searchResults.assignAll(controller.searchResults);
        isSearching.value = false;
      }).catchError((error) {
        isSearching.value = false;
        Get.snackbar(
          'Search Error',
          'Failed to search content. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      });
    }
  }

  @override
  String get searchFieldLabel => 'Search content...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  void _navigateToMaterialViewer(HubContentItem content) {
    // Close search first
    close(Get.context!, null);

    // Track view when user taps to view content
    controller.trackViewOnInteraction(content, 'view');

    // Convert hub content to LearningMaterial format for viewer compatibility
    final material = controller.convertToLearningMaterial(content);

    Get.toNamed(
      '/material-viewer',
      arguments: {
        'material': material,
        'source': controller.hubType,
      },
    );
  }
}

// Helper widget for highlighting search terms
class HighlightedText extends StatelessWidget {
  final String text;
  final String highlight;
  final TextStyle? style;

  const HighlightedText({
    super.key,
    required this.text,
    required this.highlight,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (highlight.isEmpty) {
      return Text(text, style: style);
    }

    final theme = Theme.of(context);
    final highlightStyle = (style ?? const TextStyle()).copyWith(
      backgroundColor: theme.colorScheme.primary.withOpacity(0.3),
      fontWeight: FontWeight.bold,
    );

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerHighlight = highlight.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerHighlight, start);

    while (index >= 0) {
      // Add text before highlight
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: style,
        ));
      }

      // Add highlighted text
      spans.add(TextSpan(
        text: text.substring(index, index + highlight.length),
        style: highlightStyle,
      ));

      start = index + highlight.length;
      index = lowerText.indexOf(lowerHighlight, start);
    }

    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: style,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  IconData _getContentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'article':
        return Icons.article;
      case 'discussion':
        return Icons.forum;
      case 'question':
        return Icons.help_outline;
      case 'announcement':
        return Icons.campaign;
      case 'resource':
        return Icons.folder;
      case 'case_study':
        return Icons.gavel;
      case 'study_material':
        return Icons.school;
      default:
        return Icons.description;
    }
  }
}

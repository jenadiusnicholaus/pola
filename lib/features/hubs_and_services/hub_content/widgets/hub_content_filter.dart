import 'package:flutter/material.dart';
import '../controllers/hub_content_controller.dart';
import 'comprehensive_filter_sheet.dart';

class HubContentFilter extends StatefulWidget {
  final HubContentController controller;

  const HubContentFilter({
    super.key,
    required this.controller,
  });

  @override
  State<HubContentFilter> createState() => _HubContentFilterState();

  static void showFilter(
      BuildContext context, HubContentController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HubContentFilter(controller: controller),
    );
  }

  static void showComprehensiveFilter(
      BuildContext context, HubContentController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComprehensiveFilterSheet(
        controller: controller,
        hubType: controller.hubType,
      ),
    );
  }
}

class _HubContentFilterState extends State<HubContentFilter> {
  late HubContentController controller;
  late String selectedContentType;
  late String selectedSort;
  late bool showDownloadableOnly;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    selectedContentType = controller.selectedContentType.value;
    selectedSort = controller.sortBy.value;
    showDownloadableOnly = controller.showDownloadableOnly.value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      'Filter Content',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _resetFilters,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Content Type Section
                      Text(
                        'Content Type',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'all',
                          'pdf',
                          'video',
                          'image',
                          'audio',
                          'document'
                        ]
                            .map((type) => FilterChip(
                                  label: Text(_getContentTypeLabel(type)),
                                  selected: selectedContentType == type,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        selectedContentType = type;
                                      });
                                    }
                                  },
                                ))
                            .toList(),
                      ),

                      const SizedBox(height: 24),

                      // Sort Section
                      Text(
                        'Sort By',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          'recent',
                          'popular',
                          'trending',
                          'likes',
                          'alphabetical',
                          'pinned_first',
                          'price_high',
                          'price_low'
                        ]
                            .map((sort) => RadioListTile<String>(
                                  title: Text(_getSortLabel(sort)),
                                  value: sort,
                                  groupValue: selectedSort,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedSort = value!;
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                ))
                            .toList(),
                      ),

                      const SizedBox(height: 24),

                      // Additional Options
                      Text(
                        'Options',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Show Downloadable Only'),
                        subtitle: const Text(
                            'Only show content available for download'),
                        value: showDownloadableOnly,
                        onChanged: (value) {
                          setState(() {
                            showDownloadableOnly = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),

                      const SizedBox(
                          height: 80), // Bottom padding for action buttons
                    ],
                  ),
                ),
              ),

              // Bottom action buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Apply filters
                          controller.applyFilters(
                            contentType: selectedContentType,
                            sort: selectedSort,
                            downloadableOnly: showDownloadableOnly,
                          );
                          Navigator.pop(context);
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _resetFilters() {
    setState(() {
      selectedContentType = 'all';
      selectedSort = 'recent';
      showDownloadableOnly = false;
    });
  }

  String _getContentTypeLabel(String type) {
    switch (type) {
      case 'all':
        return 'All Content';
      case 'pdf':
        return 'PDF Documents';
      case 'video':
        return 'Videos';
      case 'image':
        return 'Images';
      case 'audio':
        return 'Audio Files';
      case 'document':
        return 'Documents';
      default:
        return type
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  String _getSortLabel(String sort) {
    switch (sort) {
      case 'recent':
        return 'Most Recent';
      case 'popular':
        return 'Most Popular';
      case 'trending':
        return 'Trending (Downloads)';
      case 'likes':
        return 'Most Liked';
      case 'alphabetical':
        return 'Alphabetical (A-Z)';
      case 'pinned_first':
        return 'Pinned First';
      case 'price_high':
        return 'Price: High to Low';
      case 'price_low':
        return 'Price: Low to High';
      default:
        return sort
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }
}

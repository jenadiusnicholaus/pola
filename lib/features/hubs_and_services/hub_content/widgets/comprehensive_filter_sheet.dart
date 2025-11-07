import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/hub_content_controller.dart';

class ComprehensiveFilterSheet extends StatefulWidget {
  final HubContentController controller;
  final String hubType;

  const ComprehensiveFilterSheet({
    super.key,
    required this.controller,
    required this.hubType,
  });

  @override
  State<ComprehensiveFilterSheet> createState() =>
      _ComprehensiveFilterSheetState();
}

class _ComprehensiveFilterSheetState extends State<ComprehensiveFilterSheet> {
  late String selectedContentType;
  late String selectedUploaderType;
  late String selectedSort;
  late bool showDownloadableOnly;
  late bool showPinnedOnly;
  late bool showLectureMaterialOnly;
  late bool showFreeOnly;
  late double minPrice;
  late double maxPrice;

  @override
  void initState() {
    super.initState();
    // Initialize with current controller values
    selectedContentType = widget.controller.selectedContentType.value;
    selectedUploaderType = widget.controller.selectedUploaderType.value;
    selectedSort = widget.controller.sortBy.value;
    showDownloadableOnly = widget.controller.showDownloadableOnly.value;
    showPinnedOnly = widget.controller.showPinnedOnly.value;
    showLectureMaterialOnly = widget.controller.showLectureMaterialOnly.value;
    showFreeOnly = widget.controller.showFreeOnly.value;
    minPrice = widget.controller.minPrice.value;
    maxPrice = widget.controller.maxPrice.value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      onPressed: _resetAllFilters,
                      child: const Text('Reset All'),
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
                      // Content Type Filter
                      _buildSectionTitle('Content Type'),
                      _buildContentTypeFilter(theme),
                      const SizedBox(height: 24),

                      // Uploader Type Filter
                      _buildSectionTitle('Uploader Type'),
                      _buildUploaderTypeFilter(theme),
                      const SizedBox(height: 24),

                      // Content Properties
                      _buildSectionTitle('Content Properties'),
                      _buildContentPropertiesFilter(theme),
                      const SizedBox(height: 24),

                      // Price Range
                      _buildSectionTitle('Price Range'),
                      _buildPriceRangeFilter(theme),
                      const SizedBox(height: 24),

                      // Sort Options
                      _buildSectionTitle('Sort By'),
                      _buildSortOptions(theme),
                      const SizedBox(height: 24),

                      // Action Buttons
                      _buildActionButtons(theme),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildContentTypeFilter(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.controller.getAvailableContentTypes().map((type) {
        final isSelected = selectedContentType == type;
        return FilterChip(
          label: Text(_getContentTypeLabel(type)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              selectedContentType = selected ? type : 'all';
            });
          },
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          selectedColor: theme.colorScheme.primaryContainer,
          checkmarkColor: theme.colorScheme.onPrimaryContainer,
        );
      }).toList(),
    );
  }

  Widget _buildUploaderTypeFilter(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.controller.getAvailableUploaderTypes().map((type) {
        final isSelected = selectedUploaderType == type;
        return FilterChip(
          label: Text(_getUploaderTypeLabel(type)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              selectedUploaderType = selected ? type : 'all';
            });
          },
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          selectedColor: theme.colorScheme.secondaryContainer,
          checkmarkColor: theme.colorScheme.onSecondaryContainer,
        );
      }).toList(),
    );
  }

  Widget _buildContentPropertiesFilter(ThemeData theme) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Downloadable Only'),
          subtitle: const Text('Show only content that can be downloaded'),
          value: showDownloadableOnly,
          onChanged: (value) {
            setState(() {
              showDownloadableOnly = value;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Pinned Content'),
          subtitle: const Text('Show featured/important content'),
          value: showPinnedOnly,
          onChanged: (value) {
            setState(() {
              showPinnedOnly = value;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        if (_shouldShowLectureMaterialFilter())
          SwitchListTile(
            title: const Text('Lecture Materials'),
            subtitle: const Text('Show academic lecture content'),
            value: showLectureMaterialOnly,
            onChanged: (value) {
              setState(() {
                showLectureMaterialOnly = value;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget _buildPriceRangeFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Free Content Only'),
          subtitle: const Text('Show only free content'),
          value: showFreeOnly,
          onChanged: (value) {
            setState(() {
              showFreeOnly = value;
              if (value) {
                minPrice = 0.0;
                maxPrice = 0.0;
              } else {
                maxPrice = 1000.0;
              }
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        if (!showFreeOnly) ...[
          const SizedBox(height: 16),
          Text(
            'Price Range: \$${minPrice.toInt()} - \$${maxPrice.toInt()}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: RangeValues(minPrice, maxPrice),
            min: 0,
            max: 1000,
            divisions: 20,
            labels: RangeLabels(
              '\$${minPrice.toInt()}',
              '\$${maxPrice.toInt()}',
            ),
            onChanged: (values) {
              setState(() {
                minPrice = values.start;
                maxPrice = values.end;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSortOptions(ThemeData theme) {
    return Column(
      children: widget.controller.getSortOptions().map((option) {
        return RadioListTile<String>(
          title: Text(option['label']!),
          value: option['value']!,
          groupValue: selectedSort,
          onChanged: (value) {
            setState(() {
              selectedSort = value!;
            });
          },
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _resetAllFilters,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Reset'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Apply Filters'),
          ),
        ),
      ],
    );
  }

  void _resetAllFilters() {
    setState(() {
      selectedContentType = 'all';
      selectedUploaderType = 'all';
      selectedSort = 'recent';
      showDownloadableOnly = false;
      showPinnedOnly = false;
      showLectureMaterialOnly = false;
      showFreeOnly = false;
      minPrice = 0.0;
      maxPrice = 1000.0;
    });
  }

  void _applyFilters() {
    widget.controller.applyFilters(
      contentType: selectedContentType,
      uploaderType: selectedUploaderType,
      sort: selectedSort,
      downloadableOnly: showDownloadableOnly,
      pinnedOnly: showPinnedOnly,
      lectureMaterialOnly: showLectureMaterialOnly,
      freeOnly: showFreeOnly,
      minPrice: showFreeOnly ? null : minPrice,
      maxPrice: showFreeOnly ? null : maxPrice,
    );
    Get.back();
  }

  String _getContentTypeLabel(String type) {
    switch (type) {
      case 'all':
        return 'All Types';
      case 'pdf':
        return 'PDF Documents';
      case 'video':
        return 'Videos';
      case 'image':
        return 'Images';
      case 'audio':
        return 'Audio';
      case 'document':
        return 'Documents';
      default:
        return type.toUpperCase();
    }
  }

  String _getUploaderTypeLabel(String type) {
    switch (type) {
      case 'all':
        return 'All Uploaders';
      case 'lecturer':
        return 'Lecturers';
      case 'student':
        return 'Students';
      case 'advocate':
        return 'Advocates';
      case 'admin':
        return 'Administrators';
      default:
        return type.capitalize ?? type;
    }
  }

  bool _shouldShowLectureMaterialFilter() {
    // Show lecture material filter for educational hubs
    return widget.hubType == 'students' || widget.hubType == 'legal_ed';
  }
}

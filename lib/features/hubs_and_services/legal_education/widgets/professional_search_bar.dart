import 'package:flutter/material.dart';
import '../controllers/legal_education_controller.dart';

class ProfessionalSearchBar extends StatefulWidget {
  final LegalEducationController controller;
  final String hintText;
  final VoidCallback? onFilterTap;

  const ProfessionalSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search legal topics...',
    this.onFilterTap,
  });

  @override
  State<ProfessionalSearchBar> createState() => _ProfessionalSearchBarState();
}

class _ProfessionalSearchBarState extends State<ProfessionalSearchBar> {
  late TextEditingController _searchController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: widget.controller.searchQuery);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Search Icon
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(
                Icons.search_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                size: 20,
              ),
            ),

            // Search TextField
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: (value) {
                  setState(() {});
                  widget.controller.searchTopics(value);
                },
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 16,
                  ),
                ),
              ),
            ),

            // Action Buttons Row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Clear Button
                if (_searchController.text.isNotEmpty) ...[
                  AnimatedScale(
                    scale: _searchController.text.isNotEmpty ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        widget.controller.clearSearch();
                        setState(() {});
                      },
                      tooltip: 'Clear search',
                    ),
                  ),
                ],

                // Language Filter Button
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: PopupMenuButton<LanguageFilter>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.language_rounded,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    onSelected: (LanguageFilter value) {
                      widget.controller.setLanguageFilter(value);
                    },
                    tooltip: 'Filter by language',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                        value: LanguageFilter.both,
                        child: Row(
                          children: [
                            Icon(
                              Icons.public_rounded,
                              size: 18,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            const SizedBox(width: 12),
                            const Text('All Languages'),
                            if (widget.controller.languageFilter ==
                                LanguageFilter.both) ...[
                              const Spacer(),
                              Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: LanguageFilter.english,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'EN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('English'),
                            if (widget.controller.languageFilter ==
                                LanguageFilter.english) ...[
                              const Spacer(),
                              Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: LanguageFilter.swahili,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SW',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('Kiswahili'),
                            if (widget.controller.languageFilter ==
                                LanguageFilter.swahili) ...[
                              const Spacer(),
                              Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

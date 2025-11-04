import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/legal_education_controller.dart';

class LanguageFilterButtons extends StatelessWidget {
  const LanguageFilterButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LegalEducationController>();

    return Obx(() => Row(
          children: LanguageFilter.values.map((filter) {
            final isSelected = controller.languageFilter == filter;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildFilterButton(
                  context: context,
                  filter: filter,
                  isSelected: isSelected,
                  onTap: () => controller.setLanguageFilter(filter),
                ),
              ),
            );
          }).toList(),
        ));
  }

  Widget _buildFilterButton({
    required BuildContext context,
    required LanguageFilter filter,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Define colors based on selection and theme
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    if (isSelected) {
      backgroundColor = isDark ? Colors.white : Colors.black;
      textColor = isDark ? Colors.black : Colors.white;
      borderColor = backgroundColor;
    } else {
      backgroundColor = Colors.transparent;
      textColor = isDark ? Colors.white : Colors.black;
      borderColor = isDark
          ? Colors.white.withOpacity(0.3)
          : Colors.black.withOpacity(0.3);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getFilterIcon(filter),
                  size: 14,
                  color: textColor,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _getFilterLabel(filter),
                    style: TextStyle(
                      color: textColor,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFilterIcon(LanguageFilter filter) {
    switch (filter) {
      case LanguageFilter.both:
        return Icons.all_inclusive;
      case LanguageFilter.english:
        return Icons.language;
      case LanguageFilter.swahili:
        return Icons.translate;
    }
  }

  String _getFilterLabel(LanguageFilter filter) {
    switch (filter) {
      case LanguageFilter.both:
        return 'All';
      case LanguageFilter.english:
        return 'English';
      case LanguageFilter.swahili:
        return 'Swahili';
    }
  }
}

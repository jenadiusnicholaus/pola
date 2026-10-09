import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/legal_education_models.dart';
import '../../../../services/language_service.dart';

class TopicCard extends StatelessWidget {
  final Topic topic;
  final Function(String language) onLanguageTap; // Changed to pass language

  const TopicCard({
    super.key,
    required this.topic,
    required this.onLanguageTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.onSurface;

    return Obx(() {
      // Follow the global app language — no manual per-topic toggle.
      String lang = 'en';
      try {
        lang = Get.find<LanguageService>().languageObs.value;
      } catch (_) {}

      final isSwahili = lang == 'sw';
      final label = isSwahili
          ? (topic.nameSw.isNotEmpty ? topic.nameSw : topic.name)
          : (topic.name.isNotEmpty ? topic.name : topic.nameSw);

      return Material(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => onLanguageTap(lang),
          borderRadius: BorderRadius.circular(14),
          splashColor: accent.withOpacity(0.08),
          highlightColor: accent.withOpacity(0.04),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon tile
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTopicIcon(topic.slug),
                    size: 22,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 14),

                // Topic name + subtopic count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          letterSpacing: 0.1,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (topic.subtopicsCount > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${topic.subtopicsCount} ${topic.subtopicsCount == 1 ? 'subtopic' : 'subtopics'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Chevron button
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  IconData _getTopicIcon(String slug) {
    final s = slug.toLowerCase();
    if (s.contains('constitution')) return Icons.account_balance_rounded;
    if (s.contains('criminal')) return Icons.gavel_rounded;
    if (s.contains('civil')) return Icons.balance_rounded;
    if (s.contains('family') || s.contains('marriage'))
      return Icons.family_restroom_rounded;
    if (s.contains('land') || s.contains('property'))
      return Icons.home_work_rounded;
    if (s.contains('labour') || s.contains('labor') || s.contains('employment'))
      return Icons.work_outline_rounded;
    if (s.contains('business') ||
        s.contains('company') ||
        s.contains('commercial')) return Icons.business_rounded;
    if (s.contains('tax')) return Icons.request_quote_rounded;
    if (s.contains('human') || s.contains('right'))
      return Icons.volunteer_activism_rounded;
    if (s.contains('court') || s.contains('procedure'))
      return Icons.account_balance;
    return Icons.menu_book_rounded;
  }
}

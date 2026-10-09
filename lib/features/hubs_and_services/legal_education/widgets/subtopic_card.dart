import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:localization_lite/translate.dart';
import '../models/legal_education_models.dart';
import '../../../../services/language_service.dart';

class SubtopicCard extends StatelessWidget {
  final Subtopic subtopic;
  final VoidCallback onTap;
  final String? language; // 'swahili' or null for English

  const SubtopicCard({
    super.key,
    required this.subtopic,
    required this.onTap,
    this.language,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: theme.colorScheme.primary.withOpacity(0.08),
        highlightColor: theme.colorScheme.primary.withOpacity(0.04),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHighest
                : theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Leading Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getSubtopicIconData(),
                  size: 24,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),

              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      _getLocalizedTitle(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Description
                    Text(
                      _getLocalizedDescription(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Footer with stats
                    Row(
                      children: [
                        _buildStatChip(
                          icon: Icons.article,
                          label:
                              '${subtopic.materialsCount} ${tr('Materials')}',
                          color: theme.colorScheme.onSurface.withOpacity(0.65),
                          theme: theme,
                        ),
                        const SizedBox(width: 8),
                        _buildLanguageIndicators(theme),
                      ],
                    ),
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
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color.lerp(color, theme.colorScheme.onSurface, 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageIndicators(ThemeData theme) {
    final hasEnglish = subtopic.name.isNotEmpty;
    final hasSwahili = subtopic.nameSw.isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasEnglish) _buildLanguageChip('EN', Colors.blue, theme),
        if (hasEnglish && hasSwahili) const SizedBox(width: 4),
        if (hasSwahili) _buildLanguageChip('SW', Colors.amber, theme),
      ],
    );
  }

  Widget _buildLanguageChip(String label, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color.withOpacity(0.8),
        ),
      ),
    );
  }

  /// Explicit language param, falling back to the user's stored preference.
  String? get _effectiveLanguage {
    try {
      return language ?? Get.find<LanguageService>().apiCode;
    } catch (_) {
      return language;
    }
  }

  String _getLocalizedTitle() {
    // Use language from API parameter only
    final isSwahili = _effectiveLanguage == 'sw';

    if (isSwahili && subtopic.nameSw.isNotEmpty) {
      return subtopic.nameSw;
    } else if (subtopic.name.isNotEmpty) {
      return subtopic.name;
    } else if (subtopic.nameSw.isNotEmpty) {
      return subtopic.nameSw;
    }

    return subtopic.slug;
  }

  String _getLocalizedDescription() {
    // Use language from API parameter only
    final isSwahili = _effectiveLanguage == 'sw';

    if (isSwahili && subtopic.descriptionSw.isNotEmpty) {
      return subtopic.descriptionSw;
    } else if (subtopic.description.isNotEmpty) {
      return subtopic.description;
    } else if (subtopic.descriptionSw.isNotEmpty) {
      return subtopic.descriptionSw;
    }

    return tr('No description available');
  }

  IconData _getSubtopicIconData() {
    // Map subtopic slugs to relevant icons
    final slug = subtopic.slug.toLowerCase();

    if (slug.contains('right')) return Icons.security;
    if (slug.contains('procedure')) return Icons.format_list_numbered;
    if (slug.contains('case')) return Icons.folder;
    if (slug.contains('law')) return Icons.gavel;
    if (slug.contains('rule')) return Icons.rule;
    if (slug.contains('regulation')) return Icons.policy;
    if (slug.contains('contract')) return Icons.handshake;
    if (slug.contains('property')) return Icons.home_work;
    if (slug.contains('evidence')) return Icons.fact_check;
    if (slug.contains('appeal')) return Icons.call_made;
    if (slug.contains('judgment')) return Icons.balance;
    if (slug.contains('court')) return Icons.account_balance;

    return Icons.article; // Default icon
  }
}

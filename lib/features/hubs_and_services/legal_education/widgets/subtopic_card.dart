import 'package:flutter/material.dart';
import '../models/legal_education_models.dart';

class SubtopicCard extends StatelessWidget {
  final Subtopic subtopic;
  final VoidCallback onTap;

  const SubtopicCard({
    super.key,
    required this.subtopic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 2 : 1,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Leading Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getSubtopicColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getSubtopicIconData(),
                  size: 24,
                  color: _getSubtopicColor(),
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
                          label: '${subtopic.materialsCount} Materials',
                          color: Colors.blue,
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

              // Trailing Arrow
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
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

  String _getLocalizedTitle() {
    final locale = 'en'; // You can get this from Get.locale or other source

    if (locale.startsWith('sw') && subtopic.nameSw.isNotEmpty) {
      return subtopic.nameSw;
    } else if (subtopic.name.isNotEmpty) {
      return subtopic.name;
    } else if (subtopic.nameSw.isNotEmpty) {
      return subtopic.nameSw;
    }

    return subtopic.slug;
  }

  String _getLocalizedDescription() {
    final locale = 'en'; // You can get this from Get.locale or other source

    if (locale.startsWith('sw') && subtopic.descriptionSw.isNotEmpty) {
      return subtopic.descriptionSw;
    } else if (subtopic.description.isNotEmpty) {
      return subtopic.description;
    } else if (subtopic.descriptionSw.isNotEmpty) {
      return subtopic.descriptionSw;
    }

    return 'No description available';
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

  Color _getSubtopicColor() {
    // Map subtopic types to colors
    final slug = subtopic.slug.toLowerCase();

    if (slug.contains('right')) return Colors.purple;
    if (slug.contains('procedure')) return Colors.blue;
    if (slug.contains('case')) return Colors.orange;
    if (slug.contains('law')) return Colors.red;
    if (slug.contains('rule')) return Colors.green;
    if (slug.contains('regulation')) return Colors.indigo;
    if (slug.contains('contract')) return Colors.teal;
    if (slug.contains('property')) return Colors.brown;
    if (slug.contains('evidence')) return Colors.cyan;
    if (slug.contains('appeal')) return Colors.deepOrange;
    if (slug.contains('judgment')) return Colors.pink;
    if (slug.contains('court')) return Colors.deepPurple;

    return Colors.grey; // Default color
  }
}

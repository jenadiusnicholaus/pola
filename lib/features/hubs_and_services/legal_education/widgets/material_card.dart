import 'package:flutter/material.dart';
import '../models/legal_education_models.dart';

class MaterialCard extends StatelessWidget {
  final LearningMaterial material;
  final VoidCallback? onTap;

  const MaterialCard({
    super.key,
    required this.material,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.08),
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.08),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: theme.colorScheme.primary.withOpacity(0.08),
        highlightColor: theme.colorScheme.primary.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading icon based on content type
              _buildLeadingIcon(theme),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with verified badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            material.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: theme.colorScheme.onSurface,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (material.isVerified) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    if (material.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        material.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),

                    // Bottom row: badges and metadata
                    Row(
                      children: [
                        // Language badge
                        _buildBadge(
                          theme: theme,
                          label: material.language == 'sw' ? 'SW' : 'EN',
                          icon: Icons.language,
                          color: material.language == 'sw'
                              ? Colors.amber.shade700
                              : Colors.blue,
                        ),
                        const SizedBox(width: 8),

                        // Price badge
                        _buildBadge(
                          theme: theme,
                          label: _getPriceDisplay(),
                          icon: _isPaidMaterial()
                              ? Icons.paid_outlined
                              : Icons.check_circle_outline,
                          color: _isPaidMaterial()
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),

                        // Downloads count
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.download_outlined,
                              size: 13,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${material.downloadsCount}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Read more arrow
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(ThemeData theme) {
    final IconData icon = _getContentIcon();

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 22,
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      ),
    );
  }

  Widget _buildBadge({
    required ThemeData theme,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getContentIcon() {
    if (material.fileUrl.isEmpty) return Icons.article_outlined;
    final ext = material.fileUrl.toLowerCase();
    if (ext.contains('.pdf')) return Icons.picture_as_pdf_outlined;
    if (ext.contains('.doc') || ext.contains('.docx'))
      return Icons.description_outlined;
    if (material.isImage) return Icons.image_outlined;
    if (material.isLectureMaterial) return Icons.school_outlined;
    return Icons.article_outlined;
  }

  bool _isPaidMaterial() {
    final price = double.tryParse(material.price) ?? 0.0;
    return price > 0;
  }

  String _getPriceDisplay() {
    if (_isPaidMaterial()) {
      final price = double.tryParse(material.price) ?? 0.0;
      return 'TSH ${price.toStringAsFixed(0)}';
    } else {
      return 'FREE';
    }
  }
}

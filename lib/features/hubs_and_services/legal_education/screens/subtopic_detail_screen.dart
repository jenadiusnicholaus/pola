import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/legal_education_controller.dart';
import '../models/legal_education_models.dart';

class SubtopicDetailScreen extends StatefulWidget {
  const SubtopicDetailScreen({super.key});

  @override
  State<SubtopicDetailScreen> createState() => _SubtopicDetailScreenState();
}

class _SubtopicDetailScreenState extends State<SubtopicDetailScreen> {
  late LegalEducationController controller;
  late Subtopic subtopic;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Get subtopic from navigation arguments
    subtopic = Get.arguments as Subtopic;

    controller = Get.find<LegalEducationController>();

    // Load materials for this subtopic if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This would load materials when that feature is implemented
      // controller.loadMaterials(subtopic.slug);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.95),
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _getLocalizedTitle(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black45,
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
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background icon
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(
                          _getSubtopicIconData(),
                          size: 100,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Stats
                    Positioned(
                      bottom: 60,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          _buildStatChip(
                            icon: Icons.article,
                            label: '${subtopic.materialsCount} Materials',
                          ),
                          const SizedBox(width: 12),
                          _buildLanguageIndicators(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description Section
                  Text(
                    'About This Subtopic',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getLocalizedDescription(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Materials Section
                  _buildMaterialsSection(theme),

                  const SizedBox(height: 24),

                  // Additional Info Section
                  _buildInfoSection(theme),
                ],
              ),
            ),
          ),

          // Bottom Padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageIndicators() {
    final hasEnglish = subtopic.name.isNotEmpty;
    final hasSwahili = subtopic.nameSw.isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasEnglish) _buildLanguageChip('English', Icons.language),
        if (hasEnglish && hasSwahili) const SizedBox(width: 8),
        if (hasSwahili) _buildLanguageChip('Kiswahili', Icons.translate),
      ],
    );
  }

  Widget _buildLanguageChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Learning Materials',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${subtopic.materialsCount} items',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Placeholder for materials list
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.construction,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Materials Coming Soon',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Learning materials and resources for this subtopic will be available soon. Check back later for updates.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Information',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          theme: theme,
          icon: Icons.info_outline,
          title: 'Subtopic ID',
          content: subtopic.id.toString(),
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          theme: theme,
          icon: Icons.sort,
          title: 'Display Order',
          content: subtopic.displayOrder.toString(),
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          theme: theme,
          icon: Icons.schedule,
          title: 'Last Updated',
          content: _formatDate(subtopic.lastUpdated),
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedTitle() {
    const locale = 'en'; // Get from Get.locale if needed

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
    const locale = 'en'; // Get from Get.locale if needed

    if (locale.startsWith('sw') && subtopic.descriptionSw.isNotEmpty) {
      return subtopic.descriptionSw;
    } else if (subtopic.description.isNotEmpty) {
      return subtopic.description;
    } else if (subtopic.descriptionSw.isNotEmpty) {
      return subtopic.descriptionSw;
    }

    return 'Detailed information about this subtopic will help you understand the key concepts and applications in this area of law.';
  }

  IconData _getSubtopicIconData() {
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

    return Icons.article;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import '../controllers/template_controller.dart';
import '../models/template_model.dart';
import '../widgets/template_options_bottomsheet.dart';

class TemplatesListScreen extends StatelessWidget {
  const TemplatesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TemplateController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Legal Templates')),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            tooltip: 'My Documents',
            onPressed: () => Get.toNamed('/my-documents'),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.error.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                SizedBox(height: 16),
                Text(
                  tr('Failed to load templates'),
                  style: theme.textTheme.titleLarge,
                ),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    controller.error.value,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: controller.fetchTemplates,
                  icon: Icon(Icons.refresh),
                  label: Text(tr('Retry')),
                ),
              ],
            ),
          );
        }

        if (controller.templates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                SizedBox(height: 16),
                Text(
                  tr('No templates available'),
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchTemplates,
          child: ListView.builder(
            controller: controller.scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: controller.templates.length +
                (controller.hasMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == controller.templates.length) {
                return Obx(() => controller.isLoadingMore.value
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox.shrink());
              }
              final template = controller.templates[index];
              return _TemplateCard(template: template);
            },
          ),
        );
      }),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final DocumentTemplate template;

  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            TemplateOptionsBottomSheet.show(context, template);
          },
          splashColor: theme.colorScheme.primary.withOpacity(0.1),
          highlightColor: theme.colorScheme.primary.withOpacity(0.05),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Text(
                      template.getCategoryIcon(),
                      style: TextStyle(fontSize: 28),
                    ),
                    SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            template.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: 0.1,
                            ),
                          ),
                          SizedBox(height: 4),
                          // Swahili name
                          Text(
                            template.nameSw,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          SizedBox(height: 8),
                          // Description
                          Text(
                            template.description,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.65),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    // Arrow
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Footer with category and stats
                Row(
                  children: [
                    // Category badge
                    Text(
                      template.getCategoryLabel(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(width: 12),
                    // Usage count
                    Icon(
                      Icons.people_outline,
                      size: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${template.usageCount}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    Spacer(),
                    // Price badge - subtle
                    if (template.isFree)
                      Text(
                        tr('FREE'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      )
                    else
                      Text(
                        tr('TZS {price}')
                            .replaceAll('{price}', '${template.price}'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

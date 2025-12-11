import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/template_model.dart';
import '../screens/template_form_screen.dart';

class TemplateOptionsBottomSheet extends StatelessWidget {
  final DocumentTemplate template;

  const TemplateOptionsBottomSheet({
    super.key,
    required this.template,
  });

  static void show(BuildContext context, DocumentTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TemplateOptionsBottomSheet(template: template),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Template info
          Row(
            children: [
              Text(
                template.getCategoryIcon(),
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      template.nameSw,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Choose Document Type',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Blank option
          _OptionCard(
            icon: Icons.description_outlined,
            title: 'Blank Document',
            titleSw: 'Hati Tupu',
            description:
                'Generate an empty template that you can fill manually',
            descriptionSw: 'Tengeneza kiolezo tupu unachoweza kujaza mwenyewe',
            color: theme.colorScheme.primary,
            onTap: () {
              Navigator.pop(context);
              Get.to(
                () => const TemplateFormScreen(),
                arguments: {
                  'template': template,
                  'isBlank': true,
                },
              );
            },
          ),
          const SizedBox(height: 12),

          // Filled option
          _OptionCard(
            icon: Icons.edit_document,
            title: 'Filled Document',
            titleSw: 'Hati Iliyojazwa',
            description:
                'Fill in the form fields and generate a complete document',
            descriptionSw: 'Jaza sehemu za fomu na tengeneza hati kamili',
            color: theme.colorScheme.tertiary,
            onTap: () {
              Navigator.pop(context);
              Get.to(
                () => const TemplateFormScreen(),
                arguments: {
                  'template': template,
                  'isBlank': false,
                },
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String titleSw;
  final String description;
  final String descriptionSw;
  final Color color;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.titleSw,
    required this.description,
    required this.descriptionSw,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      titleSw,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

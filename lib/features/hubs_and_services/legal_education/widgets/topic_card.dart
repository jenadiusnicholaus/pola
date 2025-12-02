import 'package:flutter/material.dart';
import '../models/legal_education_models.dart';

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

    return Row(
      children: [
        // Left Button (Swahili) - Blue
        if (topic.nameSw.isNotEmpty)
          Flexible(
            child: _buildCompactButton(
              theme: theme,
              label: topic.nameSw,
              onTap: () => onLanguageTap('swahili'),
              color: Colors.blue,
              isAvailable: true,
            ),
          ),

        if (topic.nameSw.isNotEmpty && topic.name.isNotEmpty)
          const SizedBox(width: 8),

        // Right Button (English) - Amber
        if (topic.name.isNotEmpty)
          Flexible(
            child: _buildCompactButton(
              theme: theme,
              label: topic.name,
              onTap: () => onLanguageTap('english'),
              color: Colors.amber.shade700,
              isAvailable: true,
            ),
          ),
      ],
    );
  }

  Widget _buildCompactButton({
    required ThemeData theme,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required bool isAvailable,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(20),
            color: Colors.transparent,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
